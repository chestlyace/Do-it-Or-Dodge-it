#!/usr/bin/env bash
# Builds the signed release APK and prints its checksum.
# Needs android/key.properties (see docs/RELEASING.md) and a clean checkout.
set -euo pipefail

cd "$(dirname "$0")/.."

if [ ! -f android/key.properties ]; then
  echo "android/key.properties is missing, so the APK would be signed with the" >&2
  echo "debug key. Create the release key first: see docs/RELEASING.md." >&2
  exit 1
fi

flutter pub get
flutter analyze
flutter test

# The on-device model engine only ships for 64-bit ARM phones, so build for
# that one target. A plain `flutter build apk --release` also tries 32-bit ARM
# and x86 and fails.
flutter build apk --release --target-platform android-arm64

APK=build/app/outputs/flutter-apk/app-release.apk
echo
echo "Built $APK"
sha256sum "$APK"
ls -lh "$APK"
