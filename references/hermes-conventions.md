# Hermes Conventions Reference

Reference document for building agents targeting the Hermes runtime (NousResearch).

---

## Overview

Hermes is an agent runtime by NousResearch built around the Hermes family of models (Hermes 3, DeepHermes, Hermes 4). It provides a CLI-based agent with persistent memory, skills, context files, tool use, and multi-platform messaging gateways.

The Hermes agent runtime (`hermes-agent`) is distinct from the Hermes model format. The runtime uses any LLM provider (Anthropic, OpenAI, OpenRouter, etc.) while the model format defines specific prompt conventions (ChatML, tool XML tags). Both are documented here.

---

## File System Layout

### Global Configuration (`~/.hermes/`)

```
~/.hermes/
├── config.yaml          # Primary settings (model, terminal, TTS, memory, etc.)
├── .env                 # API keys and secrets
├── auth.json            # OAuth credentials
├── SOUL.md              # Global personality/persona
├── memories/
│   ├── MEMORY.md        # Agent's personal notes (~2,200 chars)
│   └── USER.md          # User profile data (~1,375 chars)
├── skills/              # Installed and agent-created skills
│   └── category/
│       └── skill-name/
│           ├── SKILL.md
│           ├── references/
│           ├── templates/
│           ├── scripts/
│           └── assets/
├── skins/               # Custom terminal themes (YAML)
├── cron/                # Scheduled jobs
├── sessions/            # Gateway sessions
└── logs/                # Error and gateway logs
```

### Project-Level Files

```
project-root/
├── AGENTS.md            # Project context (architecture, conventions, instructions)
├── SOUL.md              # Project-level persona override (optional)
├── .cursorrules         # Cursor IDE compat — auto-loaded by Hermes
└── .cursor/rules/*.mdc  # Cursor rules compat — auto-loaded by Hermes
```

---

## Context Files

### AGENTS.md

Primary project context file. Hermes walks the directory tree from the working directory and loads ALL `AGENTS.md` files found, sorted by depth (supports monorepos).

**Recommended sections:**

- **Architecture**: Tech stack, framework versions, directory organization
- **Conventions**: Coding standards, naming patterns, API response shapes
- **Important Notes**: Critical "do nots" and guardrails
- **Key Paths**: Relevant directories, ports, commands

**Constraints:**
- Max 20,000 characters per file (~7,000 tokens)
- Exceeding triggers head/tail truncation (70% head + 20% tail)
- Scanned for prompt injection before loading
- Excluded directories: dot-prefixed, `node_modules`, `__pycache__`, `venv`, `.venv`

### SOUL.md

Defines the agent's personality, tone, and communication style. Injected verbatim into the system prompt after security scanning.

**Location precedence:**
1. Project-level `SOUL.md` (working directory)
2. Global `~/.hermes/SOUL.md`

**Suitable content:**
- Tone and communication style
- Level of directness
- How to handle uncertainty or disagreement
- Stylistic preferences and what to avoid

**Not suitable:**
- Project-specific instructions (use AGENTS.md)
- File paths, repo conventions, temporary workflows

**Prompt hierarchy (6 layers):**
1. Default identity
2. Memory (MEMORY.md, USER.md)
3. Context files (AGENTS.md)
4. SOUL.md personality
5. Platform-specific formatting
6. Session overlays (/personality command)

---

## Memory System

Bounded, curated memory with two files loaded as frozen snapshots at session start.

### MEMORY.md (Agent's Personal Notes)

- Limit: 2,200 characters (~800 tokens)
- Stores: environment facts, project conventions, tool workarounds, task completion records, learned techniques
- Actions: `add`, `replace` (substring match), `remove` (substring match)
- Auto-consolidation when approaching limit

### USER.md (User Profile)

- Limit: 1,375 characters (~500 tokens)
- Stores: identity details, communication preferences, workflow habits, timezone, skill level
- Same actions as MEMORY.md

### Configuration

```yaml
memory:
  memory_enabled: true
  user_profile_enabled: true
  memory_char_limit: 2200
  user_char_limit: 1375
```

### What to Store vs. Skip

**Store:** User preferences, environment facts, corrections, project conventions, completed work, explicit requests.

**Skip:** Trivial information, easily researched facts, raw data dumps, session-specific paths, content already in context files.

---

## Skills System

Skills follow the `agentskills.io` open format. They are on-demand knowledge documents loaded progressively to minimize token usage.

### SKILL.md Format

```yaml
---
name: skill-identifier
description: Brief explanation
version: 1.0.0
platforms: [macos, linux]           # Optional OS restriction
metadata:
  hermes:
    tags: [category, type]
    category: domain
    fallback_for_toolsets: [toolset]
    requires_toolsets: [toolset]
---

# Skill Name

## When to Use
...

## Procedure
...

## Pitfalls
...

## Verification
...
```

### Progressive Loading

- **Level 0**: `skills_list()` returns basic metadata (~3k tokens)
- **Level 1**: `skill_view(name)` retrieves full content
- **Level 2**: `skill_view(name, path)` accesses specific files

### Skill Sources

- Bundled (installed with Hermes)
- Hub: official, skills-sh, well-known, github, clawhub, lobehub, claude-marketplace
- Agent-created via `skill_manage` tool

---

## Tool Use / Function Calling Format

### Hermes Model Format (ChatML)

Hermes models use ChatML with XML tags for structured tool interaction.

#### Prompt Format

```
<|im_start|>system
{system_message}<|im_end|>
<|im_start|>user
{user_message}<|im_end|>
<|im_start|>assistant
{response}<|im_end|>
```

#### System Prompt for Function Calling

```
<|im_start|>system
You are a function calling AI model. You are provided with function signatures within <tools></tools> XML tags. You may call one or more functions to assist with the user query. Don't make assumptions about what values to plug into functions. Here are the available tools:
<tools>
[
  {
    "type": "function",
    "function": {
      "name": "tool_name",
      "description": "What the tool does",
      "parameters": {
        "type": "object",
        "properties": {
          "param_name": {
            "type": "string",
            "description": "Parameter description"
          }
        },
        "required": ["param_name"]
      }
    }
  }
]
</tools>
Use the following pydantic model json schema for each tool call you will make:
{"properties": {"arguments": {"title": "Arguments", "type": "object"}, "name": {"title": "Name", "type": "string"}}, "required": ["arguments", "name"], "title": "FunctionCall", "type": "object"}
For each function call return a json object with function name and arguments within <tool_call></tool_call> XML tags as follows:
<tool_call>
{"arguments": <args-dict>, "name": <function-name>}
</tool_call><|im_end|>
```

#### Tool Definition Schema

OpenAI-compatible format:

```json
{
  "type": "function",
  "function": {
    "name": "get_stock_fundamentals",
    "description": "Get fundamental data for a given stock symbol.",
    "parameters": {
      "type": "object",
      "properties": {
        "symbol": {
          "type": "string",
          "description": "The stock ticker symbol"
        }
      },
      "required": ["symbol"]
    }
  }
}
```

#### Tool Call (Assistant)

```
<|im_start|>assistant
<tool_call>
{"name": "get_stock_fundamentals", "arguments": {"symbol": "TSLA"}}
</tool_call><|im_end|>
```

#### Tool Response

```
<|im_start|>tool
<tool_response>
{"name": "get_stock_fundamentals", "content": {"symbol": "TSLA", "company_name": "Tesla, Inc.", "sector": "Consumer Cyclical"}}
</tool_response>
<|im_end|>
```

#### Full Interaction Flow

```
<|im_start|>system
[System prompt with tools]<|im_end|>
<|im_start|>user
Fetch the stock fundamentals for Tesla<|im_end|>
<|im_start|>assistant
<tool_call>
{"name": "get_stock_fundamentals", "arguments": {"symbol": "TSLA"}}
</tool_call><|im_end|>
<|im_start|>tool
<tool_response>
{"name": "get_stock_fundamentals", "content": {...}}
</tool_response>
<|im_end|>
<|im_start|>assistant
The stock fundamentals for Tesla (TSLA) are...<|im_end|>
```

### Hermes 4 Additions

Hermes 4 uses Llama 3 chat format instead of ChatML and adds reasoning integration:

```
<|start_header_id|>assistant<|end_header_id|>
<think>
...reasoning about which tool to use...
</think>
<tool_call>{"function": "get_weather", "arguments": {"city": "Paris"}}</tool_call><|eot_id|>
```

---

## Structured Output

### JSON Mode

```
<|im_start|>system
You are a helpful assistant that answers in JSON. Here's the json schema you must adhere to:
<schema>
{JSON_SCHEMA}
</schema><|im_end|>
```

### Reasoning Tags (Hermes 3)

Reserved tokens for structured reasoning:

| Tag | Purpose |
|-----|---------|
| `<SCRATCHPAD>` | Intermediate processing workspace |
| `<REASONING>` | Explicit reasoning steps |
| `<INNER_MONOLOGUE>` | Transparent decision-making |
| `<PLAN>` | Planning steps |
| `<EXECUTION>` | Execution phase |
| `<REFLECTION>` | Self-evaluation |
| `<THINKING>` | General thought process |
| `<SOLUTION>` | Final solution |
| `<EXPLANATION>` | Explanatory content |
| `<UNIT_TEST>` | Test verification |

### RAG Citations

Hermes 3 cites retrieval sources using the `<co>` tag inline with generated text.

---

## XML Tags Summary

| Tag | Context | Usage |
|-----|---------|-------|
| `<tools>` | System prompt | Wraps tool/function definitions (JSON array) |
| `<tool_call>` | Assistant message | Wraps function call JSON (`name` + `arguments`) |
| `<tool_response>` | Tool message | Wraps function result JSON (`name` + `content`) |
| `<schema>` | System prompt | JSON schema for structured output mode |
| `<co>` | Assistant message | RAG citation tag |
| `<think>` | Assistant message | Reasoning/deliberation (Hermes 4) |
| `<SCRATCHPAD>` | Assistant message | Intermediate processing (Hermes 3) |
| `<REASONING>` | Assistant message | Explicit reasoning (Hermes 3) |
| `<PLAN>` | Assistant message | Planning steps (Hermes 3) |

---

## config.yaml Key Sections

```yaml
model:
  provider: "anthropic"             # Provider name
  default: "claude-sonnet-4-6"      # Default model

memory:
  memory_enabled: true
  user_profile_enabled: true
  memory_char_limit: 2200
  user_char_limit: 1375

agent:
  max_turns: 90
  reasoning_effort: ""              # xhigh, high, medium, low, minimal, none

approval_mode: ask                  # ask, smart, off

terminal:
  backend: local                    # local, docker, ssh, singularity, modal, daytona
  timeout: 180

compression:
  enabled: true
  threshold: 0.50

display:
  tool_progress: all
  skin: default
  personality: ""
  streaming: false

checkpoints:
  enabled: false
  max_snapshots: 50

worktree: true
```

---

## Hermes Agent Runtime vs. Hermes Model

| Aspect | Hermes Agent Runtime | Hermes Model Format |
|--------|---------------------|-------------------|
| What it is | CLI agent application | LLM prompt convention |
| Config | config.yaml + AGENTS.md + SOUL.md | ChatML system prompts |
| Tools | Runtime tool registry (Python) | `<tools>` XML in system prompt |
| Memory | MEMORY.md + USER.md files | N/A (stateless) |
| Skills | agentskills.io SKILL.md format | N/A |
| Platforms | CLI, Telegram, Discord, Slack, WhatsApp | Any inference server |

---

## Best Practices

1. **AGENTS.md over SOUL.md** for project instructions. SOUL.md is personality only.
2. **Keep context files under 20k chars** to avoid truncation.
3. **Front-load important info** in AGENTS.md since truncation preserves head.
4. **Use skills for procedures**, memory for facts and preferences.
5. **One well-crafted message beats three rounds of clarification.** Include file paths, error traces, expected behavior.
6. **Avoid micromanagement.** Say "find and fix the failing test" not "open tests/test_foo.py, look at line 42."
7. **Tool definitions use OpenAI-compatible JSON schema** inside `<tools>` tags.
8. **Prompt cache stability matters** — avoid changing models or system prompts mid-session.
9. **Memory consolidation** — compress multiple related entries into dense single entries.
10. **Security scanning** applies to SOUL.md, AGENTS.md, and hub-installed skills.

---

## Sources

- [Hermes 3 Model Card (HuggingFace)](https://huggingface.co/NousResearch/Hermes-3-Llama-3.1-8B)
- [Hermes 4 Model Card (HuggingFace)](https://huggingface.co/NousResearch/Hermes-4-70B)
- [Hermes Function Calling (GitHub)](https://github.com/NousResearch/Hermes-Function-Calling)
- [Hermes Agent (GitHub)](https://github.com/NousResearch/hermes-agent)
- [Hermes Agent Documentation](https://hermes-agent.nousresearch.com/docs/)
- [Hermes Agent Context Files](https://hermes-agent.nousresearch.com/docs/user-guide/features/context-files/)
- [Hermes Agent Personality & SOUL.md](https://hermes-agent.nousresearch.com/docs/user-guide/features/personality/)
- [Hermes Agent Skills System](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills/)
- [Hermes Agent Memory](https://hermes-agent.nousresearch.com/docs/user-guide/features/memory/)
- [Hermes Agent Configuration](https://hermes-agent.nousresearch.com/docs/user-guide/configuration/)
- [Hermes Agent Tips & Best Practices](https://hermes-agent.nousresearch.com/docs/guides/tips/)
- [Hermes 3 Technical Report (arXiv)](https://arxiv.org/pdf/2408.11857)
