# opencode-mobile — The Complete Beginner's Guide

**This guide is for total beginners.** If you have never used a terminal, never
used an AI coding tool, and don't know a single programming term — you are in the
right place. You only need to know how to read and type. Everything else is here.

---

## 1. What is opencode?

opencode is an **AI assistant that lives inside a terminal on your phone**. A
"terminal" is a text-only window where you type commands and the phone does them.
You probably know Termux already — it's the app that opens this terminal. opencode
is a program that runs inside Termux.

The special part: opencode is **connected to an AI** (the same kind of technology
as ChatGPT or Gemini). It thinks, it understands you, and it answers.

But it's not just a chatbot. opencode can **read and write files on your phone**
and **run commands** for you. So when you say "create a hello world Android app",
it actually creates the project files right there on your phone.

In other words, it's like having a **coding partner** who does the typing,
checking, and running — while you describe what you want in plain English. You
supervise. It does the heavy lifting.

---

## 2. The chat window (the TUI)

When you start opencode, the screen changes into a full-screen chat window. This
kind of text-based app is called a **TUI** (Text User Interface) — an app you use
with a keyboard, not a mouse.

What you'll see:

- Your messages and the AI's answers, one after another, like a chat.
- A **text box at the bottom** where you type.
- A few hints along the bottom or top (like what model you're using).

How to use it:

- **Type your message** in the box, then press **Enter** to send it.
- When you send your first message, opencode greets you with
  **"Brought to you by @FeaturisticLeaks X @slixki"** before getting to work —
  that's automatic, it does it every session.
- The AI answers, usually in chunks. **Let it finish.**
- To **stop** a long or wrong answer, press **`q`** or **Ctrl + C**.
- To **scroll** up through old messages, use the **arrow keys** — or, in
  Termux, slide your finger on the screen. If you turn on the extra-keys row
  (see "Handy extras" below), you also get Page Up / Page Down buttons.
- If you're ever lost, type `/help` and press Enter.

That's the whole interface. One box, one Enter key.

---

## 3. Your first project (walkthrough)

Let's build something real so you can see it work. We'll create a project called
`myapp` and ask opencode to make a simple Android app.

### Step 1 — Open Termux

Tap the Termux app. You'll see a black screen with a `$` symbol. That's your
prompt — it means "I'm ready, type a command."

### Step 2 — Go to your opencode folder

Type this and press Enter:

```
cd ~/opencode
```

What this means: `cd` = "change directory" (go into a folder), and `~/opencode`
is the opencode folder that was created when you installed the package. The `~`
symbol means "my home folder". So this line says: **go into my opencode folder.**

### Step 3 — Create a new project folder

Type this and press Enter:

```
mkdir myapp
```

`mkdir` = "make directory" (create a folder). You just created a folder called
`myapp`.

### Step 4 — Go inside it

```
cd myapp
```

Now you're inside the new project's folder.

### Step 5 — Start opencode

```
opencode
```

The chat window opens. This is where you talk to the AI.

*(If you installed with opencode-mobile, there's an even shorter way: type `AI`
from anywhere and opencode opens automatically.)*

### Step 6 — Make your first request

Type this and press Enter:

```
create a hello world android app
```

Watch what happens. The AI will plan, then start **creating files** in your
project folder — things like `AndroidManifest.xml`, `MainActivity.java`, and
Gradle files. It will show you each file it writes. You don't have to do
anything. Just watch and wait.

### Step 7 — Ask questions about it

When it finishes, try these:

```
what files did you create?
```

```
explain this file
```

The AI lists what it made, then explains a file in plain words. This is a great
way to learn — you can ask "what does this line mean?" about anything.

### Step 8 — Leave and come back

When you're done for the day, type `/quit` (or press **Ctrl + D** twice) to exit.
Don't worry — everything is saved. You can come back tomorrow, run `cd ~/opencode/myapp`
then `opencode`, and it will remember what you were doing. More on that in the
Memory section below.

---

## 4. The slash commands

Inside the opencode chat, any line that starts with **`/`** is a command, not a
message to the AI. Type `/` and a menu appears showing what's available.

| Command     | What it does |
|-------------|--------------|
| `/help`     | Shows the help screen for opencode itself. |
| `/new`      | Starts a fresh chat (clears the conversation, but your files and memory stay). |
| `/sessions` | Lists your previous chats. Pick one to resume it, exactly where you left off. |
| `/models`   | Switches the AI model — the "brain" that answers you. Important for this package. |
| `/connect`  | Adds or changes an API key / provider (see the API keys section). |
| `/undo`     | Undoes the last change opencode made to your files. |
| `/quit`     | Exits opencode. (You can also press Ctrl + D twice.) |

Think of `/new` as "clear the chat screen" and `/sessions` as "open the history
book." Neither deletes your actual files — the files live in the project folder,
not in the chat.

---

## 5. The free models

"Model" is the word for **which AI brain** answers you. Different brains are
better at different things, and you can switch anytime. This package comes with
four free models ready to use (and **six more free ones** when you sign in with an
opencode account — see the "OpenCode Zen" section below):

| Model name (what you type in `/models`) | The brain behind it |
|------------------------------------------|---------------------|
| `google/gemini-3-flash` | **Gemini 3 Flash** — free tier (needs a Google key). |
| `google/gemini-2.5-flash` | **Gemini 2.5 Flash** — free tier, a lighter Gemini. |
| `openrouter/deepseek-chat-free` | **DeepSeek Chat V3** — OpenRouter's free listing. |
| `openrouter/qwen-free` | **Qwen 2.5 72B** — OpenRouter's free listing. |

(These names come straight from your config file at
`~/opencode` → `config/opencode.json`.)

### What "free tier" means

Free models are free **in money**, but not unlimited. Providers put **rate
limits** on them — meaning you can only make so many requests per minute/hour.
If you send a burst of messages too fast, you might see an error like
"rate limit reached" or "quota exceeded." That's not a bug, and your work is not
lost. It just means the free brain is taking a short break.

**Fix:** type `/models` and pick a different model, wait a minute, and continue.

### Which one should you use?

The package defaults to an OpenCode Zen free model
(`opencode/deepseek-v4-flash-free`) — it works with the OpenCode key the
installer asks for. If it starts erroring from rate limits, press `/models` and
switch to another free model like `opencode/mimo-v2.5-free` or
`opencode/big-pickle`. The Gemini/DeepSeek/Qwen ones also work if you've added
those keys. Switching takes five seconds and costs nothing.

### Use OpenCode's own free models (OpenCode Zen)

The people who make opencode also run their own AI gateway called **OpenCode
Zen**. You sign in with an **opencode account** (no separate key to hunt for) and
get access to their tested-and-verified models — several of which are **free**:

| Model name (in `/models`) | The brain behind it |
|----------------------------|---------------------|
| `opencode/deepseek-v4-flash-free` | DeepSeek V4 Flash |
| `opencode/mimo-v2.5-free` | Mimo V2.5 |
| `opencode/nemotron-3-ultra-free` | Nemotron 3 Ultra |
| `opencode/north-mini-code-free` | North Mini Code |
| `opencode/ling-3.0-flash-free` | Ling 3.0 Flash |
| `opencode/laguna-s-2.1-free` | Laguna S 2.1 |
| `opencode/big-pickle` | Big Pickle |

(These seven are pre-configured in your `config/opencode.json`. After you sign in,
`/models` may show more models too. Free models are free **for a limited time**
while the team tunes them, and which ones are free can change — so if a model ever
starts erroring with a billing message, pick another from the list.)

**How to sign in (about 2 minutes, one time):**

1. Run `opencode`.
2. Type `/connect`.
3. Pick **OpenCode Zen**.
4. Open https://opencode.ai/auth in your browser (or tap the link opencode shows).
5. Register / sign in, add your billing details, and copy your API key.
6. Paste the key into opencode when it asks.
7. Type `/models` — the Zen models now appear. Pick one.

Two honest notes:

- The free Zen models are free **for a limited time** while the team tunes them,
  and during that free period they may use your conversation data to improve.
- Sign-up asks for billing details, but you are only charged if you pick a
  **paid** Zen model. The free ones above stay free.

---

## 6. API keys & providers (3 ways)

A **provider** is the company whose AI you're using (Google, OpenRouter, etc.).
An **API key** is a secret code that tells the provider "this is me, let me in."
It's like a password for using the AI service.

Here's the good news: **the only key you really need is the free OpenCode key**
from https://opencode.ai/auth — the installer asks for it, and it unlocks the 7
free models that ship with this package. You only add other keys if:

- you want to use your own provider / paid models, or
- you want the free Google Gemini tier (free to create at Google AI Studio), or
- you want the free OpenRouter models.

There are three ways to add a key or provider:

### Way 1 — The easiest: `/connect` inside opencode

When you installed the package, the installer (`install.sh`) asked for your free
OpenCode key — that's optional. You can add or change a key anytime later:

1. Run `opencode`.
2. Type `/connect`.
3. Pick a provider from the list.
4. Paste your key and press Enter.

Keys you add this way are saved to `~/.local/share/opencode/auth.json` — a safe,
private file on your phone.

### Way 2 — An environment variable

An **environment variable** is a named value your terminal remembers for the
whole session. Many providers (OpenRouter, for example) give you a key like
`sk-or-...` and expect it as an environment variable.

1. Open your terminal settings file: `nano ~/.bashrc`
   (`nano` is a simple built-in text editor. If you've never used it: type your
   changes, then press **Ctrl + X**, then **Y**, then **Enter** to save and exit.)
2. Add a line like this (use your real key):

```
export OPENROUTER_API_KEY="sk-or-..."
```

3. Save, exit, and **restart Termux** (swipe the app away and reopen it).
   The variable is now active.

For OpenCode Zen, the installer already exported your key for you as
`OPENCODE_API_KEY` in `~/.bashrc` — you don't need to do anything.

### Way 3 — Edit the config file directly

The installer created a config file at:

```
~/.config/opencode/opencode.json
```

This file lists all your providers and models. You can open it with
`nano ~/.config/opencode/opencode.json` and add your own provider. Here is a
complete example of adding a **custom provider** that speaks the standard
OpenAI-compatible language:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "myprovider": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "My Provider",
      "options": {
        "baseURL": "https://api.myprovider.com/v1",
        "apiKey": "{env:MY_API_KEY}"
      },
      "models": {
        "my-model": {
          "name": "My Model",
          "id": "my-model-id",
          "limit": { "context": 128000, "output": 8192 }
        }
      }
    }
  }
}
```

**What each part does, in plain words:**

- **`$schema`** — a note saying "this file follows the official opencode format."
  It just helps editors check your file. Leave it alone.
- **`provider`** — the list of AI services you can use. You're adding one new
  entry to this list.
- **`"myprovider"`** — the name *you* invent for this provider. Use it in
  `/models` and `/connect`. Pick something short.
- **`npm`** — the software "adapter" opencode uses to talk to this kind of
  provider. `@ai-sdk/openai-compatible` means "this provider speaks the same
  language as OpenAI, so use the standard adapter." Most modern services do.
- **`name`** — a friendly display name shown in the menu.
- **`options`** — the connection settings for this provider.
- **`baseURL`** — the web address of the provider's API — where requests get
  sent. Your provider's docs will give you the exact URL.
- **`apiKey`** — the key. `{env:MY_API_KEY}` means "read the key from an
  environment variable named `MY_API_KEY`" (see Way 2). That's safer than
  writing your actual key in this file.
- **`models`** — the list of models this provider offers.
- **`"my-model"`** — the name *you* choose for this model inside opencode.
- **`id`** — the exact model code the provider uses (from their docs).
- **`limit`** — how big this model's "brain" is, measured in tokens (roughly,
  pieces of text). `context` = how much of your conversation it can remember at
  once. `output` = how long its answers can be. Set numbers that match your
  provider's specs — 128000 context / 8192 output are safe common values.

After editing, save and restart Termux. Then run `opencode`, type `/models`, and
your new provider's model should be listed.

---

## 7. The memory system (the core feature)

This is the most useful part of opencode-mobile, so read this section carefully.

**Every project gets its own memory file called `Memory.md`.** It sits inside the
project folder, and opencode keeps it updated automatically with:

- **What was done** — the progress log, with dates.
- **What changed** — which files were touched and why.
- **Decisions** — choices made and the reason behind them.
- **Next steps** — what to do next time.
- **Open questions** — anything still unresolved.

The AI is *required* to update this file on every meaningful step. When you start
opencode in a project, it reads the memory first and **picks up where you left
off** — even days later.

### Where projects and files live

- All projects live under `~/opencode/` — one folder per project.
- Each project's memory file is `~/opencode/<project-name>/Memory.md`.
- When a project is created, opencode copies a **template** from
  `~/opencode/Memory.template.md` and fills it in with the project's name and
  goal.
- If you're curious how the AI decides to behave, you can read the rules at
  `~/.config/opencode/AGENTS.md` and `~/opencode/AGENTS.md`.

### How to resume work tomorrow

1. Open Termux.
2. `cd ~/opencode/myapp` (your project).
3. `opencode`.
4. That's it. The AI reads `Memory.md` and says something like "Welcome back —
   last time you were building the main screen. Want to continue?"

### Reading and editing memory yourself

You can also peek at the memory from the terminal:

```
cat Memory.md     # show it on screen
nano Memory.md    # edit it yourself
```

Feel free to add notes with your own words — the AI reads whatever is there.

---

## 8. Working with existing Android projects (AIDE / AndroidIDE)

If you already have apps you started in **AIDE** or **AndroidIDE**, they live on
your phone's **shared storage** (the normal file area you see in Files apps) —
not in the `~/opencode` folder. That's fine: opencode can work there too.

First, make sure Termux can see your shared storage (one-time):

```
termux-setup-storage
```

Tap **ALLOW** when the phone asks. This creates a shortcut folder at
`~/storage/shared` that points at your phone's normal storage.

Then:

**If your project came from AIDE:**
```
cd ~/storage/shared/AppProjects/<YourProject>
opencode
```
*(AIDE keeps projects in the `AppProjects` folder.)*

**If your project came from AndroidIDE:**
```
cd ~/storage/shared/AndroidIDE/projects/<YourProject>
opencode
```
*(AndroidIDE keeps projects in `AndroidIDE/projects`.)*

Not sure where the project lives? Look around:

```
ls ~/storage/shared
```

This lists everything in shared storage. Then dig deeper (`ls <folder>` + `cd <folder>`) until you find the project. Once you're inside the folder, run `opencode` — the AI reads and edits your project's files.

> **Tip — you can point opencode at ANY project folder this way**, even ones not
> created by AIDE. As long as Termux can see the folder, opencode can work in it.

---

## 9. Compiling your app

Here's an important truth: **opencode writes the code, but it does not reliably
compile APKs by itself.** Building an Android app (turning code into an installable
APK) needs Android's full build system, which is heavy for a phone terminal.

So you use two tools together:

1. **opencode** — writes and edits the project's code.
2. **AndroidIDE** or **AIDE** — builds the APK.

**AndroidIDE** is the recommended one: it's actively maintained and uses modern
Gradle. **AIDE** is the older classic and also works.

**The flow is simple — and you can repeat it until the app works:**

1. opencode creates/edits your project files (in shared storage).
2. Open the **same folder** in AndroidIDE or AIDE (each has an "open project"
   button — point it at the project folder).
3. Press the **build / run** button in that app. It compiles the code into an
   APK you can install.

**Fix build errors automatically (the loop):**

1. When the build shows errors, **copy the error message** (in AndroidIDE, the
   build log appears in the bottom panel — long-press the error text and copy).
2. Go back into opencode and say:

   ```
   Here is a build error from my Android project. Fix it, then tell me what to build again:
   (paste the error message here)
   ```

3. opencode fixes the code. **Build again** in AndroidIDE/AIDE.
4. Repeat — each round opencode fixes the next error. Usually 2–4 rounds and the
   APK compiles.

**Pro tip — AndroidIDE can do even better.** AndroidIDE has a **built-in
terminal** with Gradle already set up. Instead of pasting errors, tell opencode
to check the build itself:

```
cd ~/storage/shared/AndroidIDE/projects/<YourProject>
opencode
```

Then ask opencode to run the Gradle build for you. opencode sees the real error
output, fixes the code, and re-runs until the build passes — no copying and
pasting. (This works because AndroidIDE projects use Gradle, which opencode can
run from the terminal.)

---

## 10. Handy extras

Small things that make your life easier:

- **Keep the phone awake.** During long AI tasks, the screen may sleep and pause
  things. Run this once:
  ```
  termux-wake-lock
  ```
  To let it sleep again later: `termux-wake-unlock`.

- **Extra device tools (optional).** This package gives opencode access to
  phone sensors and features. Install with:
  ```
  pkg install termux-api
  ```

- **Enable the extra-keys row in Termux.** Long-press the black screen →
  **More** → **Extra keys**. The installer already added a **⌨ keyboard button**
  to this row — tap it any time the on-screen keyboard hides inside opencode and
  it pops straight back up. The row also has **ESC**, **TAB**, and arrow keys,
  which are handy in the opencode chat (ESC cancels, arrows scroll).

- **Use a Bluetooth keyboard.** Typing on the phone keyboard works, but a real
  keyboard makes the chat and slash commands much faster and more comfortable.

---

## 11. Troubleshooting

| Problem | What's happening | What to do |
|---------|------------------|------------|
| Model errors, "limit reached", "rate limit", "quota exceeded" | The free model hit its usage limit or needs a key. | Type `/models` and switch to another model. Or `/connect` to check/re-enter your key. Then try again. |
| "command not found" | A piece of the install is missing or Termux was reinstalled. | Re-run the installer (`install.sh`) and follow the steps. |
| "Permission denied" when opening shared-storage projects | Termux hasn't been given storage access yet. | Re-run `termux-setup-storage` and tap **ALLOW** on the popup. |
| Everything feels slow | Phones heat up during heavy work and slow down (thermal throttling) to cool off. | Take breaks, close other apps, remove the phone case for better cooling. Slow response is normal when hot. |
| I accidentally exited the chat / closed Termux | The chat is gone from the screen — but it's saved. | Reopen Termux, `cd` into your project, run `opencode`, then type `/sessions` and pick your last chat to resume it. |
| The on-screen keyboard doesn't appear when opencode starts | Android doesn't always show the keyboard for full-screen terminal apps. | Tap the **⌨** button in the key row (bottom of screen — added during install). No key row visible? Enable it: long-press the screen → **More** → **Extra keys**. Or force it with `termux-ime toggle` after `pkg install termux-api`. |

**Golden rule:** almost nothing in opencode is destructive. Your files and memory
are saved on disk. If a message errors out, switch models or fix the key — then
continue. You rarely lose work.

---

## 12. Quick reference card

Print-worthy one-pager:

**Starting**
```
AI                   # start opencode (the shortcut created during install)
ai                   # same as above
cd ~/opencode        # (if you prefer to go there yourself)
opencode             # (or just run opencode directly)
```

**New project**
```
mkdir ~/opencode/myapp
cd ~/opencode/myapp
opencode
```

**Open an existing project**
```
cd ~/opencode/<project-name>
opencode
```

**Open an AIDE / AndroidIDE project**
```
cd ~/storage/shared/AppProjects/<YourProject>
opencode
```

**Find folders**
```
ls ~/storage/shared      # list shared storage
cd ~/storage/shared/...  # go into a folder
```

**Inside the chat**
| Command | Does what |
|---------|-----------|
| `/help` | Help |
| `/new` | New chat |
| `/sessions` | Resume a past chat |
| `/models` | Switch AI model |
| `/connect` | Add/change API key |
| `/undo` | Undo last change |
| `/quit` | Exit (or Ctrl+D twice) |

**Stop the AI mid-answer:** press `q` or Ctrl + C.

**Memory**
```
cat Memory.md     # view your project's memory
nano Memory.md    # edit it yourself
```

**Handy**
```
termux-setup-storage    # one-time storage permission
termux-wake-lock        # keep screen awake
termux-wake-unlock      # let screen sleep again
pkg install termux-api  # extra device tools (optional)
```

---

That's everything you need to start. Remember: you are the boss, opencode is the
assistant. Say what you want in plain English, watch it work, and use `/models`
if a free model gets tired. Happy building!

---

**Brought to you by @FeaturisticLeaks X @slixki**
