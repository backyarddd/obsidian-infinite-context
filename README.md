# Obsidian Infinite Context for Claude Code

> Never lose context again. Give Claude Code a permanent memory backed by your Obsidian vault.

Claude Code's context window is finite — when it fills up, older conversation history gets compacted or lost. This skill gives Claude a **persistent, searchable long-term memory** stored as Markdown files in your Obsidian vault. Every preference, decision, mistake, and session is saved and can be recalled at any time — across conversations, across days, across projects.

## What It Does

- **Master Memory** — Per-project file storing preferences, patterns, architecture notes, and anything Claude needs to remember permanently
- **Per-Project API Keys** — Store different API keys for the same service across different projects (e.g., Stripe test key for Project A, Stripe prod key for Project B)
- **Session Logs** — Automatic logging of what was discussed, decided, built, and left unfinished
- **Error Journal** — Every mistake Claude makes gets logged with the fix and lesson learned, so it never repeats
- **Decision Log** — Technical decisions with full reasoning, so future sessions understand *why* things are the way they are
- **Auto-Recall** — Claude loads project context at the start of every conversation
- **Full Search** — Search across all memory files for any topic
- **Obsidian-Native** — Everything is plain Markdown with YAML frontmatter, wikilinks, and tags — fully browsable in Obsidian

## How It Works

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

Claude reads and writes to these files using standard file operations. No plugins, no servers, no APIs — just your vault folder.

---

## Installation

### Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and working
- [Obsidian](https://obsidian.md/) installed with an existing vault (or willingness to create one)
- Git (for cloning this repo)

### Option 1: Automated Setup (Recommended)

**1. Clone this repository:**

```bash
git clone https://github.com/davo-codes/obsidian-infinite-context.git
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
- Optionally set up a session-start hook

**3. Restart Claude Code** (or start a new session).

**4. Test it:**
```
/obsidian-memory status
```

---

### Option 2: Manual Installation

If you prefer to set things up yourself:

**1. Copy the skill file:**

```bash
# Create the skill directory
mkdir -p ~/.claude/skills/obsidian-memory

# Copy SKILL.md from this repo
cp skills/obsidian-memory/SKILL.md ~/.claude/skills/obsidian-memory/SKILL.md
```

**2. Edit the vault path in the skill file:**

Open `~/.claude/skills/obsidian-memory/SKILL.md` and replace `$OBSIDIAN_VAULT_PATH` with your actual vault path:

```
# Find this line:
The Obsidian vault is at: `$OBSIDIAN_VAULT_PATH`

# Replace with your path:
The Obsidian vault is at: `/Users/you/Documents/My Vault`
```

**3. Create the config file:**

```bash
# Create the config
cat > ~/.claude/obsidian-memory.json << 'EOF'
{
  "vaultPath": "/path/to/your/obsidian/vault",
  "memoryDir": "/path/to/your/obsidian/vault/Claude-Memory",
  "created": "2026-03-19",
  "version": "1.0.0"
}
EOF
```

**4. Create the vault structure:**

```bash
VAULT="/path/to/your/obsidian/vault"
mkdir -p "$VAULT/Claude-Memory/projects"
mkdir -p "$VAULT/Claude-Memory/templates"
```

**5. (Optional) Add session-start hook:**

Add this to your `~/.claude/settings.json` (create the file if it doesn't exist):

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "echo '[OBSIDIAN MEMORY] Use /obsidian-memory recall to load project context'"
          }
        ]
      }
    ]
  }
}
```

> **Note:** If you already have a `settings.json`, merge the hook into your existing `hooks.SessionStart` array — don't overwrite the file.

---

### Option 3: One-Liner Install

If you just want to get going fast:

```bash
git clone https://github.com/davo-codes/obsidian-infinite-context.git && cd obsidian-infinite-context && bash scripts/setup.sh
```

---

## Usage

### Manual Commands

| Command | Description |
|---------|-------------|
| `/obsidian-memory recall` | Load all context for current project |
| `/obsidian-memory save` | Save current conversation context |
| `/obsidian-memory search [query]` | Search across all memory files |
| `/obsidian-memory log` | Quick session log (lightweight save) |
| `/obsidian-memory keys list` | List all API keys across projects |
| `/obsidian-memory keys set [service] [key]` | Set an API key for current project |
| `/obsidian-memory keys get [service]` | Get an API key (project-first, then global) |
| `/obsidian-memory keys global set [service] [key]` | Set a global API key |
| `/obsidian-memory status` | Show memory overview across all projects |

### Auto-Behavior

Claude will also use the memory system automatically:
- **Recalls context** at the start of conversations
- **Saves important info** when it learns something new (preferences, corrections)
- **Logs mistakes** in the error journal when things go wrong
- **Records decisions** when architectural choices are made
- **Proactively saves** before context gets too long

### API Keys — Per-Project

The key feature: **different API keys for the same service across projects**.

```
# In project "my-saas-app":
/obsidian-memory keys set stripe sk_live_abc123

# In project "side-project":
/obsidian-memory keys set stripe sk_test_xyz789

# Global fallback:
/obsidian-memory keys global set openai sk-global-key
```

When Claude looks up a key, it checks the current project first, then falls back to global.

---

## Browsing in Obsidian

All memory files are standard Markdown — open Obsidian and browse to `Claude-Memory/` to see everything. You can:

- Use Obsidian's **search** to find anything across all sessions
- Use **graph view** to see connections between notes (via wikilinks)
- Use **tags** (`#error`, `#decision`, `#preference`) to filter
- Edit files directly — Claude will pick up your changes
- Use **Dataview** plugin for advanced queries across your memory

---

## Configuration

### Config File

The config lives at `~/.claude/obsidian-memory.json`:

```json
{
  "vaultPath": "/path/to/vault",
  "memoryDir": "/path/to/vault/Claude-Memory",
  "created": "2026-03-19",
  "version": "1.0.0"
}
```

### Environment Variable

You can also set the vault path via environment variable:

```bash
export OBSIDIAN_VAULT_PATH="/path/to/your/vault"
```

This takes priority over the config file.

### Multiple Vaults

If you use multiple Obsidian vaults, set `OBSIDIAN_VAULT_PATH` per-project in your shell config or use the config file. The skill always writes to one vault at a time.

---

## Troubleshooting

### "No vault path found"
- Run the setup script again, or
- Create `~/.claude/obsidian-memory.json` manually with your vault path, or
- Set the `OBSIDIAN_VAULT_PATH` environment variable

### Skill not showing up
- Make sure `~/.claude/skills/obsidian-memory/SKILL.md` exists
- Restart Claude Code
- Try `/obsidian-memory status` to test

### Files not appearing in Obsidian
- Check that `Claude-Memory/` is inside your vault root (not in `.obsidian/`)
- Obsidian auto-detects new files — they should appear within seconds

### Context still getting lost
- Make sure you `save` before long conversations
- Use `/obsidian-memory recall` at the start of new sessions
- The session-start hook helps automate this

---

## Project Structure

```
obsidian-infinite-context/
├── README.md                           # This file
├── LICENSE                             # MIT License
├── .gitignore
├── skills/
│   └── obsidian-memory/
│       └── SKILL.md                    # The Claude Code skill
└── scripts/
    ├── setup.sh                        # Setup for macOS/Linux/Git Bash
    └── setup.ps1                       # Setup for Windows PowerShell
```

---

## Contributing

Contributions welcome! Some ideas:

- [ ] MCP server wrapper for richer Obsidian integration
- [ ] Auto-compaction hook that saves before context is lost
- [ ] Obsidian plugin companion for browsing Claude memory
- [ ] Multi-vault support
- [ ] Memory export/import between machines
- [ ] Encryption for sensitive API keys

---

## License

MIT — see [LICENSE](LICENSE).

---

Built for the Claude Code community. If this helps you, star the repo!
