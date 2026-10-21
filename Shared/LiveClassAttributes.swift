import ActivityKit
import Foundation

// MARK: - Live Activity contract
// Shared by the app (which schedules the activity) and the widget extension
// (which draws it). The dates are absolute so the widget can hand them to the
// system's timer views, which keep ticking once the app is gone.

struct LiveClassAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var startDate: Date
        var endDate: Date
    }

    /// Identifies the timetable entry the activity belongs to
    /// ("2026-10-21T640"), so a scheduled activity can be matched back to its
    /// class and refreshed instead of duplicated.
    var sessionID: String
    /// The course being taught, e.g. "Computer Networks".
    var subject: String
    /// Where it happens and who takes it, e.g. "UB 512 · Dr. Karthik".
    var detail: String
}
