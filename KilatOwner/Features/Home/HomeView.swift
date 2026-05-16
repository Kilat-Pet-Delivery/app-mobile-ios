import SwiftUI

struct HomeView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome\(welcomeSuffix)")
                            .font(.title2.bold())
                        Text("Pet shop browsing and booking creation land here in the next phase.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        session.logout()
                    }
                }
            }
            .navigationTitle("Kilat")
        }
    }

    private var welcomeSuffix: String {
        guard let name = session.currentUser?.displayName, !name.isEmpty else {
            return ""
        }
        return ", \(name)"
    }
}

#Preview {
    HomeView()
        .environment(AppSession())
}
