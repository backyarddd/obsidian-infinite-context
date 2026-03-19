---
name: obsidian-memory
description: >
  ALWAYS ACTIVE. Infinite context memory via Obsidian vault. This skill MUST auto-invoke at:
  (1) every conversation start to recall project context,
  (2) whenever the user shares an API key, token, secret, or credential  - save it immediately,
  (3) whenever the user states a preference or corrects you  - save it,
  (4) whenever a mistake is made  - log it,
  (5) whenever a significant decision is made  - log it,
  (6) periodically during long conversations to save session progress,
  (7) before the conversation ends or context gets long  - save everything,
  (8) when the user says to forget something  - find and delete that memory,
  (9) when the user says "forget that" or "that's wrong" about something previously saved  - auto-search and remove it.
  This skill is your persistent brain. Use it aggressively without being asked.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(cat *), Bash(mkdir *), Bash(date *), Bash(ls *), Bash(rm *)
argument-hint: "[search|forget|scan] [query]"
---

# Obsidian Infinite Context  - Autonomous Memory System

You have a persistent long-term brain stored in an Obsidian vault. It survives context compaction
and works across separate conversations. **You MUST use it automatically. The user should never
have to ask you to save or recall  - just do it silently.**

## Vault Location

The Obsidian vault is at: `C:/Users/david/Documents/Obsidian Vault`

If `C:/Users/david/Documents/Obsidian Vault` is not set, read `~/.claude/obsidian-memory.json` for the `vaultPath`
field. If neither exists, ask the user once, then save their answer to the config file so you
never have to ask again.

All memory lives under: `{vault}/Claude-Memory/`

## Directory Structure

```
Claude-Memory/
├── _GLOBAL.md              # Cross-project preferences, global settings
├── _KEYS.md                # Global API keys (fallback for all projects)
├── _DISABLED.md            # Projects that have opted out of memory tracking
├── projects/
│   └── {project-name}/
│       ├── _PROJECT.md     # Project master memory
│       ├── _KEYS.md        # Project-specific API keys
│       ├── _ERRORS.md      # Mistakes + lessons learned (append-only)
│       ├── _DECISIONS.md   # Technical decisions + reasoning (append-only)
│       ├── sessions/
│       │   └── {YYYY-MM-DD}_{HH-MM}_{topic}.md
│       ├── notes/
│       │   └── {topic}.md
│       └── _snapshots/
│           └── {YYYY-MM-DD}_{HH-MM}/   # Rollback snapshots (max 5)
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

## Project Opt-Out (Disabled Projects)

The user can disable Obsidian memory for specific projects. They might say things like:
- "Don't use obsidian memory for this project"
- "Skip the vault stuff here, it's too small"
- "I don't need memory for this one"
- "No obsidian for this project"
- Or any similar phrasing that indicates they don't want memory tracking

**When the user opts out of a project**:
1. Save the project name to a `_DISABLED.md` file in `Claude-Memory/`:
   ```markdown
   ## {project-name}
   - **Disabled**: {date}
   - **Reason**: {what the user said}
   ```
2. Confirm: "Got it, I won't use Obsidian memory for {project}."
3. **Stop all automatic behaviors** for that project  - no recall, no saving, no logging,
   no key storage, nothing. The skill becomes completely invisible.

**During recall**, always check `_DISABLED.md` first. If the current project is listed,
skip everything silently  - don't even mention Obsidian.

**Re-enabling**: If the user later says "turn obsidian back on for this project" or
"actually, let's use memory here", remove the project from `_DISABLED.md` and resume
normal behavior.

---

# AUTOMATIC BEHAVIORS  - DO ALL OF THESE WITHOUT BEING ASKED

**IMPORTANT**: Before executing ANY automatic behavior, check `_DISABLED.md` first.
If the current project is listed there, do NOTHING. Skip silently.

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

**Session continuity**: Check the most recent session log for an "Open Items" section.
If there are unfinished items, surface them to the user:
"Last session you left off with these open items:
- {item 1}
- {item 2}
Want to pick up where you left off?"

**Memory conflict detection**: While recalling, compare memory against the current
codebase state. If something contradicts (e.g., memory says "uses React" but you see
Vue in package.json, or memory says a file exists that doesn't), flag it:
"I noticed a conflict - my memory says {X} but the codebase shows {Y}. Which is correct?"
Then update or delete the outdated memory based on the user's answer.

**Staleness check**: When reading memories, note entries that haven't been updated or
referenced in 30+ days (check the date in frontmatter or entry timestamps). Don't flag
them during recall - but if a stale memory becomes relevant later in conversation,
ask before acting on it:
"I have a note from {date} that says {X}. Is this still accurate, or has it changed?"
Update or remove based on the answer.

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

**Scope detection  - global vs project**:
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
- Each project has its OWN `_KEYS.md`  - the same service CAN have different keys per project
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

**Do NOT ask** "Should I save this?"  - just save it silently. If it's notable, briefly
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
## {YYYY-MM-DD}  - {short description}
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
## {YYYY-MM-DD}  - {decision title}
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

## Memory Stats
- Preferences saved: {count}
- Errors logged: {count}
- Decisions logged: {count}
- Keys saved: {count}
- Memories forgotten/corrected: {count}
```

**Rules for session logs**:
- Never store full file contents  - just paths and summaries
- One log per major topic/task, not per message
- Focus on WHAT and WHY, not play-by-play
- The "Context for Next Session" section is the most important  - write it as if briefing
  a colleague who will pick up your work tomorrow

## 7. AUTO-FORGET: When the User Corrects a Memory or Says to Forget

**When**: The user says things like:
- "Forget that" / "That's wrong" / "Delete that memory"
- "Actually, that's not right" / "I was wrong about X"
- "Remove that" / "I don't want you to remember X"
- "That's outdated" / "We're not doing X anymore"
- Any correction to previously saved information

**Action**:

1. **Search all memory files** for the incorrect/outdated information using Grep
   across the entire `Claude-Memory/` directory
2. **Show what was found** - list the file(s) and the specific content that matches
3. **Delete or update** the content:
   - If the entire entry is wrong: remove the full section (e.g., the whole `## heading` block)
   - If part of an entry is wrong: edit just the incorrect part
   - If it's in `_ERRORS.md` or `_DECISIONS.md`: don't delete the entry, instead append a
     correction note: `**CORRECTED {date}**: {what was wrong and the correct info}`
   - If it's an API key: remove it entirely from `_KEYS.md`
   - If it's a preference in `_GLOBAL.md` or `_PROJECT.md`: remove or replace it
   - If it's in a session log: add a correction note at the top of the session file
4. **Confirm** briefly: "Removed/corrected that from Obsidian memory."

**Rules for forgetting**:
- Search broadly - check ALL memory files, not just the obvious ones
- If multiple files contain the info, fix all of them
- When in doubt about what to delete, show the user what you found and ask which to remove
- Never silently ignore a forget request - always confirm what was done
- If nothing is found, say so: "I couldn't find that in my Obsidian memory. Could you be more specific?"

## 8. AUTO-COMPACT AT 75%: Save Everything Then Compact

**THIS IS CRITICAL. YOU MUST ACTIVELY MONITOR CONTEXT USAGE.**

You CANNOT see the exact context percentage, so you MUST count and estimate aggressively.
Use these heuristics to determine when you're at ~75%:

**Hard triggers (if ANY of these are true, you're likely at 75%+)**:
- You have exchanged 15+ back-and-forth messages with substantial content
- You have read 5+ files during this session
- You have made 10+ tool calls total
- You have generated large code blocks (100+ lines total across the session)
- You feel like earlier messages in the conversation are becoming unclear or distant
- The user has mentioned context percentage (e.g., "86% used")

**Count your messages.** After every response, mentally track: "This is message ~N."
When you hit message 15+, START the save-and-compact process.

**DO NOT WAIT for the user to tell you.** By 86% it is already too late. Act at 75%.

**Action** (do ALL of these in ONE turn, then compact):
1. **Save EVERYTHING to Obsidian first**:
   - Write a comprehensive session log covering ALL work done so far
   - Update `_PROJECT.md` with any new info learned
   - Update `_ERRORS.md`, `_DECISIONS.md` if applicable
   - Save any unsaved preferences or keys
   - Make sure the session log's "Context for Next Session" section is detailed enough
     to fully reconstruct what was happening
   - Include ALL open tasks, current state of work, and what needs to happen next
2. **Tell the user**: "Context is getting full (~75%). Saving everything to Obsidian now and compacting."
3. **Run `/compact`** to free up the context window
4. **After compaction**, immediately recall from Obsidian to reload the most important
   context back into the now-freed window

**IMPORTANT**: If the user mentions the context percentage or you see it referenced
anywhere, USE THAT NUMBER. If it's above 70%, start saving immediately.

This way nothing is ever lost to compaction. It's all in Obsidian before the context
gets cleared, and the most relevant stuff gets reloaded right after.

## 9. CROSS-PROJECT LEARNING: Generalize Solutions Across Projects

**When**: You solve a tricky problem, discover a useful pattern, or find a clever
workaround that could apply to other projects too.

**Action**:
1. **Ask the user first**: "This solution for {problem} could be useful across your
   other projects too. Want me to save a generalized version to your global memory?"
2. If they say yes, add a generalized version to `_GLOBAL.md` under a new section
   `## Learned Patterns`:

```markdown
## Learned Patterns

### {Pattern Name} (from [[{project-name}]])
**Problem**: {generalized problem description}
**Solution**: {generalized solution, not project-specific}
**Discovered**: {date}
**Tags**: #pattern #{category}
```

3. Use wikilinks back to the original project so the user can trace where it came from.

**Never auto-save cross-project learnings without asking.** The user must confirm.

## 10. DEPENDENCY AND VERSION TRACKING

**When**:
- During a `/obsidian-memory scan`
- When you notice dependency changes during normal work (e.g., reading package.json)
- When the user installs/upgrades/removes a dependency

**Action**: Maintain a `## Dependencies` section in `_PROJECT.md`:

```markdown
## Dependencies (Key)
- **{package}**: v{version} - {what it's used for}
- **{package}**: v{version} - {what it's used for}
**Last checked**: {date}
```

Only track key dependencies (frameworks, ORMs, auth libs, etc.), not every utility package.

When recalling, if you notice a version changed since last recorded, flag it:
"Heads up - {package} changed from v{old} to v{new} since my last note. Any breaking
changes I should know about?"

## 11. NEVER ASSUME - ASK WHEN UNSURE

**This overrides all other behaviors.** If you are unsure about ANY of the following,
ASK the user instead of guessing:

- Whether something is a preference or a one-time instruction
- Whether an API key is for this project or global
- Whether a decision is final or still being explored
- Whether a correction means "delete the old info" or "update it"
- Whether a pattern should be saved cross-project
- What a piece of information means or how it should be categorized
- Whether a stale memory is still valid
- Whether conflicting information should replace the old or coexist

**When in doubt, ask a short clarifying question.** A quick question is always better
than saving wrong information that has to be corrected later.

## 12. ROLLBACK SUPPORT: Snapshot Before Major Changes

**When**: Before any of these major memory operations:
- `/obsidian-memory scan` (overwrites or merges project memory)
- Bulk deletion (forget requests that affect multiple files)
- Major corrections that rewrite large sections

**Action**:
1. Create a snapshot directory: `projects/{project}/_snapshots/{YYYY-MM-DD}_{HH-MM}/`
2. Copy the files that are about to be changed into the snapshot directory
3. Proceed with the changes
4. Briefly note: "Snapshot saved. Say 'undo that memory change' to rollback."

**On rollback request** ("undo that", "revert the memory change", "go back"):
1. Find the most recent snapshot in `_snapshots/`
2. Show what would be restored
3. Ask for confirmation
4. Copy snapshot files back over the current ones
5. Delete the snapshot after successful restore

Keep only the last 5 snapshots per project. Delete older ones automatically.

## 13. RELATED MEMORIES: Auto-Link with Wikilinks

**When**: Writing any entry to `_ERRORS.md`, `_DECISIONS.md`, or session logs.

**Action**: Search existing memory for related content and add wikilinks:
- When logging an error, check if similar errors exist: `Related: [[_ERRORS#2026-01-15 - similar issue]]`
- When logging a decision, link to decisions it depends on or supersedes
- In session logs, link to relevant decisions and errors discussed
- Use Obsidian's `[[filename#heading]]` syntax for precise links

This makes Obsidian's graph view useful  - you can see how decisions, errors, and
sessions connect to each other.

---

# MANUAL COMMANDS (when user invokes /obsidian-memory directly)

### `/obsidian-memory` (no args)  - Status Overview
Show: all projects, last session date, key counts, memory file sizes.

### `/obsidian-memory search [query]`
Grep across all files in `Claude-Memory/` for the query. Show results grouped by file.

### `/obsidian-memory forget [topic]`
Manually trigger a memory search and deletion. Searches all memory files for the topic,
shows what was found, and removes/corrects it after confirmation.

### `/obsidian-memory rollback`
Show the most recent memory snapshot and offer to restore it. Lists what files would
be reverted and asks for confirmation before restoring.

### `/obsidian-memory scan`
**Deep-scan the current project and build memory from scratch**, as if Claude had been
there from the start. This is for onboarding an existing project into the memory system.

**What it does**:

1. **Detect project basics**:
   - Read `package.json`, `Cargo.toml`, `go.mod`, `requirements.txt`, `pyproject.toml`,
     `Gemfile`, `*.csproj`, `pom.xml`, or similar to identify tech stack and dependencies
   - Read `.git/config` for remote info
   - Check for CI/CD configs (`.github/workflows/`, `Dockerfile`, `.gitlab-ci.yml`, etc.)

2. **Analyze project structure**:
   - Map the directory tree (top 3 levels)
   - Identify entry points, main modules, and key directories
   - Detect patterns: monorepo, MVC, microservices, etc.

3. **Read key files**:
   - README, CONTRIBUTING, CHANGELOG if they exist
   - Config files (.env.example, tsconfig, eslint, prettier, etc.)
   - Main entry point files
   - Database schema/migration files if present

4. **Extract and save**:
   - Write a comprehensive `_PROJECT.md` with:
     - Overview (what the project does, based on README/package description)
     - Tech Stack (languages, frameworks, key dependencies with versions)
     - Architecture (folder structure, patterns detected)
     - Build/Run commands (from package.json scripts, Makefile, etc.)
     - Environment setup (from .env.example, docker-compose, etc.)
     - Testing setup (test framework, test commands)
     - Deployment info (from CI/CD configs)
   - Write `_DECISIONS.md` with architectural decisions inferred from the codebase:
     - Why certain frameworks/libraries were chosen (based on what's installed)
     - Database choice and ORM
     - Auth approach
     - State management approach (for frontend)
   - Write relevant `notes/` files for complex subsystems found
   - Detect any `.env`, `.env.example`, or config files with API key placeholders
     and create empty entries in `_KEYS.md` as reminders

5. **Report**: Show a summary of everything that was captured and saved.

**Important scan rules**:
- Never store full file contents - summarize and reference file paths
- Mark all inferred decisions with `**Inferred from codebase**` so the user knows
  these weren't explicitly discussed
- Don't overwrite existing memory files - merge new info into them
- If `_PROJECT.md` already exists, ask before overwriting or offer to merge
- The scan should take 1-2 minutes for a typical project

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
# {Project Name}  - Master Memory

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
# API Keys  - {Project Name}

## {Service Name}
- **Key**: `{api-key}`
- **Type**: {api-key|token|secret|credential|connection-string}
- **Environment**: {production|staging|development}
- **Added**: {date}
- **Notes**: {context}
```

---

# IMPORTANT RULES

1. **Be silent about most saves**  - don't narrate every write. Brief confirmations only for keys and major saves.
2. **Always append** to `_ERRORS.md` and `_DECISIONS.md`  - never overwrite old entries.
3. **API keys are per-project by default**  - same service CAN have different keys per project.
4. **Check project keys first**, then fall back to global.
5. **Use Obsidian wikilinks** (`[[note name]]`) when cross-referencing.
6. **Add YAML frontmatter** to every file.
7. **Use tags** liberally (`#error`, `#decision`, `#preference`, `#key`) for searchability.
8. **Create directories** with `mkdir -p` before writing if they don't exist.
9. **Date format**: YYYY-MM-DD for dates, HH-MM for times in filenames.
10. **Keep session logs focused**  - one per major topic, not one per message.
11. **Never store full file contents** in logs  - just paths and change summaries.
12. **The user should never have to tell you to save**  - if something is worth remembering, save it.
