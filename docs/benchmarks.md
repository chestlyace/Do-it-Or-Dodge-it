# Benchmarks

Numbers from the hidden benchmark screen, recorded on a real phone. Open it by
long-pressing the **Home** title in the app, pick a setting, tap **Run**, then
copy the results with the copy button and paste them here.

Every run uses the same fixed prompt, loads the model fresh (so load time is
measured), and streams the reply. "Tokens" counts streamed chunks, which is
close to the token count.

## Phone

| | |
| --- | --- |
| Model | Samsung Galaxy Note 20 Ultra |
| Chip | (Snapdragon 865+ or Exynos 990) |
| RAM | |
| Android version | |
| App build | debug / release |
| Model file | Gemma 4 E2B / E4B |

## Levers

Try them one at a time and keep everything else the same.

| # | Backend | Speculative decoding | Max output tokens | Backend that ran | Load time (ms) | First token (ms) | Tokens/s | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | GPU, then CPU | off | 128 | | | | | |
| 2 | CPU only | off | 128 | | | | | |
| 3 | GPU, then CPU | on | 128 | | | | | |
| 4 | GPU, then CPU | off | 64 | | | | | |
| 5 | GPU, then CPU | off | 256 | | | | | |

If speculative decoding makes no difference or fails to load, note that here:
the Gemma 4 build may not include it.

## Airplane mode

- [ ] With airplane mode on, the benchmark prompt streams a reply.

## Go / no-go

Is the speed good enough for the Do It and Dodge It flows, or is a cloud
fallback needed? The cloud fallback was left out in Phase 0, so a "no-go" means
revisiting that decision before Phase 9.

- Decision:
- Reason:

## After polish (Phase 8)

Run the same five settings again on the same phone with the Phase 8 build and
record them here next to the Phase 3 numbers above.

| # | Backend | Speculative decoding | Max output tokens | Backend that ran | Load time (ms) | First token (ms) | Tokens/s | Change vs Phase 3 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | GPU, then CPU | off | 128 | | | | | |
| 2 | CPU only | off | 128 | | | | | |
| 3 | GPU, then CPU | on | 128 | | | | | |
| 4 | GPU, then CPU | off | 64 | | | | | |
| 5 | GPU, then CPU | off | 256 | | | | | |

## Second phone (a cheaper one, 4 to 6 GB of RAM if you can borrow one)

| | |
| --- | --- |
| Phone | |
| Chip | |
| RAM | |
| Android version | |

- [ ] Onboarding shows its RAM and storage and recommends the E2B model
- [ ] The model downloads, or onboarding explains why not
- [ ] The model loads, or the app says "This phone could not load the model..."
      (and does not crash)
- [ ] Do It writes steps; the speed is acceptable (record the benchmark below)
- [ ] Dodge It writes an excuse
- [ ] Nudges arrive

| Backend | Load time (ms) | First token (ms) | Tokens/s |
| --- | --- | --- | --- |
| GPU, then CPU | | | |
| CPU only | | | |

## Phase 9 decision

The cloud fallback was left out in Phase 0, so Phase 9 is skipped. If the
second phone cannot run the model usably, note it here and tell me; that would
reopen the decision.
