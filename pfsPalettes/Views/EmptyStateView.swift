import SwiftUI

struct EmptyStateView: View {
    let onAddTapped: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text("No colors yet")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            Button("+ Add Color") {
                onAddTapped()
            }
            .buttonStyle(.link)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
