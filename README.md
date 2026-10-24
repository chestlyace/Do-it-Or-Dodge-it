# Do It or Dodge It

Do It or Dodge It is an Android app, built in Flutter, that runs entirely on the phone: an on-device Gemma model either shrinks a task you are avoiding into tiny steps or writes you a believable excuse, and the app learns which tasks you tend to dodge.

- **Do It**: the task is split into steps so small they are hard to refuse, and local notifications nudge you through them.
- **Dodge It**: you get an excuse to copy or share. The dodge is logged, never hidden.

After a one-time model download, the app works offline and no task data leaves the phone.

## Status

Under construction, built in phases. See [`docs/architecture.md`](docs/architecture.md) for the design and the decisions made so far. Phases 0 to 7 are done: decisions, the project scaffold, the data layer, the on-device Gemma 4 model, the four prompt jobs, the core screens, nudges, and the dodge predictor. You can add a task, see how likely you are to dodge it and why, then Do It (tiny steps, tick them off, draft help, and local notifications about your next step) or Dodge It (an excuse to copy or share), and see the history. The settings screen comes in a later phase.

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

**Nudges:** starting Do It schedules local notifications about the next undone step, paced by risk, never during quiet hours (21:00 to 09:00), and a daily background job plans them again. Long-press the title, then tap the bell icon, to see what is scheduled, turn on a **fast clock** (nudges 1, 2 and 3 minutes from now) and run the daily job by hand.

**Dodge risk:** each task shows a score from 0 to 100% and a one-line reason. For your first 20 outcomes it is a simple rule (how often you dodged that category, else 50%); after that a small model trained on your own history takes over and is retrained after every outcome and every day. It all stays on the phone.

**Prompt lab:** from the benchmark screen, tap the flask icon to run any prompt job with your own input, see the raw and parsed output, and run all four jobs on 20 sample tasks. Results go in [`docs/prompt-samples/`](docs/prompt-samples/README.md).

In debug builds, Home has a **Seed sample tasks** button (the flask icon). Tap a task to open it; long-press to delete it.

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
