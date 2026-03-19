#!/usr/bin/env bash
# Setup script for obsidian-infinite-context
# Creates the vault structure and configures Claude Code

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Obsidian Infinite Context — Setup           ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
echo ""

# Detect OS
OS="unknown"
case "$(uname -s)" in
    Linux*)   OS="linux";;
    Darwin*)  OS="mac";;
    MINGW*|MSYS*|CYGWIN*) OS="windows";;
esac

# Find Obsidian vault
VAULT_PATH=""
if [ -n "$OBSIDIAN_VAULT_PATH" ]; then
    VAULT_PATH="$OBSIDIAN_VAULT_PATH"
    echo -e "${GREEN}Found vault from env: $VAULT_PATH${NC}"
elif [ -f "$HOME/.claude/obsidian-memory.json" ]; then
    VAULT_PATH=$(cat "$HOME/.claude/obsidian-memory.json" | grep -o '"vaultPath"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//;s/"$//')
    echo -e "${GREEN}Found vault from config: $VAULT_PATH${NC}"
fi

if [ -z "$VAULT_PATH" ]; then
    echo -e "${YELLOW}No Obsidian vault path found.${NC}"
    echo ""

    # Try to auto-detect
    SEARCH_DIRS=("$HOME/Documents" "$HOME" "$HOME/OneDrive" "$HOME/Desktop")
    FOUND_VAULTS=()

    echo "Searching for Obsidian vaults..."
    for dir in "${SEARCH_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            while IFS= read -r vault; do
                FOUND_VAULTS+=("$(dirname "$vault")")
            done < <(find "$dir" -maxdepth 3 -name ".obsidian" -type d 2>/dev/null)
        fi
    done

    if [ ${#FOUND_VAULTS[@]} -gt 0 ]; then
        echo ""
        echo "Found Obsidian vault(s):"
        for i in "${!FOUND_VAULTS[@]}"; do
            echo "  [$((i+1))] ${FOUND_VAULTS[$i]}"
        done
        echo ""
        read -p "Select vault number (or enter custom path): " CHOICE

        if [[ "$CHOICE" =~ ^[0-9]+$ ]] && [ "$CHOICE" -ge 1 ] && [ "$CHOICE" -le ${#FOUND_VAULTS[@]} ]; then
            VAULT_PATH="${FOUND_VAULTS[$((CHOICE-1))]}"
        else
            VAULT_PATH="$CHOICE"
        fi
    else
        read -p "Enter your Obsidian vault path: " VAULT_PATH
    fi
fi

# Validate vault path
if [ ! -d "$VAULT_PATH" ]; then
    echo -e "${YELLOW}Warning: $VAULT_PATH does not exist. Create it? (y/n)${NC}"
    read -p "> " CREATE
    if [ "$CREATE" = "y" ] || [ "$CREATE" = "Y" ]; then
        mkdir -p "$VAULT_PATH"
    else
        echo "Aborting."
        exit 1
    fi
fi

echo ""
echo -e "${GREEN}Using vault: $VAULT_PATH${NC}"
echo ""

# Create Claude-Memory structure
MEMORY_DIR="$VAULT_PATH/Claude-Memory"
echo "Creating memory structure..."

mkdir -p "$MEMORY_DIR/projects"
mkdir -p "$MEMORY_DIR/templates"

# Create _GLOBAL.md if it doesn't exist
if [ ! -f "$MEMORY_DIR/_GLOBAL.md" ]; then
    cat > "$MEMORY_DIR/_GLOBAL.md" << 'TEMPLATE'
---
updated: $(date +%Y-%m-%d)
---
# Global Preferences

## Communication Style
<!-- How you like Claude to communicate -->

## Coding Preferences
<!-- Languages, frameworks, patterns you prefer -->

## General Rules
<!-- Things that apply across all projects -->
TEMPLATE
    echo "  Created _GLOBAL.md"
fi

# Create _KEYS.md if it doesn't exist
if [ ! -f "$MEMORY_DIR/_KEYS.md" ]; then
    cat > "$MEMORY_DIR/_KEYS.md" << 'TEMPLATE'
---
updated: $(date +%Y-%m-%d)
---
# Global API Keys

<!-- Keys stored here are available to ALL projects as fallback -->
<!-- Project-specific keys override these -->
TEMPLATE
    echo "  Created _KEYS.md"
fi

# Create templates
cat > "$MEMORY_DIR/templates/session.md" << 'TEMPLATE'
---
project: {{project}}
date: {{date}}
time: {{time}}
topic: {{topic}}
---
# Session: {{topic}}

## Summary


## What Was Done
-

## Decisions Made
-

## Problems & Solutions


## Code Changes
-

## Open Items
-

## Context for Next Session

TEMPLATE
echo "  Created templates/session.md"

cat > "$MEMORY_DIR/templates/project.md" << 'TEMPLATE'
---
project: {{name}}
created: {{date}}
updated: {{date}}
---
# {{name}} — Master Memory

## Overview


## Tech Stack


## Preferences


## Patterns


## Architecture


## Team / Context

TEMPLATE
echo "  Created templates/project.md"

# Save config
mkdir -p "$HOME/.claude"
cat > "$HOME/.claude/obsidian-memory.json" << EOF
{
  "vaultPath": "$VAULT_PATH",
  "memoryDir": "$MEMORY_DIR",
  "created": "$(date +%Y-%m-%d)",
  "version": "1.0.0"
}
EOF
echo ""
echo -e "${GREEN}Saved config to ~/.claude/obsidian-memory.json${NC}"

# Install skill
SKILL_SOURCE="$(cd "$(dirname "$0")/../skills/obsidian-memory" && pwd)"
SKILL_DEST="$HOME/.claude/skills/obsidian-memory"

mkdir -p "$SKILL_DEST"

# Copy skill files, replacing vault path placeholder
sed "s|\$OBSIDIAN_VAULT_PATH|$VAULT_PATH|g" "$SKILL_SOURCE/SKILL.md" > "$SKILL_DEST/SKILL.md"

echo -e "${GREEN}Installed skill to $SKILL_DEST${NC}"

# Add hook for compaction recovery
SETTINGS_FILE="$HOME/.claude/settings.json"
if [ -f "$SETTINGS_FILE" ]; then
    echo ""
    echo -e "${YELLOW}Existing settings.json found. Please manually add the compaction hook.${NC}"
    echo "See the README for hook configuration."
else
    cat > "$SETTINGS_FILE" << EOF
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "echo '[OBSIDIAN MEMORY] Remember to use /obsidian-memory recall to load project context from Obsidian vault at $VAULT_PATH'"
          }
        ]
      }
    ]
  }
}
EOF
    echo -e "${GREEN}Created settings.json with session start hook${NC}"
fi

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Setup Complete!                             ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo "Usage in Claude Code:"
echo "  /obsidian-memory recall    — Load project context"
echo "  /obsidian-memory save      — Save current context"
echo "  /obsidian-memory search X  — Search all memory"
echo "  /obsidian-memory keys list — List API keys"
echo "  /obsidian-memory log       — Quick session log"
echo "  /obsidian-memory status    — Memory overview"
echo ""
echo "Claude will also auto-save/recall as needed."
