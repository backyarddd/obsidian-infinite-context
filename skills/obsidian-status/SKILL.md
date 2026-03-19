---
name: obsidian-status
description: Show an overview of all Obsidian memory - projects, last session dates, key counts, and memory file sizes.
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Bash(cat *), Bash(ls *), Bash(wc *), Bash(date *)
---

# Memory Status

Show an overview of all stored Obsidian memory.

1. Read `~/.claude/obsidian-memory.json` to get the vault path
2. List all projects in `{vault}/Claude-Memory/projects/`
3. For each project, show:
   - Last session date (from most recent session log filename)
   - Number of session logs
   - Number of error entries in `_ERRORS.md`
   - Number of decision entries in `_DECISIONS.md`
   - Number of API keys in `_KEYS.md`
   - Total memory size
4. Show global stats:
   - Global preferences count
   - Global API keys count
   - Disabled projects list
   - Total vault memory size
