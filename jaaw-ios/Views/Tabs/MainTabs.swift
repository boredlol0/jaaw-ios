import SwiftUI

enum MainTab: Hashable {
    case home
    case attendance
    case marks
    case calendar
    case profile
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
            Tab("Marks", systemImage: "graduationcap.fill", value: .marks) {
                MarksView()
            }
            Tab("Calendar", systemImage: "calendar", value: .calendar) {
                CalendarView()
            }
            Tab("Profile", systemImage: "person.crop.circle.fill", value: .profile) {
                ProfileView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

#Preview("Tabs") {
    MainTabs()
}
