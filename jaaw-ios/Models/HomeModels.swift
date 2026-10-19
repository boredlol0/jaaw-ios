import Foundation

// MARK: - Home dashboard models
// `HomeDashboard.demo` is preview/sample content only. At runtime the view
// model builds the dashboard from the persisted API payload via
// `HomeDashboardFactory` without touching views.

struct ClassEntry: Identifiable, Hashable {
    enum Status: Hashable {
        case done
        case now(progress: Double)
        case upcoming(isNext: Bool)
        case later
    }

    let id = UUID()
    var time: String      // "8:00"
    var period: String    // "am" / "pm"
    var title: String
    var detail: String    // "TP 301 · Dr. Ramesh"
    var status: Status
}

struct StatTile: Hashable {
    var title: String
    var fraction: Double       // 0.87
    var percentLabel: String   // "87%"
    var captionLeading: String
    var captionBold: String
    var captionTrailing: String
    var usesSecondaryRing: Bool
}

struct HomeDashboard {
    var monthDayLine: String   // "7 Oct"
    var weekdayLine: String    // "Wednesday"
    var userInitial: String    // "T"
    var dayOrderLabel: String  // "Day order"
    var dayOrderNumber: String // "3"
    /// No class order today (holiday / weekend / non-numeric day order).
    var isHoliday: Bool = false
    /// The calendar's own note for today (e.g. "Muharram"), when it has one.
    var dayDescription: String? = nil
    var classCountLine: String // "5 classes"
    var nextUpLine: String     // "Next at 11:35"
    var tiles: [StatTile]
    var todayTitle: String
    var todayTrailing: String
    var classes: [ClassEntry]

    static let demo = HomeDashboard(
        monthDayLine: "7 Oct",
        weekdayLine: "Wednesday",
        userInitial: "T",
        dayOrderLabel: "Day order",
        dayOrderNumber: "3",
        classCountLine: "5 classes",
        nextUpLine: "Next at 11:35",
        tiles: [
            StatTile(
                title: "Attendance",
                fraction: 0.87,
                percentLabel: "87%",
                captionLeading: "You can skip ",
                captionBold: "4 more",
                captionTrailing: " classes and stay above 75%",
                usesSecondaryRing: false
            ),
            StatTile(
                title: "Overall marks",
                fraction: 0.82,
                percentLabel: "82%",
                captionLeading: "",
                captionBold: "412 / 500",
                captionTrailing: " across 6 courses this sem",
                usesSecondaryRing: true
            ),
        ],
        todayTitle: "Today",
        todayTrailing: "1 of 5 in progress",
        classes: [
            ClassEntry(time: "8:00", period: "am", title: "Data Structures & Algorithms", detail: "TP 301 · Dr. Ramesh", status: .done),
            ClassEntry(time: "8:50", period: "am", title: "Machine Learning", detail: "TP 405 · Dr. Anitha", status: .done),
            ClassEntry(time: "10:40", period: "am", title: "Computer Networks", detail: "UB 512 · Dr. Karthik", status: .now(progress: 0.24)),
            ClassEntry(time: "11:35", period: "am", title: "Probability & Statistics", detail: "UB 304 · Dr. Meera", status: .upcoming(isNext: true)),
            ClassEntry(time: "2:20", period: "pm", title: "ML Lab", detail: "Lab 2 · Dr. Anitha", status: .later),
        ]
    )
}
