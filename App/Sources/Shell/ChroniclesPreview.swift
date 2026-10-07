import DesignSystem
import SwiftUI

/// The Chronicles as editorial paper: the FANTASY poster's ink grid becomes a six-week
/// record of expeditions. Sample data until persistence lands in Phase 3.
struct ChroniclesPreview: View {
    private let days = ChroniclesPreview.sampleDays()

    var body: some View {
        VStack(alignment: .leading, spacing: CairSpace.m) {
            HStack {
                MicroLabel("The Chronicles")
                Spacer()
                MicroLabel("Sample data")
            }

            Text("Twelve expeditions this week")
                .cairText(.headline)

            Text("A quiet record of where you have walked. Missed days never break the path.")
                .cairText(.body)
                .foregroundStyle(.secondary)

            DayGrid(values: days)
                .padding(.top, CairSpace.xs)

            SectionRule("Streak", trailing: "5 days")
        }
        .padding(CairSpace.l)
        .foregroundStyle(CairColor.inkOnPaper)
        .cairSurface(.paper, in: .rect(cornerRadius: CairRadius.card))
    }

    /// 42 days of expedition counts (0 to 4), deterministic.
    static func sampleDays() -> [Int] {
        (0..<42).map { index in
            let value = (index * 37 + 11) % 9
            return value > 4 ? 0 : value
        }
    }
}

/// Seven columns of ink-ruled squares, shaded by how many expeditions each day held.
private struct DayGrid: View {
    let values: [Int]

    private static let weekdays = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
        VStack(spacing: CairSpace.xs) {
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(Self.weekdays.indices, id: \.self) { index in
                    Text(Self.weekdays[index])
                        .cairText(.microLabel)
                        .foregroundStyle(.secondary)
                }
            }
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(values.indices, id: \.self) { index in
                    Rectangle()
                        .fill(CairColor.inkOnPaper.opacity(Self.shade(values[index])))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            Rectangle()
                                .stroke(CairColor.inkOnPaper.opacity(0.55), lineWidth: CairStroke.rule)
                        }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Six weeks of sample expedition history")
    }

    private static func shade(_ count: Int) -> Double {
        switch count {
        case 0: 0
        case 1: 0.22
        case 2: 0.42
        case 3: 0.62
        default: 0.82
        }
    }
}
