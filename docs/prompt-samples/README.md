# Prompt samples

Results of running the four prompt jobs on the 20 sample tasks
(`lib/app/core/prompts/sample_tasks.dart`) on the phone. They are useful for the
DEV post and for tuning the prompts.

## How to produce them

1. Open the app, long-press the **Home** title (benchmark), then tap the flask
   icon to open the **Prompt lab**.
2. Tap **Run all four jobs**. It runs `shrinkTask`, `helpWithStep`,
   `writeExcuse` and `nudgeWording` on all 20 tasks (80 model calls) and shows
   the pass rate for each job.
3. Tap **Copy report (JSON)** and paste it into
   `docs/prompt-samples/<phone>-<date>.json`.
4. Record the pass rates in the table below.

The report lists, for every task: whether the reply parsed, whether it needed a
retry, the reason when it did not, the parsed object, and the raw model text.

## Pass rates

| Date | Phone | Model | shrinkTask | helpWithStep | writeExcuse | nudgeWording |
| --- | --- | --- | --- | --- | --- | --- |
| | | | /20 | /20 | /20 | /20 |

## Other checks to record

- [ ] Excuses for one recipient do not repeat across 5 runs (Prompt lab →
      `writeExcuse`, same recipient, tap **Run** 5 times).
- [ ] Stopping a job mid-stream works (**Stop** during a run).
- [ ] A broken reply shows the fallback text and does not crash the app.
