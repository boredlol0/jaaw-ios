import SwiftUI

// MARK: - Calendar tab
// The brand backdrop (blue field + `bg1.mp4`) carries the header and a glass
// month grid; the selected day's entry lives in a white sheet under the grid,
// with the jump to that day's timetable sitting at the foot of the sheet.

struct CalendarView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var session = SessionStore.shared
    @State private var monthIdx: Int?
    @State private var selectedDay: Int?
    @State private var drift = false

    // MARK: - Month state

    private var months: [CalendarMonth] { session.calendar.months }

    private var activeMonthIdx: Int {
        if let monthIdx, monthIdx < months.count { return monthIdx }
        return initialMonthIdx
    }

    private var initialMonthIdx: Int {
        let now = Date()
        let comps = Calendar.current.dateComponents([.month, .year], from: now)
        let idx = months.firstIndex {
            $0.monthIndex == comps.month && $0.year == comps.year
        }
        return idx ?? 0
    }

    private var month: CalendarMonth? {
        guard !months.isEmpty, activeMonthIdx < months.count else { return nil }
        return months[activeMonthIdx]
    }

    private var dayMap: [Int: CalendarEntry] {
        guard let month else { return [:] }
        var map: [Int: CalendarEntry] = [:]
        for entry in month.entries {
            let dayNum = Int(entry.date.split(separator: "-").last.map(String.init) ?? "") ?? 0
            if dayNum > 0 { map[dayNum] = entry }
        }
        return map
    }

    private var daysInMonth: Int {
        guard let month else { return 0 }
        var comps = DateComponents()
        comps.year = month.year
        comps.month = month.monthIndex
        comps.day = 1
        guard let first = Calendar.current.date(from: comps),
              let range = Calendar.current.range(of: .day, in: .month, for: first)
        else { return month.entries.count }
        return range.count
    }

    private var leadingBlanks: Int {
        guard let month else { return 0 }
        var comps = DateComponents()
        comps.year = month.year
        comps.month = month.monthIndex
        comps.day = 1
        guard let first = Calendar.current.date(from: comps) else { return 0 }
        return Calendar.current.component(.weekday, from: first) - 1 // Sunday-first
    }

    private var activeDay: Int {
        if let selectedDay { return selectedDay }
        if isViewingCurrentMonth { return Calendar.current.component(.day, from: Date()) }
        return 1
    }

    private var isViewingCurrentMonth: Bool {
        guard let month else { return false }
        let comps = Calendar.current.dateComponents([.month, .year], from: Date())
        return month.monthIndex == comps.month && month.year == comps.year
    }

    private var isOnToday: Bool {
        isViewingCurrentMonth && activeDay == Calendar.current.component(.day, from: Date())
    }

    /// The selected day's entry, plus the timetable slot it maps to.
    private var activeEntry: CalendarEntry? { dayMap[activeDay] }

    private var activeOrder: String? {
        DashboardStats.normalizeDayOrder(activeEntry?.dayOrder)
    }

    private var activeScheduleIndex: Int {
        DashboardStats.scheduleIndex(schedule: session.schedule, dayOrder: activeOrder)
    }

    private var activeClasses: [ScheduleEntry] {
        let idx = activeScheduleIndex
        guard idx >= 0, idx < session.schedule.count else { return [] }
        return session.schedule[idx].entries.sorted {
            DashboardStats.timeToMinutes($0.startTime) < DashboardStats.timeToMinutes($1.startTime)
        }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                if months.isEmpty {
                    emptyState
                        .padding(.top, 28)
                } else {
                    monthSwitcher
                        .padding(.top, 18)
                    monthPanel
                        .padding(.top, 14)
                    daySheet
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
        .sensoryFeedback(.selection, trigger: selectedDay)
        .onAppear {
            if monthIdx == nil { monthIdx = initialMonthIdx }
            guard !reduceMotion else { return }
            drift = true
        }
    }

    private var backdrop: some View {
        JaawTabBackdrop(
            configuration: JaawBackground.calendar,
            drift: drift,
            reduceMotion: reduceMotion,
            tab: .calendar
        )
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Calendar")
                    .font(.system(size: 34, weight: .heavy))
                    .tracking(-1.3)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(academicLine)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(JaawColors.ice.opacity(0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .shadow(color: Color(red: 0, green: 0, blue: 90 / 255, opacity: 0.45), radius: 26, y: 8)

            Spacer(minLength: 0)

            todayButton
        }
        .padding(.top, 6)
    }

    private var academicLine: String {
        let year = session.calendar.academicYearLabel
        let semester: String
        switch session.calendar.plannerType.lowercased() {
        case "odd": semester = "Odd semester"
        case "even": semester = "Even semester"
        default: semester = ""
        }
        switch (year.isEmpty, semester.isEmpty) {
        case (true, true): return "Academic calendar"
        case (false, true): return year
        case (true, false): return semester
        case (false, false): return "\(year) · \(semester)"
        }
    }

    private var todayButton: some View {
        Button {
            jumpToToday()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "calendar.day.timeline.left")
                    .font(.system(size: 12, weight: .bold))
                Text("Today")
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .glassEffect(.regular, in: .capsule)
        }
        .buttonStyle(.plain)
        .disabled(isOnToday)
        .opacity(isOnToday ? 0.4 : 1)
        .accessibilityLabel("Jump to today")
    }

    // MARK: - Month switcher

    private var monthSwitcher: some View {
        HStack(spacing: 4) {
            Button {
                stepMonth(-1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .contentShape(.circle)
            }
            .buttonStyle(PressScaleStyle())
            .disabled(activeMonthIdx == 0)
            .opacity(activeMonthIdx == 0 ? 0.3 : 1)
            .accessibilityLabel("Previous month")

            VStack(spacing: 1) {
                Text(month?.label ?? "")
                    .font(.system(size: 18, weight: .heavy))
                    .tracking(-0.4)
                    .foregroundStyle(.white)
                Text(monthSummary)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(JaawColors.ice.opacity(0.7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)

            Button {
                stepMonth(1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .contentShape(.circle)
            }
            .buttonStyle(PressScaleStyle())
            .disabled(activeMonthIdx >= months.count - 1)
            .opacity(activeMonthIdx >= months.count - 1 ? 0.3 : 1)
            .accessibilityLabel("Next month")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .glassEffect(.regular, in: .rect(cornerRadius: 26))
    }

    private var monthSummary: String {
        guard let month else { return "" }
        var holidays = 0
        var events = 0
        var teaching = 0
        for entry in month.entries {
            switch kind(for: entry) {
            case .holiday: holidays += 1
            case .event: events += 1
            case .dayOrder: teaching += 1
            case .plain: break
            }
        }
        var parts: [String] = []
        if holidays > 0 { parts.append("\(holidays) holiday\(holidays == 1 ? "" : "s")") }
        if events > 0 { parts.append("\(events) event\(events == 1 ? "" : "s")") }
        if teaching > 0 { parts.append("\(teaching) teaching day\(teaching == 1 ? "" : "s")") }
        return parts.isEmpty ? "No entries" : parts.joined(separator: " · ")
    }

    // MARK: - Month grid

    private var monthPanel: some View {
        VStack(spacing: 0) {
            weekdayHeader
            monthGrid
                .padding(.top, 8)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 12)
        .glassEffect(.regular, in: .rect(cornerRadius: 30))
    }

    private var weekdayHeader: some View {
        HStack(spacing: 2) {
            ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                Text(day)
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(JaawColors.ice.opacity(0.55))
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
    }

    private var monthGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 4) {
            ForEach(0..<leadingBlanks, id: \.self) { _ in
                Color.clear
                    .frame(height: 52)
                    .accessibilityHidden(true)
            }
            ForEach(1...max(daysInMonth, 1), id: \.self) { day in
                if day <= daysInMonth {
                    dayCell(day)
                }
            }
        }
    }

    private func dayCell(_ day: Int) -> some View {
        let entry = dayMap[day]
        let kind = kind(for: entry)
        let isSelected = day == activeDay
        let isToday = isViewingCurrentMonth && day == Calendar.current.component(.day, from: Date())
        return Button {
            select(day)
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(.white)
                            .shadow(color: .white.opacity(0.45), radius: 10, y: 2)
                    } else if isToday {
                        Circle()
                            .strokeBorder(Color.white.opacity(0.6), lineWidth: 1.5)
                    }
                    Text("\(day)")
                        .font(.system(size: 16, weight: isSelected || isToday ? .heavy : .medium))
                        .foregroundStyle(dayNumberColor(kind: kind, isSelected: isSelected))
                }
                .frame(width: 38, height: 38)

                Circle()
                    .fill(dotColor(kind))
                    .frame(width: 5, height: 5)
                    .opacity(kind == .plain ? 0 : 1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressScaleStyle(scale: 0.86))
        .accessibilityLabel("\(selectedDateStringFor(day: day))\(cellSuffix(entry))")
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    private func dayNumberColor(kind: DayKind, isSelected: Bool) -> Color {
        if isSelected { return JaawColors.ctaTint }
        switch kind {
        case .holiday, .event, .dayOrder: return .white
        case .plain: return .white.opacity(0.55)
        }
    }

    private func selectedDateStringFor(day: Int) -> String {
        guard let month else { return "Day \(day)" }
        var comps = DateComponents()
        comps.year = month.year
        comps.month = month.monthIndex
        comps.day = day
        guard let date = Calendar.current.date(from: comps) else { return "Day \(day)" }
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, MMMM d"
        fmt.locale = Locale(identifier: "en_US")
        return fmt.string(from: date)
    }

    private func cellSuffix(_ entry: CalendarEntry?) -> String {
        switch kind(for: entry) {
        case .holiday: return ", holiday"
        case .event: return ", event"
        case .dayOrder:
            guard let order = DashboardStats.normalizeDayOrder(entry?.dayOrder) else { return "" }
            return ", day order \(order)"
        case .plain: return ""
        }
    }

    // MARK: - Day sheet

    private var daySheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            sheetContent(for: activeEntry)
                .id(activeDay)
                .transition(.opacity)
        }
        .padding(22)
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
        .animation(.easeInOut(duration: 0.22), value: activeDay)
    }

    @ViewBuilder
    private func sheetContent(for entry: CalendarEntry?) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedDateString.uppercased())
                    .font(.system(size: 11.5, weight: .heavy))
                    .tracking(1.5)
                    .foregroundStyle(CardPalette.muted)
                Text(sheetTitle(for: entry))
                    .font(.system(size: 27, weight: .heavy))
                    .tracking(-0.9)
                    .foregroundStyle(CardPalette.title)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            chip(for: entry)
        }

        Text(sheetSubtitle(for: entry))
            .font(.system(size: 14.5))
            .foregroundStyle(CardPalette.body)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 8)

        if let note = noteText(for: entry) {
            Text(note)
                .font(.system(size: 13))
                .foregroundStyle(CardPalette.muted)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
        }

        if !statStrip.isEmpty {
            statStripView
                .padding(.top, 16)
        }

        Rectangle()
            .fill(CardPalette.divider)
            .frame(height: 1)
            .padding(.top, 18)
            .padding(.bottom, 14)

        timetableButton
    }

    private var selectedDateString: String {
        selectedDateStringFor(day: activeDay)
    }

    private func sheetTitle(for entry: CalendarEntry?) -> String {
        switch kind(for: entry) {
        case .holiday:
            let title = shortTitle(entry?.title ?? "")
            return title.isEmpty ? "Holiday" : title
        case .event:
            let title = shortTitle(entry?.title ?? "")
            return title.isEmpty ? "Event" : title
        case .dayOrder:
            let title = shortTitle(entry?.title ?? "")
            return title.isEmpty ? "Day order \(activeOrder ?? "")" : title
        case .plain:
            return "Nothing on this day"
        }
    }

    private func sheetSubtitle(for entry: CalendarEntry?) -> String {
        switch kind(for: entry) {
        case .holiday:
            return "College is closed — no classes scheduled."
        case .event:
            return "Marked on the academic calendar."
        case .dayOrder:
            if activeClasses.isEmpty { return "Teaching day — no timetable loaded yet." }
            return "\(activeClasses.count) classes · first at \(timeLabel(activeClasses.first?.startTime))"
        case .plain:
            return "No classes or events recorded for this date."
        }
    }

    /// The planner's titles run long ("Last Working Day - B.Tech - I / M.Tech
    /// (Int) - I / ..."), so the headline keeps only the lead and the full
    /// wording moves to a note underneath it.
    private func noteText(for entry: CalendarEntry?) -> String? {
        guard kind(for: entry) == .dayOrder,
              let raw = entry?.title,
              !raw.isEmpty
        else { return nil }
        let short = shortTitle(raw)
        return short == raw ? nil : raw
    }

    /// The lead of a planner title, e.g. "Last Working Day - B.Tech - I" →
    /// "Last Working Day".
    private func shortTitle(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let range = text.range(of: " - ") {
            let head = String(text[text.startIndex..<range.lowerBound])
                .trimmingCharacters(in: .whitespaces)
            if head.count >= 3 { text = head }
        }
        for suffix in [" for", " -"] where text.hasSuffix(suffix) {
            text = String(text.dropLast(suffix.count))
                .trimmingCharacters(in: .whitespaces)
        }
        return text
    }

    private func chip(for entry: CalendarEntry?) -> some View {
        let kind = kind(for: entry)
        let label: String
        switch kind {
        case .holiday: label = "Holiday"
        case .event: label = "Event"
        case .dayOrder: label = "DO \(activeOrder ?? "")"
        case .plain: label = "No entry"
        }
        let tint = chipColor(kind)
        return Text(label)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(tint)
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(tint.opacity(0.12), in: Capsule())
    }

    // MARK: - Details

    /// The day's numbers, as a compact strip: classes, first class, last class.
    private var statStrip: [(title: String, value: String)] {
        var items: [(String, String)] = []
        guard !activeClasses.isEmpty else { return items }
        items.append(("Classes", "\(activeClasses.count)"))
        items.append(("Starts", timeLabel(activeClasses.first?.startTime)))
        items.append(("Ends", timeLabel(activeClasses.last?.endTime)))
        return items
    }

    private var statStripView: some View {
        HStack(spacing: 0) {
            ForEach(Array(statStrip.enumerated()), id: \.offset) { index, item in
                if index > 0 {
                    Rectangle()
                        .fill(CardPalette.divider)
                        .frame(width: 1, height: 30)
                }
                VStack(spacing: 3) {
                    Text(item.title.uppercased())
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(1.1)
                        .foregroundStyle(CardPalette.muted)
                    Text(item.value)
                        .font(.system(size: 16, weight: .heavy))
                        .tracking(-0.4)
                        .foregroundStyle(CardPalette.title)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 12)
        .background(
            CardPalette.surface,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }

    private func timeLabel(_ raw: String?) -> String {
        guard let raw else { return "—" }
        let (time, period) = DashboardStats.displayTime(
            minutes: DashboardStats.timeToMinutes(raw)
        )
        return "\(time) \(period)"
    }

    // MARK: - Timetable button

    private var timetableButton: some View {
        let hasTimetable = activeScheduleIndex >= 0
        return Button {
            openTimetable()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: hasTimetable ? "tablecells.fill" : "moon.zzz.fill")
                    .font(.system(size: 15, weight: .bold))
                Text(hasTimetable ? "Open timetable" : "No timetable for this day")
                    .font(.system(size: 16, weight: .bold))
                Spacer(minLength: 0)
                if hasTimetable {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
            }
            .foregroundStyle(hasTimetable ? .white : CardPalette.muted)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        hasTimetable
                            ? AnyShapeStyle(CardPalette.accent)
                            : AnyShapeStyle(CardPalette.surfaceAlt)
                    )
                    .shadow(
                        color: hasTimetable ? CardPalette.accent.opacity(0.35) : .clear,
                        radius: 18,
                        y: 8
                    )
            }
        }
        .buttonStyle(PressScaleStyle(scale: 0.97))
        .disabled(!hasTimetable)
        .accessibilityLabel(
            hasTimetable ? "Open timetable for day order \(activeOrder ?? "")" : "No timetable for this day"
        )
    }

    private func openTimetable() {
        let idx = activeScheduleIndex
        guard idx >= 0 else { return }
        // Routed rather than posted directly: the timetable tab may not have
        // been built yet, and the request has to survive that.
        TimetableRoute.shared.request(idx)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(JaawColors.ice.opacity(0.8))
            Text("No calendar data")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(.white)
            Text("The academic calendar will appear here after your next login.")
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

    // MARK: - Kinds

    private enum DayKind { case holiday, event, dayOrder, plain }

    private func kind(for entry: CalendarEntry?) -> DayKind {
        guard let entry else { return .plain }
        if entry.category.lowercased() == "holiday" { return .holiday }
        if entry.category.lowercased() == "event" { return .event }
        if DashboardStats.normalizeDayOrder(entry.dayOrder) != nil { return .dayOrder }
        return .plain
    }

    private func dotColor(_ kind: DayKind) -> Color {
        switch kind {
        case .holiday: return CalendarPalette.holidayDot
        case .event: return CalendarPalette.eventDot
        case .dayOrder: return CalendarPalette.dayOrderDot
        case .plain: return .clear
        }
    }

    private func chipColor(_ kind: DayKind) -> Color {
        switch kind {
        case .holiday: return CalendarPalette.holidayChip
        case .event: return CalendarPalette.eventChip
        case .dayOrder: return CalendarPalette.dayOrderChip
        case .plain: return CalendarPalette.plainChip
        }
    }

    // MARK: - Actions

    private func select(_ day: Int) {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
            selectedDay = day
        }
    }

    private func stepMonth(_ delta: Int) {
        let next = max(0, min(months.count - 1, activeMonthIdx + delta))
        guard next != activeMonthIdx else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            monthIdx = next
            selectedDay = todayIfCurrentMonth(next) ?? 1
        }
    }

    private func jumpToToday() {
        let comps = Calendar.current.dateComponents([.month, .year], from: Date())
        guard let idx = months.firstIndex(where: {
            $0.monthIndex == comps.month && $0.year == comps.year
        }) else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            monthIdx = idx
            selectedDay = Calendar.current.component(.day, from: Date())
        }
    }

    private func todayIfCurrentMonth(_ index: Int) -> Int? {
        guard index < months.count else { return nil }
        let comps = Calendar.current.dateComponents([.month, .year], from: Date())
        let target = months[index]
        guard target.monthIndex == comps.month, target.year == comps.year else { return nil }
        return Calendar.current.component(.day, from: Date())
    }
}

// MARK: - Button style

/// A tap that sinks the control a touch — the small press feedback shared by
/// the day cells, the month arrows and the timetable button.
private struct PressScaleStyle: ButtonStyle {
    var scale: CGFloat = 0.9

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview("Calendar") {
    CalendarView()
}
