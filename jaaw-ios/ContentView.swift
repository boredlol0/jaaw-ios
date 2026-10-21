import SwiftUI

enum AppRoute: Hashable {
    case login
    case home
    case profile
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var path: [AppRoute] = []
    @State private var session = SessionStore.shared

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if !session.hasCheckedStoredSession {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(JaawColors.deep)
                } else if session.isLoggedIn {
                    MainTabs(onOpenProfile: openProfile)
                } else {
                    LandingView {
                        path.append(.login)
                    }
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .login:
                    LoginView(
                        onBack: { path.removeLast() },
                        onAuthenticated: { 
                            // Auth flow complete: reset the stack so back
                            // never returns to the login form.
                            path = []
                        }
                    )
                case .home:
                    MainTabs(onOpenProfile: openProfile)
                case .profile:
                    ProfileView()
                }
            }
        }
        .onAppear {
            session.restore()
            Task { await LiveClassActivityController.shared.sync() }
        }
        // Logging out clears the stack back to landing.
        .onChange(of: session.isLoggedIn) { _, loggedIn in
            if !loggedIn { path = [] }
            Task { await LiveClassActivityController.shared.sync() }
        }
        // Coming back to the app is the one moment we can top up the
        // scheduled live activities.
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await LiveClassActivityController.shared.sync() }
        }
    }

    private func openProfile() {
        path.append(.profile)
    }
}

#Preview {
    ContentView()
}
