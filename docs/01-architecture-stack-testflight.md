# Cair Paravel · Phase 1: Architecture, Stack & TestFlight Pipeline

Status: **Proposed, awaiting approval**
Date: 2026-10-07
Scope: Platform decision, module architecture, background audio and streaming constraints, project configuration, entitlements, signing, and the TestFlight pipeline. No product code ships in this phase.

---

## 0. Executive summary

| Decision | Recommendation |
| --- | --- |
| Stack | Native **Swift 6 + SwiftUI**, built with **Xcode 26 or later** |
| Minimum OS | **iPadOS 26.0**, iPad only (`TARGETED_DEVICE_FAMILY = 2`) |
| Rendering | SwiftUI `MeshGradient`, `Canvas` + `TimelineView`, Metal shaders through `ShaderLibrary`, Liquid Glass (`glassEffect`). `MTKView` only if profiling demands it |
| State | Swift Observation (`@Observable`), main-actor stores, timer engine as a pure, effect-returning state machine |
| Persistence | SwiftData for The Chronicles (CloudKit-compatible schema), small Codable snapshot in an App Group for live session state |
| Timer reliability | Wall-clock anchors, never tick counting. Local notifications (Time Sensitive) plus a Lock Screen Live Activity for phase ends |
| Primary music | **Apple MusicKit** |
| Secondary music | **Spotify by deep link** (no SDK) by default. The full App Remote SDK is capped at 5 users since Feb 2026 |
| YouTube | **No headless player.** Only a visible, foreground "Screening Room" card, or cut entirely |
| Owned audio | `AVAudioEngine` ambience engine (forest, hearth, rain stems) with background audio mode |
| Project generation | **XcodeGen** (`project.yml` is the source of truth, `.xcodeproj` is generated) |
| CI / TestFlight | **Xcode Cloud** archive → TestFlight internal. GitHub Actions macOS job as a compile gate |

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
| App Intents / Focus Filters / Shortcuts | Swift only | Swift only |
| TestFlight pipeline | Xcode Organizer, `xcodebuild`, Xcode Cloud | EAS Build + EAS Submit (very smooth) |
| OTA updates | Not allowed for native code (TestFlight builds only) | EAS Update for JS bundles |
| Cross-platform reach | Apple only | iOS + Android |

### 1.2 Verdict

**Native SwiftUI.** React Native's real advantages (Android reach, OTA JS updates) do not apply to an iPad-only product whose identity is its rendering. Every differentiating feature in this brief (shader lighting, glass materials, background audio, MusicKit, Live Activities, Focus Filters) would require Swift native modules in an RN project anyway, so RN would add a second language and a bridge without removing any Swift.

### 1.3 Why iPadOS 26 as the minimum

- **App Store Connect requires Xcode 26 / iPadOS 26 SDK** for all uploads since April 28, 2026. Building against 26 is mandatory; deploying to 26 is a small step further.
- **Liquid Glass APIs** (`glassEffect`, `GlassEffectContainer`, glass button styles) are 26+. They are the native expression of pillar 4 (frosted tactile UI) and they inherit Reduce Transparency and Increase Contrast behavior for free.
- **New iPad windowing**: `UIRequiresFullScreen` is deprecated in iPadOS 26 and will be ignored in a future release. We design for freely resizable windows from day one, so no legacy layout paths to maintain.
- **Live Activities on iPad Lock Screen** for the running Expedition countdown.
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
│   └── ExpeditionActivity/          # Live Activity + Lock Screen widget (WidgetKit)
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

### 2.4 What iPadOS actually lets a timer do in the background

iPadOS suspends an app seconds after it leaves the foreground. There is no sanctioned way to keep a countdown "running", and we do not need one:

| Layer | Mechanism | Works when app is suspended or killed |
| --- | --- | --- |
| Truth | Wall-clock anchors in the snapshot | Yes |
| Phase-end alert | `UNNotificationRequest` at the computed end time, `interruptionLevel = .timeSensitive`, custom chime (bundled, under 30 s) | Yes |
| Glanceable countdown | Live Activity on the Lock Screen using `Text(timerInterval:)` | Yes, self-updating without app execution |
| Auto-advance chain | Pre-schedule the next few phase notifications (Expedition end, Tea Time end); cancel and rebuild on any user action. iOS allows 64 pending local notifications | Yes |
| Live transitions | When ambience audio is playing, the `audio` background mode keeps the process alive, so the engine can transition and chime in real time | Only while audible audio plays |

**Never** play silent audio to stay alive. App Review rejects this (guideline 2.5.4), and TestFlight external builds go through Beta App Review.

### 2.5 Persistence: The Chronicles

- **SwiftData**, `VersionedSchema` v1 plus a `SchemaMigrationPlan` from the first commit.
- **CloudKit-compatible schema** even if sync ships later: every attribute optional or defaulted, no `@Attribute(.unique)`, optional inverse relationships. Flipping on iCloud sync later becomes a capability change, not a migration.
- Records store facts (start, end, planned, focused seconds, outcome, wander events, optional intention). Streaks are **computed**, not stored, by a pure `StreakCalculator` in `CairCore` with grace-day rules, so streak policy can change without data migration and never punishes a single missed day.
- **Live session snapshot** (the current phase anchors) is a small Codable file in the App Group container, readable by the Live Activity extension and App Intents.

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
- Shader resources: Xcode compiles `.metal` files inside a package target into the module bundle (`ShaderLibrary.bundle(.module)`). Verified on device in Phase 4; fallback is moving shaders into the app target.

### 2.7 Tumnus rendering approach

Your references point at two registers: the **illustrated faun** (watercolor, lamppost, umbrella, scarf) and an **abstract luminous presence** (the morphing glow bulb video, the haloed orbs). Proposed hybrid, behind a `TumnusRenderer` protocol:

1. **Aura**: a signed-distance-field metaball shader whose shape, color temperature, and breathing tempo encode mood (focused, drifting, gently concerned, cozy tea). Fully procedural, ships in Phase 4.
2. **Figure**: a silhouette or illustrated layer with a handful of state poses, lit by the aura (rim glow, lamplight). Placeholder silhouette first; commissioned art or a Rive state machine can slot into the same protocol later without touching the mood engine.

### 2.8 ADHD ergonomics: architectural hooks

- **Wander detection without surveillance**: `scenePhase` leaving `.active` during an Expedition records a wander event with duration. Tumnus reacts gently on return. Optional single "come back to the path" notification after N minutes. Nothing punitive.
- **Transition policy is data**, not code: per-preset auto-advance rules (e.g., Expedition → Tea Time automatic, Tea Time → Expedition with a short "gather your things" grace).
- **App Intents + Focus Filter** (`SetFocusFilterIntent`): an iPad Focus such as "Deep Work" can select a preset and silence non-essential UI. Shortcut: "Begin an Expedition".
- **Screen Time distraction shielding** (FamilyControls / ManagedSettings) is technically possible but the distribution entitlement requires Apple's approval. Deferred unless you want it (see questions).

---

## 3. Audio: background playback and streaming sandbox rules on iPadOS

### 3.1 Session strategy

- One `AudioSessionCoordinator` owns `AVAudioSession`. Category **`.playback`** (plays in background, ignores silent mode), mode `.default`.
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
| **YouTube IFrame API in WKWebView** | **No.** WebKit suspends web media when backgrounded, and policy forbids it | YouTube API Terms prohibit separating or isolating audio from video and background play; Required Minimum Functionality requires a **visible** embedded player at least **200 × 200 px** (480 × 270 recommended for 16:9); no overlays obscuring the player. App Review guideline 5.2.3 backs this up | **A headless or hidden WKWebView player is a ToS violation and a rejection risk. I will not build it.** Legitimate option: a visible "Screening Room" glass card (foreground only) for lofi streams, or cut YouTube |

---

## 4. Project configuration (exact)

### 4.1 Identifiers (proposed, change before Phase 2)

| Item | Value |
| --- | --- |
| App bundle ID | `io.cairparavel.app` |
| Live Activity extension | `io.cairparavel.app.ExpeditionActivity` |
| App Group | `group.io.cairparavel.app` |
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
    TARGETED_DEVICE_FAMILY: "2"              # iPad only
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
| `UIBackgroundModes` | `[audio]` | Ambience and MusicKit playback in background |
| `NSAppleMusicUsageDescription` | "Cair Paravel plays your Apple Music during Expeditions." | MusicKit authorization prompt |
| `NSSupportsLiveActivities` | `YES` | Lock Screen Expedition countdown |
| `ITSAppUsesNonExemptEncryption` | `NO` | Only system HTTPS; skips export compliance questions per upload |
| `UILaunchScreen` | `{ UIColorName: LaunchBackground, UIImageName: LaunchMark }` | Plist-based launch screen, no storyboard |
| `UISupportedInterfaceOrientations~ipad` | all four | Landscape and portrait |
| `UIApplicationSceneManifest` | `UIApplicationSupportsMultipleScenes = NO` (v1) | One timer, one window. Revisit for a Chronicles side window |
| `CFBundleURLTypes` | scheme `cairparavel` | Deep links from Live Activity, Shortcuts |
| `LSApplicationQueriesSchemes` | `[spotify]` | Only to detect Spotify for deep-link mode |
| `UIAppFonts` | font file list | Custom editorial typefaces |
| `UIRequiresFullScreen` | **omit** | Deprecated in iPadOS 26. Minimum window size enforced via `UIWindowScene.sizeRestrictions` |

### 4.4 Entitlements (`CairParavel.entitlements`)

```xml
<key>com.apple.security.application-groups</key>
<array><string>group.io.cairparavel.app</string></array>
<key>com.apple.developer.usernotifications.time-sensitive</key>
<true/>
```

The extension's entitlements carry the same App Group. **MusicKit is not an entitlements-file key**: it is enabled as an App Service on the App ID in the developer portal, which also provisions the developer token automatically.

Deferred (add only when the feature lands): `aps-environment` (remote Live Activity pushes), `com.apple.developer.icloud-container-identifiers` + `icloud-services` (Chronicles sync), `com.apple.developer.family-controls` (requires Apple approval for distribution).

### 4.5 Privacy manifest (`PrivacyInfo.xcprivacy`)

- `NSPrivacyTracking = false`, no tracking domains, **no collected data types** (everything stays on device; iCloud private database data is not "collected" by us).
- `NSPrivacyAccessedAPITypes`:
  - `NSPrivacyAccessedAPICategoryUserDefaults` → `CA92.1` (app's own defaults) and `1C8F.1` (App Group shared defaults).
  - `NSPrivacyAccessedAPICategoryFileTimestamp` → `C617.1` only if we read file dates (avoid if possible).
- Any third-party SDK (e.g., Rive) must ship its own privacy manifest.

---

## 5. Signing and TestFlight pipeline

### 5.1 One-time setup (your side)

1. **Apple Developer Program** membership (individual or organization; organization requires a D-U-N-S number and displays the legal entity as seller).
2. **Certificates, Identifiers & Profiles**
   - Register explicit App IDs: `io.cairparavel.app`, `io.cairparavel.app.ExpeditionActivity`.
   - Capabilities on the app ID: App Groups, Time Sensitive Notifications. App Services: **MusicKit**.
   - Register the App Group `group.io.cairparavel.app`; attach it to both IDs.
3. **App Store Connect** → Apps → New App: platform iOS, name, primary language, bundle ID `io.cairparavel.app`, SKU `CAIRPARAVEL001`. App names are globally unique and capped at 30 characters, so reserve early (see IP note in section 6).
4. **iPad**: enable Developer Mode (Settings → Privacy & Security → Developer Mode) for local runs.

### 5.2 Signing model

| Context | Certificate | Profile | Managed by |
| --- | --- | --- | --- |
| Local device runs | Apple Development | Team development profile | Xcode automatic signing (registers your iPad UDID on first run) |
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

Workflow: start condition = push to `main` → Action: Archive (iOS, Release) → Post-action: TestFlight Internal Testing. Build number comes from `$CI_BUILD_NUMBER`.

**Compile gate: GitHub Actions** on every branch push: `xcodegen generate`, then `xcodebuild build -scheme CairParavel -destination 'generic/platform=iOS Simulator'` and `swift test` for `CairCore`. Note: macOS runner minutes bill at a 10x multiplier on private repositories.

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

Every upload needs a strictly increasing `CFBundleVersion` within a marketing version. Export compliance is answered automatically by `ITSAppUsesNonExemptEncryption = NO`. A beta-only debug HUD can be gated on `AppTransaction.shared` reporting the sandbox environment.

---

## 6. Risks and flags

1. **Narnia intellectual property.** "Cair Paravel", "Tumnus", Aslan, and Narnia are owned by The C.S. Lewis Company and remain under copyright and trademark protection. Internal TestFlight is unreviewed and private, so it is fine for building. External TestFlight and the App Store run through review (guideline 5.2, intellectual property), and a rights-holder complaint can pull the app. Recommendation: build with the current names behind a single `Brand` constant, and decide on original names (or a license) before external distribution.
2. **Reference art is mood only.** The uploaded illustrations and videos are third-party copyrighted work and must not ship. Two legitimate sources that match the brief: **public-domain Romantic and Hudson River School oil paintings** (Thomas Cole, the painter behind your QUEST reference, plus Bierstadt and Church) and **Gustave Doré engravings** (your Kraken duotone reference), via CC0 open-access collections such as The Met, the National Gallery of Art, and the Smithsonian. Everything else is original or commissioned.
3. **Font licensing.** Desktop licenses do not cover app embedding. Either OFL families or a paid app/embedding license.
4. **Spotify quota** (section 3.3): plan for deep-link mode.
5. **YouTube** (section 3.3): no headless playback.
6. **No silent-audio keepalive** (section 2.4).

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
| 2 | XcodeGen project, packages, tokens, glass components, responsive iPad shell | Compile gate green; you run it on device |
| 3 | `CairCore` engine + Chronicles persistence + notifications | Engine unit tests (Linux + macOS); reconciliation tests |
| 4 | Atmosphere tiers + Tumnus mood engine and renderer | On-device profiling (Instruments: SwiftUI, Metal System Trace) |
| 5 | Audio coordinator, ambience engine, MusicKit, Spotify deep link | On-device background, interruption, and route tests |
| 6 | Icon (Icon Composer `.icon`), launch screen, release scheme, Xcode Cloud → TestFlight | First internal TestFlight build installed |

---

## 9. Open questions (defaults in bold)

1. **Minimum OS**: **iPadOS 26.0**?
2. **Names / IP**: keep "Cair Paravel" and "Tumnus" **for internal TestFlight only**, with a rename decision before external testing?
3. **Music scope**: **Apple Music (MusicKit) + Spotify deep link + owned ambience**, YouTube **cut** or kept as a visible Screening Room?
4. **Tumnus art**: **procedural aura + placeholder silhouette now**, commissioned illustration or Rive later?
5. **Developer account**: individual or organization, your Team ID, and is `io.cairparavel.app` acceptable as the bundle ID?
6. **CI**: **Xcode Cloud** for TestFlight plus a GitHub Actions compile gate? Is this repository private (macOS runner cost)?
7. **Fonts**: **OFL only** for now, or budget for commercial app licenses?
8. **Chronicles sync**: **local-only v1** with a CloudKit-ready schema?
9. **Screen Time shielding** (Apple-approved entitlement): **out of scope** for v1?
