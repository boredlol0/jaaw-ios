import SwiftUI

// MARK: - Timetable tab
// Day-order tabs (D01…) with a timeline of classes, break gaps and a live
// highlight when the selected day is today.

struct TimetableView: View {
    @State private var session = SessionStore.shared
    @State private var selectedDay: Int?

    private var schedule: [ScheduleDay] {
        session.schedule
    }

    private var todayIndex: Int? {
        let order = DashboardStats.todayDayOrder(calendar: session.calendar)
        let idx = DashboardStats.scheduleIndex(schedule: schedule, dayOrder: order)
        return idx >= 0 ? idx : nil
    }

    private var activeDay: Int? {
        if let selectedDay, selectedDay < schedule.count { return selectedDay }
        if let todayIndex { return todayIndex }
        return schedule.isEmpty ? nil : 0
    }

    private var entries: [ScheduleEntry] {
        guard let activeDay, activeDay < schedule.count else { return [] }
        return schedule[activeDay].entries.sorted {
            DashboardStats.timeToMinutes($0.startTime) < DashboardStats.timeToMinutes($1.startTime)
        }
    }

    private var isShowingToday: Bool {
        activeDay == todayIndex
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                kicker
                dayTabs
                    .padding(.top, 14)
                if entries.isEmpty {
                    emptyState
                } else {
                    timeline
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
        .onAppear {
            if selectedDay == nil { selectedDay = activeDay }
        }
        .onReceive(NotificationCenter.default.publisher(for: .jaawShowTimetable)) { note in
            if let idx = note.userInfo?["scheduleIndex"] as? Int,
               idx < schedule.count {
                selectedDay = idx
            }
        }
    }

    // MARK: - Kicker

    private var kicker: some View {
        HStack(alignment: .lastTextBaseline) {
            Text("Timetable")
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

    // MARK: - Day tabs

    private var dayTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(schedule.indices, id: \.self) { i in
                    let day = schedule[i]
                    let num = day.dayLabel.filter(\.isNumber)
                    let isActive = activeDay == i
                    let isToday = todayIndex == i
                    Button {
                        selectedDay = i
                    } label: {
                        HStack(spacing: 6) {
                            Text("D\(num.count == 1 ? "0\(num)" : num)")
                                .font(.system(size: 15, weight: .bold))
                            if isToday {
                                Circle()
                                    .fill(isActive ? .white : HomeColors.ringSecondary)
                                    .frame(width: 6, height: 6)
                                    .accessibilityHidden(true)
                            }
                        }
                        .foregroundStyle(isActive ? HomeColors.tagBlue : .white)
                        .padding(.horizontal, 17)
                        .padding(.vertical, 11)
                        .background(
                            isActive ? .white : Color.white.opacity(0.08),
                            in: Capsule()
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    isActive ? Color.clear : HomeColors.cardBorder,
                                    lineWidth: 1
                                )
                        )
                    }
                    .accessibilityLabel("Day \(num)\(isToday ? ", today" : "")")
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
        }
    }

    // MARK: - Timeline

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: schedule.isEmpty ? "calendar" : "moon.zzz.fill")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(HomeColors.faintText)
            Text(schedule.isEmpty ? "No timetable data yet." : "No classes for this day.")
                .font(.system(size: 15))
                .foregroundStyle(HomeColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .background(HomeColors.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(HomeColors.cardBorder, lineWidth: 1)
        )
        .padding(.top, 18)
        .accessibilityElement(children: .combine)
    }

    private var timeline: some View {
        VStack(spacing: 0) {
            ForEach(Array(entries.enumerated()), id: \.offset) { i, entry in
                let prev = i > 0 ? entries[i - 1] : nil
                let gap = prev.map {
                    DashboardStats.timeToMinutes(entry.startTime)
                        - DashboardStats.timeToMinutes($0.endTime)
                } ?? 0
                if gap > 5, prev != nil {
                    breakLabel(minutes: gap)
                }
                TimetableRow(
                    entry: entry,
                    isLive: isShowingToday && classStatus(entry) == .current
                )
            }
        }
    }

    private func breakLabel(minutes: Int) -> some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(HomeColors.cardBorder)
                .frame(height: 1)
            Text(breakText(minutes))
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.3)
                .foregroundStyle(HomeColors.faintText)
                .fixedSize()
            Rectangle()
                .fill(HomeColors.cardBorder)
                .frame(height: 1)
        }
        .padding(.leading, 96)
        .padding(.trailing, 2)
        .padding(.vertical, 14)
        .accessibilityHidden(true)
    }

    private func breakText(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0, m > 0 { return "\(h)h \(m)m break" }
        if h > 0 { return "\(h)h break" }
        return "\(m)m break"
    }

    private enum DayClassStatus { case done, current, upcoming }

    private func classStatus(_ entry: ScheduleEntry) -> DayClassStatus {
        let now = DashboardStats.nowMinutes()
        let start = DashboardStats.timeToMinutes(entry.startTime)
        let end = DashboardStats.timeToMinutes(entry.endTime)
        if now >= end { return .done }
        if now >= start { return .current }
        return .upcoming
    }
}

// MARK: - Row

private struct TimetableRow: View {
    var entry: ScheduleEntry
    var isLive: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .trailing, spacing: 4) {
                Text(DashboardStats.parseTime(entry.startTime))
                    .font(.system(size: 15, weight: .semibold))
                Text(DashboardStats.parseTime(entry.endTime))
                    .font(.system(size: 12.5))
                    .foregroundStyle(HomeColors.secondaryText)
            }
            .frame(width: 58, alignment: .trailing)
            .padding(.top, 28)
            .foregroundStyle(HomeColors.timeText)

            rail

            card
                .padding(.vertical, 10)
        }
        .background(alignment: .leading) { railLine }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(DashboardStats.parseTime(entry.startTime)) to \(DashboardStats.parseTime(entry.endTime)), \(entry.courseCode), \(DashboardStats.normalizeSubject(entry.courseTitle))"
        )
    }

    // MARK: - Timeline rail

    /// Full-height line drawn as a row background (a `maxHeight` frame can't
    /// stretch inside a `ScrollView`), plus a node in the middle column.
    private var railLine: some View {
        Rectangle()
            .fill(Color.white.opacity(0.10))
            .frame(width: 2)
            .padding(.leading, 76)
    }

    private var rail: some View {
        Circle()
            .fill(isLive ? HomeColors.ringSecondary : Color.white.opacity(0.30))
            .frame(width: 10, height: 10)
            .overlay(Circle().strokeBorder(HomeColors.page, lineWidth: 3))
            .padding(.top, 32)
            .frame(width: 14)
            .accessibilityHidden(true)
    }

    // MARK: - Card

    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isLive {
                Text("Live now")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(HomeColors.tagBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.white, in: Capsule())
                    .padding(.bottom, 10)
            }
            Text(entry.courseCode)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(HomeColors.tileEyebrow)
            Text(DashboardStats.normalizeSubject(entry.courseTitle))
                .font(.system(size: 18, weight: .heavy))
                .tracking(-0.45)
                .foregroundStyle(.white)
                .padding(.top, 3)
            Text("\(entry.room) · \(DashboardStats.facultyShort(entry.faculty))")
                .font(.system(size: 13))
                .foregroundStyle(HomeColors.secondaryText)
                .padding(.top, 5)
            metaRow
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.white)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(isLive ? AnyShapeStyle(liveGradient) : AnyShapeStyle(HomeColors.card))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(
                            isLive ? HomeColors.nowBorder : HomeColors.cardBorder,
                            lineWidth: 1
                        )
                )
        }
        .shadow(color: .black.opacity(isLive ? 0 : 0.35), radius: 18, y: 8)
        .shadow(
            color: isLive ? HomeColors.glowPrimary.opacity(0.8) : .clear,
            radius: 30,
            y: 10
        )
    }

    private var metaRow: some View {
        HStack(spacing: 8) {
            Text(typeLabel)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(isLab ? HomeColors.tagBlue : HomeColors.secondaryText)
                .padding(.horizontal, 9)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.08), in: Capsule())
            if !duration.isEmpty {
                Text(duration)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(HomeColors.faintText)
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 12)
    }

    private var isLab: Bool {
        entry.slotType.lowercased() == "practical"
    }

    private var typeLabel: String {
        if isLab { return "LAB" }
        if !entry.rawType.isEmpty { return entry.rawType.uppercased() }
        return "TH"
    }

    private var duration: String {
        let diff = DashboardStats.timeToMinutes(entry.endTime)
            - DashboardStats.timeToMinutes(entry.startTime)
        guard diff > 0 else { return "" }
        let h = diff / 60
        let m = diff % 60
        if h > 0, m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }

    private var liveGradient: LinearGradient {
        LinearGradient(
            colors: [HomeColors.nowStart, HomeColors.nowEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview("Timetable") {
    TimetableView()
}
