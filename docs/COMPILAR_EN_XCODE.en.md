# Clone, build, and install OmniPulse with Xcode

**[Español](COMPILAR_EN_XCODE.md) · English**

A paid Apple Developer membership is not required to test OmniPulse on your own iPhone. Xcode can use a free Apple Account as a **Personal Team**, although the resulting provisioning normally expires after seven days.

## Requirements

- A Mac with Xcode 16 or later.
- iPhone with iOS 17 or later.
- USB for the first trust/development setup.
- An Apple Account added to Xcode.
- Homebrew and XcodeGen.

## Clone and generate

```bash
cd ~/Documents
git clone https://github.com/tiburonns/OmniPulse.git
cd OmniPulse
brew install xcodegen
xcodegen generate --spec project.yml
open OmniPulse.xcodeproj
```

## Bundle identifiers

Replace `com.tiburonns.OmniPulse` in `project.yml` with a bundle identifier owned by your account, then regenerate the project. Persistent project changes belong in `project.yml`, not only in the generated `.xcodeproj`.

## Signing

Enable **Automatically manage signing** and select your Team/Personal Team for `OmniPulse`, `OmniPulseWatch`, and `OmniPulseMac` when applicable.

## Physical device

Trust the Mac, enable Developer Mode if requested, select the physical iPhone, and run with `Command + R`. Bluetooth and sensor communication require physical hardware.

## Updating

```bash
git pull --ff-only
xcodegen generate --spec project.yml
open OmniPulse.xcodeproj
```

If a free Personal Team build stops opening after several days, reconnect the iPhone and rebuild/reinstall from Xcode.
