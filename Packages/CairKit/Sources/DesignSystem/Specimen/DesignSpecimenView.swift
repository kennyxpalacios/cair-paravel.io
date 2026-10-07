import SwiftUI

/// A living specimen of every token and component, for reviewing the system on device.
public struct DesignSpecimenView: View {
    @State private var mood: AtmosphereMood
    @Environment(\.cairLayout) private var layout

    public init(mood: AtmosphereMood = .lamplight) {
        _mood = State(initialValue: mood)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CairSpace.xxl) {
                header
                SpecimenSection("Moods") { moods }
                SpecimenSection("Palette") { palette }
                SpecimenSection("Type") { type }
                SpecimenSection("Surfaces") { surfaces }
                SpecimenSection("Components") { components }
            }
            .padding(EditorialGrid.standard(for: layout).margin)
            .frame(maxWidth: 1100, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background { MoodBackdrop(mood: mood) }
        .environment(\.cairMood, mood)
        .foregroundStyle(CairColor.textPrimary)
        .navigationTitle("Design Specimen")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: CairSpace.s) {
            MicroLabel("Cair Paravel · Design System · Phase 2")
            Text("SPECIMEN").cairText(.poster)
            Text("Neo-mythical, editorial, and quiet enough to think in.")
                .cairText(.quote)
                .foregroundStyle(.secondary)
        }
    }

    private var moods: some View {
        VStack(alignment: .leading, spacing: CairSpace.m) {
            Picker("Mood", selection: $mood) {
                ForEach(AtmosphereMood.allCases) { mood in
                    Text(mood.displayName).tag(mood)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: CairSpace.m) {
                ForEach(AtmosphereMood.allCases) { option in
                    VStack(alignment: .leading, spacing: CairSpace.xs) {
                        MoodField(mood: option)
                            .frame(height: 120)
                            .clipShape(.rect(cornerRadius: CairRadius.card))
                            .overlay {
                                RoundedRectangle(cornerRadius: CairRadius.card)
                                    .strokeBorder(option == mood ? option.palette.accent : CairColor.hairline, lineWidth: CairStroke.emphasis)
                            }
                        MicroLabel(option.displayName)
                    }
                    .contentShape(.rect)
                    .onTapGesture { mood = option }
                }
            }
        }
    }

    private var palette: some View {
        VStack(alignment: .leading, spacing: CairSpace.l) {
            ForEach(CairPalette.catalog) { group in
                VStack(alignment: .leading, spacing: CairSpace.s) {
                    MicroLabel(group.name)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: CairSpace.s)], alignment: .leading, spacing: CairSpace.s) {
                        ForEach(group.swatches) { swatch in
                            VStack(alignment: .leading, spacing: CairSpace.xxs) {
                                RoundedRectangle(cornerRadius: CairRadius.chip)
                                    .fill(swatch.color)
                                    .frame(height: 56)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: CairRadius.chip)
                                            .strokeBorder(CairColor.hairline, lineWidth: CairStroke.hairline)
                                    }
                                Text(swatch.name).cairText(.microData)
                                Text(swatch.hexString).cairText(.microData).foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
        }
    }

    private var type: some View {
        VStack(alignment: .leading, spacing: CairSpace.l) {
            ForEach(CairTextStyle.allCases, id: \.self) { style in
                VStack(alignment: .leading, spacing: CairSpace.xxs) {
                    MicroLabel(style.specLabel(for: layout))
                    Text(Self.sample(for: style))
                        .cairText(style)
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)
                }
            }
        }
    }

    private var surfaces: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: CairSpace.m) { surfaceCards }
            VStack(alignment: .leading, spacing: CairSpace.m) { surfaceCards }
        }
    }

    @ViewBuilder
    private var surfaceCards: some View {
        SurfaceSample(title: "Glass", note: "Liquid Glass for controls", style: .glass)
        SurfaceSample(title: "Frost", note: "Material, tint, grain, rim", style: .frost)
        SurfaceSample(title: "Paper", note: "Vellum and ink for records", style: .paper)
            .foregroundStyle(CairColor.inkOnPaper)
    }

    private var components: some View {
        VStack(alignment: .leading, spacing: CairSpace.xl) {
            HStack(spacing: CairSpace.m) {
                StatusPill("Waiting at the lamppost")
                StatusPill("On expedition", detail: "25 MIN", isLive: true)
            }
            MicroDataStack(["CAIR PARAVEL", "LANTERN WASTE  51.7520° N  1.1920° W", "SESSION 03 / 04"])
            TimerNumerals(seconds: 25 * 60)
                .padding(CairSpace.l)
                .overlay {
                    CornerBrackets(length: 18)
                        .stroke(.tertiary, lineWidth: CairStroke.rule)
                }
            SectionRule("The Chronicles", trailing: "5 DAYS")
        }
    }

    private static func sample(for style: CairTextStyle) -> String {
        switch style {
        case .heroNumerals: "25:00"
        case .displayTitle: "Expedition"
        case .headline: "Twelve expeditions this week"
        case .quote: "Eyes on the path. I'll keep the lantern lit."
        case .body: "A calm companion for focused work, built for brains that wander."
        case .control: "Begin Expedition"
        case .microLabel: "Lantern Waste · 51.7520° N"
        case .microData: "SESSION 03 / 04 · 18:42 REMAINING"
        case .poster: "ONWARD"
        }
    }
}

private struct SpecimenSection<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CairSpace.l) {
            SectionRule(title)
            content
        }
    }
}

private struct SurfaceSample: View {
    let title: String
    let note: String
    let style: SurfaceStyle

    var body: some View {
        VStack(alignment: .leading, spacing: CairSpace.xs) {
            MicroLabel(title)
            Text(note).cairText(.headline)
        }
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
        .padding(CairSpace.l)
        .cairSurface(style, in: .rect(cornerRadius: CairRadius.card))
    }
}

#Preview {
    NavigationStack {
        DesignSpecimenView()
    }
    .onAppear { CairFonts.registerBundledFonts() }
}
