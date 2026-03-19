---
name: obsidian-forget
description: Search and delete specific memories from Obsidian vault. Use when you need to remove outdated or incorrect information.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Grep, Glob, Bash(cat *), Bash(ls *), Bash(rm *)
argument-hint: "[topic to forget]"
---

# Forget Memory

Search and delete specific memories from the Obsidian vault.

1. Read `~/.claude/obsidian-memory.json` to get the vault path
2. Search ALL files in `{vault}/Claude-Memory/` for `$ARGUMENTS`
3. Show what was found - list the file(s) and the specific content that matches
4. Ask the user which matches to delete/correct
5. Delete or update the content:
   - If the entire entry is wrong: remove the full section
   - If part of an entry is wrong: edit just the incorrect part
   - If it's in `_ERRORS.md` or `_DECISIONS.md`: append a correction note
   - If it's an API key: remove it entirely from `_KEYS.md`
   - If it's a preference: remove or replace it
   - If it's in a session log: add a correction note at the top
6. Confirm what was removed/corrected
