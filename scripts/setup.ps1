# Setup script for obsidian-infinite-context (Windows PowerShell)
# Creates the vault structure and configures Claude Code

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "  Obsidian Infinite Context - Setup" -ForegroundColor Cyan
Write-Host "  ==================================" -ForegroundColor Cyan
Write-Host ""

# Find Obsidian vault
$VaultPath = $env:OBSIDIAN_VAULT_PATH
$ConfigFile = Join-Path $env:USERPROFILE ".claude\obsidian-memory.json"

if (-not $VaultPath -and (Test-Path $ConfigFile)) {
    $config = Get-Content $ConfigFile | ConvertFrom-Json
    $VaultPath = $config.vaultPath
    Write-Host "Found vault from config: $VaultPath" -ForegroundColor Green
}

if (-not $VaultPath) {
    Write-Host "No Obsidian vault path found. Searching..." -ForegroundColor Yellow

    $searchDirs = @(
        (Join-Path $env:USERPROFILE "Documents"),
        $env:USERPROFILE,
        (Join-Path $env:USERPROFILE "OneDrive"),
        (Join-Path $env:USERPROFILE "Desktop")
    )

    $foundVaults = @()
    foreach ($dir in $searchDirs) {
        if (Test-Path $dir) {
            $vaults = Get-ChildItem -Path $dir -Filter ".obsidian" -Directory -Recurse -Depth 3 -ErrorAction SilentlyContinue
            foreach ($v in $vaults) {
                $foundVaults += $v.Parent.FullName
            }
        }
    }

    if ($foundVaults.Count -gt 0) {
        Write-Host ""
        Write-Host "Found Obsidian vault(s):"
        for ($i = 0; $i -lt $foundVaults.Count; $i++) {
            Write-Host "  [$($i + 1)] $($foundVaults[$i])"
        }
        Write-Host ""
        $choice = Read-Host "Select vault number (or enter custom path)"

        if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $foundVaults.Count) {
            $VaultPath = $foundVaults[[int]$choice - 1]
        } else {
            $VaultPath = $choice
        }
    } else {
        $VaultPath = Read-Host "Enter your Obsidian vault path"
    }
}

if (-not (Test-Path $VaultPath)) {
    $create = Read-Host "$VaultPath does not exist. Create it? (y/n)"
    if ($create -eq 'y') {
        New-Item -ItemType Directory -Path $VaultPath -Force | Out-Null
    } else {
        Write-Host "Aborting." -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "Using vault: $VaultPath" -ForegroundColor Green
Write-Host ""

# Create Claude-Memory structure
$MemoryDir = Join-Path $VaultPath "Claude-Memory"
Write-Host "Creating memory structure..."

$dirs = @("projects", "templates")
foreach ($d in $dirs) {
    New-Item -ItemType Directory -Path (Join-Path $MemoryDir $d) -Force | Out-Null
}

$today = Get-Date -Format "yyyy-MM-dd"

# Create _GLOBAL.md
$globalFile = Join-Path $MemoryDir "_GLOBAL.md"
if (-not (Test-Path $globalFile)) {
    @"
---
updated: $today
---
# Global Preferences

## Communication Style
<!-- How you like Claude to communicate -->

## Coding Preferences
<!-- Languages, frameworks, patterns you prefer -->

## General Rules
<!-- Things that apply across all projects -->
"@ | Set-Content $globalFile -Encoding UTF8
    Write-Host "  Created _GLOBAL.md"
}

# Create _KEYS.md
$keysFile = Join-Path $MemoryDir "_KEYS.md"
if (-not (Test-Path $keysFile)) {
    @"
---
updated: $today
---
# Global API Keys

<!-- Keys stored here are available to ALL projects as fallback -->
<!-- Project-specific keys override these -->
"@ | Set-Content $keysFile -Encoding UTF8
    Write-Host "  Created _KEYS.md"
}

# Create templates
@"
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
"@ | Set-Content (Join-Path $MemoryDir "templates\session.md") -Encoding UTF8
Write-Host "  Created templates/session.md"

@"
---
project: {{name}}
created: {{date}}
updated: {{date}}
---
# {{name}} - Master Memory

## Overview

## Tech Stack

## Preferences

## Patterns

## Architecture

## Team / Context
"@ | Set-Content (Join-Path $MemoryDir "templates\project.md") -Encoding UTF8
Write-Host "  Created templates/project.md"

# Save config
$claudeDir = Join-Path $env:USERPROFILE ".claude"
New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null

@{
    vaultPath = $VaultPath
    memoryDir = $MemoryDir
    created = $today
    version = "1.0.0"
} | ConvertTo-Json | Set-Content $ConfigFile -Encoding UTF8

Write-Host ""
Write-Host "Saved config to $ConfigFile" -ForegroundColor Green

# Install skill
$skillSource = Join-Path $PSScriptRoot "..\skills\obsidian-memory\SKILL.md"
$skillDest = Join-Path $env:USERPROFILE ".claude\skills\obsidian-memory"
New-Item -ItemType Directory -Path $skillDest -Force | Out-Null

(Get-Content $skillSource -Raw) -replace '\$OBSIDIAN_VAULT_PATH', $VaultPath | Set-Content (Join-Path $skillDest "SKILL.md") -Encoding UTF8

Write-Host "Installed skill to $skillDest" -ForegroundColor Green

Write-Host ""
Write-Host "  Setup Complete!" -ForegroundColor Cyan
Write-Host "  ==================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Usage in Claude Code:"
Write-Host "  /obsidian-memory recall    - Load project context"
Write-Host "  /obsidian-memory save      - Save current context"
Write-Host "  /obsidian-memory search X  - Search all memory"
Write-Host "  /obsidian-memory keys list - List API keys"
Write-Host "  /obsidian-memory log       - Quick session log"
Write-Host "  /obsidian-memory status    - Memory overview"
Write-Host ""
Write-Host "Claude will also auto-save/recall as needed."
