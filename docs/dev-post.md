<!--
DRAFT for you to edit. It is written in your voice ("I"), so change anything
that is not true to you.

Everything in [[double brackets]] needs a real value from you: the demo link, the
benchmark and pass-rate numbers (from docs/benchmarks.md and
docs/prompt-samples/README.md), and your phone's name. Nothing in [[ ]] has been
measured yet, so do not publish with any left in.

The challenge page has no required template. Its only tag I could confirm is
#hf26challenge; check the page for any others before publishing.
Prize category to enter: Best Use of Gemma. DigitalOcean and Render are not used
(the cloud fallback was left out), so do not enter those.
-->

---
title: Do It or Dodge It: a Gemma on my phone either shrinks the task or writes the excuse
published: false
tags: hf26challenge, gemma, android, flutter
cover_image:
---

You know the task. The email you have been meaning to send, the form with one box you can't fill in, the thing that has sat at the top of your list for two weeks. It is not hard. It is just *big enough to avoid*.

**Do It or Dodge It** is an Android app with exactly one idea: when you add a task you are avoiding, you get two honest buttons.

- **Do It** and a Gemma model running on your phone breaks the task into steps so small they are hard to refuse. The first one always takes under two minutes. It drafts the email or the outline if you want, and then nudges you, slowly and steadily, about only the next step.
- **Dodge It** and Gemma writes you an excuse. You copy it or send it through the Android share sheet. The dodge is logged, not hidden.

Either way the app notices. It learns which kinds of tasks *you* tend to dodge, shows you a risk score with a one-line reason ("You dodge admin tasks 70% of the time"), and uses that score to pace the nudges: a task you usually dodge gets more of them, closer together.

All of it runs on the phone. After a one-time model download there is no server, no account and no network use.

## Demo

[[Embed or link the 1 to 2 minute demo video here: add a task, Do It with a nudge, Dodge It with a shared excuse, airplane mode visible in the status bar.]]

Code: [github.com/chestlyace/Do-it-Or-Dodge-it](https://github.com/chestlyace/Do-it-Or-Dodge-it). The APK is on the [releases page](https://github.com/chestlyace/Do-it-Or-Dodge-it/releases).

## Who it is for

Anyone who has ever stared at a to-do item and done something else instead. I built it for the person who wants a nudge but not a lecture, and who would rather not hand a list of everything they are putting off to someone else's server.

## Why open models matter here

This is the part the app could not exist without.

**It works offline.** A procrastination app is most useful at the exact moments you have no patience for a spinner or a signal. The model is on the phone, so airplane mode changes nothing. The demo is recorded in it.

**Your data stays yours.** What you are avoiding is some of the most personal data there is: the awkward email, the money form, the call you dread. Here it never leaves the device. The only network request the app ever makes is downloading the model. I think that is only possible because the weights are open: I can download them once and run them myself.

**It costs nothing to run.** No API key, no per-token bill, no server to keep alive. The Gemma 4 files come from Hugging Face's public `litert-community` repositories under the Apache 2.0 licence. They need no account or token, so there is nothing secret to ship in the APK.

**The model can be swapped.** The app offers Gemma 4 E2B (about 2.6 GB) for most phones and E4B (about 3.7 GB) for phones with 8 GB of RAM or more, and picks a recommendation from the phone's memory. All model code sits behind one small interface, so a better model later is a small change, not a rewrite.

## How it works

The interesting engineering is in making a small on-device model *reliable*.

Each job asks Gemma for JSON in a fixed shape, and I validate the reply in code rather than trusting it: three to seven steps, the first under two minutes, no empty fields, an excuse that is not about health, death, legal trouble or an emergency, and not a repeat of one of the last five I wrote for the same person. If a reply fails, the app retries once with a stricter instruction that says exactly what was wrong. If it fails again, it shows the model's raw text and the reason. It never crashes, and it never pretends. [[On my 20 sample tasks the four jobs parsed: shrinkTask __/20, helpWithStep __/20, writeExcuse __/20, nudgeWording __/20, on the first try or after one retry.]]

The nudges are plain local notifications, so firing one never needs the model. Each message is written once, stored, and reused. A daily background job plans the next day, and while the phone is charging a second job quietly writes nudge text and a general excuse for your open tasks, so tapping **Dodge It** can show one instantly.

The risk score is a small logistic regression written in plain Dart and trained on your own outcomes, a few hundred rows at most, retrained after every task you finish or dodge. For your first twenty outcomes it uses a simple rule instead (how often you have dodged that category), because a model trained on five examples is just a guess in a nicer font.

## Slow and steady

The theme fit the product by accident. The whole point of the nudges is that they are slow and steady: about the next tiny step, spaced by how likely you are to dodge, never at night, never the whole task at once. A big task becomes a sequence of things you can do in a minute.

## What the numbers look like

On [[my Samsung Galaxy Note 20 Ultra]], Gemma 4 [[E2B]] loads in [[__ ms]], produces its first token in [[__ ms]] and streams at about [[__ tokens per second]] on the [[GPU]]. On [[a cheaper phone with __ GB of RAM]] it [[loads and streams at __ tokens per second / says plainly that it cannot load the model]]. The full tables are in [`docs/benchmarks.md`](https://github.com/chestlyace/Do-it-Or-Dodge-it/blob/main/docs/benchmarks.md).

## What I learned

**Check that your library is alive before you plan around it.** I planned the whole app around `flutter_gemma`. When I added it, pub.dev said it was discontinued: its last release told everyone to move to `flutter_edge_ai`. I switched before writing any code against it. The move also taught me that the on-device engine needs Android 11 and a 64-bit ARM phone, so my minimum Android version had to change. I would rather learn that at the start than on release day.

**Don't assume a model is locked.** I had decided users would need a Hugging Face token because "Gemma is gated". Checking the actual files showed the Gemma 4 LiteRT builds are public and Apache 2.0. That removed a whole class of problem: no token in the app, nothing to leak.

**Features can leak the answer.** My first design for the risk score used the number of steps Gemma produced as a feature. But only tasks you *do* get steps, so the model would have "learned" that steps mean done, true only because of which button you pressed, and every new task would have looked risky. I kept the feature list but save the features at the moment you choose, before any steps exist, and wrote down the limitation instead of hiding it.

**Edge cases hide in plain sight.** A "last call" nudge is supposed to be the final one before the deadline. With a date-only due date and quiet hours starting at 21:00, no nudge ever landed close enough to the deadline to count as the last call. The fix was to define it as the last nudge that fits, not one within a fixed gap.

**Tests that drive the real screens found real bugs.** Running them at twice the normal text size found two layouts that overflowed (a button hidden in the add-task sheet, and the counts cut off in History) and a confirmation message that appeared somewhere you could not see it.

## What's next

iOS is the obvious next step; I left it out of version 1 to do one platform properly. [[Add your own next steps here.]] For now I would settle for finishing my own list.

## Prize category

**Best Use of Gemma**: the whole product is Gemma 4 running locally on the phone, doing four jobs (shrinking a task, drafting a step, writing an excuse, wording a nudge), with validation around it so a small model is dependable.

*Try it: [APK](https://github.com/chestlyace/Do-it-Or-Dodge-it/releases) · [source](https://github.com/chestlyace/Do-it-Or-Dodge-it).*
