import SwiftUI

// MARK: - Timetable tab
// The brand backdrop carries the header and the day-order hero, a glass strip
// picks the day, and the day's classes sit in a white sheet as hairline
// separated rows — the same sheet the home page shows for today.

extension Notification.Name {
    static let jaawShowTimetable = Notification.Name("jaaw.showTimetable")
}

/// Carries a day over from another tab. The timetable tab may not exist yet
/// when the request is made (the tab bar builds tabs lazily), so the index
/// is parked here until the timetable picks it up.
@Observable
final class TimetableRoute {
    static let shared = TimetableRoute()

    var pendingIndex: Int?

    /// Ask the timetable to show a day.
    func request(_ index: Int) {
        pendingIndex = index
        NotificationCenter.default.post(
            name: .jaawShowTimetable,
            object: nil,
            userInfo: ["scheduleIndex": index]
        )
    }

    /// The parked request, cleared once it has been taken.
    func take() -> Int? {
        defer { pendingIndex = nil }
        return pendingIndex
    }
}

struct TimetableView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var session = SessionStore.shared
    @State private var selectedDay: Int?
    @State private var drift = false

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
                header
                if schedule.isEmpty {
                    emptyState
                        .padding(.top, 24)
                } else {
                    daySelector
                        .padding(.top, 18)
                    daySheet
                        .padding(.top, 16)
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
            if let index = TimetableRoute.shared.take(), index < schedule.count {
                selectedDay = index
            } else if selectedDay == nil {
                selectedDay = activeDay
            }
            guard !reduceMotion else { return }
            drift = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .jaawShowTimetable)) { note in
            // Always clears the parked request, so a later appearance can't
            // re-apply a stale day.
            let parked = TimetableRoute.shared.take()
            let index = (note.userInfo?["scheduleIndex"] as? Int) ?? parked
            if let index, index < schedule.count {
                selectedDay = index
            }
        }
    }

    private var backdrop: some View {
        JaawTabBackdrop(
            configuration: JaawBackground.timetable,
            drift: drift,
            reduceMotion: reduceMotion,
            tab: .timetable
        )
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Timetable")
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

            dayOrderHero
        }
        .padding(.top, 6)
    }

    private var summaryLine: String {
        guard !schedule.isEmpty, activeDay != nil else { return "No timetable data yet" }
        let count = entries.count
        let classes = "\(count) class\(count == 1 ? "" : "es")"
        guard let first = entries.first, let last = entries.last else { return classes }
        return "\(classes) · \(timeLabel(first.startTime)) – \(timeLabel(last.endTime))"
    }

    /// The active day's order number, in the home page's trailing-hero slot.
    private var dayOrderHero: some View {
        VStack(alignment: .trailing, spacing: -6) {
            Text("DAY ORDER")
                .font(.system(size: 12, weight: .heavy))
                .tracking(2.1)
                .foregroundStyle(JaawColors.ice.opacity(0.72))
            Text(dayOrderNumber)
                .font(.system(size: 64, weight: .heavy))
                .tracking(-3.6)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(.white)
                .shadow(color: Color(red: 0, green: 0, blue: 90 / 255, opacity: 0.5), radius: 34, y: 8)
        }
        .frame(width: 140, alignment: .trailing)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Day order \(dayOrderNumber)")
    }

    /// The day order of the selected day, zero-padded ("03").
    private var dayOrderNumber: String {
        guard let activeDay else { return "—" }
        return dayNumber(for: activeDay)
    }

    // MARK: - Day selector

    private var daySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(schedule.indices, id: \.self) { index in
                    dayPill(index)
                }
            }
            .padding(6)
        }
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
    }

    private func dayPill(_ index: Int) -> some View {
        let isActive = activeDay == index
        let isToday = todayIndex == index
        let label = dayNumber(for: index)
        return Button {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.8)) {
                selectedDay = index
            }
        } label: {
            HStack(spacing: 6) {
                Text("D\(label)")
                    .font(.system(size: 14, weight: .bold))
                if isToday {
                    Circle()
                        .fill(isActive ? CardPalette.accent : Color.white.opacity(0.8))
                        .frame(width: 6, height: 6)
                }
            }
            .foregroundStyle(isActive ? CardPalette.accent : .white)
            .padding(.horizontal, 17)
            .padding(.vertical, 10)
            .background(
                isActive ? AnyShapeStyle(.white) : AnyShapeStyle(Color.white.opacity(0.06)),
                in: .capsule
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Day order \(label)\(isToday ? ", today" : "")")
        .accessibilityAddTraits(isActive ? [.isSelected, .isButton] : .isButton)
    }

    private func dayNumber(for index: Int) -> String {
        guard index < schedule.count else { return "—" }
        let digits = schedule[index].dayLabel.filter(\.isNumber)
        guard !digits.isEmpty else { return "—" }
        return digits.count == 1 ? "0\(digits)" : digits
    }

    /// The selected day's own label from the API ("Day 1").
    private var dayTitle: String {
        guard let activeDay, activeDay < schedule.count else { return "Classes" }
        let label = schedule[activeDay].dayLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        return label.isEmpty ? "Day \(dayOrderNumber)" : label
    }

    // MARK: - Day sheet

    private var daySheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(dayTitle)
                    .font(.system(size: 19, weight: .heavy))
                    .tracking(-0.5)
                    .foregroundStyle(CardPalette.title)
                Spacer(minLength: 0)
                if isShowingToday {
                    Text("Today")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(CardPalette.accent, in: Capsule())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Rectangle()
                .fill(CardPalette.divider)
                .frame(height: 1)

            if entries.isEmpty {
                emptyDay
            } else {
                timeline
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(CardPalette.fill)
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .strokeBorder(CardPalette.border, lineWidth: 1)
                )
                .shadow(color: CardPalette.shadow, radius: 30, y: 16)
        }
    }

    // MARK: - Timeline

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
                TimetableClassRow(
                    entry: entry,
                    isLast: i == entries.count - 1,
                    status: rowStatus(entry)
                )
            }
        }
    }

    private func breakLabel(minutes: Int) -> some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(CardPalette.divider)
                .frame(height: 1)
            Text(breakText(minutes))
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.3)
                .foregroundStyle(CardPalette.muted)
                .fixedSize()
            Rectangle()
                .fill(CardPalette.divider)
                .frame(height: 1)
        }
        .padding(.leading, 86)
        .padding(.trailing, 20)
        .padding(.vertical, 12)
        .accessibilityHidden(true)
    }

    private func breakText(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0, m > 0 { return "\(h)h \(m)m break" }
        if h > 0 { return "\(h)h break" }
        return "\(m)m break"
    }

    // MARK: - Row status

    private func rowStatus(_ entry: ScheduleEntry) -> TimetableClassRow.Status {
        guard isShowingToday else { return .upcoming(isNext: false) }
        let now = DashboardStats.nowMinutes()
        let start = DashboardStats.timeToMinutes(entry.startTime)
        let end = DashboardStats.timeToMinutes(entry.endTime)
        if now >= end { return .done }
        if now >= start {
            let span = max(end - start, 1)
            return .current(progress: min(max(Double(now - start) / Double(span), 0), 1))
        }
        // The next class of the day gets the "up next" marker.
        let nextEntry = entries.first { DashboardStats.timeToMinutes($0.startTime) > now }
        return .upcoming(isNext: nextEntry == entry)
    }

    // MARK: - Empty state

    private var emptyDay: some View {
        VStack(spacing: 6) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(CardPalette.muted)
            Text("No classes for this day.")
                .font(.system(size: 15))
                .foregroundStyle(CardPalette.body)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 38)
        .accessibilityElement(children: .combine)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(JaawColors.ice.opacity(0.8))
            Text("No timetable data")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(.white)
            Text("Your weekly timetable will appear here after your next login.")
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

    // MARK: - Times

    private func timeLabel(_ raw: String) -> String {
        let (time, period) = DashboardStats.displayTime(
            minutes: DashboardStats.timeToMinutes(raw)
        )
        return "\(time) \(period)"
    }
}

// MARK: - Class row

/// One class on the white sheet: its time down the left, the course and its
/// status to the right, hairline separated like the home page's list.
private struct TimetableClassRow: View {
    var entry: ScheduleEntry
    var isLast: Bool
    var status: Status

    enum Status {
        case done
        case current(progress: Double)
        case upcoming(isNext: Bool)
    }

    private var isDone: Bool {
        if case .done = status { return true }
        return false
    }

    private var isCurrent: Bool {
        if case .current = status { return true }
        return false
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 14) {
                timeColumn
                content
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background {
                if isCurrent {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(CardPalette.accent.opacity(0.07))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                }
            }

            if case .current(let progress) = status {
                progressBar(progress)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            }

            if !isLast {
                Rectangle()
                    .fill(CardPalette.divider)
                    .frame(height: 1)
                    .padding(.leading, 86)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(DashboardStats.parseTime(entry.startTime)) \(period), \(entry.courseCode), \(DashboardStats.normalizeSubject(entry.courseTitle))\(statusSuffix)"
        )
    }

    // MARK: - Time column

    private var timeColumn: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(DashboardStats.parseTime(entry.startTime))
                .font(.system(size: 15, weight: .bold))
            Text(period)
                .font(.system(size: 10.5, weight: .semibold))
                .tracking(0.5)
                .textCase(.uppercase)
                .foregroundStyle(CardPalette.muted)
        }
        .foregroundStyle(isDone ? CardPalette.muted : CardPalette.title)
        .frame(width: 52, alignment: .leading)
        .padding(.top, 1)
    }

    /// "am" / "pm", worked out from the start time.
    private var period: String {
        DashboardStats.timeToMinutes(entry.startTime) >= 12 * 60 ? "pm" : "am"
    }

    // MARK: - Content

    private var content: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(DashboardStats.normalizeSubject(entry.courseTitle))
                    .font(.system(size: 17, weight: isCurrent ? .heavy : .semibold))
                    .tracking(-0.35)
                    .foregroundStyle(isDone ? CardPalette.muted : CardPalette.title)
                    .strikethrough(isDone, color: CardPalette.strike)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                statusTag
            }
            Text("\(entry.room) · \(DashboardStats.facultyShort(entry.faculty))")
                .font(.system(size: 13))
                .foregroundStyle(CardPalette.body)
                .lineLimit(1)

            HStack(spacing: 8) {
                Text(typeLabel)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(isLab ? CardPalette.accentInk : CardPalette.muted)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3)
                    .background(
                        isLab ? CardPalette.accent.opacity(0.10) : CardPalette.surfaceAlt,
                        in: Capsule()
                    )
                if !duration.isEmpty {
                    Text(duration)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(CardPalette.muted)
                }
                Spacer(minLength: 0)
            }
            .padding(.top, 6)
        }
    }

    @ViewBuilder
    private var statusTag: some View {
        switch status {
        case .current:
            Text("Now")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(CardPalette.accent, in: Capsule())
        case .upcoming(let isNext) where isNext:
            Text("Up next")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(CardPalette.accentInk)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(CardPalette.accent.opacity(0.12), in: Capsule())
        case .done:
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(CardPalette.muted)
                .accessibilityHidden(true)
        default:
            EmptyView()
        }
    }

    private func progressBar(_ progress: Double) -> some View {
        GeometryReader { proxy in
            Capsule()
                .fill(CardPalette.accent.opacity(0.14))
                .frame(height: 5)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(CardPalette.accent)
                        .frame(width: proxy.size.width * progress, height: 5)
                }
        }
        .frame(height: 5)
        .accessibilityValue("\(Int(progress * 100)) percent elapsed")
    }

    // MARK: - Values

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

    private var statusSuffix: String {
        switch status {
        case .done: return ", completed"
        case .current: return ", in progress now"
        case .upcoming(let isNext): return isNext ? ", up next" : ""
        }
    }
}

#Preview("Timetable") {
    TimetableView()
}
