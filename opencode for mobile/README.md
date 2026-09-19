# opencode-mobile

Run the opencode AI coding agent on your Android phone. Free models. One command install.

> **Brought to you by @FeaturisticLeaks X @slixki**

> ⚡ **New here? Read `INSTALL.txt` first — it's the whole guide on one page.**

---

## What you need

- An Android phone — **64-bit ARM (ARM64 / aarch64)**. Most phones made since ~2018.
- Internet connection
- About 10 minutes

> ⚠️ **Which devices work:** opencode's Android build is **aarch64-only**.
> It runs on real 64-bit ARM phones. It does **not** run on x86_64 Android
> emulators (MuMu, GameLoop, BlueStacks) or on 32-bit devices — the installer
> detects this and stops with a clear message. Use a real ARM64 phone, or an
> ARM64 Android emulator.

That's it. No computer, no coding experience, no paid subscriptions.

---

## Step-by-step install

### Step 1 — Install Termux

Download **Termux** from F-Droid:

> https://f-droid.org/packages/com.termux/

Do **not** use the Google Play version — it is outdated and will not work.

### Step 2 — Download and extract opencode-mobile

1. Download the `opencode-mobile` zip on your phone (from wherever you got this package).
2. Extract it with any file manager.
3. Recommended: put the extracted folder in **Downloads**. It should look like `Downloads/opencode-mobile`.

If you are not sure where it went, don't worry — Step 4 shows how to find it.

### Step 3 — Allow file access

Open the **Termux** app and run this:

```bash
termux-setup-storage
```

When Android asks for permission, tap **ALLOW**.

### Step 4 — Go to the extracted folder

Run this command:

```bash
cd ~/storage/downloads/opencode-mobile
```

If you extracted the folder somewhere else, find it like this:

```bash
cd ~/storage/
```

```bash
ls
```

You will see a list of folders. The one holding your files is usually `downloads`. Keep going deeper (`cd <folder>` then `ls`) until you are inside the `opencode-mobile` folder.

### Step 5 — Run the installer

```bash
bash install.sh
```

The installer installs everything from **requirements.txt** (curl, unzip, git, ripgrep, openssh, nodejs), then **opencode** itself, then sets up the free models, your key, and the memory system. It takes a few minutes — let it finish.

### Step 6 — Get your free OpenCode key (~1 minute)

The installer will ask for your **OpenCode API key**. Get a free one (no card required):

> https://opencode.ai/auth

Sign in or register, tap **API key**, copy it, then paste it into the installer.

Pasting the key is **optional** — press **Enter** to skip and add it later. It unlocks the free models that come with this package.

### Step 7 — Start opencode (one command)

When the install finishes, close Termux and reopen it (or run `source ~/.bashrc`), then type:

```bash
AI
```

That's it — opencode opens automatically. (`ai` also works.)

### Step 8 — Type your first request

Inside opencode, describe what you want to build. For example:

```
create a hello world android app in java
```

Press **Enter** and watch it work.

---

## Your first 5 minutes with opencode

- Start opencode anytime by typing **`AI`** (from anywhere).
- Type what you want in plain English, just like texting a friend.
- opencode writes the code, explains what it did, and runs commands.
- If you leave and come back, opencode **remembers** your project — it auto-creates and updates a `Memory.md` file inside every project folder, so you can pick up right where you left off.
- Your projects live under `~/opencode/`.

---

## Free API key — quick start

**OpenCode Zen** is the key this package is built around (no card required):

> https://opencode.ai/auth

Sign in or register, tap **API key**, copy it, and paste it when the installer
asks — or add it later inside opencode with `/connect` → **OpenCode Zen**. It
unlocks the 7 free models that ship with this package.

**Optional extras:** [Google Gemini](https://aistudio.google.com/app/apikey) and
[OpenRouter](https://openrouter.ai) also work as free alternatives and can be
added any time. Full walkthrough in GUIDE.md → "API keys & providers".

---

## Common problems

| Problem | Fix |
|---|---|
| Commands got jumbled (errors like `-ypkg` or `unzipunzip`) | In Termux, run **one command per line** — type it, press Enter, then type the next. Don't paste several commands together. |
| Termux says "command not found" | Make sure you followed every step in order and typed the commands exactly. You must be inside the `opencode-mobile` folder when you run `bash install.sh`. |
| Installer can't find the opencode download | Re-run `bash install.sh` — it now finds the download automatically, or asks you to paste the zip link from https://github.com/guysoft/opencode-termux/releases/latest |
| Model error on first run | Press `/models` and pick another free model, or press `/connect` to add or change your API key. |
| Can't find my downloads | Run `cd ~/storage/` then `ls` — keep going folder by folder until you see `opencode-mobile`. |
| opencode is slow | Free models can take a moment on the first reply. Try a lighter model like **Gemini 2.5 Flash** with `/models`. |
| Storage permission | Run `termux-setup-storage` again and tap **ALLOW** when Android asks. |

---

## What's in this folder

- `install.sh` — the one-command installer (Step 5)
- `requirements.txt` — the prerequisites install.sh installs first
- `config/` — the free model setup and memory templates
- `GUIDE.md` — the full beginner's guide to opencode

---

New to opencode? Read **GUIDE.md**.

---

**Brought to you by @FeaturisticLeaks X @slixki**
