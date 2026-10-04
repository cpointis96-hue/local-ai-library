import SwiftUI

struct SectionLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(AppDesign.Typography.section)
            .foregroundStyle(AppDesign.Colors.secondaryText)
            .textCase(.uppercase)
            .padding(.horizontal, AppDesign.Spacing.lg)
            .padding(.vertical, AppDesign.Spacing.sm)
    }
}

struct CompactIconButton: View {
    let systemImage: String
    let title: String
    let action: () -> Void
    var isDisabled = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .imageScale(.medium)
                .frame(minWidth: AppDesign.Control.regularHeight, minHeight: AppDesign.Control.regularHeight)
        }
        .buttonStyle(.borderless)
        .disabled(isDisabled)
        .help(title)
        .accessibilityLabel(title)
    }
}

struct InspectorRow: View {
    let label: String
    let value: String
    var action: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.xs) {
            Text(label)
                .font(AppDesign.Typography.detailLabel)
                .foregroundStyle(AppDesign.Colors.secondaryText)
            Text(value)
                .font(AppDesign.Typography.detailValue)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .lineLimit(2)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .help(action == nil ? value : "Double-click to copy")
                .accessibilityHint(action == nil ? "" : "Double-click to copy")
                .onTapGesture(count: 2) { action?() }
        }
        .padding(.vertical, AppDesign.Spacing.lg)
        .overlay(alignment: .bottom) {
            Divider()
                .overlay(AppDesign.Colors.separator.opacity(0.65))
        }
    }
}
