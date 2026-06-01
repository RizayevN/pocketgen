# LocalGen

**Unlimited, private, on-device image generation for iOS.** Your prompts and images never leave your iPhone.

LocalGen is a SwiftUI app for iOS 17+. The image-generation pipeline is abstracted behind a single protocol so a real on-device diffusion model (e.g. Apple's [`ml-stable-diffusion`](https://github.com/apple/ml-stable-diffusion) Core ML package) can drop in without any UI changes. Today it ships with a deterministic mock engine so the full app — prompt → progress → result → save/share — runs and is testable without a model download.

## Features

- Compose a prompt and optional negative prompt
- Choose output size (384 / 512 / 768 px) and step count (10–40)
- Optional fixed seed for reproducible results ("generate again")
- Cancellable generation with live progress
- Save to Photos or share the result
- Up-front device-tier banner setting performance expectations for the hardware

## Requirements

- iOS 17.0+
- Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Getting started

The Xcode project is generated from `project.yml` — it is not checked in. Generate it, then open or build:

```sh
xcodegen generate
open LocalGen.xcodeproj
```

Build from the command line (Simulator, no code signing):

```sh
xcodebuild -project LocalGen.xcodeproj -scheme LocalGen \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' \
  -configuration Debug build CODE_SIGNING_ALLOWED=NO
```

> `project.yml` is the source of truth for the project. After adding, removing, or moving files under `LocalGen/`, run `xcodegen generate` again — sources are picked up by directory globbing.

## Architecture

The app is one screen driven by a single view model and an engine behind a protocol.

| Piece | Role |
| --- | --- |
| `GenerationEngine` (protocol) | The seam between UI and pixel production: `generate(_:progress:) async throws -> (UIImage, UInt32)`. Swap in a real Core ML pipeline by conforming to it. |
| `MockGenerationEngine` | Current implementation. Fakes step-by-step diffusion progress, then renders a deterministic prompt+seed-derived abstract image (watermarked `MOCK`). |
| `GenerationViewModel` | `@MainActor` `ObservableObject` owning a `Phase` state machine (`idle → generating → finished \| failed`). Engine is injected, defaulting to the mock. |
| `GenerationRequest` | The unit the engine consumes: prompt, negative prompt, size, steps, optional seed. |
| `DeviceCapability` / `DeviceTier` | Maps the device model identifier to a coarse hardware tier for the expectations banner. |

To wire in a real model, implement `GenerationEngine` and pass it to `GenerationViewModel(engine:)` — no view changes required.

## Privacy

All generation runs on device. Prompts and images are never transmitted off the iPhone.
