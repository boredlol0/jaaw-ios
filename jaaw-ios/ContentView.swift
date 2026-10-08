import SwiftUI

enum AppRoute: Hashable {
    case login
    case home
}

struct ContentView: View {
    @State private var path: [AppRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            LandingView {
                path.append(.login)
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .login:
                    LoginView(
                        onBack: { path.removeLast() },
                        onAuthenticated: {
                            // Auth flow complete: reset the stack so back
                            // never returns to the login form.
                            path = [.home]
                        }
                    )
                case .home:
                    MainTabs()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
