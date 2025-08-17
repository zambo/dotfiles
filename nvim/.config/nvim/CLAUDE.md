# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a LazyVim-based Neovim configuration that extends the LazyVim starter template with AI-focused enhancements and professional development tools. The configuration emphasizes AI-assisted coding through CodeCompanion and includes comprehensive language support for modern development workflows.

## Architecture

### Core Structure
- **`init.lua`**: Minimal entry point that bootstraps lazy.nvim
- **`lua/config/`**: Core configuration modules (lazy.lua, options.lua, keymaps.lua, autocmds.lua)
- **`lua/plugins/`**: Plugin configurations organized by category
- **`lua/plugins/extras/`**: Optional/experimental plugin configurations

### Key Components
- **Plugin Management**: lazy.nvim with locked versions (lazy-lock.json)
- **Base Distribution**: LazyVim with 35+ extras enabled (lazyvim.json)
- **AI Integration**: CodeCompanion as primary AI assistant with Claude-4 and Mistral
- **Language Support**: TypeScript, Python, Docker, SQL, Markdown with full LSP/DAP/testing

## Common Commands

### Plugin Management
```bash
# Inside Neovim
:Lazy                    # Open plugin manager UI
:Lazy update            # Update all plugins
:Lazy sync              # Sync with lockfile
:LazyExtras             # Manage LazyVim extras
```

### AI Assistant (CodeCompanion)
```bash
:CodeCompanion          # Start AI chat
:CodeCompanionActions   # Show available actions
:CodeCompanionHistory   # View chat history

# Key bindings
<leader>aa              # Actions menu
<leader>ac              # Toggle chat
<leader>ad              # Add selection to chat
<leader>ai              # Inline chat
<leader>ar              # Refactor code
<leader>ae              # Explain code
```

### Development Tools
```bash
:Format                 # Format current buffer (uses stylua.toml)
:Neotest                # Run tests
:Trouble                # Show diagnostics
:Mason                  # Manage LSP servers
```

## Configuration Patterns

### AI Integration
- API keys managed via 1Password CLI (`op read` commands)
- Multiple AI adapters configured (Claude, Mistral, Copilot)
- Vector database integration for semantic search
- MCP (Model Context Protocol) hub support

### Plugin Organization
- **`ai.lua`**: All AI-related plugins (CodeCompanion, Copilot, VectorCode, MCP)
- **`ui.lua`**: Interface enhancements (Snacks.nvim file picker)
- **`extras/`**: Experimental or optional features

### LazyVim Extras
The configuration includes curated LazyVim extras for TypeScript, debugging, testing, formatting, and editor enhancements. Check `lazyvim.json` for the complete list.

## Security Notes
- No hardcoded API keys - all managed through 1Password CLI
- Plugin versions locked for stability
- Secure external tool integration patterns

## File Management
- Hidden files always visible in pickers
- Custom window picker for navigation
- Snacks.nvim for enhanced file exploration
- Dropbar integration for breadcrumb navigation