import SwiftUI

/// Ev arkadaşı için renkli avatar görünümü
public struct AvatarBadgeView: View {
    public let emoji: String
    public let initials: String
    public let colorHex: String
    public let size: CGFloat
    public let showBorder: Bool

    public init(
        emoji: String = "👤",
        initials: String = "",
        colorHex: String = "#4F46E5",
        size: CGFloat = 40,
        showBorder: Bool = false
    ) {
        self.emoji = emoji
        self.initials = initials
        self.colorHex = colorHex
        self.size = size
        self.showBorder = showBorder
    }

    public var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: colorHex).opacity(0.2))

            if !emoji.isEmpty && emoji != "👤" {
                Text(emoji)
                    .font(.system(size: size * 0.52))
            } else if !initials.isEmpty {
                Text(initials)
                    .font(.system(size: size * 0.38, weight: .bold))
                    .foregroundColor(Color(hex: colorHex))
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.45))
                    .foregroundColor(Color(hex: colorHex))
            }
        }
        .frame(width: size, height: size)
        .overlay(
            Circle()
                .stroke(showBorder ? Color.white : Color.clear, lineWidth: 2)
        )
    }
}
