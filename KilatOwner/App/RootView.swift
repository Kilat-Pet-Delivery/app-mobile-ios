import SwiftUI

struct RootView: View {
    @Environment(AppSession.self) private var session
    @State private var authMode: AuthMode = .login

    var body: some View {
        switch session.state {
        case .bootstrapping:
            SplashView(viewModel: SplashViewModel(appSession: session))
        case .unauthenticated:
            switch authMode {
            case .login:
                LoginView(viewModel: LoginViewModel(appSession: session)) {
                    authMode = .register
                }
            case .register:
                RegisterView(viewModel: RegisterViewModel(appSession: session)) {
                    authMode = .login
                }
            }
        case .authenticated:
            AuthenticatedRootView()
        }
    }
}

private struct AuthenticatedRootView: View {
    var body: some View {
        HomeView()
    }
}

private enum AuthMode {
    case login
    case register
}

#Preview {
    RootView()
        .environment(AppSession())
}
