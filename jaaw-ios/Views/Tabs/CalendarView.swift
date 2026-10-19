import SwiftUI

// MARK: - Calendar tab
// Month grid coloured by entry tier, prev/next month nav and a hero card
// for the selected day. Tapping a day-order cell jumps to the timetable.

extension Notification.Name {
    static let jaawShowTimetable = Notification.Name("jaaw.showTimetable")
}

struct CalendarView: View {
    @State private var session = SessionStore.shared
    @State private var monthIdx: Int?
    @State private var selectedDay: Int?

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

    private var isTodaySelected: Bool {
        isViewingCurrentMonth && activeDay == Calendar.current.component(.day, from: Date())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                kicker
                if month == nil {
                    TabEmptyState(
                        title: "No calendar data",
                        message: "The academic calendar will appear here after your next login."
                    )
                } else {
                    hero
                        .padding(.top, 14)
                    monthNav
                        .padding(.top, 14)
                    weekdayHeader
                        .padding(.top, 10)
                    monthGrid
                        .padding(.top, 6)
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
            if monthIdx == nil { monthIdx = initialMonthIdx }
        }
    }

    // MARK: - Kicker

    private var kicker: some View {
        HStack(alignment: .lastTextBaseline) {
            Text("Calendar")
                .font(.system(size: 28, weight: .heavy))
                .tracking(-1.1)
                .foregroundStyle(.white)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            if let month {
                Text(month.label)
                    .font(.system(size: 14))
                    .foregroundStyle(HomeColors.faintText)
            }
        }
        .padding(.horizontal, 6)
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Hero

    private var hero: some View {
        let entry = dayMap[activeDay]
        let badge = badgeFor(entry)
        return VStack(alignment: .leading, spacing: 0) {
            Text("Selected day")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(HomeColors.tileEyebrow)
            Text(selectedDateString)
                .font(.system(size: 24, weight: .heavy))
                .tracking(-0.8)
                .foregroundStyle(.white)
                .padding(.top, 6)
            Text(heroDescription(entry: entry, badge: badge))
                .font(.system(size: 14))
                .foregroundStyle(HomeColors.secondaryText)
                .padding(.top, 4)
            if let badge {
                HStack(spacing: 8) {
                    Text(badge.label)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.14), in: Capsule())
                    Text(badge.sub)
                        .font(.system(size: 12))
                        .foregroundStyle(HomeColors.secondaryText)
                }
                .padding(.top, 10)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(AnyShapeStyle(heroBackground(entry: entry)))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(HomeColors.cardBorder, lineWidth: 1)
                )
        }
        .accessibilityElement(children: .combine)
    }

    private var selectedDateString: String {
        guard let month else { return "" }
        var comps = DateComponents()
        comps.year = month.year
        comps.month = month.monthIndex
        comps.day = activeDay
        guard let date = Calendar.current.date(from: comps) else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, MMMM d"
        fmt.locale = Locale(identifier: "en_US")
        return fmt.string(from: date)
    }

    private func heroDescription(entry: CalendarEntry?, badge: (label: String, sub: String)?) -> String {
        if let title = entry?.title, !title.isEmpty { return title }
        if let badge { return badge.label }
        return "No entry for this day yet."
    }

    private func heroBackground(entry: CalendarEntry?) -> some ShapeStyle {
        switch tierFor(entry) {
        case .holiday:
            return AnyShapeStyle(Color(hex: 0x122B1F))
        case .event:
            return AnyShapeStyle(Color(hex: 0x331D1D))
        case .dayOrder:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [HomeColors.nowStart, HomeColors.nowEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .empty:
            return AnyShapeStyle(HomeColors.card)
        }
    }

    // MARK: - Month nav

    private var monthNav: some View {
        HStack {
            Button {
                let next = max(0, activeMonthIdx - 1)
                monthIdx = next
                selectedDay = months[next].monthIndex == Calendar.current.component(.month, from: Date())
                    && months[next].year == Calendar.current.component(.year, from: Date())
                    ? Calendar.current.component(.day, from: Date()) : 1
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(activeMonthIdx == 0 ? HomeColors.faintText.opacity(0.4) : .white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.08), in: Circle())
            }
            .disabled(activeMonthIdx == 0)
            .accessibilityLabel("Previous month")

            Spacer(minLength: 0)
            Text(month?.label ?? "")
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(.white)
            Spacer(minLength: 0)

            Button {
                let next = min(months.count - 1, activeMonthIdx + 1)
                monthIdx = next
                selectedDay = months[next].monthIndex == Calendar.current.component(.month, from: Date())
                    && months[next].year == Calendar.current.component(.year, from: Date())
                    ? Calendar.current.component(.day, from: Date()) : 1
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(activeMonthIdx >= months.count - 1 ? HomeColors.faintText.opacity(0.4) : .white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.08), in: Circle())
            }
            .disabled(activeMonthIdx >= months.count - 1)
            .accessibilityLabel("Next month")
        }
        .padding(.horizontal, 6)
    }

    // MARK: - Grid

    private var weekdayHeader: some View {
        HStack(spacing: 6) {
            ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                Text(day)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HomeColors.faintText)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 2)
        .accessibilityHidden(true)
    }

    private var monthGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
            ForEach(0..<leadingBlanks, id: \.self) { i in
                Color.clear
                    .frame(height: 48)
                    .accessibilityHidden(true)
                    .id("blank-\(i)")
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
        let tier = tierFor(entry)
        let isSelected = day == activeDay
        let isToday = isViewingCurrentMonth && day == Calendar.current.component(.day, from: Date())
        return Button {
            handleDayTap(day)
        } label: {
            VStack(spacing: 2) {
                Text("\(day)")
                    .font(.system(size: 14, weight: isSelected || isToday ? .heavy : .medium))
                if let micro = microLabel(entry) {
                    Text(micro)
                        .font(.system(size: 8, weight: .bold))
                        .lineLimit(1)
                }
            }
            .foregroundStyle(cellForeground(tier: tier, isSelected: isSelected))
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(cellBackground(tier: tier, isSelected: isSelected), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.white.opacity(0.7) : (isToday ? HomeColors.ringSecondary : .clear),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .accessibilityLabel("\(selectedDateStringFor(day: day))\(cellSuffix(entry))")
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
        guard let badge = badgeFor(entry) else { return "" }
        return ", \(badge.label)"
    }

    // MARK: - Tiers

    private enum CellTier { case holiday, event, dayOrder, empty }

    private func tierFor(_ entry: CalendarEntry?) -> CellTier {
        guard let entry else { return .empty }
        if entry.category == "holiday" { return .holiday }
        if entry.category == "event" { return .event }
        if DashboardStats.normalizeDayOrder(entry.dayOrder) != nil { return .dayOrder }
        return .empty
    }

    private func badgeFor(_ entry: CalendarEntry?) -> (label: String, sub: String)? {
        guard let entry else { return nil }
        if entry.category == "holiday" { return ("Holiday", "holiday") }
        if entry.category == "event" { return (entry.title?.isEmpty == false ? entry.title! : "Event", "event") }
        if let order = DashboardStats.normalizeDayOrder(entry.dayOrder) {
            return ("DO \(order)", "Day order")
        }
        return nil
    }

    private func microLabel(_ entry: CalendarEntry?) -> String? {
        guard let entry else { return nil }
        if entry.category == "holiday" { return "HOL" }
        if entry.category == "event" { return "EVT" }
        if let order = DashboardStats.normalizeDayOrder(entry.dayOrder) { return "D\(order)" }
        if let title = entry.title, !title.isEmpty { return "EVT" }
        return nil
    }

    private func cellForeground(tier: CellTier, isSelected: Bool) -> Color {
        if isSelected { return .white }
        switch tier {
        case .holiday: return Color(hex: 0x3DDC84)
        case .event: return Color(hex: 0xE06C6C)
        case .dayOrder: return .white
        case .empty: return HomeColors.faintText.opacity(0.6)
        }
    }

    private func cellBackground(tier: CellTier, isSelected: Bool) -> Color {
        if isSelected { return Color.white.opacity(0.18) }
        switch tier {
        case .holiday: return Color(hex: 0x122B1F)
        case .event: return Color(hex: 0x331D1D)
        case .dayOrder: return HomeColors.card
        case .empty: return Color.white.opacity(0.04)
        }
    }

    // MARK: - Tap

    private func handleDayTap(_ day: Int) {
        let entry = dayMap[day]
        if let order = DashboardStats.normalizeDayOrder(entry?.dayOrder),
           DashboardStats.scheduleIndex(schedule: session.schedule, dayOrder: order) >= 0 {
            let idx = DashboardStats.scheduleIndex(schedule: session.schedule, dayOrder: order)
            NotificationCenter.default.post(
                name: .jaawShowTimetable,
                object: nil,
                userInfo: ["scheduleIndex": idx]
            )
            return
        }
        selectedDay = day
    }
}

#Preview("Calendar") {
    CalendarView()
}
