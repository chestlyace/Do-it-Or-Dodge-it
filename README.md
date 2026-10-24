# Do It or Dodge It

An Android app that runs entirely on your phone. You add a task you are avoiding, then pick one of two buttons:

- **Do It**: an on-device Gemma model breaks the task into steps so small they are hard to refuse (the first takes under two minutes), drafts what it can (an email, an outline), and sends you slow, steady nudges about the next step until it is done.
- **Dodge It**: Gemma writes an excuse you copy or share through the Android share sheet. The dodge is logged, never hidden.

The app learns which tasks you tend to dodge, shows a dodge risk with a one-line reason, and uses it to pace the nudges. It all happens on the phone. After a one-time model download there is no server, no account and no network use, and your tasks never leave the device.

Built for the DEV [Hugging Face challenge](https://dev.to/challenges/hf26) (HF26), Week 3, "Slow and Steady".

<!--
Screenshots: add the images to docs/screenshots/ and uncomment this block.

| Add a task | Do It | Dodge It | Nudge |
| --- | --- | --- | --- |
| ![Home](docs/screenshots/home.png) | ![Do It](docs/screenshots/do-it.png) | ![Dodge It](docs/screenshots/dodge-it.png) | ![Nudge](docs/screenshots/nudge.png) |
-->

## Install

1. Download `app-release.apk` from the [latest release](../../releases/latest) and open it on your phone (allow installs from your browser or file manager when Android asks).
2. Open the app. On first launch it shows your phone's RAM and free storage, recommends a model, and downloads it once.

You need an Android 11 (API 30) or newer phone with a 64-bit ARM processor, 4 GB of RAM or more, and 3 to 5 GB of free storage for the model.

## The model

Do It or Dodge It does not bundle a model. On first launch it downloads one of two **Gemma 4** builds from Hugging Face and checks it against its published SHA-256:

| Model | Download | Recommended for |
| --- | --- | --- |
| Gemma 4 E2B | about 2.6 GB | phones with under 8 GB of RAM |
| Gemma 4 E4B | about 3.7 GB | phones with 8 GB of RAM or more |

The files come from the public [`litert-community`](https://huggingface.co/litert-community) repositories (`gemma-4-E2B-it-litert-lm` and `gemma-4-E4B-it-litert-lm`), pinned to a specific commit. They are released under the **Apache 2.0** licence, need no account or token, and are not part of this repository or the APK. The download can be limited to Wi-Fi, resumes if interrupted, and the model can be deleted in Settings.

## How it works

- **Prompt jobs.** `shrinkTask`, `helpWithStep`, `writeExcuse` and `nudgeWording` each ask Gemma for JSON, validate it (3 to 7 steps, first step under 2 minutes, no health, death, legal or emergency excuses, no repeats of the last 5 excuses for a person), retry once with a stricter instruction, and fall back to showing the raw text. Bad output never crashes the app.
- **Nudges.** Local notifications about the next undone step. A task you usually dodge gets more, closer nudges (2, 4 or 6 a day for low, medium and high risk), never between 21:00 and 09:00 by default. A daily background job plans them again, and they come back after a restart.
- **Dodge predictor.** A small logistic regression written in Dart, trained on your own outcomes. It uses a simple rule for your first 20 outcomes, then takes over and is retrained after every outcome.
- **Ready ahead of time.** While your phone charges, a background job writes nudge text and a general excuse for your open tasks, so Dodge It can show one instantly.
- **Settings.** Quiet hours, nudge limit, Wi-Fi-only download, model info, delete the model, clear your data.

See [`docs/architecture.md`](docs/architecture.md) for the design and every decision, [`docs/benchmarks.md`](docs/benchmarks.md) for speed numbers, and [`docs/prompt-samples/`](docs/prompt-samples/README.md) for how well Gemma follows the JSON formats.

## Build from source

You need Flutter (stable channel) with the Android SDK; `flutter doctor` should be clean.

```bash
flutter pub get
flutter run                 # on a connected Android phone (API 30+, arm64)
flutter analyze
flutter test
```

If you change the database tables in `lib/app/data/db/tables.dart`, regenerate the code with `dart run build_runner build`.

### Release build

Signing keys are never committed. Follow [`docs/RELEASING.md`](docs/RELEASING.md) to create your own key, then:

```bash
scripts/build_release.sh    # analyze, test, build and print the APK's SHA-256
```

The release build targets 64-bit ARM only, because the on-device model engine ships nothing else.

### Developer tools

Long-press the title on Home to open a hidden **benchmark** screen (load time, first token, tokens per second, GPU or CPU). Its top bar links to a **prompt lab** (run any job on your own input or on 20 sample tasks) and a **nudge screen** (the schedule, a fast clock, the daily job, pre-generation, a test notification). In debug builds, Home also has a button that adds sample tasks.

## Privacy

The only network request the app makes is the one-time model download from Hugging Face. Tasks, excuses, outcomes, the predictor's weights and nudges are stored in a local database on the phone. The app asks for the notification permission (for nudges) and nothing else; it never reads your contacts, calendar, microphone or location, and it never sends a message itself.

## Project layout

```
lib/
  main.dart
  app/
    core/        theme, prompts, scoring and planning helpers
    data/        database (drift), models, repositories
    services/    model, predictor, nudges, background jobs, sharing
    modules/     one folder per screen (binding, controller, view)
    routes/
docs/            architecture, benchmarks, release and demo notes, the DEV post
scripts/         release build script
test/            unit, service and screen tests
```

## Challenge notes

- Started on **23 October 2026** (the first commit), inside the Week 3 window.
- Commits made after the challenge deadline: none so far. Any will be listed here.

## Credits

Built with these open-source projects. Their licences are shown in the app under Settings, Open source licences.

- [Flutter](https://flutter.dev) and Dart
- Google's [Gemma 4](https://ai.google.dev/gemma) models and [LiteRT-LM](https://ai.google.dev/edge/litert-lm/overview), through [`flutter_edge_ai`](https://pub.dev/packages/flutter_edge_ai) and `flutter_edge_ai_litertlm` by Anton Denisov
- [GetX](https://pub.dev/packages/get) for state, routing and dependency injection
- [drift](https://pub.dev/packages/drift) and `drift_flutter` for the on-device SQLite database
- [`path_provider`](https://pub.dev/packages/path_provider) for file locations
- [`share_plus`](https://pub.dev/packages/share_plus) for the Android share sheet
- [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications) and [`timezone`](https://pub.dev/packages/timezone) for nudges
- [`workmanager`](https://pub.dev/packages/workmanager) for the daily and charging-time background jobs
- [`crypto`](https://pub.dev/packages/crypto) to verify the model download
- [`cupertino_icons`](https://pub.dev/packages/cupertino_icons), `build_runner`, `drift_dev` and `flutter_lints` for development

## Licence

The code in this repository is released under the [MIT licence](LICENSE). The Gemma 4 model files are downloaded separately and are covered by their own Apache 2.0 licence.
