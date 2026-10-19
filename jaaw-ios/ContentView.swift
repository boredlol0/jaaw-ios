import SwiftUI

enum AppRoute: Hashable {
    case login
    case home
}

struct ContentView: View {
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
                    MainTabs()
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
                    MainTabs()
                }
            }
        }
        .onAppear {
            session.restore()
        }
        // Logging out clears the stack back to landing.
        .onChange(of: session.isLoggedIn) { _, loggedIn in
            if !loggedIn { path = [] }
        }
    }
}

#Preview {
    ContentView()
}
