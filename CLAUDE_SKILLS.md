# Claude Code Skills & Slash Commands

A quick reference for Claude Code capabilities.

## Built-in Slash Commands

### Workspace & Navigation
| Command | Description |
|---------|-------------|
| `/clear` | Clear conversation history |
| `/help` | Get usage help |
| `/exit` | Exit the REPL |
| `/add-dir` | Add additional working directories |
| `/context` | Visualize current context usage |
| `/resume [session]` | Resume a conversation by ID or name |
| `/rename <name>` | Rename the current session |

### Configuration & Settings
| Command | Description |
|---------|-------------|
| `/config` | Open the Settings interface |
| `/status` | Show version, model, account info |
| `/model` | Select or change the AI model |
| `/permissions` | View or update permissions |
| `/privacy-settings` | Update privacy settings |
| `/sandbox` | Enable sandboxed bash with isolation |
| `/terminal-setup` | Install Shift+Enter for newlines |

### Code & Project Management
| Command | Description |
|---------|-------------|
| `/init` | Initialize project with CLAUDE.md |
| `/memory` | Edit CLAUDE.md memory files |
| `/todos` | List current TODO items |
| `/rewind` | Rewind conversation and/or code |
| `/export [filename]` | Export conversation to file |
| `/compact [instructions]` | Compact conversation with focus |

### Git & GitHub
| Command | Description |
|---------|-------------|
| `/review` | Request code review |
| `/security-review` | Security review of pending changes |
| `/pr-comments` | View pull request comments |
| `/install-github-app` | Set up Claude GitHub Actions |

### IDE & Extensions
| Command | Description |
|---------|-------------|
| `/ide` | Manage IDE integrations |
| `/output-style [style]` | Set the output style |
| `/statusline` | Set up status line UI |
| `/vim` | Enter vim mode |

### Integration & Customization
| Command | Description |
|---------|-------------|
| `/agents` | Manage custom AI subagents |
| `/hooks` | Manage hook configurations |
| `/mcp` | Manage MCP server connections |
| `/plugin` | Manage Claude Code plugins |

### Account & Monitoring
| Command | Description |
|---------|-------------|
| `/login` | Switch Anthropic accounts |
| `/logout` | Sign out |
| `/cost` | Show token usage statistics |
| `/usage` | Show plan usage and rate limits |
| `/stats` | Visualize daily usage and history |
| `/bug` | Report bugs to Anthropic |
| `/doctor` | Check installation health |
| `/release-notes` | View release notes |

### Background Tasks
| Command | Description |
|---------|-------------|
| `/bashes` | List and manage background tasks |

---

## Custom Skills

Skills are markdown files that teach Claude how to do specific tasks. Unlike slash commands, Claude automatically applies relevant skills based on your request.

### Skill Locations
| Location | Path | Scope |
|----------|------|-------|
| Personal | `~/.claude/skills/` | All your projects |
| Project | `.claude/skills/` | This repository |
| Plugin | `skills/` in plugin dir | Anyone with plugin |

### Creating a Skill

Create a directory with a `SKILL.md` file:

```yaml
---
name: my-skill
description: What this skill does
allowed-tools: Read, Grep, Bash(python:*)
---

# My Skill

## Instructions
Step-by-step guidance for Claude.

## Examples
Concrete usage examples.
```

### Skills vs Slash Commands

| Use Case | Best Choice |
|----------|-------------|
| Quick, simple prompts | Slash command |
| Complex multi-step workflows | Skill |
| Single file instruction | Slash command |
| Multiple files/scripts needed | Skill |
| Manual invocation | Slash command |
| Automatic context detection | Skill |

---

## Related Features

- **Subagents** (`/agents`) - Separate AI contexts with their own tools
- **MCP Servers** (`/mcp`) - Connect to external tools and data
- **Hooks** (`/hooks`) - Run scripts on tool events
- **CLAUDE.md** - Project-wide instructions for every conversation
