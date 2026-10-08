import SwiftUI

private struct PlaceholderPage: View {
    var title: String

    var body: some View {
        Text(title)
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(HomeColors.secondaryText)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(HomeColors.page)
    }
}

struct AttendanceView: View {
    var body: some View {
        PlaceholderPage(title: "Attendance page")
    }
}

struct MarksView: View {
    var body: some View {
        PlaceholderPage(title: "Marks page")
    }
}

struct CalendarView: View {
    var body: some View {
        PlaceholderPage(title: "Calendar page")
    }
}

struct ProfileView: View {
    var body: some View {
        PlaceholderPage(title: "Profile page")
    }
}
