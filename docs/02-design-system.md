# Cair Paravel · Phase 2: Design Tokens & Layout Scaffolding

Status: **Built, awaiting your review on device**
Date: 2026-10-07
Code: `Packages/CairKit/Sources/DesignSystem` (tokens and components), `App/Sources/Shell` (layout)

---

## 1. Two material worlds

The system splits into two worlds that never blur together:

| World | Where | Made of | References |
| --- | --- | --- | --- |
| **Night** | The canvas: Expeditions, Tea Time, the lamppost | Breathing mesh gradients, Liquid Glass and frosted cards, neon rims, grain | Lamppost watercolor, magenta-beam hiker, Mitra waves, glow bulb, dark gallery panels |
| **Paper** | The Chronicles: records, history, streaks | Vellum, ink-brown hairlines, Swiss grid, grain | FANTASY poster, Kraken engravings |

The app runs dark everywhere (`UIUserInterfaceStyle = Dark`). Paper appears as cards inside the night, the way a lit page sits on a desk at night.

## 2. Color

### 2.1 Palette

| Group | Token | Hex | Drawn from |
| --- | --- | --- | --- |
| Night | Midnight | `#0A0F1E` | Hiker sky, canvas base |
| | Nightfall | `#141B3A` | Upper lamplight sky |
| | Indigo | `#2B2F6B` | Umbrella, hiker blue |
| | Cobalt | `#4A5BD0` | Kraken engraving blue |
| | Deep Forest | `#0D2622` | Rivendell and Aslan forest depths |
| | Pine | `#1E463C` | Forest midtones |
| | Moss | `#5C7A3A` | Aslan oil painting ground |
| | Snow Blue | `#9DB8D6` | Lamppost snow |
| | Frost | `#DCE7F2` | Snow highlights |
| Warmth | Lamplight | `#F2A953` | The lamp itself |
| | Ochre | `#C9973F` | Aslan's gold |
| | Ember | `#E0663A` | Red-lit foliage under the beam |
| | Vermilion | `#C8432B` | Tumnus's scarf |
| | Sienna | `#9A5A33` | Faun fur, Fellowship cloaks |
| | Umber | `#4A2C1E` | Hearth shadow |
| | Dusk | `#3A1E2E` | Tea Time sky |
| | Peach | `#F2B79A` | Glass-pill landscape sky |
| Light | Magenta Beam | `#FF4FA3` | The hiker's light beam |
| | Cyan Beam | `#4FE3F0` | Bioluminescent edge light |
| | Periwinkle | `#A9B4F2` | Glow-bulb halo |
| | Chartreuse | `#F4F94B` | QUEST display type (signal, used rarely) |
| Paper | Parchment | `#F2EDE4` | Primary text on night |
| | Vellum | `#EADFD6` | FANTASY poster paper |
| | Ink Brown | `#4E3020` | FANTASY poster ink |
| | Ink | `#15110F` | Deepest ink |

### 2.2 Semantic roles

| Role | Value |
| --- | --- |
| Canvas | Midnight |
| Text primary / secondary / tertiary | Parchment, then the hierarchical `.secondary` / `.tertiary` styles (they also work on paper, resolving against ink) |
| Hairline / grid line | Parchment at 14% / 6% |
| Surface fallback (Reduce Transparency) | `#1A2035`, opaque |
| Signal | Chartreuse |
| Paper / ink on paper | Vellum / Ink Brown |

### 2.3 Moods

Each mood is a 3 × 3 mesh plus four accent roles. The canvas crossfades between moods over 1.6 s.

| Mood | When | Mesh story | Accent | Glass tint | Aura | Rim |
| --- | --- | --- | --- | --- | --- | --- |
| **Lamplight** | No session | Snow-blue night, amber pool at center | Lamplight | Lamplight | Lamplight | Periwinkle |
| **Expedition** | Focus | Cobalt canopy over deep forest, magenta bleeding in at upper left | Cyan Beam | Cyan Beam | Cyan Beam | Magenta Beam |
| **Tea Time** | Rest | Dusk plum above a hearth glow | Peach | Ember | Peach | Lamplight |

## 3. Type

| Style | Face | iPad / iPhone | Use |
| --- | --- | --- | --- |
| Hero numerals | Bodoni Moda | 184 / 104 pt, fixed | The countdown. Each glyph sits in a fixed slot so digits never shift |
| Display title | Bodoni Moda | 58 / 38 pt | "Expedition", "Tea Time" |
| Headline | Instrument Serif | 34 / 27 pt | Panel headlines |
| Quote | Instrument Serif Italic | 28 / 22 pt | Tumnus's voice |
| Body | SF Pro | Dynamic Type body | Reading copy |
| Control | SF Pro Semibold | Dynamic Type callout | Buttons and pills |
| Micro label | IBM Plex Mono Medium | 11 pt, +1.8 tracking, uppercase | Section labels |
| Micro data | IBM Plex Mono | 12 pt, +0.6 tracking | Coordinates, counters |
| Poster | SF Pro Expanded Black | 72 / 44 pt | Rare poster moments (QUEST) |

All three custom faces are OFL and committed in `DesignSystem/Resources/Fonts` with their licenses. They register at launch through Core Text; if one fails, text falls back to SF instead of disappearing. Custom styles (except the hero numerals) scale with Dynamic Type.

**Trying another face**: drop the file into `App/Resources/Fonts/Local/` (gitignored, never pushed), regenerate the project, and change its PostScript name in `CairFontName`.

## 4. Space, shape, grid

- **Spacing**: 4, 8, 12, 16, 24, 32, 48, 64, 96 pt.
- **Radii**: chip 10, control 18, card 28, panel 36.
- **Strokes**: hairline 0.5, rule 1, emphasis 1.5.
- **Editorial grid**: 12 columns, 48 pt margins, 24 pt gutters on iPad; 4 columns, 20 pt margins, 16 pt gutters on iPhone. Drawn as 6% hairlines with registration crosses (toggle in the Workshop).

## 5. Surfaces

| Surface | Built from | Use |
| --- | --- | --- |
| **Glass** | Liquid Glass (`glassEffect`) tinted 18% with the mood | Pills, dock, icon buttons |
| **Frost** | Ultra-thin material, mood tint gradient, 6% grain, gradient rim highlight, soft drop shadow | Large floating panels (the folio) |
| **Paper** | Vellum, 14% grain, ink-brown hairline | The Chronicles |

Reduce Transparency swaps glass and frost for an opaque surface with a hairline border.

## 6. Motion: the low-stimulation contract

- Ambient loops are slow: the aura and live dot breathe on 10 s and 4 s periods, the mesh drifts on 14 s.
- Every ambient `TimelineView` renders at 30 fps. ProMotion is left for direct interaction.
- No flashes, no strobing, no hard cuts. Mood changes crossfade over 1.6 s; panels spring in at 0.5 s with minimal bounce.
- Grain and grid are static.
- **Reduce Motion** freezes every ambient loop to a still frame.
- Haptics (iPhone only, automatic): a light impact when a session starts or pauses, a selection tick on mood change.

## 7. Components

| Component | Notes |
| --- | --- |
| `StatusPill` | Glass capsule, breathing live dot, copy morphs between states |
| `MicroLabel`, `MicroDataStack`, `SectionRule` | The editorial micro-typography |
| `CornerBrackets` | Technical framing around the countdown and the Screening Room |
| `TimerNumerals` | Fixed-slot Bodoni countdown with numeric content transitions and a spoken accessibility label |
| `MoodBackdrop` / `MoodField` | Breathing mesh, full-bleed or tiled |
| `GrainOverlay` | Static tiled noise, overlay blend |
| `EditorialGridOverlay` | Column hairlines and registration marks |
| `DesignSpecimenView` | Every token and component on one screen |

## 8. Layout shell

Layout is chosen by available width, never by device:

```
Width ≥ 1100 pt (iPad landscape)        700 to 1099 pt (iPad portrait)        < 700 pt (iPhone, narrow iPad windows)
┌──────────────────────────┬────────┐   ┌──────────────────────────────┐      ┌──────────────────┐
│ data      [pill]   [◎ ◎] │ FOLIO  │   │ data     [pill]    [◎ ◎]     │      │     [pill]       │
│                          │ docked │   │                  ┌─────────┐ │      │                  │
│        (Tumnus)          │ panel  │   │     (Tumnus)     │ FOLIO   │ │      │    (Tumnus)      │
│       EXPEDITION         │        │   │    EXPEDITION    │ floats  │ │      │   EXPEDITION     │
│       ⌜ 18:42 ⌟          │        │   │    ⌜ 18:42 ⌟     │ over    │ │      │   ⌜ 18:42 ⌟      │
│   "Eyes on the path."    │        │   │                  └─────────┘ │      │                  │
│     [■] [Pause] [☕]      │        │   │   [■] [Pause] [☕]            │      │ [■][Pause][☕][📖][♪]│
└──────────────────────────┴────────┘   └──────────────────────────────┘      └──────────────────┘
                                                                               panels open as sheets
```

- Top bar (iPad): place and date micro-data on the left, status pill centered, panel buttons on the right.
- Keyboard (iPad): Space starts or pauses, ⌘1 opens The Chronicles, ⌘2 opens the Media Hub.
- Tumnus is a placeholder (his aura breathing around the lamppost) until the Phase 4 rig.

## 9. How to review on device

1. Run `./scripts/bootstrap.sh` (it installs XcodeGen if needed, generates the project, and opens Xcode).
2. Pick an iPad or iPhone simulator (or your own device with your Personal Team) and press Run.
3. Tap **Begin Expedition**, then **Pause**, then the teacup to see the three moods. Open the panels.
4. Tap the **wrench** (debug builds only) for the Workshop: flip moods, toggle the grid, and open the **Design specimen** to see every token on one screen.
5. Try iPad landscape, portrait, and a narrow Stage Manager window, which should switch to the iPhone layout.

## 10. What is placeholder

| Placeholder | Replaced in |
| --- | --- |
| Static countdown values and preview state machine | Phase 3 (timer engine) |
| Chronicles sample data | Phase 3 (SwiftData) |
| Tumnus aura + lamppost glyph | Phase 4 (rig and art) |
| Mesh-only atmosphere | Phase 4 (beams, dust, light) |
| Media Hub rows and Screening Room frame | Phase 5 |
| App icon | Phase 6 |
