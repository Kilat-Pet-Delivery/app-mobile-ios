import SwiftUI

struct SplashView: View {
    @Bindable private var viewModel: SplashViewModel

    init(viewModel: SplashViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "pawprint.circle.fill")
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(.blue)

            Text("Kilat Owner")
                .font(.largeTitle.bold())

            ProgressView(viewModel.message)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .task {
            await viewModel.bootstrap()
        }
    }
}

#Preview {
    SplashView(viewModel: SplashViewModel(appSession: AppSession()))
}
