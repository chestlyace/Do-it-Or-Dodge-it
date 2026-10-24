# Do It or Dodge It — Architecture

Oct 23, 2026 · @Preshu

## Overview

Do It or Dodge It is an Android app, built in Flutter, that runs entirely on the phone: an on-device Gemma model either shrinks a task you are avoiding into tiny steps or writes you a believable excuse, and the app learns which tasks you tend to dodge.

The user adds a task and picks one of two buttons:

- **Do It** — Gemma breaks the task into steps so small they are hard to refuse, drafts what it can (an email, an outline), and the app nudges the user slowly and steadily until it is done.
- **Dodge It** — Gemma writes an excuse the user copies or shares through the Android share sheet. The dodge is logged, never hidden.

Goals for v1:

1. Work fully offline after a one-time model download; no task data leaves the phone.
2. Make the first step of any task feel trivial to start.
3. Predict dodge risk from the user's own history and use it to pace nudges.

## Decisions confirmed by Preshu

Every row below was chosen explicitly; anything not listed here is marked "proposed" in this doc and answered in the Decisions (Phase 0) section.

| Topic | Decision | Consequence |
| --- | --- | --- |
| Where it runs | 100% on the phone (path A) | No server, no laptop companion |
| Platform | Android only, Flutter | iOS is out of v1 |
| AI model | Gemma, on-device | Gemma 4, E2B and E4B (see Decisions) |
| Model delivery | Downloaded on first launch | Internet needed once; small install size |
| Dodge prediction | On-device predictor | TabPFN is not used |
| State management | GetX | Routing, DI and state all through GetX |
| Excuse output | Copy to clipboard or Android share sheet | The app never sends messages itself |
| Partner tools | Mastra, Temporal and TabPFN dropped | They need a server or Python runtime; path A has neither |
| Deadline | Not a constraint | Scope is set by quality, not the challenge window |

## Scope for v1

v1 is a single-user Android app with task capture, the two buttons, local nudges and an on-device dodge predictor; everything that needs a server or another platform waits.

**In v1**

- First-launch model download with progress, resume and a storage check
- Add a task (title, optional due date, optional note)
- Do It: Gemma splits the task into tiny steps; user ticks them off
- Do It helper: Gemma drafts text for a step when asked (email, message, outline)
- Dodge It: Gemma writes an excuse; copy or share sheet
- Log every outcome as done, dodged or abandoned
- On-device dodge-risk score per task
- Local notifications paced by dodge risk
- History screen: what you did, what you dodged

**Out of v1**

- iOS
- Sending messages directly from the app
- Accounts, sync, cloud backup
- Calendar or contacts integration
- Voice input
- Any server, including Mastra, Temporal and TabPFN

## Core user flows

Every task is scored, then either shrunk into steps or excused, and every outcome is logged to retrain the dodge predictor.

&#91;embedded content: core flow · 2 branches, 1 learning loop\]

Do It keeps nudging on the next undone step until the task is done; Dodge It ends as soon as the excuse is copied or shared. A Do It task left untouched past its due date is logged as abandoned.

## System architecture

The app has four layers, all inside the phone: GetX screens call services, services use repositories and plugins, and only the first-launch model download touches the network.

&#91;embedded content: system architecture · 4 layers on the phone, 1 external download\]

Screens hold no logic beyond UI state. The Gemma service is the only code that touches the model, and the Background service wakes once a day to re-plan nudges and retrain the predictor.

## Tech stack

The stack is Flutter + GetX on Android, with Gemma running through the `flutter_edge_ai` plugin and everything else stored and scheduled on the device.

| Layer | Choice | Status | Why |
| --- | --- | --- | --- |
| App framework | Flutter (Dart), Android target | Confirmed | Your choice |
| State, routing, DI | `get` (GetX) | Confirmed | Your choice |
| On-device LLM | [`flutter_edge_ai`](https://pub.dev/packages/flutter_edge_ai) core + `flutter_edge_ai_litertlm` engine | Confirmed | Successor to `flutter_gemma`, which is discontinued (1.11.4 was its last release). Runs Gemma 4 `.litertlm` files on the GPU with a CPU fallback |
| Model | Gemma 4 E2B and E4B (`.litertlm`), chosen per device | Confirmed | See Decisions |
| Model download | `flutter_edge_ai` built-in installer (foreground service for large files) | Confirmed | Resumes interrupted downloads and handles downloads over 500 MB without the Android timeout |
| Local database | `drift` (SQLite) | Confirmed | Typed queries, generated classes, built-in migrations |
| Dodge predictor | Logistic regression written in pure Dart | Proposed | Tiny, fast, trains on the phone, explainable |
| Notifications | `flutter_local_notifications` | Proposed | Scheduled local notifications, no internet |
| Background jobs | `workmanager` | Proposed | Daily re-plan of nudges and predictor retrain |
| Sharing excuses | `share_plus` + `Clipboard` (Flutter services) | Proposed | Android share sheet and copy |
| File paths | `path_provider` | Proposed | Locate model file and DB |
| RAM, free storage, connection type | Small Kotlin method channel (`ConnectivityManager`, `StatFs`, `ActivityManager`) | Confirmed | No extra Dart packages |
| Download check | `crypto` (SHA-256) | Added in Phase 3 | Verifies the downloaded file against its published checksum |

No backend, no cloud services and no API keys are part of the running app.

## On-device AI: Gemma

One `GemmaService` owns the model: it downloads it once, loads it on demand, and exposes four prompt jobs that all return validated JSON.

**Model lifecycle**

1. First launch: onboarding screen checks free storage, then downloads the `.litertlm` file with progress and resume.
2. File is saved in app storage; a checksum and version are stored in settings.
3. The model loads when the user first taps Do It or Dodge It, not at app start, to keep startup fast.
4. The model is released when the app goes to the background, to free RAM.
5. If loading on GPU fails, retry on CPU.

**Prompt jobs**

| Job | Input | Output (JSON) |
| --- | --- | --- |
| `shrinkTask` | Task title, note, due date | 3 to 7 steps, each with a title and an estimated minutes value; step 1 must take under 2 minutes |
| `helpWithStep` | Task, the chosen step | A draft (email, message, outline) the user can copy |
| `writeExcuse` | Task, who it is for, tone, excuses already used for that person | One excuse, plus a shorter variant |
| `nudgeWording` | Task, the next step | Gentle, firm and last-call notification text, each one sentence of at most 100 characters |

**Rules for every job**

- System instruction fixes the job and the JSON shape.
- Responses stream to the UI; JSON is parsed when the stream ends.
- Invalid JSON, or JSON that breaks a rule (wrong number of steps, first step 2 minutes or more, empty field) → one automatic retry with a stricter instruction, then the raw text is returned as a fallback. Bad model output never throws.
- Every job caps its output length: `shrinkTask` 400 tokens, `helpWithStep` 450, `writeExcuse` 220, `nudgeWording` 160.
- `writeExcuse` also rejects, and retries, a reply that mentions health, death, legal trouble or an emergency, or that repeats one of the last 5 excuses for that person.
- Prompts stay short; history passed to `writeExcuse` is capped at the last 5 excuses for that person.
- The user can stop generation at any time.

The model's licence terms apply to the downloaded file; the file is downloaded directly from Hugging Face (see Decisions).

## Dodge predictor

A proposed logistic-regression model, written in Dart and trained on the phone, scores each task with a dodge risk from 0 to 1; that score sets how often and how firmly the app nudges.

**Label:** an outcome row is `dodged` (1) or `done` (0). `abandoned` counts as dodged.

**Proposed features** (all computed from local data):

| Feature | Type |
| --- | --- |
| Category of the task | One-hot |
| Days until due (none = large value) | Number |
| Number of steps Gemma produced | Number |
| Total estimated minutes | Number |
| Hour of day and day of week when created | Cyclic (sin/cos) |
| User's past dodge rate for this category | Number |
| User's dodge rate over the last 14 days | Number |

**Training and use**

1. Retrain after each new outcome and in the daily background job; training on a few hundred rows takes milliseconds.
2. Until there are enough outcomes, use a simple rule instead of the model (20 outcomes; see Decisions).
3. Show the top reason next to the score, e.g. "You dodge admin tasks 70% of the time", using the largest weighted feature.
4. Weights are stored in the database so the model survives restarts.

Task categories come from a fixed list the user picks from; the list itself is settled in Phase 2, with an "Other" option that takes free text.

## Data model

Six SQLite tables on the phone hold everything; `tasks` is the hub and every other table except `settings` points back to it.

| Table | Key columns | Purpose |
| --- | --- | --- |
| `tasks` | `id`, `title`, `note`, `category`, `due_at`, `created_at`, `status` (open, doing, done, dodged, abandoned), `dodge_risk` | One row per task |
| `steps` | `id`, `task_id`, `position`, `title`, `est_minutes`, `done_at`, `draft_text` | Gemma's tiny steps and any drafts |
| `outcomes` | `id`, `task_id`, `result` (done, dodged, abandoned), `at`, feature snapshot (JSON) | Training rows for the predictor |
| `excuses` | `id`, `task_id`, `recipient_label`, `tone`, `text`, `created_at`, `shared` | Stops the same excuse being reused on the same person |
| `nudges` | `id`, `task_id`, `fire_at`, `level` (gentle, firm, last call), message, `notification_id`, `fired`, `opened` | What is scheduled and what worked |
| `settings` | `key`, `value` | Model file path, checksum, model version, predictor weights, quiet hours |

`recipient_label` is free text the user types (e.g. "boss"); no contacts are read. The feature snapshot in `outcomes` is saved at decision time so retraining uses what the app knew then.

## Nudge engine

`NudgeService` turns each Do It task's dodge risk into a schedule of local notifications, and re-plans once a day so nudges keep coming even if the app is never opened.

**How a schedule is built (proposed)**

1. When the user taps Do It, the service reads the task's dodge risk and due date.
2. Higher risk means more nudges, closer together, with firmer wording (gentle → firm → last call).
3. Each nudge names only the next undone step, never the whole task.
4. Quiet hours from settings are skipped.
5. Ticking a step cancels pending nudges for that task and plans new ones for the next step.

**Keeping it alive without a server**

- Notifications are scheduled with `flutter_local_notifications` and re-registered after a reboot.
- A daily `workmanager` job re-plans every open task and retrains the predictor.
- Inexact alarms are used, so the app does not need the Android exact-alarm permission.
- Whether a nudge was opened is recorded in `nudges` for later tuning.

The maximum is 6 nudges per day with quiet hours 21:00 to 09:00; the spacing per risk level is settled in Phase 6; wording for each level is generated once by Gemma per task and stored, so firing a notification never needs the model.

## Flutter project structure (GetX)

The app follows the GetX module pattern: each screen is a module with its own binding, controller and view, and shared logic lives in services registered once at startup.

```
lib/
  main.dart                      # GetMaterialApp, initial bindings
  app/
    routes/
      app_pages.dart             # GetPage list
      app_routes.dart            # route names
    core/
      theme/
      prompts/                   # shrink, help, excuse, nudge-wording prompts
      utils/
    data/
      db/                        # SQLite schema + migrations
      models/                    # Task, Step, Outcome, Excuse, Nudge
      repositories/              # TaskRepository, OutcomeRepository, ...
    services/                    # GetxService, permanent
      gemma_service.dart         # download, load, prompt jobs
      predictor_service.dart     # features, training, scoring
      nudge_service.dart         # scheduling, re-planning
      share_service.dart         # copy + share sheet
      background_service.dart    # workmanager daily job
    modules/
      onboarding/                # model download screen
      home/                      # task list + add task
      task_detail/               # Do It / Dodge It buttons, risk score
      do_it/                     # steps, tick off, draft helper
      dodge_it/                  # recipient, tone, excuse, share
      history/                   # done vs dodged
      settings/                  # quiet hours, model info
      (each module: bindings/, controllers/, views/)
```

Controllers never call `flutter_edge_ai` or the database directly; they go through services and repositories, so the model or the DB package can be swapped later.

## Privacy, permissions and device requirements

The only network call the app ever makes is the one-time model download; tasks, excuses, outcomes and predictor weights never leave the phone.

**Android permissions (proposed)**

| Permission | Why |
| --- | --- |
| `INTERNET` | Model download only |
| `ACCESS_NETWORK_STATE` | Wi-Fi-only download check |
| `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_DATA_SYNC` | Keep the large download running |
| `WAKE_LOCK` | Keep the download alive while the screen is off |
| `POST_NOTIFICATIONS` | Nudges, Android 13 and later |
| `RECEIVE_BOOT_COMPLETED` | Re-register nudges after a restart |

No contacts, calendar, microphone, location or exact-alarm permission is requested.

**Device requirements**

- Free storage: enough for the model file plus headroom; the exact figure depends on the model chosen (Decisions).
- RAM: an on-device Gemma 3n E2B build lists 4 GB of RAM as the recommended minimum ([agent-gemma model card](https://huggingface.co/kontextdev/agent-gemma/blob/main/README.md)); the final floor should be set after testing on a real low-end phone.
- Minimum Android version: Android 11 (API 30), because LiteRT-LM needs it. Minimum RAM: 4 GB. Only `arm64-v8a` phones are supported.

## Risks and mitigations

The biggest risks are phone hardware and the multi-gigabyte download; the rest are about keeping Gemma's output usable.

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Phone has too little RAM to load the model | App unusable on low-end phones | Check RAM at onboarding; offer the smaller model; CPU fallback |
| Download fails or is too large for mobile data | User never gets past onboarding | Resume support, Wi-Fi-only toggle, size shown before starting |
| Gemma returns broken JSON | Steps or excuse missing | Strict system instruction, one retry, raw-text fallback |
| Slow generation | User loses interest | Stream tokens; short prompts; load model only when needed |
| Predictor has too little data early on | Bad risk scores | Rule-based fallback until enough outcomes |
| Android kills background work | Nudges stop | Scheduled notifications plus daily re-plan; reboot receiver |
| Excuses read as dishonest or harmful | Reputation, misuse | Keep excuses light and low-stakes by default; app never sends them itself |
| `flutter_edge_ai` API changes | Build breaks | Pin the version; wrap it in `GemmaService` and `ModelRuntime` |

## Decisions (Phase 0)

The open decisions were answered in Phase 0; the "proposed" items in this doc stand unless a row below changes them.

| Topic | Decision | Consequence |
| --- | --- | --- |
| Gemma family and variants | Gemma 4, E2B and E4B | Onboarding offers both and recommends one from the phone's RAM and free storage; the user can override |
| Model hosting | Hugging Face direct | The Gemma 4 `litert-community` repos are public (Apache 2.0), so no token is needed and none ships in the app. Files are pinned to a commit and checked against their SHA-256: E2B 2,588,147,712 bytes, E4B 3,659,530,240 bytes |
| Database package | `drift` | Typed queries, generated classes, built-in migrations |
| Predictor cold start | 20 outcomes; below that, the user's dodge rate for the task's category, or 0.5 if the category has no history | The logistic-regression model replaces the rule at 20 outcomes |
| Task categories | Fixed list plus "Other" with free text | The free text is stored with the task; the predictor treats it as "Other". The list is set in Phase 2 |
| Nudge limits | Max 6 per day; quiet hours 21:00 to 09:00 | Spacing per risk level is not yet decided and is settled in Phase 6 |
| Excuse tones | Polite, Casual, Funny, Formal | |
| Excuse off-limits | No health, death, legal or emergency excuses | Enforced in the `writeExcuse` prompt and checked again in code with a keyword list (Phase 4) |
| Languages | English only | |
| Minimum Android version | Android 11 (API 30) | Changed in Phase 3 from API 29: `.litertlm` models need API 30. `minSdk` is 30 |
| Minimum RAM | 4 GB | Onboarding warns below this |
| Model recommendation | E4B at 8 GB of RAM or more, otherwise E2B | The user can override. Free storage needed is the file size plus 1 GB. Thresholds are revisited after benchmarking |
| Inference package | `flutter_edge_ai` + `flutter_edge_ai_litertlm` | Changed in Phase 3: `flutter_gemma` and its LiteRT-LM engine are discontinued |
| Project location | Flutter app at the repository root | Phase 1 runs `flutter create .` in the repo, not in a subfolder |
| Wi-Fi-only download | On by default | User can switch it off |
| App name | Do It or Dodge It | Unchanged |
| Cloud fallback | Left out | Phase 9 is skipped; the app stays 100% on the phone |
| Proposed components | Accepted as proposed: Dart logistic regression, `workmanager`, `flutter_local_notifications`, `share_plus` | |

**Still open, settled in the phase that needs it**

- [ ] Fixed category list (Phase 2)
- [ ] Nudge spacing per risk level (Phase 6)
- [ ] Go or no-go on speed after benchmarking the Note 20 Ultra (Phase 3)

## Hackathon fit

The app fits the HF26 prompt directly (open-weight model, local inference) and qualifies for Best Use of Gemma; dropping the server also drops the TabPFN, Temporal and Mastra categories.

- **Prompt:** Gemma runs on the phone with no server, which is the core of the "why open matters" story.
- **Category:** Best Use of Gemma (featured, $200 in the weekend challenge's prize list).
- **Theme:** "Slow and Steady" was the Week 3 theme; future themes are revealed at launch, so the write-up angle is set once you pick a challenge.
- **Write-up angles:** your procrastination data never leaves the phone; works offline; costs nothing to run; the model can be swapped.
- **Judging:** writing quality is weighted most, so plan the DEV post alongside the build.

## Sources

- [HF26 DEV Challenge Hub](https://dev.to/challenges/hf26)
- [flutter\_edge\_ai on pub.dev](https://pub.dev/packages/flutter_edge_ai)
- [LiteRT-LM overview, Google AI Edge](https://ai.google.dev/edge/litert-lm/overview)
- [agent-gemma model card (Gemma 3n E2B, LiteRT-LM)](https://huggingface.co/kontextdev/agent-gemma/blob/main/README.md)
