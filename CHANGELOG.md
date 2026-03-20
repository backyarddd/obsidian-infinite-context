# Changelog

## 1.1.0 (2026-03-19)

- Added `/obsidian-update` command for self-updating
- Split commands into individual skills with descriptions
  - `/obsidian-search` - Search all memory files
  - `/obsidian-forget` - Delete specific memories
  - `/obsidian-scan` - Onboard existing projects
  - `/obsidian-rollback` - Undo memory changes
  - `/obsidian-status` - Memory overview
- Replaced auto-compact with proactive save before compaction
  (Claude saves everything and tells you to run `/compact` manually)
- Added `CLAUDE.md.example` for recommended global config
- Updated setup scripts to install all skills

## 1.0.0 (2026-03-19)

- Initial release
- Auto-recall on conversation start
- Auto-save API keys, preferences, errors, decisions
- Session logging with continuity
- Per-project API key storage
- Memory conflict detection
- Staleness checking
- Cross-project learning
- Dependency tracking
- Rollback snapshots
- Related memories via wikilinks
- Memory stats in session logs
- Project opt-out support
- Setup scripts for macOS/Linux/Windows
