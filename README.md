# Obsidian Infinite Context for Claude Code

> Never lose context again. Give Claude Code a permanent, fully automatic memory backed by your Obsidian vault.

Claude Code's context window is finite  - when it fills up, older conversation history gets compacted or lost. This skill gives Claude a **persistent, searchable long-term memory** stored as Markdown files in your Obsidian vault. It works **completely automatically**  - no manual commands needed. Every preference, decision, mistake, API key, and session is saved and recalled without you lifting a finger.

## What It Does  - Automatically

| Trigger | What Claude Does | Where It's Stored |
|---------|-----------------|-------------------|
| **New conversation starts** | Recalls all project context silently | reads `_PROJECT.md`, `_ERRORS.md`, `_DECISIONS.md`, `_KEYS.md`, recent sessions |
| **You share an API key** | Saves it to the current project immediately | `projects/{name}/_KEYS.md` |
| **You correct Claude or state a preference** | Saves the preference so it never forgets | `_GLOBAL.md` or `_PROJECT.md` |
| **Claude makes a mistake** | Logs the error, root cause, and lesson learned | `projects/{name}/_ERRORS.md` |
| **A technical decision is made** | Logs the decision with full reasoning | `projects/{name}/_DECISIONS.md` |
| **After completing a task** | Writes a session log with full context | `projects/{name}/sessions/` |
| **Conversation getting long** | Proactively saves before context is lost | session log + project updates |
| **You say "forget that" or correct old info** | Searches all memory, deletes/corrects it | all memory files |

**You never have to tell Claude to save or remember anything. It just does it.**
**You can also tell it to forget anything, and it will find and remove it automatically.**

## Per-Project API Keys

The same service can have **different keys in different projects**:

```
Project A (my-saas-app)     →  Stripe: sk_live_abc123
Project B (side-project)    →  Stripe: sk_test_xyz789
Global fallback             →  OpenAI: sk-global-key
```

Just paste a key in conversation and Claude saves it to the right project. When it needs a key later, it checks the current project first, then falls back to global.

## Vault Structure

```
Your Obsidian Vault/
└── Claude-Memory/
    ├── _GLOBAL.md              ← Cross-project preferences
    ├── _KEYS.md                ← Global API keys (fallback)
    └── projects/
        ├── my-web-app/
        │   ├── _PROJECT.md     ← Project master memory
        │   ├── _KEYS.md        ← Project-specific API keys
        │   ├── _ERRORS.md      ← Mistakes + lessons learned
        │   ├── _DECISIONS.md   ← Technical decisions + reasoning
        │   ├── sessions/       ← Conversation logs
        │   └── notes/          ← Reference notes
        └── another-project/
            └── ...
```

Everything is plain Markdown with YAML frontmatter  - fully browsable and searchable in Obsidian.

---

## Installation

### Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and working
- [Obsidian](https://obsidian.md/) installed with an existing vault (or willingness to create one)
- Git (for cloning this repo)

### Option 1: Automated Setup (Recommended)

**1. Clone this repository:**

```bash
git clone https://github.com/backyarddd/obsidian-infinite-context.git
cd obsidian-infinite-context
```

**2. Run the setup script:**

On **macOS / Linux / Git Bash (Windows)**:
```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

On **Windows PowerShell**:
```powershell
.\scripts\setup.ps1
```

The setup script will:
- Auto-detect your Obsidian vault (or ask you for the path)
- Create the `Claude-Memory/` folder structure in your vault
- Install the skill to `~/.claude/skills/obsidian-memory/`
- Save your vault path to `~/.claude/obsidian-memory.json`
- Set up a session-start hook for automatic recall

**3. Restart Claude Code** (or start a new session).

**4. That's it.** Claude will automatically recall context on the next conversation. To verify, just ask: *"What do you remember about this project?"*

---

### Option 2: Manual Installation

**1. Copy the skill file:**

```bash
mkdir -p ~/.claude/skills/obsidian-memory
cp skills/obsidian-memory/SKILL.md ~/.claude/skills/obsidian-memory/SKILL.md
```

**2. Set your vault path**  - pick ONE of these methods:

**Method A: Config file** (recommended)
```bash
mkdir -p ~/.claude
cat > ~/.claude/obsidian-memory.json << 'EOF'
{
  "vaultPath": "/path/to/your/obsidian/vault",
  "memoryDir": "/path/to/your/obsidian/vault/Claude-Memory",
  "created": "2026-03-19",
  "version": "1.0.0"
}
EOF
```

**Method B: Edit SKILL.md directly**
Open `~/.claude/skills/obsidian-memory/SKILL.md` and replace `$OBSIDIAN_VAULT_PATH` with your vault path.

**Method C: Environment variable**
```bash
export OBSIDIAN_VAULT_PATH="/path/to/your/vault"
```

**3. Create the vault structure:**

```bash
VAULT="/path/to/your/obsidian/vault"
mkdir -p "$VAULT/Claude-Memory/projects"
mkdir -p "$VAULT/Claude-Memory/templates"
```

**4. (Optional) Add session-start hook** for an extra recall reminder:

Add to `~/.claude/settings.json`:
```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "echo '[OBSIDIAN MEMORY] Auto-recalling project context from Obsidian vault...'"
          }
        ]
      }
    ]
  }
}
```

> **Note:** If you already have a `settings.json`, merge the hook into your existing config  - don't overwrite the file.

---

### Option 3: One-Liner Install

```bash
git clone https://github.com/backyarddd/obsidian-infinite-context.git && cd obsidian-infinite-context && bash scripts/setup.sh
```

---

## Usage

### It's Automatic

Once installed, you don't need to do anything. Claude will:

1. **Load context** at the start of every conversation
2. **Save API keys** the moment you share them (asks global vs project if ambiguous)
3. **Remember preferences** when you correct it or state one
4. **Log mistakes** so they don't repeat
5. **Record decisions** with reasoning for future reference
6. **Write session logs** at natural stopping points
7. **Forget on command** - say "forget that" or "that's wrong" and it searches all memory and removes it

### Manual Commands (Optional)

You can still invoke the skill manually if needed:

| Command | Description |
|---------|-------------|
| `/obsidian-memory` | Show status overview of all projects |
| `/obsidian-memory search [query]` | Search across all memory files |
| `/obsidian-memory forget [topic]` | Search and delete specific memories |
| `/obsidian-memory scan` | Deep-scan current project and build memory from scratch |

### Project Scanning

For **existing projects** that you're onboarding into the memory system:

```
/obsidian-memory scan
```

Claude will read through your entire project - package files, configs, source structure, README, CI/CD, database schemas - and build a full set of memory files as if it had been there from the start. It captures:

- Tech stack and dependencies
- Project architecture and folder patterns
- Build/run/test commands
- Environment setup
- Deployment configuration
- Inferred architectural decisions (marked as inferred so you know they weren't explicitly discussed)

### API Keys in Practice

Just share keys naturally in conversation:

> "Here's my Stripe key: sk_test_abc123"

Claude automatically:
1. Detects the key
2. Identifies the service (Stripe)
3. Saves it to the current project's `_KEYS.md`
4. Confirms briefly: *"Saved your Stripe key to Obsidian."*

Next conversation, Claude already knows the key without you sharing it again. Different projects get different keys.

---

## Browsing in Obsidian

All memory files are standard Markdown  - open your vault and browse to `Claude-Memory/`:

- **Search**  - find anything across all sessions
- **Graph view**  - see connections between notes via wikilinks
- **Tags**  - filter by `#error`, `#decision`, `#preference`, `#key`
- **Edit directly**  - Claude picks up your changes
- **Dataview** plugin  - advanced queries across your memory

---

## Configuration

### Config File

`~/.claude/obsidian-memory.json`:

```json
{
  "vaultPath": "/path/to/vault",
  "memoryDir": "/path/to/vault/Claude-Memory",
  "created": "2026-03-19",
  "version": "1.0.0"
}
```

### Environment Variable

```bash
export OBSIDIAN_VAULT_PATH="/path/to/your/vault"
```

Takes priority over the config file.

### Multiple Vaults

Set `OBSIDIAN_VAULT_PATH` per-project in your shell config. The skill writes to one vault at a time.

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "No vault path found" | Run setup script, create config file manually, or set `OBSIDIAN_VAULT_PATH` env var |
| Skill not showing up | Verify `~/.claude/skills/obsidian-memory/SKILL.md` exists, restart Claude Code |
| Files not in Obsidian | Make sure `Claude-Memory/` is inside vault root (not `.obsidian/`) |
| Keys not being saved | Say the key explicitly in conversation  - Claude detects patterns like `sk-...`, `pk_...` |

---

## Project Structure

```
obsidian-infinite-context/
├── README.md
├── LICENSE
├── .gitignore
├── skills/
│   └── obsidian-memory/
│       └── SKILL.md            # The Claude Code skill (this is the brain)
└── scripts/
    ├── setup.sh                # Setup for macOS / Linux / Git Bash
    └── setup.ps1               # Setup for Windows PowerShell
```

---

## Contributing

Contributions welcome! Ideas:

- [ ] MCP server wrapper for richer Obsidian integration
- [ ] Obsidian plugin companion for browsing Claude memory
- [ ] Multi-vault support
- [ ] Memory export/import between machines
- [ ] Encryption for sensitive API keys at rest
- [ ] Auto-tagging and categorization of session logs

---

## License

MIT  - see [LICENSE](LICENSE).

---

Built for the Claude Code community. If this saves your context, star the repo!
