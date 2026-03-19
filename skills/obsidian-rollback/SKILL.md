---
name: obsidian-rollback
description: Undo the last major Obsidian memory change by restoring from a snapshot.
disable-model-invocation: true
allowed-tools: Read, Write, Glob, Bash(cat *), Bash(ls *), Bash(cp *), Bash(rm *)
---

# Rollback Memory

Undo the last major memory change by restoring from a snapshot.

1. Read `~/.claude/obsidian-memory.json` to get the vault path
2. Detect the project name from the working directory
3. Look in `{vault}/Claude-Memory/projects/{project}/_snapshots/` for available snapshots
4. If no snapshots exist, say so and stop
5. Show the most recent snapshot - list what files it contains and their dates
6. Ask for confirmation before restoring
7. Copy snapshot files back over the current ones
8. Confirm what was restored
9. Delete the used snapshot after successful restore

Keep only the last 5 snapshots per project. Delete older ones automatically.
