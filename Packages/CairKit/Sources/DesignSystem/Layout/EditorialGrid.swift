import SwiftUI

/// The Swiss editorial grid (the FANTASY poster). Content aligns to it; the overlay
/// draws it as hairlines so the structure is part of the look.
public struct EditorialGrid: Sendable {
    public let columns: Int
    public let margin: CGFloat
    public let gutter: CGFloat

    public static func standard(for layout: LayoutClass) -> EditorialGrid {
        switch layout {
        case .regular: EditorialGrid(columns: 12, margin: 48, gutter: 24)
        case .compact: EditorialGrid(columns: 4, margin: 20, gutter: 16)
        }
    }

    /// Leading and trailing x position of every column.
    public func columnEdges(in width: CGFloat) -> [CGFloat] {
        let inner = max(0, width - margin * 2)
        let columnWidth = max(0, (inner - gutter * CGFloat(columns - 1)) / CGFloat(columns))
        var edges: [CGFloat] = []
        for index in 0..<columns {
            let x = margin + CGFloat(index) * (columnWidth + gutter)
            edges.append(x)
            edges.append(x + columnWidth)
        }
        return edges
    }
}

/// Hairline column guides plus registration marks. Static by design: no motion.
public struct EditorialGridOverlay: View {
    @Environment(\.cairLayout) private var layout
    private let showsMarks: Bool

    public init(showsMarks: Bool = true) {
        self.showsMarks = showsMarks
    }

    public var body: some View {
        let grid = EditorialGrid.standard(for: layout)
        let showsMarks = showsMarks
        Canvas { context, size in
            var lines = Path()
            for x in grid.columnEdges(in: size.width) {
                lines.move(to: CGPoint(x: x, y: 0))
                lines.addLine(to: CGPoint(x: x, y: size.height))
            }
            context.stroke(lines, with: .color(CairColor.gridLine), lineWidth: CairStroke.hairline)

            guard showsMarks else { return }
            let inset = grid.margin
            let arm: CGFloat = 6
            var marks = Path()
            for point in [
                CGPoint(x: inset, y: inset * 1.5),
                CGPoint(x: size.width - inset, y: inset * 1.5),
                CGPoint(x: inset, y: size.height - inset * 1.5),
                CGPoint(x: size.width - inset, y: size.height - inset * 1.5),
            ] {
                marks.move(to: CGPoint(x: point.x - arm, y: point.y))
                marks.addLine(to: CGPoint(x: point.x + arm, y: point.y))
                marks.move(to: CGPoint(x: point.x, y: point.y - arm))
                marks.addLine(to: CGPoint(x: point.x, y: point.y + arm))
            }
            context.stroke(marks, with: .color(CairColor.hairline), lineWidth: CairStroke.rule)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
