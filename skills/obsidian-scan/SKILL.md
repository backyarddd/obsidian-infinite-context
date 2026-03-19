---
name: obsidian-scan
description: Deep-scan the current project and build Obsidian memory from scratch, as if Claude had been there from the start. For onboarding existing projects.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(cat *), Bash(mkdir *), Bash(date *), Bash(ls *)
---

# Scan Project Into Memory

Deep-scan the current project and build memory from scratch.

1. Read `~/.claude/obsidian-memory.json` to get the vault path
2. Detect the project name from the working directory

3. **Detect project basics**:
   - Read `package.json`, `Cargo.toml`, `go.mod`, `requirements.txt`, `pyproject.toml`,
     `Gemfile`, `*.csproj`, `pom.xml`, or similar for tech stack and dependencies
   - Read `.git/config` for remote info
   - Check for CI/CD configs (`.github/workflows/`, `Dockerfile`, `.gitlab-ci.yml`, etc.)

4. **Analyze project structure**:
   - Map the directory tree (top 3 levels)
   - Identify entry points, main modules, and key directories
   - Detect patterns: monorepo, MVC, microservices, etc.

5. **Read key files**:
   - README, CONTRIBUTING, CHANGELOG if they exist
   - Config files (.env.example, tsconfig, eslint, prettier, etc.)
   - Main entry point files
   - Database schema/migration files if present

6. **Create a rollback snapshot first** if memory files already exist:
   - Copy existing files to `_snapshots/{date}_{time}/`

7. **Extract and save**:
   - Write `_PROJECT.md` with overview, tech stack, architecture, build commands, env setup, testing, deployment
   - Write `_DECISIONS.md` with inferred architectural decisions (marked as **Inferred from codebase**)
   - Write relevant `notes/` files for complex subsystems
   - Create empty `_KEYS.md` entries for any API key placeholders found in .env.example

8. **Report** a summary of everything captured

**Rules**:
- Never store full file contents - summarize and reference paths
- If `_PROJECT.md` already exists, ask before overwriting or offer to merge
- Mark all inferred decisions so the user knows they weren't explicitly discussed
