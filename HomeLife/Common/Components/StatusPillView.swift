import SwiftUI

/// Durum bildiren rozet (pill)
public struct StatusPillView: View {
    public let text: String
    public let icon: String?
    public let color: Color
    public let style: PillStyle

    public enum PillStyle {
        case subtle
        case solid
    }

    public init(
        text: String,
        icon: String? = nil,
        color: Color = AppTheme.primary,
        style: PillStyle = .subtle
    ) {
        self.text = text
        self.icon = icon
        self.color = color
        self.style = style
    }

    public var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(style == .subtle ? color.opacity(0.15) : color)
        )
        .foregroundColor(style == .subtle ? color : .white)
    }
}
