import DesignSystem
import SwiftUI

/// Media Hub layout. Every source is a placeholder until Phase 5.
struct MediaHubPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: CairSpace.m) {
            MicroLabel("Media Hub")
            Text("Sound for the path")
                .cairText(.headline)

            SectionRule("Ambience")
            MediaRow(symbol: "tree", title: "Pine wood at night", detail: "Wind, leaves, distant bells")
            MediaRow(symbol: "flame", title: "Hearth", detail: "Fire, kettle, rain on glass")

            SectionRule("Music")
            MediaRow(symbol: "music.note", title: "Apple Music", detail: "Your library and playlists")
            MediaRow(symbol: "arrow.up.forward.app", title: "Spotify", detail: "Opens your playlist in Spotify")

            SectionRule("Screening Room")
            ScreeningRoomPlaceholder()

            Text("Sources connect in Phase 5.")
                .cairText(.microData)
                .foregroundStyle(.tertiary)
        }
    }
}

private struct MediaRow: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: CairSpace.m) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .regular))
                .frame(width: 28)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).cairText(.control)
                Text(detail).cairText(.microData).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, CairSpace.xs)
        .accessibilityElement(children: .combine)
    }
}

/// The visible YouTube card. The player viewport will never drop below 200 pt on
/// either axis (YouTube's Required Minimum Functionality).
private struct ScreeningRoomPlaceholder: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CairRadius.control)
                .fill(.black.opacity(0.35))
            VStack(spacing: CairSpace.xs) {
                Image(systemName: "play.rectangle")
                    .font(.system(size: 28, weight: .light))
                MicroLabel("Visible player · 200 pt minimum")
            }
            .foregroundStyle(.secondary)
        }
        .aspectRatio(16.0 / 9.0, contentMode: .fit)
        .frame(minHeight: 200)
        .overlay {
            CornerBrackets(length: 12)
                .stroke(.tertiary, lineWidth: CairStroke.rule)
                .padding(CairSpace.xs)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Screening Room, coming in Phase 5")
    }
}
