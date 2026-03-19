---
name: obsidian-memory
description: >
  Infinite context memory system using Obsidian vault. Use this skill to persist conversation context,
  preferences, API keys (per-project), decisions, errors, and session logs so nothing is lost during
  context compaction. Auto-invokes when context should be saved or recalled. Also invocable manually
  with /obsidian-memory to save, recall, search, or manage persistent memory.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(cat *), Bash(mkdir *), Bash(date *), Bash(ls *)
argument-hint: "[save|recall|search|log|keys|status] [query]"
---

# Obsidian Infinite Context Memory System

You have access to an Obsidian vault for persistent memory that survives context compaction and even
across entirely separate conversations. This is your long-term brain. USE IT AGGRESSIVELY.

## Vault Location

The Obsidian vault is at: `$OBSIDIAN_VAULT_PATH`

If `$OBSIDIAN_VAULT_PATH` is not set, check for a config file at `~/.claude/obsidian-memory.json`
and read the `vaultPath` field. If neither exists, ask the user for their vault path.

All memory lives under: `{vault}/Claude-Memory/`

## Directory Structure

```
Claude-Memory/
├── _GLOBAL.md              # Cross-project preferences, global settings
├── _KEYS.md                # API keys index (links to per-project key files)
├── projects/
│   └── {project-name}/
│       ├── _PROJECT.md     # Project master memory (preferences, patterns, architecture)
│       ├── _KEYS.md        # Project-specific API keys and credentials
│       ├── _ERRORS.md      # Mistakes made + lessons learned (append-only)
│       ├── _DECISIONS.md   # Key technical decisions + reasoning
│       ├── sessions/
│       │   └── {YYYY-MM-DD}_{HH-MM}_{topic}.md  # Session logs
│       └── notes/
│           └── {topic}.md  # Standalone reference notes
└── templates/
    ├── session.md
    └── project.md
```

## Project Name Detection

Determine the project name from (in order):
1. The current working directory basename
2. `package.json` name field
3. `.git` remote origin name
4. Ask the user

## Commands

When invoked with `/obsidian-memory`, check the first argument:

### `save` — Save Current Context
Write a session log capturing:
- What was discussed and decided
- Code changes made (file paths + summaries, not full code)
- Problems encountered and how they were solved
- Any preferences or patterns discovered
- Update `_PROJECT.md` if new persistent info was learned
- Update `_ERRORS.md` if mistakes were made
- Update `_DECISIONS.md` if key decisions were made

### `recall` — Load Context for Current Project
Read and present:
1. `_GLOBAL.md` for cross-project preferences
2. `_PROJECT.md` for project-specific memory
3. `_ERRORS.md` to avoid past mistakes
4. `_DECISIONS.md` for architectural context
5. Latest 2-3 session logs for recent work context
6. `_KEYS.md` for available API keys

### `search [query]` — Search All Memory
Use Grep to search across all files in `Claude-Memory/` for the query.
Present results grouped by file with context.

### `log` — Quick Session Log
Write a quick session log without the full save workflow. Just capture what happened.

### `keys [action]` — Manage API Keys
Actions:
- `keys list` — Show all keys across all projects
- `keys set [service] [key]` — Set a key for current project
- `keys get [service]` — Get a key for current project
- `keys global set [service] [key]` — Set a global key
Keys are stored in `_KEYS.md` files with this format:

```markdown
## {Service Name}
- **Key**: `{api-key}`
- **Environment**: {production|staging|development}
- **Added**: {date}
- **Notes**: {any notes}
```

Each project has its OWN `_KEYS.md`. The same service (e.g., OpenAI, Stripe) can have
DIFFERENT keys in different projects. When looking up a key, check project-level first,
then fall back to global.

### `status` — Show Memory Status
List all projects, their last session date, and memory file sizes.

## Auto-Behavior (When Claude Decides to Invoke)

Claude should auto-invoke this skill in these situations:

1. **Start of conversation**: Always `recall` at the beginning to load context.
   Check if there's existing memory for the current project.

2. **Before context compaction**: If you sense the context is getting long,
   proactively `save` important context before it's lost.

3. **After learning something important**: When the user corrects you, shares a
   preference, or you discover a project pattern — save it immediately.

4. **After making a mistake**: Log it in `_ERRORS.md` with the fix so it never
   happens again.

5. **After a significant decision**: Log architectural or design decisions with
   full reasoning in `_DECISIONS.md`.

## File Formats

### _GLOBAL.md
```markdown
---
updated: {date}
---
# Global Preferences

## Communication Style
{how the user likes to interact}

## Coding Preferences
{languages, frameworks, patterns they prefer}

## General Rules
{things that apply across all projects}
```

### _PROJECT.md
```markdown
---
project: {name}
created: {date}
updated: {date}
---
# {Project Name} — Master Memory

## Overview
{what this project is}

## Tech Stack
{languages, frameworks, tools}

## Preferences
{project-specific preferences}

## Patterns
{coding patterns used in this project}

## Architecture
{key architectural notes}

## Team / Context
{who works on this, deployment info, etc.}
```

### _KEYS.md (per-project)
```markdown
---
project: {name}
updated: {date}
---
# API Keys — {Project Name}

## {Service Name}
- **Key**: `{api-key}`
- **Environment**: {production|staging|development}
- **Added**: {date}
- **Notes**: {any notes}

## {Another Service}
- **Key**: `{different-key}`
- **Environment**: {production}
- **Added**: {date}
- **Notes**: {any notes}
```

### _ERRORS.md
```markdown
---
project: {name}
updated: {date}
---
# Error Journal — {Project Name}

## {date} — {short description}
**What happened**: {description}
**Root cause**: {why it happened}
**Fix**: {how it was fixed}
**Lesson**: {what to do differently next time}
**Tags**: {relevant tags}
```

### Session Log
```markdown
---
project: {name}
date: {YYYY-MM-DD}
time: {HH:MM}
topic: {main topic}
---
# Session: {topic}

## Summary
{2-3 sentence overview}

## What Was Done
- {action 1}
- {action 2}

## Decisions Made
- {decision}: {reasoning}

## Problems & Solutions
- **Problem**: {description}
  **Solution**: {how it was solved}

## Code Changes
- `{file path}`: {what changed and why}

## Open Items
- {anything left unfinished}

## Context for Next Session
{what the next session needs to know to continue}
```

## Important Rules

1. **Never store full file contents** in session logs — just paths and summaries
2. **Always append** to `_ERRORS.md` and `_DECISIONS.md`, never overwrite
3. **API keys are per-project by default** — the same service CAN have different keys in different projects
4. **Check project keys first**, then fall back to global keys
5. **Use Obsidian wikilinks** (`[[note name]]`) when cross-referencing between files
6. **Add frontmatter** to every file for Obsidian compatibility
7. **Use tags** liberally (e.g., `#error`, `#decision`, `#preference`) for searchability
8. **Create directories** before writing files if they don't exist
9. **Date format**: Always use YYYY-MM-DD for dates, HH-MM for times in filenames
10. **Keep session logs focused** — one log per major topic/task, not one per message
