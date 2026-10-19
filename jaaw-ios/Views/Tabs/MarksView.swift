import SwiftUI

// MARK: - Marks tab
// Per-course cards with total scores, tier-colored progress bars and
// expandable assessment breakdowns. Empty marks fall back to an empty state.

struct MarksView: View {
    @State private var session = SessionStore.shared

    private var marks: [MarkRecord] { session.marks }

    private var courseTitles: [String: String] {
        Dictionary(uniqueKeysWithValues: session.courses.map { ($0.courseCode, $0.courseTitle) })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                kicker
                if marks.isEmpty {
                    SpUnavailableCard(
                        title: "Marks unavailable",
                        message: "We couldn't get your marks from Academia.",
                        systemImage: "chart.bar.xaxis"
                    )
                    .padding(.top, 14)
                    SpFallbackForm(kind: .marks)
                        .padding(.top, 16)
                } else {
                    cards
                        .padding(.top, 18)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(HomeColors.page)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Kicker

    private var kicker: some View {
        HStack(alignment: .lastTextBaseline) {
            Text("Marks")
                .font(.system(size: 28, weight: .heavy))
                .tracking(-1.1)
                .foregroundStyle(.white)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            Text(dateLabel)
                .font(.system(size: 14))
                .foregroundStyle(HomeColors.faintText)
        }
        .padding(.horizontal, 6)
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
    }

    private var dateLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "d MMM yyyy"
        fmt.locale = Locale(identifier: "en_US")
        return fmt.string(from: Date())
    }

    // MARK: - Cards

    private var cards: some View {
        VStack(spacing: 14) {
            ForEach(Array(marks.enumerated()), id: \.offset) { _, record in
                MarkCard(
                    record: record,
                    courseName: courseTitles[record.courseCode] ?? record.courseCode
                )
            }
        }
    }
}

// MARK: - Card

private struct MarkCard: View {
    var record: MarkRecord
    var courseName: String

    @State private var isOpen = false

    private var totalPct: Double {
        guard let obtained = record.totalMarksObtained,
              let maximum = record.totalMarksMaximum,
              maximum > 0
        else { return 0 }
        return obtained / maximum * 100
    }

    private var hasTotals: Bool {
        record.totalMarksObtained != nil && record.totalMarksMaximum != nil
    }

    private var tierColor: Color {
        if totalPct >= 80 { return Color(hex: 0x2DD4BF) }
        if totalPct >= 60 { return Color(hex: 0xE7A63F) }
        return Color(hex: 0xE06C6C)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                guard !record.assessments.isEmpty else { return }
                withAnimation(.easeInOut(duration: 0.25)) { isOpen.toggle() }
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(record.courseCode)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                            if !record.courseType.isEmpty {
                                Text(record.courseType)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(HomeColors.secondaryText)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.white.opacity(0.08), in: Capsule())
                            }
                        }
                        Text(courseName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    scoreBadge
                    if !record.assessments.isEmpty {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(HomeColors.secondaryText)
                            .rotationEffect(.degrees(isOpen ? 180 : 0))
                            .padding(.top, 16)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(record.assessments.isEmpty)
            .accessibilityLabel(
                "\(record.courseCode), \(courseName), score \(scoreText)"
            )

            progressBar
                .padding(.top, 16)
                .accessibilityValue("\(Int(totalPct.rounded())) percent")

            if isOpen {
                Rectangle()
                    .fill(HomeColors.cardBorder)
                    .frame(height: 1)
                    .padding(.top, 16)
                assessments
                    .padding(.top, 14)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HomeColors.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(HomeColors.cardBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 18, y: 8)
    }

    private var scoreBadge: some View {
        VStack(spacing: 0) {
            Text(obtainedText)
                .font(.system(size: 24, weight: .heavy))
                .tracking(-1)
            Text("/ \(maxText)")
                .font(.system(size: 11, weight: .semibold))
                .opacity(0.7)
        }
        .foregroundStyle(hasTotals ? tierColor : HomeColors.secondaryText)
        .frame(minWidth: 80)
        .padding(.vertical, 9)
        .padding(.horizontal, 12)
        .background(badgeColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(badgeColor.opacity(0.22), lineWidth: 1)
        )
        .accessibilityHidden(true)
    }

    private var badgeColor: Color {
        hasTotals ? tierColor : HomeColors.secondaryText
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.09))
                    .frame(height: 6)
                Capsule()
                    .fill(tierColor)
                    .frame(width: proxy.size.width * min(max(totalPct, 0), 100) / 100, height: 6)
            }
        }
        .frame(height: 6)
    }

    private var obtainedText: String {
        record.totalMarksObtained.map { String(format: "%.2f", $0) } ?? "—"
    }

    private var maxText: String {
        record.totalMarksMaximum.map { String(format: "%.2f", $0) } ?? "—"
    }

    private var scoreText: String {
        guard let obtained = record.totalMarksObtained else { return "—" }
        let max = record.totalMarksMaximum.map { String(format: "%.2f", $0) } ?? "—"
        return "\(String(format: "%.2f", obtained))/\(max)"
    }

    private var assessments: some View {
        VStack(spacing: 14) {
            ForEach(Array(record.assessments.enumerated()), id: \.offset) { _, assessment in
                AssessmentRow(assessment: assessment)
            }
        }
    }
}

// MARK: - Assessment row

private struct AssessmentRow: View {
    var assessment: MarkAssessment

    private var obtained: Double {
        Double(assessment.obtainedMarks.trimmingCharacters(in: .whitespaces)) ?? 0
    }

    private var maxMarks: Double {
        Double(assessment.maximumMarks.trimmingCharacters(in: .whitespaces)) ?? 0
    }

    private var rowPct: Double {
        maxMarks > 0 ? obtained / maxMarks * 100 : 0
    }

    private var tierColor: Color {
        if rowPct >= 80 { return Color(hex: 0x2DD4BF) }
        if rowPct >= 60 { return Color(hex: 0xE7A63F) }
        return Color(hex: 0xE06C6C)
    }

    private var obtainedText: String { String(format: "%.2f", obtained) }
    private var maxText: String { String(format: "%.2f", maxMarks) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(assessment.title)
                    .font(.system(size: 13.5))
                    .foregroundStyle(HomeColors.secondaryText)
                Spacer(minLength: 0)
                Text("\(obtainedText)/\(maxText)")
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(.white)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.09))
                        .frame(height: 5)
                    Capsule()
                        .fill(tierColor)
                        .frame(width: proxy.size.width * min(max(rowPct, 0), 100) / 100, height: 5)
                }
            }
            .frame(height: 5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(assessment.title), \(obtainedText) out of \(maxText)")
    }
}

#Preview("Marks") {
    MarksView()
}
