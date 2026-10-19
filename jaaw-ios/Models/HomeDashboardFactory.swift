import Foundation

// MARK: - Dashboard derivation
// Turns the persisted API payload into the home screen's numbers: day order,
// attendance/marks totals, today's timeline and the stat tiles.

enum DashboardStats {
    // MARK: Time parsing

    /// Strips tab characters and literal `\t` sequences the API embeds in times.
    static func parseTime(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "\\t", with: "")
            .replacingOccurrences(of: "\t", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Minutes since midnight. API times have no meridian, so hours < 8 are PM.
    static func timeToMinutes(_ raw: String) -> Int {
        let clean = parseTime(raw)
        let pattern = #"(\d{1,2}):(\d{2})(?:\s*([AaPp][Mm]))?"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: clean, range: NSRange(clean.startIndex..., in: clean)),
              let hRange = Range(match.range(at: 1), in: clean),
              let mRange = Range(match.range(at: 2), in: clean),
              var hours = Int(clean[hRange]),
              let minutes = Int(clean[mRange])
        else { return 0 }

        var meridian = ""
        if match.range(at: 3).location != NSNotFound,
           let merRange = Range(match.range(at: 3), in: clean) {
            meridian = String(clean[merRange]).lowercased()
        }
        if meridian == "pm", hours < 12 { hours += 12 }
        else if meridian == "am", hours == 12 { hours = 0 }
        else if meridian.isEmpty, hours < 8 { hours += 12 }
        return hours * 60 + minutes
    }

    static func nowMinutes() -> Int {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: Date())
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }

    /// Splits minutes-since-midnight into the demo's ("8:00", "am") pair.
    static func displayTime(minutes: Int) -> (time: String, period: String) {
        let h24 = ((minutes / 60) % 24 + 24) % 24
        let period = h24 >= 12 ? "pm" : "am"
        let h12 = h24 % 12 == 0 ? 12 : h24 % 12
        return ("\(h12):\(String(format: "%02d", minutes % 60))", period)
    }

    // MARK: Attendance / marks

    static func overallAttendance(_ records: [AttendanceRecord]) -> Double {
        let conducted = records.reduce(0) { $0 + $1.classesConducted }
        let absent = records.reduce(0) { $0 + $1.classesAbsent }
        if conducted == 0 {
            guard !records.isEmpty else { return 100 }
            return records.reduce(0) { $0 + $1.attendancePercentage } / Double(records.count)
        }
        return Double(conducted - absent) / Double(conducted) * 100
    }

    static func isFinishedSemester(_ records: [AttendanceRecord]) -> Bool {
        !records.isEmpty && records.allSatisfy { $0.classesConducted == 0 && $0.classesAbsent == 0 }
    }

    static func canSkip(conducted: Int, absent: Int) -> Int {
        let attended = conducted - absent
        return max(0, Int(floor(Double(attended) / 0.75 - Double(conducted))))
    }

    static func needToAttend(conducted: Int, absent: Int) -> Int {
        let attended = conducted - absent
        return max(0, Int(ceil(3 * Double(conducted) - 4 * Double(attended))))
    }

    static func averageMarksPct(_ marks: [MarkRecord]) -> Double? {
        let valid = marks.filter {
            ($0.totalMarksMaximum ?? 0) > 0 && $0.totalMarksObtained != nil
        }
        guard !valid.isEmpty else { return nil }
        let sum = valid.reduce(0.0) { $0 + ($1.totalMarksObtained! / $1.totalMarksMaximum!) * 100 }
        return sum / Double(valid.count)
    }

    // MARK: Calendar / schedule

    static func normalizeDayOrder(_ value: String?) -> String? {
        guard let cleaned = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !cleaned.isEmpty else { return nil }
        if let match = cleaned.range(of: #"\d+"#, options: .regularExpression) {
            return String(cleaned[match])
        }
        return cleaned
    }

    static func todayDayOrder(calendar: AcademicCalendar, now: Date = Date()) -> String? {
        let key = Self.dateKey(now)
        for month in calendar.months {
            for entry in month.entries where entry.date == key {
                if let order = normalizeDayOrder(entry.dayOrder) { return order }
            }
        }
        return nil
    }

    static func todayCalendarEntry(calendar: AcademicCalendar, now: Date = Date()) -> CalendarEntry? {
        let key = Self.dateKey(now)
        for month in calendar.months {
            for entry in month.entries where entry.date == key {
                return entry
            }
        }
        return nil
    }

    /// True when today has no class order: an explicit holiday, a missing
    /// calendar row (e.g. a weekend), or a non-numeric order label such as
    /// "Holiday" / "—" that would otherwise render as a meaningless glyph.
    static func isHoliday(dayOrder: String?, entry: CalendarEntry?) -> Bool {
        if entry?.category.lowercased() == "holiday" { return true }
        guard let order = dayOrder, order.contains(where: \.isNumber) else { return true }
        return false
    }

    static func scheduleIndex(schedule: [ScheduleDay], dayOrder: String?) -> Int {
        guard let order = normalizeDayOrder(dayOrder) else { return -1 }
        return schedule.firstIndex { normalizeDayOrder($0.dayLabel) == order } ?? -1
    }

    static func dateKey(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        return fmt.string(from: date)
    }

    // MARK: Titles

    private static let romanNumeral = try? NSRegularExpression(pattern: "^[IVXLCDM]+$")

    static func normalizeSubject(_ title: String) -> String {
        var text = title.replacingOccurrences(of: #"\band\b"#, with: "&", options: .regularExpression)
        text = text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression).trimmingCharacters(in: .whitespaces)
        return text.split(separator: " ").map { word -> String in
            let w = String(word)
            if let roman = romanNumeral,
               roman.firstMatch(in: w, range: NSRange(w.startIndex..., in: w)) != nil {
                return w
            }
            return w.prefix(1).uppercased() + w.dropFirst().lowercased()
        }.joined(separator: " ")
    }

    static func facultyShort(_ faculty: String) -> String {
        (faculty.components(separatedBy: "(").first ?? faculty).trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - HomeDashboard factory

enum HomeDashboardFactory {
    static func make(
        profile: UserProfile,
        attendance: [AttendanceRecord],
        marks: [MarkRecord],
        schedule: [ScheduleDay],
        calendar: AcademicCalendar,
        now: Date = Date()
    ) -> HomeDashboard {
        let overallPct = DashboardStats.overallAttendance(attendance)
        let totalSkip = attendance.reduce(0) {
            $0 + DashboardStats.canSkip(conducted: $1.classesConducted, absent: $1.classesAbsent)
        }
        let totalNeed = attendance.reduce(0) {
            $0 + DashboardStats.needToAttend(conducted: $1.classesConducted, absent: $1.classesAbsent)
        }
        let avgMarks = DashboardStats.averageMarksPct(marks)

        let dayOrder = DashboardStats.todayDayOrder(calendar: calendar, now: now)
        let todayEntry = DashboardStats.todayCalendarEntry(calendar: calendar, now: now)
        let isHoliday = DashboardStats.isHoliday(dayOrder: dayOrder, entry: todayEntry)
        let trimmedDescription = todayEntry?.title?.trimmingCharacters(in: .whitespacesAndNewlines)
        let dayDescription = trimmedDescription?.isEmpty == false ? trimmedDescription : nil
        let idx = DashboardStats.scheduleIndex(schedule: schedule, dayOrder: dayOrder)
        let entries = idx >= 0 ? schedule[idx].entries.sorted {
            DashboardStats.timeToMinutes($0.startTime) < DashboardStats.timeToMinutes($1.startTime)
        } : []

        let nowMins = DashboardStats.nowMinutes()
        let statuses: [ClassEntry.Status] = entries.map { entry in
            let start = DashboardStats.timeToMinutes(entry.startTime)
            let end = DashboardStats.timeToMinutes(entry.endTime)
            if nowMins >= end { return .done }
            if nowMins >= start {
                let total = max(1, end - start)
                return .now(progress: Double(nowMins - start) / Double(total))
            }
            return .upcoming(isNext: false)
        }
        let firstUpcoming = statuses.firstIndex {
            if case .upcoming = $0 { return true }
            return false
        }
        let classes: [ClassEntry] = entries.enumerated().map { i, entry in
            let startMins = DashboardStats.timeToMinutes(entry.startTime)
            let (time, period) = DashboardStats.displayTime(minutes: startMins)
            var status = statuses[i]
            if case .upcoming = status, i == firstUpcoming {
                status = .upcoming(isNext: true)
            }
            let detail = "\(entry.room) · \(DashboardStats.facultyShort(entry.faculty))"
            return ClassEntry(
                time: time,
                period: period,
                title: DashboardStats.normalizeSubject(entry.courseTitle),
                detail: detail,
                status: status
            )
        }

        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "d MMM"
        dateFmt.locale = Locale(identifier: "en_US")
        let weekdayFmt = DateFormatter()
        weekdayFmt.dateFormat = "EEEE"
        weekdayFmt.locale = Locale(identifier: "en_US")
        let initial = profile.name.first.map { String($0).uppercased() } ?? "J"

        let count = classes.count
        let classCountLine: String
        switch count {
        case 0: classCountLine = "No classes"
        case 1: classCountLine = "1 class"
        default: classCountLine = "\(count) classes"
        }

        let nextUpLine: String
        if let current = entries.first(where: { e in
            let s = DashboardStats.timeToMinutes(e.startTime)
            let e2 = DashboardStats.timeToMinutes(e.endTime)
            return nowMins >= s && nowMins < e2
        }) {
            nextUpLine = "Now till \(DashboardStats.parseTime(current.endTime))"
        } else if let next = entries.first(where: {
            DashboardStats.timeToMinutes($0.startTime) > nowMins
        }) {
            nextUpLine = "Next at \(DashboardStats.parseTime(next.startTime))"
        } else if count == 0 {
            nextUpLine = "Holiday"
        } else {
            nextUpLine = "Done for today"
        }

        let attendanceTile: StatTile = {
            let pct = min(100, max(0, overallPct))
            let label = "\(Int(pct.rounded()))%"
            if DashboardStats.isFinishedSemester(attendance) {
                return StatTile(
                    title: "Attendance", fraction: pct / 100, percentLabel: label,
                    captionLeading: "Semester ", captionBold: "completed",
                    captionTrailing: " — final percentage",
                    usesSecondaryRing: false
                )
            }
            if totalSkip > 0 {
                return StatTile(
                    title: "Attendance", fraction: pct / 100, percentLabel: label,
                    captionLeading: "You can skip ", captionBold: "\(totalSkip) more",
                    captionTrailing: " classes and stay above 75%",
                    usesSecondaryRing: false
                )
            }
            if overallPct >= 75 {
                return StatTile(
                    title: "Attendance", fraction: pct / 100, percentLabel: label,
                    captionLeading: "At the edge — ", captionBold: "attend all",
                    captionTrailing: " upcoming classes",
                    usesSecondaryRing: false
                )
            }
            return StatTile(
                title: "Attendance", fraction: pct / 100, percentLabel: label,
                captionLeading: "Attend ", captionBold: "\(totalNeed) more",
                captionTrailing: " classes to reach 75%",
                usesSecondaryRing: false
            )
        }()

        let marksTile: StatTile = {
            guard let avg = avgMarks else {
                return StatTile(
                    title: "Overall marks", fraction: 0, percentLabel: "--",
                    captionLeading: "No ", captionBold: "marks yet",
                    captionTrailing: " uploaded this sem",
                    usesSecondaryRing: true
                )
            }
            let withData = marks.filter { ($0.totalMarksMaximum ?? 0) > 0 && $0.totalMarksObtained != nil }
            let obtained = withData.reduce(0.0) { $0 + ($1.totalMarksObtained ?? 0) }
            let maximum = withData.reduce(0.0) { $0 + ($1.totalMarksMaximum ?? 0) }
            let score = "\(Int(obtained.rounded())) / \(Int(maximum.rounded()))"
            return StatTile(
                title: "Overall marks", fraction: min(1, max(0, avg / 100)),
                percentLabel: "\(Int(avg.rounded()))%",
                captionLeading: "", captionBold: score,
                captionTrailing: " across \(withData.count) courses this sem",
                usesSecondaryRing: true
            )
        }()

        let doneCount = statuses.filter {
            if case .done = $0 { return true }
            return false
        }.count
        let hasCurrent = statuses.contains {
            if case .now = $0 { return true }
            return false
        }
        let todayTrailing: String
        if count == 0 {
            todayTrailing = "No classes today"
        } else if hasCurrent, let i = statuses.firstIndex(where: {
            if case .now = $0 { return true }
            return false
        }) {
            todayTrailing = "\(i + 1) of \(count) in progress"
        } else {
            todayTrailing = "\(doneCount) of \(count) done"
        }

        return HomeDashboard(
            monthDayLine: dateFmt.string(from: now),
            weekdayLine: weekdayFmt.string(from: now),
            userInitial: initial,
            dayOrderLabel: "Day order",
            dayOrderNumber: dayOrder ?? "",
            isHoliday: isHoliday,
            dayDescription: dayDescription,
            classCountLine: classCountLine,
            nextUpLine: nextUpLine,
            tiles: [attendanceTile, marksTile],
            todayTitle: "Today",
            todayTrailing: todayTrailing,
            classes: classes
        )
    }
}
