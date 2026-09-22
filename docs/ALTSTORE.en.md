# Install OmniPulse with AltStore or Sideloadly

**[Español](ALTSTORE.md) · English**

Download `OmniPulse-AltStore-v1.2.0.ipa` from the [1.2.0 release](https://github.com/tiburonns/OmniPulse/releases/tag/v1.2.0), or add:

```text
https://raw.githubusercontent.com/tiburonns/OmniPulse/main/source.json
```

The IPA contains no Apple ID, Team ID, certificate, or provisioning profile. AltStore/Sideloadly signs it locally with the installer's account.

## Why the 1.0 IPA crashed AltStore

The original IPA included the Apple Watch companion and its `arm64_32` executable. AltStore 2.2.1's signer did not recognize that architecture and crashed in `ldid::Allocate` before installation. Since 1.0.1, the sideloading IPA excludes only `Payload/OmniPulse.app/Watch`. The Watch target remains in Xcode/TestFlight/App Store builds.

## AltStore

1. Remove old 1.0 IPA downloads.
2. Add the source above and install OmniPulse 1.2.0, or open the downloaded IPA with AltStore.
3. Keep AltServer reachable over the same network or USB while signing/installing.
4. Free Apple accounts must renew signing before the seven-day provisioning period expires.

## Sideloadly

1. Connect and trust the iPhone.
2. Select `OmniPulse-AltStore-v1.2.0.ipa`.
3. Select the device/account and complete Apple's verification prompts.

## Build the compatible IPA

```sh
brew install xcodegen
./script/build_altstore_ipa.sh
```

The script builds unsigned Release, validates version/package contents, excludes the Watch bundle, and verifies that signing material is absent. For the complete iPhone + Watch app, build the `OmniPulse` scheme with your own development team.
