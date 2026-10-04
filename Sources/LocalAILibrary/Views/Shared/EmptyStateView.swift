import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: AppDesign.Spacing.sm) {
            Image(systemName: "folder")
                .imageScale(.large)
                .foregroundStyle(AppDesign.Colors.secondaryText)
            Text(title)
                .font(.headline)
            Text(message)
                .font(AppDesign.Typography.metadata)
                .foregroundStyle(AppDesign.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppDesign.Spacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
