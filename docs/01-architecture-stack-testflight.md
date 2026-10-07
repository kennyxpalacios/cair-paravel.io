# Cair Paravel · Phase 1: Architecture, Stack & TestFlight Pipeline

Status: **Decisions recorded (Revision 3), awaiting explicit go for Phase 2**
Date: 2026-10-07
Revision 2: scope widened from iPad-only to a universal iPhone + iPad app (new section 2.9; updates to 1.x, 2.4, 2.6, 2.8, 3.1, 4.x, 5.x, 8, 9).
Revision 4: pre-membership mode until the Apple Developer Program membership activates on Oct 15 (section 5.5).
Revision 3: decisions recorded (section 9). Screening Room kept, figure-first Tumnus direction (2.7), iCloud sync on (2.5, 4.x, 5.x), iPad leads design, public-repo rules (6).
Scope: Platform decision, module architecture, background audio and streaming constraints, project configuration, entitlements, signing, and the TestFlight pipeline. No product code ships in this phase.

---

## 0. Executive summary

| Decision | Recommendation |
| --- | --- |
| Stack | Native **Swift 6 + SwiftUI**, built with **Xcode 26 or later** |
| Devices | **Universal: iPhone + iPad**, one binary, one bundle ID (`TARGETED_DEVICE_FAMILY = 1,2`) |
| Minimum OS | **iOS 26.0 / iPadOS 26.0** |
| Layout | Driven by **available space**, not device type: a compact layout (iPhone, and iPad in narrow windows) and a regular layout (iPad full screen and wide windows) |
| Rendering | SwiftUI `MeshGradient`, `Canvas` + `TimelineView`, Metal shaders through `ShaderLibrary`, Liquid Glass (`glassEffect`). `MTKView` only if profiling demands it |
| State | Swift Observation (`@Observable`), main-actor stores, timer engine as a pure, effect-returning state machine |
| Persistence | SwiftData for The Chronicles with **iCloud (CloudKit) sync** across iPhone and iPad; small Codable snapshot in an App Group for live session state |
| Timer reliability | Wall-clock anchors, never tick counting. Local notifications (Time Sensitive) plus a Lock Screen Live Activity for phase ends |
| Primary music | **Apple MusicKit** |
| Secondary music | **Spotify by deep link** (no SDK) by default. The full App Remote SDK is capped at 5 users since Feb 2026 |
| YouTube | **Screening Room**: a visible, foreground-only glass card using the official IFrame player. No headless or background playback |
| Tumnus | **Figure-first faun** fused from the references: layered 2D rig with ink and watercolor shaders, lit by a mood-driven aura |
| Owned audio | `AVAudioEngine` ambience engine (forest, hearth, rain stems) with background audio mode |
| Project generation | **XcodeGen** (`project.yml` is the source of truth, `.xcodeproj` is generated) |
| CI / TestFlight | **Xcode Cloud** archive → TestFlight internal. GitHub Actions macOS job as a compile gate (free: the repo is public) |
| Design lead | **iPad** is the hero canvas; the compact iPhone layout is a first-class adaptation |

---

## 1. Platform decision: native SwiftUI vs React Native / Expo (EAS)

### 1.1 Evaluation

| Criterion | Native Swift / SwiftUI | React Native + Expo (EAS Build/Submit) |
| --- | --- | --- |
| Metal / shader pipeline | First class: `.colorEffect`, `.distortionEffect`, `.layerEffect`, `MTKView` | Via `react-native-skia` (SkSL shaders). No direct Metal, extra compositing layer |
| Liquid Glass (`glassEffect`, `GlassEffectContainer`) | Direct API | Not available without custom native modules |
| `MeshGradient`, `TimelineView`, `Canvas` | Direct API | Reimplement in Skia |
| ProMotion frame pacing | Native render loop, predictable | JS thread + bridge adds frame-time variance |
| `AVAudioSession` / `AVAudioEngine` control | Full | Native module required anyway |
| MusicKit | Swift-native API | Native module required |
| Live Activities / WidgetKit | Swift only | Swift extension required regardless |
| Dynamic Island, Control Center controls, Action button, Core Haptics (iPhone) | Direct API | Native modules or Swift extensions |
| App Intents / Focus Filters / Shortcuts | Swift only | Swift only |
| TestFlight pipeline | Xcode Organizer, `xcodebuild`, Xcode Cloud | EAS Build + EAS Submit (very smooth) |
| OTA updates | Not allowed for native code (TestFlight builds only) | EAS Update for JS bundles |
| Cross-platform reach | Apple only | iOS + Android |

### 1.2 Verdict

**Native SwiftUI.** Adding iPhone does not change the verdict: SwiftUI is already one codebase across iPhone and iPad, so React Native's only remaining advantages are Android reach and OTA JS updates. Neither applies to an Apple-only product whose identity is its rendering. Every differentiating feature in this brief (shader lighting, glass materials, background audio, MusicKit, Live Activities, Dynamic Island, Focus Filters) would require Swift native modules in an RN project anyway, so RN would add a second language and a bridge without removing any Swift. If Android ever enters scope, revisit then.

### 1.3 Why iOS / iPadOS 26 as the minimum

- **App Store Connect requires Xcode 26 / iOS 26 & iPadOS 26 SDK** for all uploads since April 28, 2026. Building against 26 is mandatory; deploying to 26 is a small step further.
- **Liquid Glass APIs** (`glassEffect`, `GlassEffectContainer`, glass button styles) are 26+. They are the native expression of pillar 4 (frosted tactile UI) and they inherit Reduce Transparency and Increase Contrast behavior for free.
- **New iPad windowing**: `UIRequiresFullScreen` is deprecated in iPadOS 26 and will be ignored in a future release. We design for freely resizable windows from day one, so no legacy layout paths to maintain.
- **Live Activities** on the iPad Lock Screen, and on iPhone across the Lock Screen, Dynamic Island, and StandBy.
- **Device floor**: iOS 26 runs on iPhone 11 / iPhone SE (2nd gen) and later (A13 and up), which sets the lowest GPU tier the atmosphere must handle.
- TestFlight audiences are self-selected; there is no long-tail install base to back-deploy to.

### 1.4 Development workflow constraint (important)

I am authoring code in a Linux cloud container. There is no Xcode, no simulator, no device here. Consequences:

1. **XcodeGen.** The project is described in `project.yml` (text, diffable, conflict-free). You run `xcodegen generate` on your Mac after pulling. The generated `.xcodeproj` is gitignored.
2. **Portable core.** `CairCore` (timer engine, streak math) is Foundation-only and lives in its own package so its tests can run on Linux (`swift test`) as well as macOS. I can verify engine logic here if a Swift toolchain is added to this environment's setup script.
3. **Remote compile gate.** A GitHub Actions macOS job runs `xcodegen generate && xcodebuild build` on every push. I read the job logs to catch compile errors without a Mac. You remain the source of truth for on-device feel.

---

## 2. System architecture

### 2.1 Repository layout (created in Phase 2)

```
cair-paravel.io/
├── project.yml                      # XcodeGen spec (source of truth)
├── App/
│   ├── Sources/                     # Composition root, scenes, navigation, App Intents
│   ├── Resources/                   # Assets.xcassets, AppIcon.icon, Fonts/, Audio/
│   ├── Info.plist
│   ├── CairParavel.entitlements
│   └── PrivacyInfo.xcprivacy
├── Extensions/
│   └── ExpeditionActivity/          # WidgetKit bundle: Live Activity (Lock Screen + Dynamic Island), Start control
├── Packages/
│   ├── CairCore/                    # Foundation only, Linux-testable
│   │   ├── Sources/CairCore/
│   │   └── Tests/CairCoreTests/
│   └── CairKit/                     # Apple frameworks: UI, data, media
│       ├── Sources/
│       │   ├── DesignSystem/
│       │   ├── Atmosphere/
│       │   ├── Tumnus/
│       │   ├── Chronicles/
│       │   └── MediaHub/
│       └── Tests/
├── ci_scripts/ci_post_clone.sh      # Xcode Cloud: install XcodeGen, generate project
├── .github/workflows/build.yml      # macOS compile gate
├── ExportOptions.plist              # CLI archive/upload path
└── docs/
```

### 2.2 Module map and dependency rules

```
                       ┌──────────────────────────┐
                       │   CairParavel (App)      │  composition root, scenes,
                       │   + ExpeditionActivity   │  DI container, App Intents
                       └────────────┬─────────────┘
       ┌───────────────┬────────────┼─────────────┬──────────────┐
       ▼               ▼            ▼             ▼              ▼
  ┌─────────┐   ┌───────────┐  ┌─────────┐  ┌────────────┐  ┌──────────┐
  │ Tumnus  │   │Atmosphere │  │MediaHub │  │ Chronicles │  │  Design  │
  │         │──▶│           │  │         │  │ (SwiftData)│  │  System  │
  └────┬────┘   └─────┬─────┘  └────┬────┘  └─────┬──────┘  └──────────┘
       │              │             │             │               ▲
       │              └─────────────┼─────────────┼───────────────┤ (UI modules
       ▼                            ▼             ▼               │  import it)
  ┌──────────────────────────────────────────────────────┐
  │ CairCore: TimerEngine, Phase/Preset models, Clock,   │
  │ StreakCalculator, WanderPolicy. Foundation only.     │
  └──────────────────────────────────────────────────────┘
```

| Module | Owns | May import |
| --- | --- | --- |
| `CairCore` | Timer state machine, domain types, clock abstraction, streak math, wander policy | Foundation |
| `Chronicles` | SwiftData models, `VersionedSchema`, migration plan, queries, history projections | CairCore, SwiftData |
| `DesignSystem` | Color, type, spacing, grid, motion tokens; glass cards; editorial type modifiers; font registration | SwiftUI |
| `Atmosphere` | Mesh gradient fields, beam and grain shaders (`.metal`), particle dust, quality tiers | DesignSystem |
| `Tumnus` | Companion mood state machine (derived from timer events), renderer protocol, aura shader | CairCore, DesignSystem, Atmosphere |
| `MediaHub` | Audio session coordinator, ambience engine, MusicKit adapter, Spotify link-out, Screening Room, Now Playing | CairCore, AVFoundation, MusicKit, MediaPlayer |
| App target | Wiring, scenes, navigation, notifications, Live Activity control, App Intents, Focus Filter | Everything above |

Rules: `CairCore` never imports Apple UI frameworks. Feature modules never import each other laterally except through `DesignSystem` and the `Tumnus → Atmosphere` render dependency. Cross-module communication goes through `CairCore` event types.

### 2.3 State management

- **Swift 6 language mode**, strict concurrency. App target uses Xcode 26 *approachable concurrency* with default `MainActor` isolation; packages stay explicit.
- **Timer engine as a pure reducer.** The engine never touches the clock, the disk, or the notification center directly:

  ```swift
  // Shape only. Implementation lands in Phase 3.
  public struct SessionEngine: Sendable {
      public func reduce(_ state: SessionState,
                         _ event: SessionEvent,
                         at now: Date) -> Transition
  }

  public struct Transition: Sendable {
      public var state: SessionState
      public var effects: [SessionEffect]   // scheduleAlert, cancelAlerts, persistSnapshot,
                                            // logChronicle, playChime, updateLiveActivity
  }
  ```

  A `@MainActor @Observable` `ExpeditionController` feeds events in, applies the new state, and executes effects through injected services. The engine is deterministic and exhaustively unit-testable with a fixed `now`.

- **Wall-clock anchors, never tick counting.** A running phase stores `startedAt`, `plannedDuration`, and accumulated pause time. Remaining time is computed on demand. The UI renders it through `TimelineView(.periodic(from:by: 1))` or `Text(timerInterval:)`. This survives suspension, termination, and reboot. On launch the controller *reconciles*: if a phase ended while the app was dead, it advances per policy and logs the Expedition with its true end time.
- We avoid `ProcessInfo.systemUptime` / `mach_absolute_time` for persisted anchors (they reset on reboot and are Required Reason APIs). `Date` is used and negative intervals (user changed system clock) are clamped.

### 2.4 What iOS and iPadOS actually let a timer do in the background

Both systems suspend an app seconds after it leaves the foreground (on iPhone this is the common case: the phone gets locked and pocketed mid-Expedition). There is no sanctioned way to keep a countdown "running", and we do not need one:

| Layer | Mechanism | Works when app is suspended or killed |
| --- | --- | --- |
| Truth | Wall-clock anchors in the snapshot | Yes |
| Phase-end alert | `UNNotificationRequest` at the computed end time, `interruptionLevel = .timeSensitive`, custom chime (bundled, under 30 s) | Yes |
| Glanceable countdown | Live Activity using `Text(timerInterval:)`: Lock Screen on both devices, plus Dynamic Island (compact, minimal, expanded) and StandBy on iPhone | Yes, self-updating without app execution |
| Auto-advance chain | Pre-schedule the next few phase notifications (Expedition end, Tea Time end); cancel and rebuild on any user action. iOS allows 64 pending local notifications | Yes |
| Live transitions | When ambience audio is playing, the `audio` background mode keeps the process alive, so the engine can transition and chime in real time | Only while audible audio plays |

**Never** play silent audio to stay alive. App Review rejects this (guideline 2.5.4), and TestFlight external builds go through Beta App Review.

### 2.5 Persistence: The Chronicles

- **SwiftData**, `VersionedSchema` v1 plus a `SchemaMigrationPlan` from the first commit.
- **iCloud sync is on (decided)**: SwiftData's CloudKit integration against the private database in container `iCloud.io.cairparavel.app`, so The Chronicles follow the user between iPhone and iPad. Sync is live before the first TestFlight build.
- **CloudKit schema rules** from the first model: every attribute optional or defaulted, no `@Attribute(.unique)`, all relationships optional with inverses.
- **Conflict-light by design**: each Expedition or Tea Time is an append-only fact created on one device, so merges rarely collide. Presets and shared preferences sync through the same store; device-specific settings (quality tier, haptics, orientation) stay local in `UserDefaults`.
- **Signed out of iCloud**: the store works locally and syncs once the user signs in. Nothing in the UI depends on sync having completed.
- Records store facts (start, end, planned, focused seconds, outcome, wander events, optional intention). Streaks are **computed**, not stored, by a pure `StreakCalculator` in `CairCore` with grace-day rules, so streak policy can change without data migration and never punishes a single missed day.
- **Live session snapshot** (the current phase anchors) is a small Codable file in the App Group container, readable by the Live Activity extension and App Intents. It stays local to each device (no live hand-off in v1).

### 2.6 Rendering stack

Escalate only when profiling demands it:

| Tier | Technique | Used for |
| --- | --- | --- |
| 0 | `MeshGradient` with slowly animated control points | Breathing midnight/aurora fields, the wave horizon |
| 1 | `ShaderLibrary` Metal shaders via `.colorEffect` / `.layerEffect` / `.visualEffect` | Diagonal neon beams, film grain, chromatic halo rims, duotone engraving treatment, glowing foliage edges |
| 2 | `Canvas` + `TimelineView(.animation(minimumInterval: 1/30))` | Particle dust (a few hundred motes, CPU is fine) |
| 3 | `MTKView` via `UIViewRepresentable`, compute particles | Only if volumetric light or 2k+ particles are needed |
| HUD | Liquid Glass for interactive controls; custom frost (material + grain + rim stroke) for large editorial cards | Floating control cards, status pill |

Budget and comfort rules (ADHD low-stimulation contract):

- Ambient layers capped at **30 fps**; ProMotion 120 Hz is reserved for direct-manipulation gestures.
- Motion periods of 8 to 14 seconds for breathing fields. No flashes, no strobing, no hard cuts during an Expedition.
- `accessibilityReduceMotion` → frozen composed frame. `accessibilityReduceTransparency` → opaque cards. Low Power Mode and `ProcessInfo.thermalState` step the atmosphere down a quality tier automatically.
- **Device tiering**: a starting quality tier is chosen at launch from device class (GPU family, display size, ProMotion), then adjusted at runtime by thermal state. iPhone starts one tier lighter than iPad: smaller thermal envelope, battery matters more, and a 6 inch canvas needs fewer particles to read as the same density. The A13 floor (iPhone 11 / SE 2nd gen) must hold 30 fps on tier 0 to 2.
- Shader resources: Xcode compiles `.metal` files inside a package target into the module bundle (`ShaderLibrary.bundle(.module)`). Verified on device in Phase 4; fallback is moving shaders into the app target.

### 2.7 Tumnus: character direction and rendering

**Direction (decided): figure first.** Tumnus is what you get when the references are fused into a single faun of Narnia. He is a recognizable storybook character, not an abstract glow, rendered in the hybrid language of the moodboard. The aura stays, but as his breath and light, not as a replacement for him.

| Trait | Drawn from | Treatment |
| --- | --- | --- |
| Silhouette and costume | Watercolor lamppost faun; Lewis's own description of the faun | Slight, gentle adult faun: curly hair, small curled horns, pointed ears, shaggy goat legs, cloven hooves, long tail. Red wool scarf, umbrella, brown-paper parcels. Kind, slightly anxious eyes |
| Linework | Fellowship poster, Moebius-style landscape, lamppost sketch | Variable-weight ink contour that goes dry and broken at the ends. Never a uniform cartoon outline |
| Color and fill | Lamppost watercolor, the Aslan oil paintings | Transparent watercolor washes on paper grain: umber and sienna fur, vermilion scarf, indigo umbrella that turns amber where lamplight passes through it |
| Ornament | Folk-pattern lion | Embroidered folk border on the scarf hem and waistcoat |
| Shadow texture | Kraken engravings | Fine engraved hatching in the deepest shadows, visible only at large sizes (iPad) |
| Light | Lamppost, magenta-beam hiker, haloed orbs | Amber key light from above, snow-blue fill, a thin neon rim (magenta or cyan) during Expeditions, a chromatic halo at his edges |
| Presence | Morphing glow-bulb video | A soft luminous field behind him that swells, dims, and shifts temperature with his mood |

He is an original faun built from these references, not a copy of any film or published illustration design.

**Rendering: a layered 2D rig in SwiftUI**, behind a `TumnusRenderer` protocol:

1. **Layers with pivots**: head (hair, ears, horns), eyes and brows, torso and waistcoat, scarf body and scarf tails, arms, umbrella, props (parcels, teacup), legs and hooves, tail.
2. **Two passes per layer**: an ink line layer and a wash fill layer, so shaders treat them separately (watercolor edge darkening and paper grain on fills; a very slow line wobble on ink).
3. **Procedural secondary motion**, all slow and low-stimulation: breathing, blinking, ear twitches, scarf and tail on damped springs, snow settling on the umbrella.
4. **Pose set per mood state**, spring-blended between states:

| Mood state | Trigger | Pose and light |
| --- | --- | --- |
| Waiting | Idle, no session | Under the lamppost, umbrella up, warm amber pool |
| Expedition | Focus running | Walking ahead, umbrella as a walking stick, occasional glance back; cool forest light with a neon rim |
| Wander | You left mid-Expedition and came back | Turns toward you, brows lifted, hand held out; aura dims and cools. Gentle, never scolding |
| Tea Time | Rest running | Seated, teacup steaming, scarf loosened; hearth-amber aura |
| Milestone | Expedition completed, streak day earned | Small bow with the umbrella tip; aura blooms once, then settles |

5. **Scale**: full figure on iPad (the hero canvas). On iPhone, a three-quarter crop where the aura carries more of the state.

**Asset pipeline**: concept sheet → line and color sheet → layered vector export (SVG or PDF per layer) → asset catalog with preserved vector data, or 3x PNG layers where painted texture matters. A faun drawn purely as code paths reads stiff, so the art needs a real drawing pass. Phase 4 sources, in order of preference for testing: (a) generated concept sheets that we then trace into layers (the Higgsfield image connector is available in this session; it spends your credits, so I will ask before using it), (b) you or an illustrator draw the sheet, (c) I hand-author stylized vector layers. The rig and the mood engine are the same whichever source fills the layers.

### 2.8 ADHD ergonomics: architectural hooks

- **Wander detection without surveillance**: `scenePhase` leaving `.active` during an Expedition records a wander event with duration. Tumnus reacts gently on return. Optional single "come back to the path" notification after N minutes. Nothing punitive.
- **Transition policy is data**, not code: per-preset auto-advance rules (e.g., Expedition → Tea Time automatic, Tea Time → Expedition with a short "gather your things" grace).
- **App Intents + Focus Filter** (`SetFocusFilterIntent`): a Focus such as "Deep Work" on either device can select a preset and silence non-essential UI. Shortcut: "Begin an Expedition".
- **One-press start (zero friction)**: the same App Intent powers a Control Center / Lock Screen control (`ControlWidget`) on both devices and the Action button on iPhones that have one. Starting an Expedition never requires opening the app.
- **Haptics as the quiet cue (iPhone)**: phase changes and wander nudges get a soft haptic signature (`sensoryFeedback`, Core Haptics for custom patterns). iPads have no Taptic Engine, so iPad relies on light and sound. Haptics are often the least overstimulating cue for ADHD users, so they are on by default on iPhone.
- **Screen Time distraction shielding** (FamilyControls / ManagedSettings) is technically possible but the distribution entitlement requires Apple's approval. Deferred unless you want it (see questions).

### 2.9 Universal layout strategy (iPhone + iPad)

Supporting iPhone costs less than it looks, because iPadOS 26 already forces us to build a compact layout: an iPad window in Stage Manager or Split View can be as narrow as a phone. One adaptive shell serves both devices.

- **Layout is driven by available space, never by device idiom.** Breakpoints come from the container width (`onGeometryChange`, `ViewThatFits`, `horizontalSizeClass` as a coarse hint). `userInterfaceIdiom` is used only for hardware capabilities (haptics, quality tier), never for layout.
- **Two layout families, shared components:**

| Family | Where | Structure |
| --- | --- | --- |
| **Compact** | iPhone (all), iPad narrow windows | Full-bleed atmosphere canvas, Tumnus and timer as the single focal column, HUD controls in a bottom glass dock, Chronicles and Media Hub as sheets |
| **Regular** | iPad full screen, iPad wide windows | Canvas with floating HUD cards, side column for Chronicles / Media Hub (split navigation), editorial grid overlays at full density |

- **Grid and type scale adapt as tokens**, not per-screen overrides: e.g., 12-column editorial grid on regular, 4-column on compact, with a display type scale that steps down by width. Defined in Phase 2.
- **Orientation**: iPad supports all four. iPhone ships **portrait-only in v1**; the "propped up on the desk" use case is covered by the Live Activity in StandBy, which the system renders in landscape for free.
- **Design lead**: iPad stays the hero canvas where the atmosphere is richest; the compact layout is a first-class design, not a squeezed iPad layout, and is reviewed on a real iPhone every phase.
- **Cross-device continuity**: the same person may own both devices. History syncs through iCloud (decided, see 2.5). Live hand-off of a *running* Expedition between devices is out of scope for v1.

---

## 3. Audio: background playback and streaming sandbox rules on iOS and iPadOS

The audio architecture is identical on both devices. The rules below apply to iPhone and iPad alike.

### 3.1 Session strategy

- One `AudioSessionCoordinator` owns `AVAudioSession`. Category **`.playback`** (plays in background, ignores silent mode), mode `.default`.
- **iPhone silent mode**: `.playback` ignores the Ring/Silent switch, which is right for ambience the user explicitly started, but wrong for surprise chimes. Rule: in-app chimes play only while the user has ambience running; otherwise phase changes use the notification sound (which respects silent mode) plus haptics.
- Two policies, switched by deactivating and reactivating the session:

| Policy | Options | When | Behavior |
| --- | --- | --- | --- |
| **Solo** | none | Only Cair ambience is playing | We own Now Playing (Lock Screen shows phase + remaining time + artwork) and remote commands |
| **Layered** | `.mixWithOthers` | Apple Music, Spotify, or any other app is playing | Ambience mixes under the user's music; we do not claim Now Playing |

- Phase chimes over someone else's music: briefly reactivate with `.duckOthers`, play, then deactivate with `.notifyOthersOnDeactivation`, the same pattern navigation apps use.
- Handle interruptions (calls, Siri), route changes (pause ambience when headphones disconnect, per HIG), and media services reset.
- **Visual reactivity**: we can tap our own `AVAudioEngine` mix for amplitude to let the atmosphere breathe with the ambience. We cannot read samples from Apple Music or Spotify (DRM, out-of-process), so music-reactive visuals are limited to our owned audio.

### 3.2 Owned ambience engine (the core of "focus audio")

- `AVAudioEngine` with layered stems (wind in pines, leaf rustle, distant bells, hearth, kettle, rain) on `AVAudioPlayerNode`s with gapless looping and per-stem gain.
- Expedition → Tea Time crossfades the soundscape (forest to hearth and kettle).
- Requires **licensed or original audio**. Bundled as AAC/CAF; roughly 4 MB per two-minute stereo stem at 256 kbps.

### 3.3 Provider evaluation

| Provider | Background playback | Gating constraints | Verdict |
| --- | --- | --- | --- |
| **Apple MusicKit** | Yes with `audio` background mode (`ApplicationMusicPlayer`), or delegated to the Music app (`SystemMusicPlayer`) | MusicKit App Service on the App ID; `NSAppleMusicUsageDescription`; user authorization; active Apple Music subscription for catalog playback | **Primary.** Native, no quota, no ToS traps. Ambience mixing alongside `ApplicationMusicPlayer` gets verified on device in Phase 5, fallback is `SystemMusicPlayer` + Layered policy |
| **Spotify App Remote SDK** | Yes, because audio plays inside the Spotify app, not ours | Spotify app installed; Premium. **Since Feb 2026, Development Mode requires Premium for the developer, allows one Client ID per developer, and caps authorized users at 5.** Extended quota is for established organizations. App Remote disconnects when our app backgrounds (reconnect on foreground). Developer Policy restricts combining Spotify content with other content, so we never programmatically duck or crossfade Spotify | **Not viable for a TestFlight group larger than 5.** Recommend **deep-link mode** instead: user saves a playlist link, we open it in Spotify, ambience runs Layered. Zero SDK, zero quota |
| **YouTube IFrame API in WKWebView** | **No.** WebKit suspends web media when backgrounded, and policy forbids it | YouTube API Terms prohibit separating or isolating audio from video and background play; Required Minimum Functionality requires a **visible** embedded player at least **200 × 200 px** (480 × 270 recommended for 16:9); no overlays obscuring the player. App Review guideline 5.2.3 backs this up | **Decided: visible Screening Room** (rules below). No headless or hidden player |

### 3.4 Screening Room (decided)

A glass card in the Media Hub that hosts the official YouTube IFrame player for lofi and ambient streams. Compliance is built into the component, not left to discipline:

- **Size floor**: the player viewport never drops below 200 pt on either axis. On iPad the card targets 480 × 270 or larger. On iPhone the player runs edge to edge (no side margins), so even the narrowest supported iPhone (375 pt wide) gets a 211 pt tall 16:9 viewport.
- **No overlays**: our glass chrome, grid lines, and particles stay outside the player's bounds. YouTube's own controls and branding stay intact.
- **Foreground only**: playback pauses when the card leaves the screen, when the sheet is dismissed, and when `scenePhase` leaves `.active`. No audio-only or minimized modes.
- **User-initiated**: no autoplay; the user presses play inside the player.
- **Mixing**: our ambience can keep playing underneath, because both are our app's audio.
- **Embedding**: loaded through the official IFrame API with a proper `origin` and an HTTPS base URL, since YouTube rejects embeds that arrive without a referrer.

---

## 4. Project configuration (exact)

### 4.1 Identifiers

| Item | Value |
| --- | --- |
| App bundle ID | `io.cairparavel.app` |
| Live Activity extension | `io.cairparavel.app.ExpeditionActivity` |
| App Group | `group.io.cairparavel.app` |
| iCloud container | `iCloud.io.cairparavel.app` |
| URL scheme | `cairparavel` |
| Marketing version / build | `0.1.0` / `1` (CI overrides build number) |

### 4.2 `project.yml` (XcodeGen, abridged)

```yaml
name: CairParavel
options:
  bundleIdPrefix: io.cairparavel
  deploymentTarget:
    iOS: "26.0"
  createIntermediateGroups: true
settings:
  base:
    SWIFT_VERSION: "6.0"
    TARGETED_DEVICE_FAMILY: "1,2"            # iPhone + iPad, one universal binary
    MARKETING_VERSION: "0.1.0"
    CURRENT_PROJECT_VERSION: "1"
    DEVELOPMENT_TEAM: YOUR_TEAM_ID
    CODE_SIGN_STYLE: Automatic
    ENABLE_USER_SCRIPT_SANDBOXING: YES
    SUPPORTS_MACCATALYST: NO
    SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD: NO  # no untested Mac surface
    SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD: NO   # no untested visionOS surface
packages:
  CairCore:
    path: Packages/CairCore
  CairKit:
    path: Packages/CairKit
targets:
  CairParavel:
    type: application
    platform: iOS
    sources: [App/Sources, App/Resources]
    info:
      path: App/Info.plist
    entitlements:
      path: App/CairParavel.entitlements
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: io.cairparavel.app
        SWIFT_DEFAULT_ACTOR_ISOLATION: MainActor
        SWIFT_APPROACHABLE_CONCURRENCY: YES
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
    dependencies:
      - package: CairCore
      - package: CairKit
        products: [DesignSystem, Atmosphere, Tumnus, Chronicles, MediaHub]
      - target: ExpeditionActivity
  ExpeditionActivity:
    type: app-extension
    platform: iOS
    sources: [Extensions/ExpeditionActivity]
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: io.cairparavel.app.ExpeditionActivity
    dependencies:
      - package: CairCore
      - sdk: WidgetKit.framework
      - sdk: SwiftUI.framework
```

### 4.3 `Info.plist` keys (app target)

| Key | Value | Why |
| --- | --- | --- |
| `UIBackgroundModes` | `[audio, remote-notification]` | Ambience and MusicKit playback in background; silent CloudKit pushes that trigger Chronicles sync |
| `NSAppleMusicUsageDescription` | "Cair Paravel plays your Apple Music during Expeditions." | MusicKit authorization prompt |
| `NSSupportsLiveActivities` | `YES` | Expedition countdown on Lock Screen, Dynamic Island, StandBy |
| `ITSAppUsesNonExemptEncryption` | `NO` | Only system HTTPS; skips export compliance questions per upload |
| `UILaunchScreen` | `{ UIColorName: LaunchBackground, UIImageName: LaunchMark }` | Plist-based launch screen, no storyboard |
| `UISupportedInterfaceOrientations` | `[Portrait]` | iPhone is portrait-only in v1 (see 2.9) |
| `UISupportedInterfaceOrientations~ipad` | all four | iPad landscape and portrait |
| `UIApplicationSceneManifest` | `UIApplicationSupportsMultipleScenes = NO` (v1) | One timer, one window. Revisit for a Chronicles side window |
| `CFBundleURLTypes` | scheme `cairparavel` | Deep links from Live Activity, Shortcuts |
| `LSApplicationQueriesSchemes` | `[spotify]` | Only to detect Spotify for deep-link mode |
| `UIAppFonts` | font file list | Custom editorial typefaces |
| `UIRequiresFullScreen` | **omit** | Deprecated in iPadOS 26. The compact layout already handles narrow iPad windows; `UIWindowScene.sizeRestrictions` sets a floor only if testing shows we need one |

### 4.4 Entitlements (`CairParavel.entitlements`)

```xml
<key>com.apple.security.application-groups</key>
<array><string>group.io.cairparavel.app</string></array>
<key>com.apple.developer.usernotifications.time-sensitive</key>
<true/>
<key>com.apple.developer.icloud-container-identifiers</key>
<array><string>iCloud.io.cairparavel.app</string></array>
<key>com.apple.developer.icloud-services</key>
<array><string>CloudKit</string></array>
<key>aps-environment</key>
<string>development</string>
```

`aps-environment` is required because CloudKit delivers sync changes as silent pushes. Xcode switches it to `production` automatically when exporting for TestFlight.

The extension's entitlements carry the same App Group. **MusicKit is not an entitlements-file key**: it is enabled as an App Service on the App ID in the developer portal, which also provisions the developer token automatically.

Deferred: `com.apple.developer.family-controls` (Screen Time shielding, out of scope for v1; requires Apple approval for distribution).

### 4.5 Privacy manifest (`PrivacyInfo.xcprivacy`)

- `NSPrivacyTracking = false`, no tracking domains, **no collected data types** (everything stays on device; iCloud private database data is not "collected" by us).
- `NSPrivacyAccessedAPITypes`:
  - `NSPrivacyAccessedAPICategoryUserDefaults` → `CA92.1` (app's own defaults) and `1C8F.1` (App Group shared defaults).
  - `NSPrivacyAccessedAPICategoryFileTimestamp` → `C617.1` only if we read file dates (avoid if possible).
- Any third-party SDK (e.g., Rive) must ship its own privacy manifest.

---

## 5. Signing and TestFlight pipeline

### 5.1 One-time setup (your side)

1. **Apple Developer Program** membership. Your developer Apple ID has been shared with me in chat; it is deliberately not recorded in this public repository. Still needed: confirm the membership is active (paid and approved) and send the 10-character **Team ID** from developer.apple.com → Account → Membership details. The Team ID is not secret and goes into `project.yml`.
2. **Certificates, Identifiers & Profiles**
   - Register explicit App IDs: `io.cairparavel.app`, `io.cairparavel.app.ExpeditionActivity`.
   - Capabilities on the app ID: App Groups, Time Sensitive Notifications, **iCloud (CloudKit)** with container `iCloud.io.cairparavel.app`, Push Notifications (carries CloudKit's silent sync pushes). App Services: **MusicKit**.
   - Register the App Group `group.io.cairparavel.app`; attach it to both IDs.
3. **App Store Connect** → Apps → New App: platform iOS, name, primary language, bundle ID `io.cairparavel.app`, SKU `CAIRPARAVEL001`. App names are globally unique and capped at 30 characters, so reserve early (see IP note in section 6).
4. **iPhone and iPad**: enable Developer Mode on each device (Settings → Privacy & Security → Developer Mode) for local runs.
5. **CloudKit Dashboard**: TestFlight builds talk to the CloudKit **Production** environment. Before any TestFlight build that changes the data model, deploy the schema from Development to Production, or testers' sync silently fails. This becomes a checklist item in Phase 6.

### 5.2 Signing model

| Context | Certificate | Profile | Managed by |
| --- | --- | --- | --- |
| Local device runs | Apple Development | Team development profile | Xcode automatic signing (registers your iPhone and iPad UDIDs on first run) |
| Archive → TestFlight | Apple Distribution (cloud-managed) | App Store Connect profile | Xcode Organizer or Xcode Cloud, automatic |
| CLI / GitHub Actions | Same | Same | `-allowProvisioningUpdates` with an App Store Connect API key (`.p8`, Key ID, Issuer ID) stored as CI secrets |

### 5.3 Pipeline

**Primary: Xcode Cloud** (included compute hours with the membership, native signing, posts straight to TestFlight).

```sh
# ci_scripts/ci_post_clone.sh
#!/bin/sh
set -euo pipefail
brew install xcodegen
cd "$CI_PRIMARY_REPOSITORY_PATH"
xcodegen generate
```

Workflow: start condition = push to `main` → Action: Archive (iOS, Release) → Post-action: TestFlight Internal Testing. Build number comes from `$CI_BUILD_NUMBER`. (Today the only branch is the working branch, which GitHub made the default; `main` is created when the first phase is merged.)

**Compile gate: GitHub Actions** on every branch push: `xcodegen generate`, then `xcodebuild build -scheme CairParavel -destination 'generic/platform=iOS Simulator'` and `swift test` for `CairCore`. The repository is public, so GitHub-hosted macOS runners cost nothing. Signing secrets (the App Store Connect `.p8` key) live only in GitHub encrypted secrets or Xcode Cloud, never in the repo.

**Manual fallback: CLI**

```sh
xcodebuild -project CairParavel.xcodeproj -scheme CairParavel \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath build/CairParavel.xcarchive archive -allowProvisioningUpdates

xcodebuild -exportArchive -archivePath build/CairParavel.xcarchive \
  -exportOptionsPlist ExportOptions.plist -exportPath build/export \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$ASC_KEY_PATH" \
  -authenticationKeyID "$ASC_KEY_ID" \
  -authenticationKeyIssuerID "$ASC_ISSUER_ID"
```

```xml
<!-- ExportOptions.plist -->
<dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>upload</string>
  <key>teamID</key><string>YOUR_TEAM_ID</string>
  <key>signingStyle</key><string>automatic</string>
  <key>manageAppVersionAndBuildNumber</key><false/>
</dict>
```

### 5.4 TestFlight distribution rules

| | Internal testing | External testing |
| --- | --- | --- |
| Who | Up to 100 App Store Connect team members | Up to 10,000 by email or public link |
| Review | None, available after processing | Beta App Review for the first build of each version |
| Requires | Nothing extra | Test information: beta description, feedback email, privacy policy URL, review contact |
| Build life | 90 days | 90 days |

One universal build covers both devices: testers install it through the TestFlight app on their iPhone and their iPad from the same invite. App Store screenshots (not needed for TestFlight) will be required for both device classes later.

Every upload needs a strictly increasing `CFBundleVersion` within a marketing version. Export compliance is answered automatically by `ITSAppUsesNonExemptEncryption = NO`. A beta-only debug HUD can be gated on `AppTransaction.shared` reporting the sandbox environment.

### 5.5 Before the membership activates (until Oct 15)

The paid membership is only required for TestFlight, App Store Connect, MusicKit, and the production iCloud container. Everything else runs today:

| Need | Works without the paid membership? | How |
| --- | --- | --- |
| Build and run in the iOS Simulator (iPhone and iPad) | Yes | No account at all; Xcode with any Apple ID or none |
| Run on your own iPhone and iPad | Yes | Free Apple ID added in Xcode → Settings → Accounts creates a "Personal Team". Limits: profiles expire after 7 days (press Run again to re-sign), a few free-provisioned apps per device, no distribution |
| Compile gate on GitHub Actions | Yes | Simulator builds need no signing (`CODE_SIGNING_ALLOWED=NO`) |
| Background audio, Live Activities, notifications, App Intents, haptics | Yes | Info.plist and local APIs |
| App Groups, Time Sensitive Notifications | Listed by Apple as available to free accounts | Kept on in personal mode; the code already falls back if Xcode refuses either |
| iCloud sync | Off until Oct 15 (our choice) | iCloud container IDs are permanent and bound to the team that creates them, so `iCloud.io.cairparavel.app` is created once, under the paid team. Until then The Chronicles are local-only; SwiftData's `.automatic` CloudKit mode syncs only when the entitlement exists, so the same code runs in both modes |
| MusicKit | No | It is an App Service configured in the paid developer portal. Lands with Phase 5 after Oct 15 |
| TestFlight / App Store Connect | No | Phase 6, after Oct 15 |

**Two signing modes**, selected in `Config/Signing.xcconfig` (Phase 2):

| Setting | Personal (now) | Distribution (after Oct 15) |
| --- | --- | --- |
| `DEVELOPMENT_TEAM` | your Personal Team ID (gitignored local file) | paid Team ID |
| Bundle ID | `io.cairparavel.app.dev` | `io.cairparavel.app` |
| App Group | `group.io.cairparavel.app.dev` | `group.io.cairparavel.app` |
| Entitlements | App Groups, Time Sensitive | + iCloud (CloudKit), `aps-environment` |
| MusicKit | hidden in the UI | enabled |

The `.dev` identifiers keep the real IDs unclaimed, so the paid team can register them cleanly. Switching modes is a one-line change; no code changes.

**Requirement**: a Mac that runs Xcode 26 or later. Everything above assumes one.

| Your Mac runs | Install | Notes |
| --- | --- | --- |
| macOS Tahoe 26.6 or later | **Xcode 27** (current, Mac App Store) | Preferred. Builds with the iOS 27 SDK while still deploying to iOS 26 |
| macOS Tahoe 26.0 to 26.5 | Update macOS, then Xcode 27 | Software Update is free |
| macOS Sequoia 15.6 or later, cannot upgrade to Tahoe | **Xcode 26.3** from developer.apple.com/download/all (free Apple ID) | Last Xcode that runs on Sequoia; fully sufficient for this project |
| Older than Sequoia 15.6 | Not supported | Needs a newer Mac (or a rented cloud Mac) |

Plan on at least 40 GB of free disk space for Xcode, the iOS simulator runtime, and build caches.

---

## 6. Risks and flags

1. **Narnia intellectual property.** "Cair Paravel", "Tumnus", Aslan, and Narnia are owned by The C.S. Lewis Company and remain under copyright and trademark protection. Internal TestFlight is unreviewed and private, so it is fine for building. External TestFlight and the App Store run through review (guideline 5.2, intellectual property), and a rights-holder complaint can pull the app. Recommendation: build with the current names behind a single `Brand` constant, and decide on original names (or a license) before external distribution.
2. **Reference art is mood only.** The uploaded illustrations and videos are third-party copyrighted work and must not ship. Two legitimate sources that match the brief: **public-domain Romantic and Hudson River School oil paintings** (Thomas Cole, the painter behind your QUEST reference, plus Bierstadt and Church) and **Gustave Doré engravings** (your Kraken duotone reference), via CC0 open-access collections such as The Met, the National Gallery of Art, and the Smithsonian. Everything else is original or commissioned.
3. **Fonts: testing mode (decided).** Licensing is ignored when choosing faces, so we pick the best fit for the references. One hard rule because the repository is public: font files that are not OFL are **never committed** (that would be public redistribution). They go in a gitignored `App/Resources/Fonts/Local/` folder you fill on your Mac, with committed OFL fallbacks so the build always works. Replace or license before external TestFlight.
4. **Spotify quota** (section 3.3): plan for deep-link mode.
5. **YouTube**: Screening Room only, visible and foreground (section 3.4).
6. **No silent-audio keepalive** (section 2.4).
7. **Public repository.** Everything pushed is world-readable: no secrets or API keys, no reference images, no licensed font files, no personal account details.

---

## 7. Reference intake (feeds Phase 2 tokens and Phase 4 atmosphere)

| Reference | What we take | Implementation target |
| --- | --- | --- |
| Watercolor faun under the lamppost | Canonical Tumnus character; **amber lamplight against cold snow blue** is the system's primary temperature contrast; the lamppost is the Tea Time motif | Color tokens; aura key light |
| Fellowship poster, Rivendell bridge, Moebius-style sci-fi landscape | Ink linework over dense flat palettes; "editorial sci-fi" clarity | Illustration layer style; line-weight tokens |
| Aslan triad (folk-pattern, painterly forest, classical oil) | Romantic oil palette: ochre, sienna, moss, gilded light through giant trunks | Mesh gradient palettes for Expedition depth |
| Surreal pastel landscape with haloed orbs | Chromatic aberration halos around soft forms | Halo rim shader for particles and Tumnus aura |
| FANTASY poster | Swiss grid, high-contrast Didone display, caps micro-data columns, paper grain | Grid overlay system, grain shader, micro-label type style |
| QUEST (Thomas Cole + chartreuse display) | Classical oil plate under a saturated modern display face | Signature accent token; type-over-painting composition |
| Hiker with magenta beam | Diagonal additive light beams on deep blue, ember-lit foliage | Beam shader, blend modes |
| Kraken engravings + ligature serif | Cobalt duotone engraving, ornate ligature serif | Duotone shader; display serif with alternates |
| Video: floating glowing panels (dark gallery) | Depth-stacked luminous cards in darkness | HUD layering and depth |
| Video: painted landscape + glass pill toolbar | Status pill that morphs copy ("Preparing…" → "Ready") over a living illustration | Phase status pill component |
| Video: glossy 3D forest with selection brackets | Technical overlays on organic scenes | Corner-bracket and coordinate overlay components |
| Video: Mitra wave gradient | Slow breathing wave horizon, glass cards | `MeshGradient` horizon |
| Video: morphing glow bulb | A luminous form that inflates, dims, and reshapes | Tumnus aura SDF states |

---

## 8. Phase plan confirmation

| Phase | Deliverable | Verification |
| --- | --- | --- |
| 2 | XcodeGen project, packages, tokens, glass components, adaptive shell (compact for iPhone and narrow iPad windows, regular for iPad) | Compile gate green; you run it on an iPhone and an iPad |
| 3 | `CairCore` engine + Chronicles persistence + notifications + Live Activity (Lock Screen, Dynamic Island) + Start intent / control | Engine unit tests (Linux + macOS); reconciliation tests |
| 4 | Atmosphere tiers + Tumnus mood engine and renderer + iPhone haptic signatures | On-device profiling on both devices, including the A13 floor (Instruments: SwiftUI, Metal System Trace) |
| 5 | Audio coordinator, ambience engine, MusicKit, Spotify deep link | On-device background, interruption, and route tests |
| 6 | Icon (Icon Composer `.icon`), launch screen, release scheme, Xcode Cloud → TestFlight | First internal TestFlight build installed |

---

## 9. Decisions log

| # | Topic | Decision | Source |
| --- | --- | --- | --- |
| 1 | Minimum OS | iOS 26.0 / iPadOS 26.0, universal iPhone + iPad | Default, not contested |
| 2 | Names / IP | Keep "Cair Paravel" and "Tumnus" for internal TestFlight; revisit before external testing | Default, not contested |
| 3 | Music scope | Apple MusicKit + Spotify deep link + owned ambience + **visible Screening Room** | You |
| 4 | Tumnus | **Figure-first faun** fused from the references; layered 2D rig (section 2.7) | You |
| 5 | Developer account | Apple ID received (kept out of the repo). Paid membership activates **Oct 15**; until then, Personal signing mode (section 5.5). Paid Team ID needed on Oct 15 | You |
| 6 | CI | Xcode Cloud → TestFlight; GitHub Actions compile gate. Repo verified **public** | Default + verified |
| 7 | Fonts | Best fit, licensing ignored for testing; non-OFL files never committed | You |
| 8 | Chronicles sync | **iCloud (CloudKit) sync on** before the first TestFlight build | You ("yes") |
| 9 | Screen Time shielding | Out of scope for v1 | Default, not contested |
| 10 | iPhone orientation | Portrait-only in v1 | Default, not contested |
| 11 | Design lead | **iPad leads** | You |

Not blocking Phases 2 to 4: the membership. Personal mode covers simulator and on-device runs; MusicKit, iCloud sync, and TestFlight switch on after Oct 15.
