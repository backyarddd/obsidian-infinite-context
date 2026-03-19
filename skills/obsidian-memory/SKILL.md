---
name: obsidian-memory
description: >
  ALWAYS ACTIVE. Infinite context memory via Obsidian vault. This skill MUST auto-invoke at:
  (1) every conversation start to recall project context,
  (2) whenever the user shares an API key, token, secret, or credential — save it immediately,
  (3) whenever the user states a preference or corrects you — save it,
  (4) whenever a mistake is made — log it,
  (5) whenever a significant decision is made — log it,
  (6) periodically during long conversations to save session progress,
  (7) before the conversation ends or context gets long — save everything.
  This skill is your persistent brain. Use it aggressively without being asked.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(cat *), Bash(mkdir *), Bash(date *), Bash(ls *)
argument-hint: "[search query]"
---

# Obsidian Infinite Context — Autonomous Memory System

You have a persistent long-term brain stored in an Obsidian vault. It survives context compaction
and works across separate conversations. **You MUST use it automatically. The user should never
have to ask you to save or recall — just do it silently.**

## Vault Location

The Obsidian vault is at: `$OBSIDIAN_VAULT_PATH`

If `$OBSIDIAN_VAULT_PATH` is not set, read `~/.claude/obsidian-memory.json` for the `vaultPath`
field. If neither exists, ask the user once, then save their answer to the config file so you
never have to ask again.

All memory lives under: `{vault}/Claude-Memory/`

## Directory Structure

```
Claude-Memory/
├── _GLOBAL.md              # Cross-project preferences, global settings
├── _KEYS.md                # Global API keys (fallback for all projects)
├── projects/
│   └── {project-name}/
│       ├── _PROJECT.md     # Project master memory
│       ├── _KEYS.md        # Project-specific API keys
│       ├── _ERRORS.md      # Mistakes + lessons learned (append-only)
│       ├── _DECISIONS.md   # Technical decisions + reasoning (append-only)
│       ├── sessions/
│       │   └── {YYYY-MM-DD}_{HH-MM}_{topic}.md
│       └── notes/
│           └── {topic}.md
└── templates/
    ├── session.md
    └── project.md
```

## Project Name Detection

Determine the project name from (in order):
1. Current working directory basename
2. `package.json` name field
3. `.git` remote origin name
4. Ask the user (then save it so you never ask again)

---

# AUTOMATIC BEHAVIORS — DO ALL OF THESE WITHOUT BEING ASKED

## 1. AUTO-RECALL: Every Conversation Start

**When**: First message of any conversation.
**Action**: Silently read all project memory and internalize it:

1. Read `~/.claude/obsidian-memory.json` to get vault path
2. Read `_GLOBAL.md` for cross-project preferences
3. Read `projects/{project}/_PROJECT.md` for project memory
4. Read `projects/{project}/_ERRORS.md` to avoid past mistakes
5. Read `projects/{project}/_DECISIONS.md` for architectural context
6. Read `projects/{project}/_KEYS.md` for API keys
7. Read the latest 3 session logs from `projects/{project}/sessions/`
8. If the project folder doesn't exist yet, create it with empty template files

**How to present**: Don't dump all the memory at the user. Just internalize it and say
something brief like "Loaded project context from Obsidian." Only mention specifics if
they're directly relevant to what the user is asking about.

## 2. AUTO-SAVE API KEYS: Whenever a Key Appears

**When**: The user shares ANY of these in conversation:
- API keys (e.g., `sk-...`, `pk_...`, `key_...`)
- Tokens (bearer tokens, access tokens, refresh tokens)
- Secrets (client secrets, webhook secrets)
- Credentials (usernames + passwords for services)
- Connection strings (database URLs, Redis URLs)
- Environment variable values that contain credentials

**Action**: IMMEDIATELY save to the project's `_KEYS.md`:

```markdown
## {Service Name}
- **Key**: `{the-key}`
- **Type**: {api-key|token|secret|credential|connection-string}
- **Environment**: {production|staging|development|unknown}
- **Added**: {YYYY-MM-DD}
- **Notes**: {any context from the conversation}
```

**Scope detection — global vs project**:
When the user shares a key, determine where to save it:

1. **Auto-detect as PROJECT key** (save silently) when:
   - The user explicitly says "for this project" or mentions the project name
   - The key is shared while working on project-specific code
   - The key is clearly environment-specific (e.g., "here's my staging key")

2. **Auto-detect as GLOBAL key** (save silently) when:
   - The user explicitly says "use this for all projects" or "global"
   - It's a general-purpose key not tied to any project (e.g., a personal OpenAI key)

3. **ASK the user** when scope is ambiguous:
   - Say: "Is this [service] key just for this project ({project-name}), or should I save it globally for all projects?"
   - Then save to the appropriate `_KEYS.md` based on their answer

**Other key rules**:
- Each project has its OWN `_KEYS.md` — the same service CAN have different keys per project
- When looking up a key: check project `_KEYS.md` first, then global `_KEYS.md`
- If a key already exists for that service in this project, UPDATE it (don't duplicate)
- Briefly confirm: "Saved your [service] key to Obsidian ({scope})."

## 3. AUTO-SAVE PREFERENCES: Whenever the User Corrects or Instructs

**When**: The user says things like:
- "Don't do X" / "Stop doing X" / "I prefer Y" / "Always use Z"
- "I like when you..." / "Never..." / "From now on..."
- Any correction to your behavior or output
- Any stated preference about code style, communication, tools, etc.

**Action**: Update `_GLOBAL.md` (if cross-project) or `_PROJECT.md` (if project-specific):
- Add the preference under the appropriate section
- Include WHY if the user gave a reason
- If a preference contradicts an existing one, replace the old one

**Do NOT ask** "Should I save this?" — just save it silently. If it's notable, briefly
confirm: "Noted, I'll remember that."

## 4. AUTO-LOG ERRORS: Whenever a Mistake Happens

**When**: Any of these occur:
- You produce code that fails/errors
- The user says "no", "wrong", "that's not right", "you broke it"
- A test fails because of something you did
- You misunderstand the user's request
- You repeat a mistake that was already in `_ERRORS.md`

**Action**: Append to `projects/{project}/_ERRORS.md`:

```markdown
## {YYYY-MM-DD} — {short description}
**What happened**: {description}
**Root cause**: {why it happened}
**Fix**: {how it was fixed}
**Lesson**: {what to do differently next time}
**Tags**: #error #{category}
```

## 5. AUTO-LOG DECISIONS: Whenever a Technical Choice Is Made

**When**:
- Choosing between frameworks, libraries, or approaches
- Architectural decisions (database schema, API design, folder structure)
- The user explains WHY something is done a certain way
- Trade-offs are discussed and a direction is chosen

**Action**: Append to `projects/{project}/_DECISIONS.md`:

```markdown
## {YYYY-MM-DD} — {decision title}
**Decision**: {what was decided}
**Alternatives considered**: {what else was considered}
**Reasoning**: {why this choice}
**Consequences**: {what this means going forward}
**Tags**: #decision #{category}
```

## 6. AUTO-LOG SESSIONS: Periodically During Long Conversations

**When**:
- After completing a significant task or feature
- After a natural stopping point in the conversation
- When the conversation is getting long (you've exchanged 20+ messages)
- When switching to a completely different topic
- Before the user seems to be wrapping up ("thanks", "that's all", "bye")

**Action**: Create a session log at `projects/{project}/sessions/{YYYY-MM-DD}_{HH-MM}_{topic}.md`:

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
{what the next session needs to know to continue seamlessly}
```

**Rules for session logs**:
- Never store full file contents — just paths and summaries
- One log per major topic/task, not per message
- Focus on WHAT and WHY, not play-by-play
- The "Context for Next Session" section is the most important — write it as if briefing
  a colleague who will pick up your work tomorrow

## 7. AUTO-SAVE ON CONTEXT PRESSURE: Before Things Get Lost

**When**: The conversation has been going for a while and you've accumulated significant
context that hasn't been saved yet.

**Action**: Proactively write a session log + update `_PROJECT.md` with anything new.
Don't announce this — just do it quietly. If asked, you can mention you saved progress.

---

# MANUAL COMMANDS (when user invokes /obsidian-memory directly)

### `/obsidian-memory` (no args) — Status Overview
Show: all projects, last session date, key counts, memory file sizes.

### `/obsidian-memory search [query]`
Grep across all files in `Claude-Memory/` for the query. Show results grouped by file.

---

# FILE FORMATS

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
- **Type**: {api-key|token|secret|credential|connection-string}
- **Environment**: {production|staging|development}
- **Added**: {date}
- **Notes**: {context}
```

---

# IMPORTANT RULES

1. **Be silent about most saves** — don't narrate every write. Brief confirmations only for keys and major saves.
2. **Always append** to `_ERRORS.md` and `_DECISIONS.md` — never overwrite old entries.
3. **API keys are per-project by default** — same service CAN have different keys per project.
4. **Check project keys first**, then fall back to global.
5. **Use Obsidian wikilinks** (`[[note name]]`) when cross-referencing.
6. **Add YAML frontmatter** to every file.
7. **Use tags** liberally (`#error`, `#decision`, `#preference`, `#key`) for searchability.
8. **Create directories** with `mkdir -p` before writing if they don't exist.
9. **Date format**: YYYY-MM-DD for dates, HH-MM for times in filenames.
10. **Keep session logs focused** — one per major topic, not one per message.
11. **Never store full file contents** in logs — just paths and change summaries.
12. **The user should never have to tell you to save** — if something is worth remembering, save it.
