import Foundation

@Observable
final class HomeViewModel {
    var dashboard: HomeDashboard

    init(dashboard: HomeDashboard? = nil) {
        if let dashboard {
            self.dashboard = dashboard
        } else {
            let store = SessionStore.shared
            self.dashboard = HomeDashboardFactory.make(
                profile: store.profile,
                attendance: store.attendance,
                marks: store.marks,
                schedule: store.schedule,
                calendar: store.calendar
            )
        }
    }

    /// Rebuild the dashboard from the latest persisted payload (e.g. after login).
    func reload() {
        let store = SessionStore.shared
        dashboard = HomeDashboardFactory.make(
            profile: store.profile,
            attendance: store.attendance,
            marks: store.marks,
            schedule: store.schedule,
            calendar: store.calendar
        )
    }
}
