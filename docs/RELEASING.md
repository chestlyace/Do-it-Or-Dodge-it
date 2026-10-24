# Releasing

How to build, check and publish the signed APK. The steps that need your phone,
your signing key or your GitHub account are marked.

## 1. Create a signing key (once, on your computer)

The key proves every update comes from you. Keep it safe and **back it up**: if
you lose it, new versions will not install over old ones.

```bash
keytool -genkeypair -v \
  -keystore android/doitordodgeit-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias doitordodgeit
```

Then copy `android/key.properties.example` to `android/key.properties` and fill
in the two passwords. Both files are in `.gitignore`; never commit or share
them.

## 2. Build

```bash
scripts/build_release.sh
```

It analyses, runs the tests, builds `build/app/outputs/flutter-apk/app-release.apk`
for 64-bit ARM, and prints the file's SHA-256. It refuses to run without
`android/key.properties`, so you cannot publish a debug-signed APK by accident.

Check the signature is yours and not the debug key:

```bash
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
```

(`apksigner` is in the Android SDK's `build-tools` folder.) The certificate must
show your key, not `CN=Android Debug`.

## 3. Try it on a clean phone

Use a phone that never had the debug build (or uninstall it first: a debug and a
release build are signed differently and cannot replace each other).

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

Run the whole flow once, and tick each box:

- [ ] The app is called **Do It or Dodge It** and has the check-mark icon
- [ ] Onboarding shows the phone's RAM and storage and recommends a model
- [ ] The model downloads (kill the app mid-download and reopen it: it resumes)
- [ ] Add a task, tap **Do It**: steps stream in, the first takes under 2 minutes
- [ ] Allow notifications; turn on the fast clock (long-press the Home title, bell
      icon) and a nudge arrives with the app closed, showing a white check-mark
      icon in the status bar
- [ ] Tap the nudge: the right task opens
- [ ] Tick every step: the task is done and History shows it
- [ ] Add another task, tap **Dodge It**, write an excuse, share it to WhatsApp:
      the task shows as dodged
- [ ] Turn on airplane mode and do both paths again
- [ ] Settings: change quiet hours, the nudge limit, open the licences page
- [ ] Restart the phone: scheduled nudges still arrive

## 4. Publish the GitHub Release

1. Make sure `main` has everything and `pubspec.yaml` says `version: 1.0.0+1`.
2. Tag and publish, attaching the APK:

   ```bash
   git tag v1.0.0 && git push origin v1.0.0
   gh release create v1.0.0 build/app/outputs/flutter-apk/app-release.apk \
     --title "Do It or Dodge It 1.0.0" \
     --notes-file docs/release-notes-v1.0.0.md
   ```

   Or use the Releases page on GitHub and drag the APK in.
3. Put the SHA-256 from step 2 into the release notes first.

## 5. Finish

- [ ] Add screenshots to `docs/screenshots/` and uncomment the block in `README.md`
- [ ] Fill in `docs/benchmarks.md` and `docs/prompt-samples/README.md`
- [ ] Record the demo (`docs/demo-script.md`) and upload it
- [ ] Publish the DEV post (`docs/dev-post.md`)
- [ ] If any commit lands after the challenge deadline, list it under
      "Challenge notes" in `README.md` (an HF26 rule)
