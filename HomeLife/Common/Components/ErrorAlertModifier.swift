import SwiftUI

/// ViewModel'deki `errorMessage` dolduğunda kullanıcıya alert gösteren modifier
private struct ErrorAlertModifier: ViewModifier {
    @Binding var message: String?

    func body(content: Content) -> some View {
        content.alert(
            "İşlem Başarısız",
            isPresented: Binding(
                get: { message != nil },
                set: { isPresented in
                    if !isPresented { message = nil }
                }
            )
        ) {
            Button("Tamam", role: .cancel) {
                message = nil
            }
        } message: {
            Text(message ?? "")
        }
    }
}

extension View {
    /// Hata mesajı nil değilse alert gösterir, kapatılınca mesajı temizler
    public func errorAlert(_ message: Binding<String?>) -> some View {
        modifier(ErrorAlertModifier(message: message))
    }
}

/// Oturum / bağlantı hataları için ekranın üstünde gösterilen küçük banner
public struct ErrorBannerView: View {
    public let message: String
    public let onRetry: () -> Void
    public let onDismiss: () -> Void

    public init(message: String, onRetry: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.message = message
        self.onRetry = onRetry
        self.onDismiss = onDismiss
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.icloud.fill")
                .foregroundColor(AppTheme.danger)

            VStack(alignment: .leading, spacing: 2) {
                Text("Sunucuya bağlanılamadı")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.danger)
                Text(message)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }

            Spacer(minLength: 4)

            Button("Tekrar Dene", action: onRetry)
                .font(.caption)
                .fontWeight(.semibold)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppTheme.danger.opacity(0.12))
    }
}
