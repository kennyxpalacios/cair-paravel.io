# Cair Paravel

A high-aesthetic, ADHD-friendly Pomodoro timer for iPhone and iPad. Focus intervals are Expeditions into the wild, rest periods are Tea Time, and an ethereal faun companion, Tumnus, keeps you company.

Native Swift 6 / SwiftUI, one universal app for iOS 26+ and iPadOS 26+, distributed through TestFlight.

## Getting started

Requirements: a Mac with Xcode 26 or later (see `docs/01-architecture-stack-testflight.md`, section 5.5).

```sh
git clone https://github.com/kennyxpalacios/cair-paravel.io.git
cd cair-paravel.io
./scripts/bootstrap.sh   # installs XcodeGen if needed, generates the project, opens Xcode
```

Pick an iPhone or iPad simulator and press Run. To run on your own device, put your Team ID in `Config/Signing.local.xcconfig` (created by the script, never committed) and run the script again.

The Xcode project is generated from `project.yml`. After every pull, run `./scripts/bootstrap.sh` (or `xcodegen generate`).

## Phases

| Phase | Scope | Status |
| --- | --- | --- |
| 1 | [Architecture, stack & TestFlight pipeline](docs/01-architecture-stack-testflight.md) | Approved |
| 2 | [Design tokens & layout scaffolding](docs/02-design-system.md) | Built, awaiting review |
| 3 | Core timer engine & state management | Not started |
| 4 | Ambient atmosphere, lighting & Tumnus agent states | Not started |
| 5 | Media hub & audio integration | Not started |
| 6 | TestFlight build & verification | Not started |

Character art: [Tumnus art brief](docs/tumnus-art-brief.md)
