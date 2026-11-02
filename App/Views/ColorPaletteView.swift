import LbxCore
import SwiftUI

/// Picks one of the fixed palette colors.
struct ColorPaletteView: View {
    @Binding var selection: String

    private let columns = [GridItem(.adaptive(minimum: 36, maximum: 44), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(HexColor.palette, id: \.self) { hex in
                let isSelected = hex.caseInsensitiveCompare(selection) == .orderedSame
                Button {
                    selection = hex
                } label: {
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: 32, height: 32)
                        .overlay {
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(3)
                        .overlay {
                            Circle().strokeBorder(isSelected ? Color(hex: hex) : .clear, lineWidth: 2)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(hex)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }
}
