import SwiftUI

enum MainTab: Hashable {
    case home
    case attendance
    case timetable
    case marks
    case calendar
}

/// Tracks which tab is on screen. Each tab plays the same backdrop clip, and
/// only the visible one should be decoding it.
@Observable
final class TabActivity {
    static let shared = TabActivity()

    var activeTab: MainTab = .home

    func isActive(_ tab: MainTab) -> Bool {
        activeTab == tab
    }
}

struct MainTabs: View {
    @State private var selection: MainTab = .home

    var body: some View {
        TabView(selection: $selection) {
            Tab("Home", systemImage: "house.fill", value: .home) {
                HomeView()
            }
            Tab("Attendance", systemImage: "checkmark.circle.fill", value: .attendance) {
                AttendanceView()
            }
            Tab("Timetable", systemImage: "tablecells.fill", value: .timetable) {
                TimetableView()
            }
            Tab("Marks", systemImage: "graduationcap.fill", value: .marks) {
                MarksView()
            }
            Tab("Calendar", systemImage: "calendar", value: .calendar) {
                CalendarView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .onAppear {
            TabActivity.shared.activeTab = selection
        }
        .onChange(of: selection) { _, newValue in
            TabActivity.shared.activeTab = newValue
        }
        .onReceive(NotificationCenter.default.publisher(for: .jaawShowTimetable)) { _ in
            selection = .timetable
        }
    }
}

#Preview("Tabs") {
    MainTabs()
}
