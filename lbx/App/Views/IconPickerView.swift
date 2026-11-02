import SwiftUI
import UIKit

/// Picks an SF Symbol from a curated list, or by typing any symbol name.
struct IconPickerView: View {
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var customName = ""

    private let columns = [GridItem(.adaptive(minimum: 52), spacing: 12)]

    private var filtered: [String] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return Self.symbols }
        return Self.symbols.filter { $0.contains(q) }
    }

    private var customIsValid: Bool {
        let name = customName.trimmingCharacters(in: .whitespaces)
        return !name.isEmpty && UIImage(systemName: name) != nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                customField

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(filtered, id: \.self) { symbol in
                        Button {
                            choose(symbol)
                        } label: {
                            Image(systemName: symbol)
                                .font(.title2)
                                .frame(width: 52, height: 52)
                                .background(
                                    symbol == selection ? Color.accentColor.opacity(0.2) : Color(.secondarySystemBackground),
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(symbol)
                    }
                }
            }
            .padding()
        }
        .searchable(text: $query, prompt: "Search symbols")
        .navigationTitle("Icon")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var customField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Any SF Symbol name")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                TextField("e.g. airplane.departure", text: $customName)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { if customIsValid { choose(customName) } }
                if customIsValid {
                    Image(systemName: customName.trimmingCharacters(in: .whitespaces))
                        .font(.title3)
                }
                Button("Use") { choose(customName) }
                    .disabled(!customIsValid)
            }
        }
    }

    private func choose(_ symbol: String) {
        selection = symbol.trimmingCharacters(in: .whitespaces)
        dismiss()
    }

    /// About 100 symbols that suit launcher actions.
    static let symbols: [String] = [
        "bolt.fill", "star.fill", "heart.fill", "flag.fill", "bookmark.fill", "tag.fill",
        "magnifyingglass", "doc.text.magnifyingglass", "globe", "safari.fill", "link", "network",
        "message.fill", "bubble.left.fill", "phone.fill", "video.fill", "envelope.fill", "paperplane.fill",
        "person.fill", "person.2.fill", "person.crop.circle.fill", "at", "megaphone.fill", "bell.fill",
        "calendar", "clock.fill", "alarm.fill", "timer", "stopwatch.fill", "hourglass",
        "note.text", "doc.fill", "doc.on.clipboard.fill", "folder.fill", "tray.fill", "archivebox.fill",
        "pencil", "square.and.pencil", "highlighter", "list.bullet", "checklist", "checkmark.circle.fill",
        "book.fill", "books.vertical.fill", "newspaper.fill", "character.bubble.fill", "textformat", "quote.bubble.fill",
        "camera.fill", "photo.fill", "photo.on.rectangle", "film.fill", "play.rectangle.fill", "play.circle.fill",
        "music.note", "headphones", "mic.fill", "speaker.wave.2.fill", "radio.fill", "tv.fill",
        "map.fill", "location.fill", "car.fill", "tram.fill", "airplane", "bicycle",
        "house.fill", "building.2.fill", "cart.fill", "bag.fill", "creditcard.fill", "dollarsign.circle.fill",
        "gearshape.fill", "wrench.and.screwdriver.fill", "hammer.fill", "terminal.fill", "chevron.left.forwardslash.chevron.right", "cpu.fill",
        "wifi", "antenna.radiowaves.left.and.right", "battery.100", "lightbulb.fill", "power", "lock.fill",
        "sun.max.fill", "moon.fill", "cloud.sun.fill", "cloud.rain.fill", "snowflake", "leaf.fill",
        "cup.and.saucer.fill", "fork.knife", "dumbbell.fill", "figure.walk", "bed.double.fill", "pills.fill",
        "gamecontroller.fill", "puzzlepiece.fill", "gift.fill", "graduationcap.fill", "briefcase.fill", "square.stack.3d.up.fill",
        "app.fill", "square.grid.2x2.fill", "sparkles", "wand.and.stars", "arrow.triangle.2.circlepath", "square.and.arrow.up.fill",
    ]
}
