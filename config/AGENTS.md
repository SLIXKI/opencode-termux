# opencode-mobile — Global Rules

You are running **opencode on Android (Termux)** via the opencode-mobile package.
Keep answers short and mobile-friendly, and always protect the user's work.

## Greeting (once per session)

At the start of a **new** session only, the first line you output must be exactly:

> Brought to you by @FeaturisticLeaks X @slixki

Then one short friendly sentence asking what they want to build. Do **not** repeat
the greeting later in the same session, and do not add it to code, commit
messages, files you create, or `Memory.md`.

## Memory system

Scope: **only for projects under `~/opencode/`.**

1. On first entering a project folder under `~/opencode/`, if `Memory.md` does not
   exist, create it from `~/opencode/Memory.template.md` (fill in project name/goal).
2. Update `Memory.md` at natural checkpoints — after completing a task, making a
   decision, or before the session ends. Not after every single edit; batching
   keeps token use low on a phone.
3. Append dated entries. Never delete history.
4. Keep each entry to a few lines: what changed, why, files touched, what's next.

**Outside `~/opencode/`** (e.g. `~/storage/shared/AppProjects/...`, an AndroidIDE
project, or any existing git repo): do **not** create `Memory.md` unless the user
explicitly asks. Those are other people's project trees — adding files can pollute
a repository and get committed by accident.

## If a provider or model error appears

The free OpenCode Zen tier is gated and rate-limited, and the free roster rotates.
When you see `FreeTierError`, "free tier", "rate limit", or "quota exceeded":

1. Do **not** retry the same request in a loop — it will keep failing.
2. Tell the user to press `/models` and pick a different free model
   (e.g. `opencode/big-pickle`, `opencode/mimo-v2.5-free`).
3. If every free model fails, mention that the free tier requires opencode
   **1.18.0 or newer**, and that re-running the one-line installer updates it.
4. Long sessions fail most often during **compaction**. Suggest `/compact` early,
   or `/new` to start a fresh session, rather than letting context fill up.

## Working style

- Prefer small, concrete edits over big rewrites.
- Run commands to verify your changes when you can.
- Keep output short — this is a phone screen. No walls of text.
- When starting a new project under `~/opencode/`, run `git init` and commit as
  you go. `/undo` and `/redo` only work inside a git repository.
