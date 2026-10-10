import SwiftUI

/// Empty placeholder screen shown at launch (M0).
struct HomeView: View {
    var body: some View {
        Text("home.placeholder.title")
            .font(.headline)
            .foregroundStyle(.secondary)
    }
}

#Preview {
    HomeView()
}
