import SwiftUI

// MARK: - Attendance tab
// The brand backdrop carries the header and the overall-score hero, a glass
// strip sums up the skip margin, and every course then gets a white sheet
// card with a score ring and the number of classes it can still afford to
// miss.

struct AttendanceView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var session = SessionStore.shared
    @State private var drift = false
    @State private var appeared = false

    private var records: [AttendanceRecord] { session.attendance }
    private var overallPct: Double { DashboardStats.overallAttendance(records) }
    private var finished: Bool { DashboardStats.isFinishedSemester(records) }

    private var totalConducted: Int {
        records.reduce(0) { $0 + $1.classesConducted }
    }

    private var totalAbsent: Int {
        records.reduce(0) { $0 + $1.classesAbsent }
    }

    /// Classes that can still be missed across the term.
    private var canSkip: Int {
        DashboardStats.canSkip(conducted: totalConducted, absent: totalAbsent)
    }

    /// Classes that have to be attended to hold on to 75%.
    private var mustAttend: Int {
        DashboardStats.needToAttend(conducted: totalConducted, absent: totalAbsent)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                if records.isEmpty {
                    emptyState
                        .padding(.top, 22)
                    SpFallbackForm(kind: .attendance)
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
            configuration: JaawBackground.attendance,
            drift: drift,
            reduceMotion: reduceMotion,
            tab: .attendance
        )
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Attendance")
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
        guard !records.isEmpty else { return "No attendance published yet" }
        let courses = "\(records.count) course\(records.count == 1 ? "" : "s")"
        guard totalConducted > 0 else { return "\(courses) · no classes held yet" }
        return "\(courses) · \(totalConducted) classes held"
    }

    /// The overall attendance, in the home page's trailing-hero slot.
    private var scoreHero: some View {
        VStack(alignment: .trailing, spacing: -4) {
            Text("OVERALL")
                .font(.system(size: 12, weight: .heavy))
                .tracking(2.1)
                .foregroundStyle(JaawColors.ice.opacity(0.72))
            if records.isEmpty {
                Text("—")
                    .font(.system(size: 64, weight: .heavy))
                    .tracking(-3.2)
                    .foregroundStyle(JaawColors.ice.opacity(0.6))
            } else {
                Text("\(Int(overallPct.rounded()))%")
                    .font(.system(size: 64, weight: .heavy))
                    .tracking(-3.2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(.white)
                    .shadow(color: Color(red: 0, green: 0, blue: 90 / 255, opacity: 0.5), radius: 32, y: 8)
            }
        }
        .frame(width: 140, alignment: .trailing)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            records.isEmpty
                ? "Overall attendance unavailable"
                : "Overall attendance \(Int(overallPct.rounded())) percent"
        )
    }

    // MARK: - Stats strip

    private var statsStrip: some View {
        HStack(spacing: 0) {
            stat(title: "Courses", value: "\(records.count)")
            statDivider
            stat(
                title: "Can skip",
                value: "\(canSkip)",
                tint: canSkip > 0 ? AttendancePalette.safe : AttendancePalette.warning
            )
            statDivider
            stat(
                title: "Must attend",
                value: "\(mustAttend)",
                tint: mustAttend > 0 ? AttendancePalette.atRisk : nil
            )
        }
        .padding(.vertical, 14)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.14))
            .frame(width: 1, height: 28)
    }

    private func stat(title: String, value: String, tint: Color? = nil) -> some View {
        VStack(spacing: 3) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.1)
                .foregroundStyle(JaawColors.ice.opacity(0.6))
            Text(value)
                .font(.system(size: 19, weight: .heavy))
                .tracking(-0.4)
                .foregroundStyle(tint ?? .white)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Cards

    private var cards: some View {
        VStack(spacing: 14) {
            ForEach(Array(records.enumerated()), id: \.offset) { index, record in
                AttendanceCard(
                    record: record,
                    finished: finished,
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

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(JaawColors.ice.opacity(0.8))
            Text("No attendance yet")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(.white)
            Text("Your attendance will show up here once it's published.")
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

/// A course on a white sheet: its code and name, a score ring, how many
/// classes it has held — and how much slack the 75% rule leaves.
private struct AttendanceCard: View {
    var record: AttendanceRecord
    var finished: Bool
    var appeared: Bool
    var reduceMotion: Bool

    private var attended: Int {
        max(record.classesConducted - record.classesAbsent, 0)
    }

    private var percent: Double {
        record.attendancePercentage.clamped(to: 0...100)
    }

    private var fraction: Double { percent / 100 }

    private var tier: Color { AttendancePalette.tier(for: percent) }

    /// How many more classes can be missed before dropping under 75%.
    private var margin: Int {
        let skip = DashboardStats.canSkip(
            conducted: record.classesConducted,
            absent: record.classesAbsent
        )
        if skip > 0 { return skip }
        return -DashboardStats.needToAttend(
            conducted: record.classesConducted,
            absent: record.classesAbsent
        )
    }

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
                        if hasData {
                            Text(tierLabel.uppercased())
                                .font(.system(size: 10, weight: .heavy))
                                .tracking(0.8)
                                .foregroundStyle(tier)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(tier.opacity(0.14), in: Capsule())
                        }
                    }
                    Text(DashboardStats.normalizeSubject(record.courseTitle))
                        .font(.system(size: 19, weight: .heavy))
                        .tracking(-0.5)
                        .foregroundStyle(CardPalette.title)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                scoreRing
            }

            statStrip
                .padding(.top, 16)

            attendanceBar
                .padding(.top, 12)

            if !finished {
                marginStrip
                    .padding(.top, 14)
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

    // MARK: - Stat strip

    /// The course's numbers: classes held, classes attended, classes missed.
    private var statStrip: some View {
        HStack(spacing: 0) {
            statCell(title: "Total", value: "\(record.classesConducted)")
            statDivider
            statCell(
                title: "Attended",
                value: "\(attended)",
                tint: hasData ? tier : nil
            )
            statDivider
            statCell(
                title: "Absent",
                value: "\(record.classesAbsent)",
                tint: record.classesAbsent > 0 ? AttendancePalette.atRisk : nil
            )
        }
        .padding(.vertical, 11)
        .background(
            CardPalette.surface,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }

    private var statDivider: some View {
        Rectangle()
            .fill(CardPalette.divider)
            .frame(width: 1, height: 28)
    }

    private func statCell(title: String, value: String, tint: Color? = nil) -> some View {
        VStack(spacing: 3) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.1)
                .foregroundStyle(CardPalette.muted)
            Text(value)
                .font(.system(size: 17, weight: .heavy))
                .tracking(-0.4)
                .foregroundStyle(tint ?? CardPalette.title)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Score ring

    private var scoreRing: some View {
        ZStack {
            Circle()
                .stroke(hasData ? tier.opacity(0.16) : CardPalette.track, lineWidth: 5)
            if hasData {
                Circle()
                    .trim(from: 0, to: appeared || reduceMotion ? fraction : 0)
                    .stroke(tier, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(
                        reduceMotion ? nil : .easeOut(duration: 0.9).delay(0.1),
                        value: appeared
                    )
            }
            if hasData {
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

    // MARK: - Bar

    private var attendanceBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(CardPalette.track)
                    .frame(height: 6)
                Capsule()
                    .fill(hasData ? tier : Color.clear)
                    .frame(width: proxy.size.width * fraction, height: 6)
            }
        }
        .frame(height: 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            hasData
                ? "\(attended) of \(record.classesConducted) classes attended, \(record.classesAbsent) absent, \(Int(percent.rounded())) percent, \(tierLabel)"
                : "No classes held yet"
        )
    }

    // MARK: - Margin strip

    private var marginStrip: some View {
        HStack(spacing: 8) {
            Image(systemName: margin >= 0 ? "figure.walk" : "exclamationmark.triangle.fill")
                .font(.system(size: 12, weight: .bold))
            Text(marginCaption)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .foregroundStyle(marginColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(marginColor.opacity(0.11), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Values

    private var hasData: Bool {
        record.classesConducted > 0
    }

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

    private var tierLabel: String {
        switch percent {
        case 85...: return "Safe"
        case 75..<85: return "Watch"
        default: return "At risk"
        }
    }

    private var marginCaption: String {
        if margin > 0 { return "Can skip \(margin) more class\(margin == 1 ? "" : "es")" }
        if margin < 0 { return "Attend \(abs(margin)) more to stay above 75%" }
        return "Right at the 75% line"
    }

    private var marginColor: Color {
        if margin > 0 { return AttendancePalette.safe }
        if margin < 0 { return AttendancePalette.atRisk }
        return AttendancePalette.warning
    }
}

// MARK: - Clamping

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}

#Preview("Attendance") {
    AttendanceView()
}
