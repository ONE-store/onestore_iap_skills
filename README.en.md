# ONE Store IAP Skill

[한국어](README.md) | **English**

> An Agent Skill that helps AI coding agents integrate the ONE Store in-app purchase (IAP) SDK

![sdk-iap](https://img.shields.io/badge/sdk--iap-21.04.00-blue)
![Agent Skills](https://img.shields.io/badge/Agent%20Skills-open%20standard-brightgreen)
![platform](https://img.shields.io/badge/platform-Android-green)

Once installed, your AI coding agent understands the ONE Store IAP SDK and helps with
**adding dependencies · manifest setup · placing purchase code · a hands-on test screen ·
error diagnosis · pre-release checks**.

Just ask in plain language — you never need to call the skill by name. Agent Skills is an
[open standard](https://agentskills.io), so **one bundle works across multiple AI coding tools.**

```text
Me: Add ONE Store in-app purchase to this app

Agent: I added the dependency and <queries>, and placed the purchase manager.
       I need three values — please copy the form below and fill it in.
       License key: (paste it here)
                    Developer Center → Common Info → License Management ...
```

## Table of Contents

- [Features](#features)
- [Getting Started](#getting-started)
  - [Requirements](#requirements)
  - [Installation](#installation)
  - [Supported Tools](#supported-tools)
  - [Updating](#updating)
- [Usage](#usage)
  - [What to Prepare](#what-to-prepare)
  - [Language Support](#language-support)
- [Important Notes](#important-notes)
- [What the Skill Does Not Do](#what-the-skill-does-not-do)
- [Layout](#layout)
- [Customizing](#customizing)
- [Troubleshooting](#troubleshooting)
- [Baseline SDK Versions](#baseline-sdk-versions)
- [Changelog](#changelog)
- [References](#references)
- [Support](#support)
- [License](#license)

## Features

| Feature | Description |
|---|---|
| **Status diagnosis** | Reads your project and reports what is done and what is missing, as a table. This step **never modifies files** |
| **Dependency setup** | Version Catalog · Kotlin DSL · Groovy DSL — whichever your project uses |
| **Manifest setup** | `<queries>` and the INTERNET permission — without them, connection fails on Android 11+ |
| **Purchase code placement** | Places a verified manager class adapted to your package. The license key is never stored as a plain-text constant |
| **Filling in values** | License key · product IDs · **which products are consumable**, matched to your app |
| **Test screen** | A screen to try sign-in · product list · purchase · consume/acknowledge by tapping (Compose projects only) |
| **Error diagnosis** | Explains response codes as cause · reproduction · fix code · docs. Even with no error code — just "purchases don't work" — it starts from the logs |
| **Pre-release checks** | Sweeps the items that cause real incidents, and separates release blockers from the rest |

## Getting Started

### Requirements

| Item | Details |
|---|---|
| Android project | A Gradle project. **Your existing `compileSdk` · `minSdk` · Java target are never changed** |
| AI coding tool | Any tool that reads Agent Skills (see [Supported Tools](#supported-tools)) |
| ONE Store Developer Center | An account and **registered in-app products**. Without them, product queries return an empty list |
| Jetpack Compose | Needed **only for the test screen**. Everything else works without Compose |
| Shell | The install script is bash — macOS · Linux; on Windows use WSL or Git Bash. You can also [copy manually](#installation) without the script |

### Installation

```bash
git clone https://github.com/ONE-store/onestore_iap_skills.git
cd onestore_iap_skills
./install.sh <path_to_android_project>
```

This installs into three locations — `.claude/skills/` · `.agents/skills/` · `.grok/skills/` —
which covers most tools listed below.

**Options**

| Option | What it does |
|---|---|
| `--dry-run` | Shows what would be copied where, without changing anything |
| `--user` | Installs into your home directory, for use in **all projects** |
| `--all` | Also installs into `.cursor/` · `.github/` · `.gemini/` · `.codex/` · `.junie/` |
| `--pull` | Pulls the latest from the remote before installing |
| `--force` | Overwrites even if you edited the installed copy |
| `--offline` | Skips the remote check |

**Manual copy** works too — put the `skills/onestore-iap` folder into the path your tool reads.

```bash
cp -R skills/onestore-iap <project>/.claude/skills/
```

### Supported Tools

| Tool | Project-level skill path |
|---|---|
| Claude Code | `.claude/skills/` |
| Cursor | `.agents/skills/` · `.cursor/skills/` (also reads `.claude/` · `.codex/`) |
| GitHub Copilot / VS Code | `.github/skills/` · `.claude/skills/` · `.agents/skills/` |
| Gemini CLI | `.gemini/skills/` · `.agents/skills/` |
| OpenAI Codex | `.agents/skills/` |
| Grok Build | `.grok/skills/` — **does not read `.agents/skills/` at project level** |
| Junie (JetBrains) | `.junie/skills/` — install with `--all` |

For personal (all-projects) use, place it under the same paths in your home directory
(`~/.claude/skills/` and so on).

### Updating

Running the same command again **updates only what changed.** Before installing, the script
checks the remote and tells you if your local copy is behind; pass `--pull` to fetch first.

```bash
./install.sh --pull <path_to_android_project>
```

**If you edited the installed copy, the script stops instead of overwriting.** Per-file
checksums recorded at install time distinguish "the source got newer" from "you changed it".
Use `--force` to overwrite.

## Usage

After installing, open your AI coding tool in that project and ask as you normally would.

```text
Add ONE Store in-app purchase
How far along is my ONE Store billing setup?
I have three coin products and a remove-ads product. Fill in the values
I want to tap through it to see it working. Add the test screen
Purchases return responseCode 7 — why?
Purchases aren't working. How do I check the logs?
Check the billing code before release
```

| When you are stuck, ask | What you get |
|---|---|
| **"What can the ONE Store billing skill do?"** | Lists its features and immediately diagnoses your current status |
| **"What should I do next?"** | Re-reads your project state and tells you the next step — **including exactly what to ask for** |

### What to Prepare

Finishing the integration takes three values. Without them, code placement still proceeds —
the value slots are left blank and the agent stops with a fill-in form.

| Value | Where to get it |
|---|---|
| **License key** | Developer Center → Common Info (공통정보) → License Management (라이선스 관리) |
| **Product IDs** | The `In-App ID`s registered under Developer Center → In-App Info (In-App 정보) |
| **Which of them are consumable** | Your app's design — which products must be purchasable again |

The third one cannot be inferred from code, so the agent always asks. Things that are used up —
coins, items — are consumable; one-time unlocks like ad removal or premium are not.
**Getting this wrong breaks silently, with no error** — consuming a permanent product lets
users buy it again.

### Language Support

Feel free to ask in Korean or English. Other languages work too — the agent answers in
whatever language you use.

Whatever the answer language, menus you need to find in the Developer Center are given
with their on-screen Korean labels, so you can match them to what you actually see.

Note that the skill documents and the comments in the placed code are written in Korean.

## Important Notes

> [!IMPORTANT]
> **Billing code breaks silently.** It can compile and render fine while products are never
> granted, or purchases get refunded. This skill ships verification tools and checklists,
> but **the final check is on the developer.**

- **Read the generated and modified code** — especially the product-granting logic and the
  consume/acknowledge branching
- **Always run a sandbox test.** If an account is not registered as a **test ID** in the
  Developer Center, tapping purchase in the production environment **charges real money**
- **Consume or acknowledge within 3 days of purchase.** Otherwise the purchase is treated as
  not delivered and is automatically refunded. The placed code handles this automatically —
  **the test screen is the one exception**, with auto-processing turned off so you can tap
  through it yourself. Do not ship that screen as production UI
- **Run the pre-release check once before shipping.** It re-verifies the items above in code

## What the Skill Does Not Do

- **Gradle sync and builds** — after dependencies are added, you sync yourself
- **Real purchase testing** — sandbox tests and test-ID registration happen in the Developer Center
- **Server-side receipt verification** — server-to-server verification is not something an app
  can do. If your server grants products, the skill wires up the hook in code; the server side
  is yours. **Purchase signatures are already verified by the SDK** using the license key
- **Turning the test screen into production UI** — it is a verification tool, and stops there.
  Build your production screens to your own design and granting logic
- **Changing your build settings** — `compileSdk` · `minSdk` · Java target are never bumped to
  match the sample values
- **Changing your launch screen on its own** — after placing the test screen it **asks whether
  to wire it up**, and offers the option that leaves your entry screen untouched (a separate
  activity) first

## Layout

```text
install.sh                        # installs the skill into project/home directories
skills/onestore-iap/
├── SKILL.md                      # entry point — procedures and decision rules
└── references/
    ├── sdk-context.md            # API · call order · product types · all response codes · license key
    ├── dependencies.md           # three ways to add the dependency
    ├── manifest-queries.xml.txt  # <queries> · permission · dev option
    ├── purchase-manager.kt.txt   # purchase manager (package is a placeholder)
    ├── license-key.kt.txt        # license key provider (no plain-text constants)
    ├── license-manager.kt.txt    # license verification manager (paid apps only)
    ├── test-screen.kt.txt        # Compose test screen for hands-on verification
    ├── checks.md                 # status diagnosis · pre-release checklist
    ├── build-env.md              # when the build fails because of Java (JDK) setup
    └── diagnose.md               # when all you have is "it doesn't work"
```

`SKILL.md` holds only procedures and decision rules; facts and code originals live in
`references/`. The agent reads only the files it needs, when it needs them.

## Customizing

The bundle is Markdown and text files — open and edit them as you like. Adapting the
procedures or code originals to your app is fine.

> [!WARNING]
> **Keep the manager's consume/acknowledge branching and its connection-guard function.**
> Removing them gets purchases refunded under the 3-day rule, or makes calls fail
> intermittently after the service connection drops.

Rather than editing the installed copy, **edit your clone of this repository and reinstall** —
otherwise you repeat the same choice on every update.

## Troubleshooting

<details>
<summary><b>The agent doesn't use the skill</b></summary>

First check whether the skill is visible — ask **"List the skills you can use right now."**

- **Not in the list** → an install-path problem. Check the path your tool reads in
  [Supported Tools](#supported-tools), and **start a new session** after installing
- **Listed but not used** → include words like "ONE Store" or "in-app purchase" in your
  request. If it still writes its own code, add **"use the skill for this"**

</details>

<details>
<summary><b>The build fails</b></summary>

**Most of the time it is not the billing code — it is the Java (JDK) setup**, especially when
a project created in the IDE is built from the terminal. These messages mean it's the JDK:

- `Unsupported class file major version`
- `Android Gradle plugin requires Java …`
- `JAVA_HOME is not set`

Paste the full error to the agent — it identifies the cause and the fix. It also
distinguishes build errors that *are* caused by the placed code (missing key file,
dependency in the wrong module, and so on).

</details>

<details>
<summary><b>Purchases don't work and I don't know why</b></summary>

The placed code logs its progress under the `OneStoreIAP` tag in debug builds.

```bash
adb logcat -s OneStoreIAP
```

Connection · product query results · purchase requests and results · consume/acknowledge
branching are logged in order, so **the last line tells you how far it got.** Paste that
output to the agent.

**No log lines at all is also a clue** — the billing code is not running, usually because
the activity never starts the manager.

</details>

<details>
<summary><b>Product list comes back empty</b></summary>

Not an error — the query returned nothing. One of three things:

1. Products are not registered in the Developer Center
2. The product IDs in code don't match the registered `In-App ID`s **character for character**
3. The products are not in "on sale" status

None of these can be verified from code, so the agent will ask you.

</details>

<details>
<summary><b>Bought a product but can't buy it again (responseCode 7)</b></summary>

That is `RESULT_ITEM_ALREADY_OWNED`. Most of the time it means **a consumable product was
never consumed.**

However, **this code is normal for permanent products and subscriptions** — it just means
"already owned", and there is nothing to fix. Which case you are in depends on whether the
product is consumable.

</details>

## Baseline SDK Versions

| Artifact | Version |
|---|---|
| `com.onestorecorp.sdk:sdk-iap` | 21.04.00 |
| `com.onestorecorp.sdk:sdk-licensing` | 2.2.1 (paid apps only) |

Every class, method, constant, and response code in this skill was written against the
public references below. When the SDK moves, the skill is re-checked the same way.

## Changelog

| Date | Changes |
|---|---|
| 2026-08-28 | Initial release, based on `sdk-iap 21.04.00` |

## References

- **In-App Purchase Developer Guide (API V7 / SDK V21)** —
  <https://onestore-dev.gitbook.io/dev/tools/billing/v21>
  Overview · prerequisites · implementation · testing, plus the full API reference
  (classes, builders, constants)
- **Official sample app** — <https://github.com/ONE-store/onestore_iap_release>
- **Developer portal** — <https://dev.onestore.net/dev/>
- **Maven Central** — <https://repo1.maven.org/maven2/com/onestorecorp/sdk/>

## Support

- Bugs and suggestions for the skill itself:
  [Issues](https://github.com/ONE-store/onestore_iap_skills/issues) on this repository
- SDK, billing policy, and product registration questions:
  [ONE Store Developer Center](https://dev.onestore.net/dev/)

## License

This repository is provided under the **OneStore IAP SDK License Agreement**. See the
[LICENSE](LICENSE) file for the full terms.
