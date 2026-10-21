import SwiftUI

// MARK: - Marks tab
// The brand backdrop carries the header and an overall-score hero, a glass
// strip sums the term up, and every course then gets a white sheet card
// with a score ring and an expandable assessment breakdown.

struct MarksView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var session = SessionStore.shared
    @State private var drift = false
    @State private var appeared = false

    private var marks: [MarkRecord] { session.marks }

    private var courseTitles: [String: String] {
        Dictionary(
            session.courses.map { ($0.courseCode, $0.courseTitle) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    /// Courses, strongest score first — the page reads as a leaderboard.
    private var rankedMarks: [MarkRecord] {
        marks.sorted { percent($0) > percent($1) }
    }

    private var bestPercent: Double {
        marks.map(percent).max() ?? 0
    }

    /// The term's weighted score across every course that reported totals.
    private var overallFraction: Double? {
        let obtained = marks.compactMap(\.totalMarksObtained).reduce(0, +)
        let maximum = marks.compactMap(\.totalMarksMaximum).reduce(0, +)
        guard maximum > 0 else { return nil }
        return obtained / maximum
    }

    private var assessmentCount: Int {
        marks.reduce(0) { $0 + $1.assessments.count }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                if marks.isEmpty {
                    emptyState
                        .padding(.top, 22)
                    SpFallbackForm(kind: .marks)
                        .padding(.top, 16)
                } else {
                    statsStrip
                        .padding(.top, 18)
                    cards
                        .padding(.top, 18)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .background { backdrop }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            appeared = true
            guard !reduceMotion else { return }
            drift = true
        }
    }

    private var backdrop: some View {
        JaawTabBackdrop(
            configuration: JaawBackground.marks,
            drift: drift,
            reduceMotion: reduceMotion,
            tab: .marks
        )
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Marks")
                    .font(.system(size: 34, weight: .heavy))
                    .tracking(-1.3)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(summaryLine)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(JaawColors.ice.opacity(0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .shadow(color: Color(red: 0, green: 0, blue: 90 / 255, opacity: 0.45), radius: 26, y: 8)

            Spacer(minLength: 0)

            scoreHero
        }
        .padding(.top, 6)
    }

    private var summaryLine: String {
        guard !marks.isEmpty else { return "No results published yet" }
        return "\(marks.count) course\(marks.count == 1 ? "" : "s") · \(assessmentCount) assessment\(assessmentCount == 1 ? "" : "s")"
    }

    /// The overall score, in the home page's trailing-hero slot.
    private var scoreHero: some View {
        VStack(alignment: .trailing, spacing: -4) {
            Text("OVERALL")
                .font(.system(size: 12, weight: .heavy))
                .tracking(2.1)
                .foregroundStyle(JaawColors.ice.opacity(0.72))
            if let overallFraction {
                Text("\(Int((overallFraction * 100).rounded()))%")
                    .font(.system(size: 64, weight: .heavy))
                    .tracking(-3.2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(.white)
                    .shadow(color: Color(red: 0, green: 0, blue: 90 / 255, opacity: 0.5), radius: 32, y: 8)
            } else {
                Text("—")
                    .font(.system(size: 64, weight: .heavy))
                    .tracking(-3.2)
                    .foregroundStyle(JaawColors.ice.opacity(0.6))
            }
        }
        .frame(width: 140, alignment: .trailing)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            overallFraction.map { "Overall score \(Int(($0 * 100).rounded())) percent" }
                ?? "Overall score unavailable"
        )
    }

    // MARK: - Stats strip

    private var statsStrip: some View {
        HStack(spacing: 0) {
            stat(title: "Courses", value: "\(marks.count)")
            statDivider
            stat(title: "Best", value: bestPercent > 0 ? "\(Int(bestPercent.rounded()))%" : "—")
            statDivider
            stat(title: "Assessments", value: "\(assessmentCount)")
        }
        .padding(.vertical, 14)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.14))
            .frame(width: 1, height: 28)
    }

    private func stat(title: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.1)
                .foregroundStyle(JaawColors.ice.opacity(0.6))
            Text(value)
                .font(.system(size: 19, weight: .heavy))
                .tracking(-0.4)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Cards

    private var cards: some View {
        VStack(spacing: 14) {
            ForEach(Array(rankedMarks.enumerated()), id: \.offset) { index, record in
                MarkCourseCard(
                    record: record,
                    courseName: courseTitles[record.courseCode] ?? record.courseCode,
                    isBest: index == bestIndex,
                    appeared: appeared,
                    reduceMotion: reduceMotion
                )
                .opacity(appeared || reduceMotion ? 1 : 0)
                .offset(y: appeared || reduceMotion ? 0 : 14)
                .animation(
                    reduceMotion
                        ? nil
                        : .easeOut(duration: 0.5).delay(0.05 * Double(index)),
                    value: appeared
                )
            }
        }
    }

    /// Where the top-scoring course sits in the ranked list.
    private var bestIndex: Int? {
        guard bestPercent > 0 else { return nil }
        return rankedMarks.firstIndex { percent($0) == bestPercent }
    }

    // MARK: - Maths

    /// A course's percentage, or zero when it hasn't reported totals.
    private func percent(_ record: MarkRecord) -> Double {
        guard let maximum = record.totalMarksMaximum, maximum > 0,
              let obtained = record.totalMarksObtained
        else { return 0 }
        return (obtained / maximum) * 100
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(JaawColors.ice.opacity(0.8))
            Text("No marks yet")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(.white)
            Text("Your results will show up here once they are published.")
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .foregroundStyle(JaawColors.ice.opacity(0.7))
                .frame(maxWidth: 280)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
        .padding(.horizontal, 20)
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Course card

/// A course on a white sheet: the code and name, a score ring, the absolute
/// marks and — folded away until asked for — the assessment breakdown.
private struct MarkCourseCard: View {
    var record: MarkRecord
    var courseName: String
    var isBest: Bool
    var appeared: Bool
    var reduceMotion: Bool

    @State private var isOpen = false

    private var fraction: Double {
        guard let maximum = record.totalMarksMaximum, maximum > 0,
              let obtained = record.totalMarksObtained
        else { return 0 }
        return (obtained / maximum).clamped(to: 0...1)
    }

    private var percent: Double { fraction * 100 }

    private var tier: Color { MarksPalette.tier(for: percent) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(record.courseCode)
                            .font(.system(size: 12.5, weight: .heavy))
                            .tracking(0.3)
                            .foregroundStyle(CardPalette.accentInk)
                        if !typeLabel.isEmpty {
                            Text(typeLabel)
                                .font(.system(size: 10, weight: .heavy))
                                .tracking(0.8)
                                .foregroundStyle(CardPalette.muted)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(CardPalette.surfaceAlt, in: Capsule())
                        }
                        if isBest {
                            Label("Best", systemImage: "star.fill")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundStyle(MarksPalette.best)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(MarksPalette.best.opacity(0.16), in: Capsule())
                        }
                    }
                    Text(courseName)
                        .font(.system(size: 19, weight: .heavy))
                        .tracking(-0.5)
                        .foregroundStyle(CardPalette.title)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                scoreRing
            }

            marksBar
                .padding(.top, 16)

            if !record.assessments.isEmpty {
                Rectangle()
                    .fill(CardPalette.divider)
                    .frame(height: 1)
                    .padding(.top, 16)
                    .padding(.bottom, 4)

                Button {
                    guard !record.assessments.isEmpty else { return }
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.85)) {
                        isOpen.toggle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 12.5, weight: .semibold))
                        Text("Assessment breakdown")
                            .font(.system(size: 13.5, weight: .semibold))
                        Text("\(record.assessments.count)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(CardPalette.muted)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(CardPalette.surfaceAlt, in: Capsule())
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(CardPalette.muted)
                            .rotationEffect(.degrees(isOpen ? 180 : 0))
                    }
                    .foregroundStyle(CardPalette.body)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if isOpen {
                    assessments
                        .padding(.top, 6)
                        .padding(.bottom, 4)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(CardPalette.fill)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(CardPalette.border, lineWidth: 1)
                )
                .shadow(color: CardPalette.shadow, radius: 26, y: 12)
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Score ring

    private var scoreRing: some View {
        ZStack {
            Circle()
                .stroke(hasTotals ? tier.opacity(0.16) : CardPalette.track, lineWidth: 5)
            if hasTotals {
                Circle()
                    .trim(from: 0, to: appeared || reduceMotion ? fraction : 0)
                    .stroke(tier, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(
                        reduceMotion ? nil : .easeOut(duration: 0.9).delay(0.1),
                        value: appeared
                    )
            }
            if hasTotals {
                VStack(spacing: -2) {
                    Text("\(Int(percent.rounded()))")
                        .font(.system(size: 19, weight: .heavy))
                        .tracking(-0.6)
                        .foregroundStyle(CardPalette.title)
                    Text("%")
                        .font(.system(size: 9.5, weight: .heavy))
                        .foregroundStyle(CardPalette.muted)
                }
            } else {
                Text("—")
                    .font(.system(size: 19, weight: .heavy))
                    .foregroundStyle(CardPalette.muted)
            }
        }
        .frame(width: 58, height: 58)
        .accessibilityHidden(true)
    }

    // MARK: - Marks bar

    private var marksBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(obtainedText)
                    .font(.system(size: 16, weight: .heavy))
                    .tracking(-0.4)
                    .foregroundStyle(CardPalette.title)
                Text("/ \(maximumText)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(CardPalette.muted)
                Spacer(minLength: 0)
                if hasTotals {
                    Text(tierLabel)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(tier)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3)
                        .background(tier.opacity(0.13), in: Capsule())
                }
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(CardPalette.track)
                        .frame(height: 6)
                    Capsule()
                        .fill(tier)
                        .frame(width: proxy.size.width * fraction, height: 6)
                }
            }
            .frame(height: 6)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            hasTotals
                ? "\(obtainedText) out of \(maximumText), \(Int(percent.rounded())) percent, \(tierLabel)"
                : "Marks not published"
        )
    }

    // MARK: - Assessments

    private var assessments: some View {
        VStack(spacing: 14) {
            ForEach(Array(record.assessments.enumerated()), id: \.offset) { _, assessment in
                AssessmentRowLight(assessment: assessment)
            }
        }
    }

    // MARK: - Values

    /// The course type, shortened to its first word when the portal sends a
    /// long form ("Lab Based Theory" → "Lab").
    private var typeLabel: String {
        let type = record.courseType.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !type.isEmpty else { return "" }
        if type.count > 12, let first = type.split(separator: " ").first {
            return String(first).uppercased()
        }
        return type.uppercased()
    }

    private var hasTotals: Bool {
        guard let maximum = record.totalMarksMaximum, maximum > 0,
              record.totalMarksObtained != nil
        else { return false }
        return true
    }

    private var obtainedText: String {
        guard let obtained = record.totalMarksObtained else { return "—" }
        return String(format: "%.2f", obtained)
    }

    private var maximumText: String {
        guard let maximum = record.totalMarksMaximum else { return "—" }
        return String(format: "%.2f", maximum)
    }

    private var tierLabel: String {
        switch percent {
        case 85...: return "Excellent"
        case 70..<85: return "Good"
        case 50..<70: return "Fair"
        default: return "Needs work"
        }
    }
}

// MARK: - Assessment row

/// A single assessment on the white sheet: its title and marks, with a
/// hairline bar carrying the share that was scored.
private struct AssessmentRowLight: View {
    var assessment: MarkAssessment

    private var obtained: Double {
        Double(assessment.obtainedMarks.trimmingCharacters(in: .whitespaces)) ?? 0
    }

    private var maximum: Double {
        Double(assessment.maximumMarks.trimmingCharacters(in: .whitespaces)) ?? 0
    }

    private var fraction: Double {
        guard maximum > 0 else { return 0 }
        return (obtained / maximum).clamped(to: 0...1)
    }

    private var tier: Color { MarksPalette.tier(for: fraction * 100) }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(assessment.title)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(CardPalette.title)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text("\(obtainedText) / \(maximumText)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(tier)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(CardPalette.track)
                        .frame(height: 5)
                    Capsule()
                        .fill(tier)
                        .frame(width: proxy.size.width * fraction, height: 5)
                }
            }
            .frame(height: 5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(assessment.title), \(obtainedText) out of \(maximumText)")
    }

    private var obtainedText: String { String(format: "%.2f", obtained) }
    private var maximumText: String { String(format: "%.2f", maximum) }
}

// MARK: - Clamping

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}

#Preview("Marks") {
    MarksView()
}
