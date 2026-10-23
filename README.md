# Do It or Dodge It

Do It or Dodge It is an Android app, built in Flutter, that runs entirely on the phone: an on-device Gemma model either shrinks a task you are avoiding into tiny steps or writes you a believable excuse, and the app learns which tasks you tend to dodge.

- **Do It**: the task is split into steps so small they are hard to refuse, and local notifications nudge you through them.
- **Dodge It**: you get an excuse to copy or share. The dodge is logged, never hidden.

After a one-time model download, the app works offline and no task data leaves the phone.

## Status

Under construction, built in phases. See [`docs/architecture.md`](docs/architecture.md) for the design and the decisions made so far. Phases 0 to 2 are done: decisions, the project scaffold, and the data layer (six SQLite tables via drift, with repositories and tests). The screens are still placeholders.

## Requirements

- Flutter (stable channel) and the Android SDK; `flutter doctor` should be clean
- An Android 10 (API 29) or newer phone with USB debugging enabled
- 4 GB of RAM or more for on-device Gemma (used from Phase 3)

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
