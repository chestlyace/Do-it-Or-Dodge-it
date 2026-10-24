# Do It or Dodge It

Do It or Dodge It is an Android app, built in Flutter, that runs entirely on the phone: an on-device Gemma model either shrinks a task you are avoiding into tiny steps or writes you a believable excuse, and the app learns which tasks you tend to dodge.

- **Do It**: the task is split into steps so small they are hard to refuse, and local notifications nudge you through them.
- **Dodge It**: you get an excuse to copy or share. The dodge is logged, never hidden.

After a one-time model download, the app works offline and no task data leaves the phone.

## Status

Under construction, built in phases. See [`docs/architecture.md`](docs/architecture.md) for the design and the decisions made so far. Phases 0 to 3 are done: decisions, the project scaffold, the data layer, and the on-device Gemma 4 model (first-launch download, loading, and a benchmark screen). The task screens are still placeholders.

## Requirements

- Flutter (stable channel) and the Android SDK; `flutter doctor` should be clean
- An arm64 Android 11 (API 30) or newer phone with USB debugging enabled
- 4 GB of RAM or more for on-device Gemma, and 3 to 5 GB of free storage for the model

## Run

```bash
flutter pub get
flutter devices      # your phone should be listed
flutter run
```

## Generated code

The drift database code (`app_database.g.dart`) is committed. After changing `lib/app/data/db/tables.dart`, regenerate it:

```bash
dart run build_runner build
```

## The model

On first launch the app offers Gemma 4 E2B (about 2.6 GB) or E4B (about 3.7 GB), recommending E4B only on phones with 8 GB of RAM or more. It downloads from public Hugging Face repos, so no account or token is needed. The download resumes if it is interrupted, runs in a foreground service, can be limited to Wi-Fi, and is checked against its SHA-256. After that the app works offline.

**Benchmark:** long-press the **Home** title to open the hidden benchmark screen. Record the numbers in [`docs/benchmarks.md`](docs/benchmarks.md).

In debug builds, the Home placeholder has a **Seed sample tasks** button. Tap a task to move it open, doing, done; long-press to delete it.

## Check

```bash
flutter analyze
flutter test
```

## Project layout

```
lib/
  main.dart                  # GetMaterialApp
  app/
    initial_binding.dart     # registers the permanent services
    routes/                  # route names and GetPage list
    core/                    # theme, prompts, utils
    data/                    # db, models, repositories
    services/                # GetxService classes
    modules/                 # one folder per screen: bindings, controllers, views
```
