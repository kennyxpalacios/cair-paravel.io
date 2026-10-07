import SwiftUI

/// Tracked uppercase mono label. Uses the hierarchical `.secondary` style, so it reads
/// correctly on both the night canvas and paper.
public struct MicroLabel: View {
    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .cairText(.microLabel)
            .foregroundStyle(.secondary)
    }
}

/// Stacked micro-data lines: coordinates, dates, counters (the FANTASY poster's corner columns).
public struct MicroDataStack: View {
    private let lines: [String]

    public init(_ lines: [String]) {
        self.lines = lines
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(lines.indices, id: \.self) { index in
                Text(lines[index])
                    .cairText(.microData)
                    .foregroundStyle(.tertiary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// A labeled hairline rule that opens a section.
public struct SectionRule: View {
    private let label: String
    private let trailing: String?

    public init(_ label: String, trailing: String? = nil) {
        self.label = label
        self.trailing = trailing
    }

    public var body: some View {
        HStack(spacing: CairSpace.s) {
            Text(label).cairText(.microLabel)
            Rectangle()
                .frame(height: CairStroke.hairline)
                .opacity(0.5)
            if let trailing {
                Text(trailing).cairText(.microLabel)
            }
        }
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
    }
}
