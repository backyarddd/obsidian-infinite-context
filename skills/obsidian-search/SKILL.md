---
name: obsidian-search
description: Search across all Obsidian memory files for any topic, preference, decision, error, or session log.
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash(cat *), Bash(ls *)
argument-hint: "[query]"
---

# Search Obsidian Memory

Search across all files in the Obsidian vault memory directory for the given query.

1. Read `~/.claude/obsidian-memory.json` to get the vault path
2. Use Grep to search across all files in `{vault}/Claude-Memory/` for `$ARGUMENTS`
3. Present results grouped by file with surrounding context
4. If no results found, suggest alternative search terms
