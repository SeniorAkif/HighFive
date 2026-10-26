import SwiftUI

/// Boş liste ve durumlar için bilgilendirme görünümü
public struct EmptyStateView: View {
    public let icon: String
    public let title: LocalizedStringKey
    public let message: LocalizedStringKey
    public let actionTitle: LocalizedStringKey?
    public let action: (() -> Void)?

    public init(
        icon: String,
        title: LocalizedStringKey,
        message: LocalizedStringKey,
        actionTitle: LocalizedStringKey? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundColor(.secondary)
                .padding(.bottom, 4)

            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AppTheme.primary)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}
