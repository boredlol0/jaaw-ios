import ActivityKit
import Foundation

// MARK: - Live activity scheduling
//
// iOS 26 can start a Live Activity at a date of our choosing, so a class can
// reach the lock screen with the app closed and no server: the app schedules
// it while it is open, and the system starts it at the bell.

@MainActor
final class LiveClassActivityController {
    static let shared = LiveClassActivityController()

    /// The UserDefaults key behind the switch on the profile page.
    static let enabledKey = "jaaw.liveActivities.enabled"

    /// How many upcoming classes to keep scheduled.
    private static let horizon = 8
    /// How far ahead to look for class days in the academic calendar.
    private static let lookaheadDays = 21

    /// Guards against two syncs racing each other.
    private var isSyncing = false

    private init() {}

    /// Whether the student wants live activities at all.
    var isEnabled: Bool {
        UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? true
    }

    /// On schedules the upcoming classes, off dismisses everything running.
    func setEnabled(_ enabled: Bool) async {
        UserDefaults.standard.set(enabled, forKey: Self.enabledKey)
        if enabled {
            await sync()
        } else {
            await endAll()
        }
    }

    /// Brings the scheduled activities in line with the timetable: it only
    /// adds what is missing and removes what no longer belongs.
    func sync(now: Date = Date()) async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        guard isEnabled, SessionStore.shared.isLoggedIn else {
            await endAll()
            return
        }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let sessions = upcomingSessions(now: now)
        let wanted = Set(sessions.map(\.id))
        let running = Activity<LiveClassAttributes>.activities

        // Drop the ones whose class has run or no longer matches.
        for activity in running where !wanted.contains(activity.attributes.sessionID) {
            await activity.end(nil, dismissalPolicy: .immediate)
        }

        // Schedule the ones we don't have yet.
        let existing = Set(running.map(\.attributes.sessionID))
        for session in sessions where !existing.contains(session.id) {
            await start(session)
        }
    }

    /// Dismisses every live activity.
    func endAll() async {
        for activity in Activity<LiveClassAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    // MARK: - Starting one

    private func start(_ session: ClassSession) async {
        let attributes = LiveClassAttributes(
            sessionID: session.id,
            subject: session.subject,
            detail: session.detail
        )
        let state = LiveClassAttributes.ContentState(
            startDate: session.start,
            endDate: session.end
        )
        let content = ActivityContent(state: state, staleDate: session.end)

        do {
            if session.start <= Date() {
                // Already running — put it on the lock screen now.
                _ = try Activity.request(attributes: attributes, content: content, pushType: nil)
            } else {
                // iOS starts it at the class's start time, whether or not the
                // app is running then.
                let alert = AlertConfiguration(
                    title: "\(session.subject) is live",
                    body: "\(session.detail)",
                    sound: .default
                )
                _ = try Activity.request(
                    attributes: attributes,
                    content: content,
                    pushType: nil,
                    style: .standard,
                    alertConfiguration: alert,
                    start: session.start
                )
            }
        } catch {
            print("[live-activity] could not schedule \(session.id): \(error)")
        }
    }

    // MARK: - The timetable

    /// A class the app knows about, with the dates it actually runs on.
    private struct ClassSession {
        let id: String
        let subject: String
        let detail: String
        let start: Date
        let end: Date
    }

    /// The next few classes across the days ahead, oldest first.
    ///
    /// The timetable is stored as a cycle of day orders and the academic
    /// calendar maps each date onto one of them.
    private func upcomingSessions(now: Date) -> [ClassSession] {
        let store = SessionStore.shared
        let schedule = store.schedule
        guard !schedule.isEmpty else { return [] }

        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)

        // Date -> day order, skipping the days the portal marks as holidays.
        var dayOrders: [String: String] = [:]
        for month in store.calendar.months {
            for entry in month.entries {
                guard entry.category.lowercased() != "holiday" else { continue }
                guard let order = DashboardStats.normalizeDayOrder(entry.dayOrder) else { continue }
                dayOrders[entry.date] = order
            }
        }
        guard !dayOrders.isEmpty else { return [] }

        var sessions: [ClassSession] = []
        for dayOffset in 0..<Self.lookaheadDays {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: startOfToday) else { continue }
            let key = DashboardStats.dateKey(day)
            guard let order = dayOrders[key] else { continue }
            let index = DashboardStats.scheduleIndex(schedule: schedule, dayOrder: order)
            guard index >= 0, index < schedule.count else { continue }

            for entry in schedule[index].entries {
                let startMinutes = DashboardStats.timeToMinutes(entry.startTime)
                let endMinutes = DashboardStats.timeToMinutes(entry.endTime)
                guard endMinutes > startMinutes else { continue }
                guard let start = calendar.date(byAdding: .minute, value: startMinutes, to: day),
                      let end = calendar.date(byAdding: .minute, value: endMinutes, to: day)
                else { continue }
                guard end > now else { continue }

                sessions.append(
                    ClassSession(
                        id: sessionID(dateKey: key, startMinutes: startMinutes, entry: entry),
                        subject: DashboardStats.normalizeSubject(entry.courseTitle),
                        detail: detailLine(for: entry),
                        start: start,
                        end: end
                    )
                )
            }
        }

        return Array(sessions.sorted { $0.start < $1.start }.prefix(Self.horizon))
    }

    /// A stable name for one class. The course code is in there because two
    /// slots can share a start time.
    private func sessionID(dateKey: String, startMinutes: Int, entry: ScheduleEntry) -> String {
        let code = entry.courseCode.trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(dateKey)T\(startMinutes)-\(code)"
    }

    /// "UB 512 · Dr. Karthik", or just the room when there is no faculty.
    private func detailLine(for entry: ScheduleEntry) -> String {
        let room = entry.room.trimmingCharacters(in: .whitespacesAndNewlines)
        let faculty = DashboardStats.facultyShort(entry.faculty)
        switch (room.isEmpty, faculty.isEmpty) {
        case (false, false): return "\(room) · \(faculty)"
        case (false, true): return room
        default: return faculty
        }
    }
}
