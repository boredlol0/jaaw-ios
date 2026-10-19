import SwiftUI

// MARK: - Attendance tab
// Overall hero card plus per-course rows with skip/need margins.
// Empty records (API returned nothing) fall back to an empty state.

struct AttendanceView: View {
    @State private var session = SessionStore.shared

    private var records: [AttendanceRecord] { session.attendance }
    private var overallPct: Double { DashboardStats.overallAttendance(records) }
    private var finished: Bool { DashboardStats.isFinishedSemester(records) }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                kicker
                if records.isEmpty {
                    SpUnavailableCard(
                        title: "Attendance unavailable",
                        message: "We couldn't get your attendance from Academia.",
                        systemImage: "calendar.badge.exclamationmark"
                    )
                    .padding(.top, 14)
                    SpFallbackForm(kind: .attendance)
                        .padding(.top, 16)
                } else {
                    hero
                        .padding(.top, 14)
                    rows
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
            Text("Attendance")
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

    // MARK: - Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Overall attendance")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(HomeColors.tileEyebrow)
            Text(String(format: "%.1f%%", overallPct))
                .font(.system(size: 44, weight: .heavy))
                .tracking(-1.5)
                .foregroundStyle(.white)
                .padding(.top, 6)
                .accessibilityLabel("Overall attendance \(String(format: "%.1f", overallPct)) percent")
            Text(finished ? "Final semester result" : "Across all subjects")
                .font(.system(size: 13))
                .foregroundStyle(HomeColors.secondaryText)
                .padding(.top, 4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [HomeColors.nowStart, HomeColors.nowEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(HomeColors.nowBorder, lineWidth: 1)
                )
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Rows

    private var rows: some View {
        VStack(spacing: 14) {
            ForEach(Array(records.enumerated()), id: \.offset) { _, record in
                AttendanceRow(record: record, finished: finished)
            }
        }
    }
}

// MARK: - Row

private struct AttendanceRow: View {
    var record: AttendanceRecord
    var finished: Bool

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
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
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
                    Text(DashboardStats.normalizeSubject(record.courseTitle))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                if !finished {
                    marginBadge
                }
            }

            VStack(alignment: .leading, spacing: 9) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(String(format: "%.1f%%", record.attendancePercentage))
                        .font(.system(size: 24, weight: .heavy))
                        .tracking(-0.8)
                        .foregroundStyle(tierColor)
                    if record.classesConducted > 0 {
                        Text("· \(record.classesConducted - record.classesAbsent)/\(record.classesConducted) classes")
                            .font(.system(size: 13))
                            .foregroundStyle(HomeColors.secondaryText)
                    }
                    Spacer(minLength: 0)
                }
                attendanceBar
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(record.courseCode), \(String(format: "%.1f", record.attendancePercentage)) percent. \(marginText) \(marginCaption)"
        )
    }

    private var marginBadge: some View {
        VStack(spacing: 1) {
            Text(marginText)
                .font(.system(size: 30, weight: .heavy))
                .tracking(-1.2)
            Text(marginCaption)
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.6)
                .textCase(.uppercase)
                .opacity(0.8)
        }
        .foregroundStyle(marginColor)
        .frame(minWidth: 72)
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(marginColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(marginColor.opacity(0.22), lineWidth: 1)
        )
        .accessibilityHidden(true)
    }

    private var attendanceBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 6)
                Capsule()
                    .fill(tierColor)
                    .frame(width: proxy.size.width * min(max(record.attendancePercentage, 0), 100) / 100, height: 6)
            }
        }
        .frame(height: 6)
        .accessibilityHidden(true)
    }

    private var tierColor: Color {
        let pct = record.attendancePercentage
        if pct >= 85 { return Color(hex: 0x3DDC84) }
        if pct >= 75 { return Color(hex: 0xE7A63F) }
        return Color(hex: 0xE06C6C)
    }

    private var marginText: String {
        if margin > 0 { return "+\(margin)" }
        if margin < 0 { return "\(abs(margin))" }
        return "0"
    }

    private var marginCaption: String {
        if margin > 0 { return "margin" }
        if margin < 0 { return "required" }
        return "margin"
    }

    private var marginColor: Color {
        if margin > 0 { return Color(hex: 0x3DDC84) }
        if margin == 0 { return Color(hex: 0xE7A63F) }
        return Color(hex: 0xE06C6C)
    }
}

// MARK: - Shared empty state

struct TabEmptyState: View {
    var title: String
    var message: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(.white)
            Text(message)
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .foregroundStyle(HomeColors.secondaryText)
                .frame(maxWidth: 280)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Attendance") {
    AttendanceView()
}
