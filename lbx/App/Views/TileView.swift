import LbxCore
import SwiftUI

extension Color {
    /// Falls back to the default palette color for malformed hex strings.
    init(hex: String) {
        let color = HexColor(hex) ?? HexColor(HexColor.defaultHex)!
        self.init(.sRGB, red: color.red, green: color.green, blue: color.blue)
    }
}

/// The icon square used by grid cells and editor previews.
struct IconTile: View {
    let symbol: String
    let colorHex: String
    var isGroup = false
    var size: CGFloat = 64

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
            .fill(Color(hex: colorHex).gradient)
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.hierarchical)
            }
            .overlay(alignment: .bottomTrailing) {
                if isGroup {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: size * 0.18, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(size * 0.06)
                        .background(.black.opacity(0.25), in: Circle())
                        .padding(size * 0.06)
                }
            }
            .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
    }
}

/// A grid cell: icon plus name label.
struct TileView: View {
    let item: LaunchItem
    var isEditing = false
    var onDelete: (@MainActor () -> Void)?

    var body: some View {
        VStack(spacing: 6) {
            IconTile(symbol: item.iconSymbol, colorHex: item.colorHex, isGroup: item.isGroup)
                .overlay(alignment: .topLeading) {
                    if isEditing, let onDelete {
                        Button { onDelete() } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title3)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .red)
                        }
                        .buttonStyle(.plain)
                        .offset(x: -8, y: -8)
                        .accessibilityLabel("Delete \(item.name)")
                    }
                }
            Text(item.name)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(item.isGroup ? "\(item.name), group" : item.name)
    }
}
