---
name: obsidian-update
description: Check for updates to obsidian-infinite-context and auto-update skills if a new version is available.
disable-model-invocation: true
allowed-tools: Read, Write, Bash(cat *), Bash(ls *), Bash(curl *), Bash(git *), Bash(cp *), Bash(mkdir *), Bash(rm *), Bash(date *)
---

# Update Obsidian Infinite Context

Check for updates and install the latest version automatically.

## Steps

1. **Read current version** from `~/.claude/obsidian-memory.json` (the `version` field)

2. **Fetch latest version** from GitHub:
   ```
   curl -s https://raw.githubusercontent.com/backyarddd/obsidian-infinite-context/master/VERSION
   ```

3. **Compare versions**:
   - If the remote VERSION file doesn't exist or the fetch fails, say so and stop
   - If versions match, say "You're already on the latest version (v{version})." and stop
   - If remote is newer, continue to step 4
   - Show the user: "Update available: v{current} -> v{latest}"

4. **Fetch the changelog** for what changed:
   ```
   curl -s https://raw.githubusercontent.com/backyarddd/obsidian-infinite-context/master/CHANGELOG.md
   ```
   Show the user what changed since their current version.

5. **Ask for confirmation**: "Want me to update now?"

6. **If confirmed, update**:
   a. Create a temp directory and clone the latest:
      ```
      git clone --depth 1 https://github.com/backyarddd/obsidian-infinite-context.git /tmp/obsidian-update
      ```
   b. Back up current skills:
      ```
      cp -r ~/.claude/skills/obsidian-memory ~/.claude/skills/obsidian-memory.bak
      ```
      (and same for all obsidian-* skill dirs)
   c. Copy new skill files over existing ones:
      - For each `obsidian-*` directory in the cloned repo's `skills/` folder,
        copy the SKILL.md to `~/.claude/skills/{skill-name}/SKILL.md`
      - For `obsidian-memory`, replace `$OBSIDIAN_VAULT_PATH` with the vault path
        from `~/.claude/obsidian-memory.json` before copying
   d. Update the version in `~/.claude/obsidian-memory.json`
   e. Clean up: remove `/tmp/obsidian-update` and the `.bak` directories
   f. On Windows, use `$env:TEMP` or `C:\Users\{user}\AppData\Local\Temp` instead of `/tmp`

7. **Confirm**: "Updated to v{latest}. Restart Claude Code to use the new version."

## Rollback

If the user says the update broke something:
1. Check if `.bak` directories still exist in `~/.claude/skills/`
2. If yes, restore them
3. If no, tell the user to run the setup script again from the repo

## Rules
- Always show what changed before updating
- Always ask before updating
- Never touch the vault contents (Claude-Memory/) during updates, only skill files
- On Windows, use PowerShell-compatible paths
