# Deep Agents CLI

## Overview
The Deep Agents CLI is an open-source terminal coding agent built on the Deep Agents SDK. Features persistent memory, context retention across sessions, project convention learning, customizable skills, and approval-controlled code execution.

## Key Capabilities

- File operations (read, write, edit)
- Shell command execution
- Web search functionality
- HTTP request capabilities
- Task planning and tracking
- Memory storage and retrieval
- Human-in-the-loop approval processes
- Custom skill extensions

## Built-in Tools

12 integrated tools:
- **File management**: `ls`, `read_file`, `write_file`, `edit_file`
- **Searching**: `glob`, `grep`
- **Command execution**: `shell`, `execute`
- **Web operations**: `web_search`, `fetch_url`
- **Task management**: `task`, `write_todos`

Most destructive operations require user approval.

## Installation & Setup

```bash
# Global install
uv tool install deepagents-cli

# Direct run
uvx deepagents-cli
```

Set API credentials as environment variables for your chosen provider (OpenAI, Anthropic, Google, or Vertex AI).

## Command-line Options

- `-a/--agent`: Specify named agent configuration
- `-M/--model`: Choose specific model
- `-n/--non-interactive`: Execute single task without interactive UI
- `--auto-approve`: Skip human confirmation prompts
- `--sandbox`: Execute code in remote environments (Modal, Daytona, Runloop)

## Interactive Features

- Slash commands: `/model`, `/remember`, `/tokens`
- Bash command execution: prefix with `!`
- Keyboard shortcuts for productivity

## Memory & Learning

Automatically stores learned conventions in `~/.deepagents/<agent_name>/memories/` using markdown files.

Context files:
- **Global**: `~/.deepagents/<agent_name>/AGENTS.md`
- **Project-specific**: `.deepagents/AGENTS.md` in project roots

## Skills System

Skills extend agent capabilities through structured SKILL.md files:
```bash
deepagents skills create NAME
deepagents skills list
```

## Remote Execution

Remote sandboxes provide isolated, safe code execution across multiple providers, enabling parallel agent execution and consistent team environments.
