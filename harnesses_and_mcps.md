# Harnesses & MCPs — project_x

Everything the agent (pi) uses in this project, what each piece is for, and how to
recreate it on another machine. Written for the antiX laptop, but it applies anywhere.

Last verified: pi 1.5.2 · pi-context-prune 2.2.0 · context-mode 2.1.10

---

## 1. The harness: pi

pi *is* the harness — the agent loop, model access, tools, and config. This project
uses four of its extension points:

| Feature | Location here | What it gives us |
|---|---|---|
| **Skills** | `.pi/skills/<name>/SKILL.md` | Loadable workflows (see §2) |
| **Extensions** | `.pi/extensions/build-quake.ts` | Custom `build_quake` tool (see §3) |
| **Packages** | installed user-wide | Context management (see §4) |
| **MCP servers** | `.pi/mcp.json` | GitHub API access (see §5) |

Project-scoped files (`.pi/`) only load after the project is **trusted**. In a fresh
clone you'll be asked once; non-interactively pass `pi --approve`.

User-level config lives in `~/.pi/agent/`:

| File | Purpose |
|---|---|
| `settings.json` | installed packages, provider/model |
| `instructions.md` | standing rules (context-management + skill-loading policy) |
| `.github_pat` | GitHub token, mode 600 — referenced by `$GITHUB_PAT`, never in the repo |
| `trust.json` | which projects are trusted |

Relevant pi docs (in the install tree):
`docs/skills.md`, `docs/extensions.md`, `docs/packages.md`, `docs/mcp.md`, `docs/security.md`.

---

## 2. Skills

Auto-loaded by matching their `description` against the request, or forced with
`/skill:<name>`. All four carry the project's non-negotiables: vanilla QuakeC via
FTEQCC, numeric frame indices (never `$frame`), all balance numbers in
`qc/tuning.qc`, complete file contents rather than fragments.

| Skill | Use it when |
|---|---|
| `slipgate-context` | Always first. Engine facts, asset naming, build/launch commands, answer format. |
| `slipgate-feature` | Adding or changing gameplay behaviour. Fill in the template, get files + tests. |
| `slipgate-debug` | Compiler error, engine console error, or crash. Cause in one sentence, smallest fix. |
| `slipgate-assets` | Swapping in art (Blender → MDL/PNG), incl. `frames.qc` numbers and CREDITS rows. |

`/skill:slipgate-feature add a grenade launcher` appends the request to the template.

> `slipgate-context` is a *skill*, so it only loads on demand. If the agent keeps
> forgetting the project facts, move its content into `AGENTS.md` at the repo root,
> which pi loads every session.

---

## 3. Extension: `build_quake`

`.pi/extensions/build-quake.ts` registers one tool with the whole toolchain, so
builds never get hand-rolled in bash.

| Target | Runs | Notes |
|---|---|---|
| `progs` | `fteqcc progs.src` → `tools/fix_progs_crc.py` → copy to `slipgate/progs.dat` | The crc stamp is mandatory, see below |
| `map` | `qbsp -wadpath .` → `vis` → `light` in `slipgate/maps/` | Skips with a clear message if ericw-tools are missing |
| `engine` | `meson setup` (once) + `ninja` in `vkQuake/` | Uses the LunarG SDK env |
| `launch` | `vkQuake/build/vkquake -game slipgate +map starter` from the repo root | Never launch by hand |
| `all` | `progs` then `map` | Stops if `progs` fails |

Why it exists: three steps that were wrong every time they were done manually —
the **crc stamp** (vkQuake hard-requires `progs.dat` crc 5927, fteqcc can never
produce it), the **SDK environment** (must not be sourced from a script, see §6),
and **basedir** (`id1/` sits at the repo root, not inside the mod).

---

## 4. Context management packages

Two user-level npm packages do the heavy lifting when a session gets long. Both are
installed with pi, not npm directly:

```sh
pi install npm:pi-context-prune@latest
pi install npm:context-mode@latest
```

### 4.1 pi-context-prune 2.2.0

Runs in *agentic auto mode*: it watches how much unpruned tool output has piled up
and nudges the agent to prune in batches of 8–12 related calls.

| Tool | What it does |
|---|---|
| `context_prune` | Summarises the pending tool results (batch of 8–12), keeps a compact bullet summary, drops the raw text from context |
| `context_tree_query` | Retrieves the original full output for any pruned call by short ref (`t42`, …) |

Key property: **nothing is lost**, only moved. Summaries carry a list of short refs
so any pruned result can be pulled back verbatim. Guidance it enforces: prune at
task boundaries, not after every 2–3 calls (that wrecks prompt-cache efficiency).

### 4.2 context-mode 2.1.10

Keeps large output out of the conversation in the first place: a sandboxed code
runner plus a local index.

| Tool | Use for |
|---|---|
| `ctx_execute` | Run a command/script and return **only** the answer (counts, parsed fields), not the raw dump. Also the way to read one section of a big file. |
| `ctx_batch` | Several shell commands + several questions in one call; returns only matching sections. |
| `ctx_index` | Store a file, folder, or URL so it can be searched later instead of re-read. |
| `ctx_search` | Query indexed content and earlier sandbox output; supports `sort: timeline`, scope `session`/`worktree`/`project`. |
| `ctx_resume` | After a compaction or a resumed session: what was the last task, which files changed, what's still broken. |
| `ctx_stats` | How much text context-mode kept out of the chat. |
| `ctx_doctor` | Diagnose the install (hooks, DB, version, host config). |
| `ctx_upgrade` | Update/uninstall context-mode itself. |
| `ctx_purge` | Delete stored data (session / source / project). Destructive. |

Rule of thumb in this repo: reading `vkQuake/` source or a full build log → use
`ctx_execute`/`ctx_search`; editing files → normal read/edit tools.

### 4.3 Standing instructions

`~/.pi/agent/instructions.md` encodes the policy: prefer the `ctx_*` tools over raw
`read`/`bash` for big output, never paste whole files or logs, prune proactively,
and read `skill.md` sections incrementally. Copy that file to the new machine.

---

## 5. MCP servers

MCP servers are declared in `.pi/mcp.json` (project, needs trust) or
`~/.pi/agent/mcp.json` (user). Currently one:

```json
{
  "mcpServers": {
    "github": {
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": { "Authorization": "Bearer ${GITHUB_PAT}" },
      "description": "GitHub: repo management, issues, pull requests, and Actions"
    }
  }
}
```

### 5.1 GitHub MCP — auth, honestly

A **PAT is mandatory**. The GitHub API never accepts SSH keys; your SSH key only
authenticates `git push`/`pull`. So the split is:

| Task | Mechanism |
|---|---|
| clone/commit/push | **SSH key** (`git@github.com:Irgathane/project_x.git`) |
| issues, PRs, Actions, releases, repo settings | **fine-grained PAT** via MCP |

Token setup that we validated:

1. fine-grained PAT, repository access → `Irgathane/project_x`
2. permissions: **Contents** RW, **Issues** RW, **Pull requests** RW, **Actions** RW,
   **Metadata** R, **Administration** RW (only needed to change repo settings)
3. store it **outside the repo**, mode 600, and export it from the shell:

```sh
install -m 600 /path/to/token ~/.pi/agent/.github_pat
echo 'export GITHUB_PAT="$(cat ~/.pi/agent/.github_pat)"' >> ~/.bashrc
```

Gotcha worth remembering: `GET /repos/...` reports `permissions.admin: true` because
*you* are an org owner — that says nothing about what the token was granted. Probe
what you need instead (e.g. `GET /repos/.../hooks` needs `administration:read`;
`PATCH /repos/...` needs `administration:write`).

The repo owner `Irgathane` is an **organisation**, so the token must be allowed for
org repos and the org must permit fine-grained tokens.

### 5.2 SSH key

```sh
ssh -T git@github.com        # expect "Hi <user>! You've successfully authenticated"
git remote -v                # must be git@github.com:..., not https://...
```

### 5.3 Deliberately not installed

| Server | Why not |
|---|---|
| filesystem | pi already has native read/edit/bash |
| fetch/URL | `ctx_index` on a URL covers it |
| Playwright/browser | no web UI in a QuakeC mod |
| database | nothing to query |

---

## 6. Recreating this on the new machine

```sh
# 1. pi itself is already there (you said you'll use it again); then:
pi install npm:pi-context-prune@latest
pi install npm:context-mode@latest

# 2. copy the user-level bits (no secrets in the repo)
cp <stick>/agent-instructions.md   ~/.pi/agent/instructions.md
install -m 600 <stick>/github_pat ~/.pi/agent/.github_pat
echo 'export GITHUB_PAT="$(cat ~/.pi/agent/.github_pat)"' >> ~/.bashrc
exec bash                     # so the new env var exists

# 3. project (tools/setup-machine.sh does this and much more)
git clone git@github.com:Irgathane/project_x.git ~/Desktop/project_x
cd ~/Desktop/project_x && pi        # answer "yes" to the trust prompt, or: pi --approve

# 4. verify
pi list                            # both packages listed
# inside pi: /mcp to check the GitHub server, ctx_doctor for context-mode
```

### Vulkan SDK — do not source `setup-env.sh`

Three separate failures came from this, so it is a rule:

`VulkanSDK/*/setup-env.sh` derives `VULKAN_SDK` from `BASH_SOURCE`. Sourced from a
script (`eval "$(source ...)"`, or inside `bash -c`), that resolves to the **caller's**
directory, so `PATH`/`PKG_CONFIG_PATH` point nowhere, meson finds the distro's
Vulkan 1.4.309 (too old), and the build dies on `spirv-opt --canonicalize-ids`.
It also reads `$1`, which is fatal under `set -u`.

Set the paths explicitly instead (the real `.pc` lives in
`x86_64/lib/VulkanLoader/lib/pkgconfig`):

```sh
export VULKAN_SDK="$HOME/VulkanSDK/1.4.363.1/x86_64"
export PATH="$VULKAN_SDK/bin:$PATH"
export PKG_CONFIG_PATH="$VULKAN_SDK/lib/VulkanLoader/lib/pkgconfig:$VULKAN_SDK/share/pkgconfig:$VULKAN_SDK/lib/pkgconfig"
export LD_LIBRARY_PATH="$VULKAN_SDK/lib/VulkanLoader/lib:$VULKAN_SDK/lib:${LD_LIBRARY_PATH:-}"
```

`tools/setup-machine.sh`, `slipgate/launch.sh` and `.pi/extensions/build-quake.ts`
all do exactly this.

---

## 7. Quick reference

| Need | Use |
|---|---|
| edit QuakeC, then build | `build_quake` target `progs` |
| rebuild the map | `build_quake` target `map` |
| play | `build_quake` target `launch` (or `./slipgate/launch.sh`) |
| engine got touched | `build_quake` target `engine` |
| read something huge | `ctx_execute` / `ctx_search`, not `read` |
| session is bloated | `context_prune` (batch of 8–12), recover via `context_tree_query` |
| lost the thread after compaction | `ctx_resume` |
| file an issue / open a PR | GitHub MCP (needs `$GITHUB_PAT`) |
| push code | plain `git` over SSH |