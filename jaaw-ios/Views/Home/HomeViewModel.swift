import Foundation

@Observable
final class HomeViewModel {
    var dashboard: HomeDashboard

    init(dashboard: HomeDashboard = .demo) {
        self.dashboard = dashboard
    }
}
