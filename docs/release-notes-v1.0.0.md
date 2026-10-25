# Do It or Dodge It 1.0.0

An Android app that runs entirely on your phone. Add a task you are avoiding,
then pick **Do It** (an on-device Gemma model breaks it into tiny steps and
nudges you through them) or **Dodge It** (Gemma writes an excuse to copy or
share). It learns which tasks you tend to dodge and paces the nudges to match.

## Install

1. Download `app-release.apk` below and open it on your phone.
2. Open the app: on first launch it downloads the Gemma 4 model once
   (about 2.6 GB for E2B, 3.7 GB for E4B) from Hugging Face. After that it works
   offline.

Needs Android 11 or newer, a 64-bit ARM phone, 4 GB of RAM or more, and 3 to
5 GB of free storage.

## Checksum

`app-release.apk` SHA-256: `[[paste the output of scripts/build_release.sh]]`

## Notes

- The model is not part of the APK. It is downloaded from the public
  `litert-community` Hugging Face repositories under the Apache 2.0 licence.
- Everything stays on your phone. The only network request is the model
  download.
- Source and design notes: see the repository README and `docs/architecture.md`.
