# ASK Template Variables — Master Reference

All `{{VARIABLE}}` placeholders used across ASK templates. This document ensures consistent naming across runtimes (OpenClaw, Hermes, Claude Code) and traces each variable back to its Discovery/Architecture source.

Last updated: 2026-03-17

---

## Naming Conventions

- **UPPER_SNAKE_CASE** for all variables
- **Blocks** use `{{#BLOCK}}...{{/BLOCK}}` for iteration and `{{^BLOCK}}...{{/BLOCK}}` for negation
- **Same concept = same variable name** across all runtimes. If a variable means the same thing, it has the same name regardless of which template uses it.

---

## Identity Variables

| Variable | Description | Source | Used In |
|----------|-------------|--------|---------|
| `AGENT_NAME` | Agent display name | Discovery A | Hermes (all), Claude Code, Common (system-prompt, guardrails) |
| `AGENT_DISPLAY_NAME` | Agent display name (OpenClaw convention) | Discovery A | OpenClaw (IDENTITY, AGENTS) |
| `AGENT_SLUG` | Lowercase identifier (paths, commands) | Discovery A | Claude Code (CLAUDE.md, settings.json), OpenClaw (config.yaml) |
| `AGENT_EMOJI` | Agent emoji identity | Discovery A | OpenClaw (IDENTITY) |
| `AGENT_CHANNEL` | Dedicated channel name | Discovery A | OpenClaw (IDENTITY) |
| `AGENT_ONE_LINE_DESCRIPTION` | Single-sentence description | Discovery A | Hermes (AGENTS, system-prompt) |
| `AGENT_ROLE_DESCRIPTION` | Multi-paragraph role definition | Discovery A + Architecture S6 | OpenClaw (IDENTITY), Hermes (AGENTS, system-prompt), Claude Code, Common (system-prompt) |
| `AGENT_MISSION` | One-line mission statement | Discovery A | Claude Code |
| `AGENT_DESCRIPTION` | 2-3 sentence description | Discovery A | Claude Code, OpenClaw (config.yaml) |
| `AGENT_DOMAIN` | Primary domain | Discovery A | Hermes (AGENTS), Claude Code |
| `AGENT_VERSION` | Agent version (semver) | Architecture | OpenClaw (config.yaml) |
| `AGENT_OUTPUT_DIR` | Output directory for generated files | Architecture S2 | Hermes (all files) |

## Operator Variables

| Variable | Description | Source | Used In |
|----------|-------------|--------|---------|
| `OPERATOR_NAME` | Operator's name | Discovery B | OpenClaw (USER), Hermes (AGENTS), Claude Code, Common (system-prompt) |
| `OPERATOR_PREFERRED_NAME` | What to call the operator | Discovery B | OpenClaw (USER) |
| `OPERATOR_ROLE` | Operator's role/title | Discovery B | OpenClaw (USER), Hermes (AGENTS), Claude Code |
| `OPERATOR_PRONOUNS` | Operator's pronouns | Discovery B | OpenClaw (USER) |
| `OPERATOR_TIMEZONE` | Operator's timezone | Discovery B | OpenClaw (USER) |
| `OPERATOR_EMAIL` | Operator email | Discovery B | OpenClaw (USER) |
| `OPERATOR_CHANNEL` | Preferred communication channel | Discovery B | OpenClaw (USER) |
| `OPERATOR_CONTEXT` | Brief operator context | Discovery B | OpenClaw (USER), Claude Code |
| `OPERATOR_LANGUAGE` | Operator's default language | Discovery B | OpenClaw (USER) |

## Personality & Communication Variables

| Variable | Description | Source | Used In |
|----------|-------------|--------|---------|
| `SOUL_CORE_STATEMENT` | Fundamental identity statement | Discovery A + Architecture S6 | OpenClaw (SOUL) |
| `SOUL_VIBE` | Communication personality | Discovery A | OpenClaw (SOUL) |
| `PERSONALITY_TONE` | Tone description | Discovery A | Hermes (SOUL, system-prompt) |
| `PERSONALITY_TRAITS` | Comma-separated personality descriptors | Discovery A | Claude Code |
| `PERSONALITY_PRESET` | Built-in Hermes personality preset | Architecture | Hermes (config.yaml) |
| `PERSONALITY_AVOID` | What to avoid in communication | Discovery A | Hermes (SOUL) |
| `COMMUNICATION_STYLE` | How the agent communicates | Discovery A | Hermes (SOUL, system-prompt), Common (system-prompt) |
| `COMMUNICATION_FILTER` | Filter question before responding | Discovery A | OpenClaw (IDENTITY) |
| `INTERACTION_PRINCIPLES` | Interaction guidelines | Discovery A | Hermes (SOUL) |
| `TONE` | Communication tone | Discovery A | Claude Code |
| `PROSE_STYLE` | Prose style rules | Discovery A | Claude Code |
| `DEFAULT_TONE` | Default tone | Discovery A | Common (system-prompt) |

## Behavior & Instructions Variables

| Variable | Description | Source | Used In |
|----------|-------------|--------|---------|
| `CORE_INSTRUCTIONS` | Primary behavioral directives | Architecture S6 | Hermes (AGENTS, system-prompt) |
| `WORKFLOW_STEPS` | Standard operating procedures | Architecture S6 | Hermes (AGENTS) |
| `CONVENTIONS` | Coding/output conventions | Architecture | Hermes (AGENTS) |
| `OUTPUT_FORMAT` | Default output format | Architecture | Hermes (AGENTS), Claude Code |
| `DOMAIN_CONTEXT` | Domain knowledge and org context | Discovery B + Research | Hermes (AGENTS, system-prompt) |

## Responsibility & Scope Variables (Blocks)

| Variable | Description | Source | Used In |
|----------|-------------|--------|---------|
| `{{#CORE_RESPONSIBILITIES}}` | Block: agent's core responsibilities | Discovery A + Architecture | OpenClaw (IDENTITY) |
| `RESPONSIBILITY_INDEX` | Responsibility number | - | OpenClaw (IDENTITY) |
| `RESPONSIBILITY_NAME` | Responsibility short name | - | OpenClaw (IDENTITY) |
| `RESPONSIBILITY_DESCRIPTION` | Responsibility description | - | OpenClaw (IDENTITY) |
| `{{#SCOPE_EXCLUSIONS}}` | Block: things the agent does NOT do | Discovery A + Architecture S7 | OpenClaw (IDENTITY) |
| `EXCLUSION_NAME` | What is excluded | - | OpenClaw (IDENTITY) |
| `EXCLUSION_REASON` | Why it is excluded | - | OpenClaw (IDENTITY) |
| `EXCLUSION_REDIRECT` | Where to redirect instead | - | OpenClaw (IDENTITY) |
| `{{#CHARACTER_NOTES}}` | Block: personality traits | Discovery A | OpenClaw (IDENTITY) |
| `TRAIT` | Trait adjective | - | OpenClaw (IDENTITY) |
| `TRAIT_DESCRIPTION` | Trait explanation | - | OpenClaw (IDENTITY) |

## Guardrails Variables

| Variable | Description | Source | Used In |
|----------|-------------|--------|---------|
| `{{#HARD_RULES}}` | Block: absolute prohibitions | Discovery A + Architecture S7 | OpenClaw (SOUL), Common (guardrails) |
| `RULE_DESCRIPTION` | Rule text | - | OpenClaw (SOUL), Common (guardrails) |
| `{{#ALWAYS_RULES}}` | Block: mandatory behaviors | Discovery A | OpenClaw (SOUL), Common (system-prompt) |
| `{{#ASK_FIRST_RULES}}` | Block: actions requiring approval | Architecture S7 | OpenClaw (SOUL) |
| `HARD_RULES` | NEVER/ALWAYS statements (flat text) | Discovery A + Architecture S7 | Hermes (AGENTS, system-prompt) |
| `GUARDRAILS_HARD` | NEVER-do rules (flat text) | Discovery A + Architecture S7 | Claude Code |
| `GUARDRAILS_SOFT` | SHOULD-avoid rules (flat text) | Architecture S7 | Claude Code |
| `GUARDRAILS_APPROVAL` | Approval-required actions (flat text) | Architecture S7 | Claude Code |
| `APPROVAL_REQUIRED_ACTIONS` | Actions needing confirmation | Architecture S7 | Hermes (AGENTS) |
| `ESCALATION_RULES` | When/how to escalate | Architecture S7 | OpenClaw (SOUL), Hermes (AGENTS), Claude Code |

## Autonomy Variables

| Variable | Description | Source | Used In |
|----------|-------------|--------|---------|
| `AUTONOMOUS_CONDITIONS` | When to act autonomously | Discovery A | OpenClaw (SOUL), Common (system-prompt) |
| `NOTIFY_CONDITIONS` | When to act with notification | Discovery A | OpenClaw (SOUL), Common (system-prompt) |
| `ASK_CONDITIONS` | When to ask before acting | Discovery A | OpenClaw (SOUL), Common (system-prompt) |
| `REFUSE_CONDITIONS` | When to refuse and escalate | Discovery A | OpenClaw (SOUL), Common (system-prompt) |
| `CONFIDENCE_THRESHOLD_HIGH` | High confidence % | Discovery A | OpenClaw (SOUL), Common (guardrails) |
| `CONFIDENCE_THRESHOLD_MED` | Medium confidence % | Discovery A | OpenClaw (SOUL), Common (guardrails) |
| `CONFIDENCE_THRESHOLD_LOW` | Critical uncertainty % | Discovery A | OpenClaw (SOUL), Common (guardrails) |

## Memory Variables

| Variable | Description | Source | Used In |
|----------|-------------|--------|---------|
| `MEMORY_DEMOTION_DAYS` | Days before non-permanent entries are demoted | Architecture S3 | OpenClaw (MEMORY, HEARTBEAT) |
| `MEMORY_MAX_LINES` | Max lines for MEMORY.md | Architecture S3 | OpenClaw (MEMORY, HEARTBEAT) |
| `INTEGRITY_CHECK_CADENCE` | How often integrity checks run | Architecture S3 | OpenClaw (MEMORY, HEARTBEAT) |
| `MEMORY_DIRECTORY_STRUCTURE` | ASCII tree of memory layout | Architecture S3 | OpenClaw (MEMORY) |
| `{{#MEMORY_CATEGORIES}}` | Block: what types of info to remember | Architecture S3 | OpenClaw (MEMORY) |
| `{{#DAY_ZERO_ENTRIES}}` | Block: pre-populated discovery context | Discovery (all) | OpenClaw (MEMORY) |
| `DAY_ZERO_ENTRY` | A single day-zero memory entry | Discovery | OpenClaw (MEMORY) |
| `MEMORY_ENABLED` | true/false | Architecture | Hermes (config.yaml) |
| `USER_PROFILE_ENABLED` | true/false | Architecture | Hermes (config.yaml) |
| `MEMORY_CHAR_LIMIT` | Max chars for Hermes MEMORY.md | Architecture | Hermes (config.yaml) |
| `USER_CHAR_LIMIT` | Max chars for Hermes USER.md | Architecture | Hermes (config.yaml) |
| `PRELOADED_AGENT_MEMORY` | Initial MEMORY.md content | Discovery + Architecture | Hermes (MEMORY) |
| `PRELOADED_USER_PROFILE` | Initial USER.md content | Discovery B | Hermes (USER) |
| `MEMORY_PATH` | Path to memory persistence | Architecture S3 | Claude Code |
| `MEMORY_STRATEGY` | Memory strategy description | Architecture S3 | Claude Code |

## Model & Runtime Variables

| Variable | Description | Source | Used In |
|----------|-------------|--------|---------|
| `MODEL_PROVIDER` | LLM provider | Discovery C + Architecture | Hermes (AGENTS, config.yaml), OpenClaw (config.yaml) |
| `MODEL_NAME` | Model identifier | Discovery C + Architecture | Hermes (AGENTS, config.yaml) |
| `MODEL_PRIMARY` | Full model path (provider/model) | Architecture | OpenClaw (config.yaml) |
| `MODEL_SECONDARY` | Fallback model | Architecture | OpenClaw (config.yaml) |
| `MODEL_TEMPERATURE` | Temperature | Architecture | OpenClaw (config.yaml) |
| `MODEL_MAX_TOKENS` | Max output tokens | Architecture | OpenClaw (config.yaml) |
| `FALLBACK_MODEL_CONFIG` | Fallback model YAML block | Architecture | Hermes (config.yaml) |
| `REASONING_EFFORT` | Reasoning level | Architecture | Hermes (config.yaml) |
| `MAX_TURNS` | Max iterations per turn | Architecture | Hermes (config.yaml) |
| `APPROVAL_MODE` | ask, smart, or off | Architecture | Hermes (config.yaml) |

## Infrastructure & Integration Variables

| Variable | Description | Source | Used In |
|----------|-------------|--------|---------|
| `{{#INFRASTRUCTURE}}` | Block: infrastructure items | Discovery C + Architecture S5 | OpenClaw (TOOLS) |
| `{{#INTEGRATIONS}}` | Block: external integrations | Architecture S5 | OpenClaw (TOOLS) |
| `INTEGRATIONS` | External services (flat text) | Architecture S5 | Hermes (AGENTS), Claude Code |
| `KEY_PATHS_TABLE` | Markdown table of key paths | Architecture | Hermes (AGENTS) |
| `{{#CHANNELS}}` | Block: communication channels | Discovery A | OpenClaw (TOOLS) |
| `{{#TOOL_CAPABILITIES}}` | Block: tool capability matrix | Architecture S5 | OpenClaw (TOOLS) |
| `WORKSPACE_PATH` | Agent workspace path | Architecture | OpenClaw (config.yaml) |

## Heartbeat & Scheduling Variables

| Variable | Description | Source | Used In |
|----------|-------------|--------|---------|
| `HAS_HEARTBEAT` | Boolean flag for heartbeat | Architecture S6 | OpenClaw (HEARTBEAT, config.yaml) |
| `HEARTBEAT_INTERVAL` | Heartbeat cycle in minutes | Architecture S6 | OpenClaw (config.yaml) |
| `{{#SCHEDULED_TASKS}}` | Block: scheduled autonomous tasks | Discovery C + Architecture S6 | OpenClaw (HEARTBEAT) |
| `{{#MONITORS}}` | Block: passive monitoring items | Architecture S6 | OpenClaw (HEARTBEAT) |
| `{{#REMINDERS}}` | Block: one-off reminders | Operator | OpenClaw (HEARTBEAT) |
| `MAX_CONSECUTIVE_FAILURES` | Circuit breaker threshold | Architecture S7 | OpenClaw (HEARTBEAT) |
| `ERROR_ALERT_CHANNEL` | Where to alert on circuit break | Architecture S7 | OpenClaw (HEARTBEAT) |
| `{{#TASK_ERROR_BUDGETS}}` | Block: per-task error budgets | Architecture S7 | OpenClaw (HEARTBEAT) |

## Multi-Agent Variables

| Variable | Description | Source | Used In |
|----------|-------------|--------|---------|
| `HAS_MULTI_AGENT` | Boolean flag for multi-agent | Discovery A | OpenClaw (AGENTS) |
| `{{#AGENT_ROSTER}}` | Block: agents in ecosystem | Discovery A + Architecture S8 | OpenClaw (AGENTS) |
| `{{#COORDINATION_RULES}}` | Block: inter-agent rules | Architecture S8 | OpenClaw (AGENTS) |
| `HANDOFF_FORMAT` | Handoff template | Architecture S8 | OpenClaw (AGENTS) |
| `CONFLICT_RESOLUTION_PROTOCOL` | What happens on disagreement | Architecture S8 | OpenClaw (AGENTS) |

## Error Recovery Variables

| Variable | Description | Source | Used In |
|----------|-------------|--------|---------|
| `MAX_RETRIES` | Max retry attempts | Architecture S7 | OpenClaw (SOUL), Common (guardrails) |
| `BACKOFF_STRATEGY` | Retry backoff pattern | Architecture S7 | OpenClaw (SOUL), Common (guardrails) |
| `AFTER_MAX_RETRIES` | Action after retries exhausted | Architecture S7 | OpenClaw (SOUL), Common (guardrails) |
| `{{#ERROR_RECOVERY_PROCEDURES}}` | Block: error recovery steps | Architecture S7 | OpenClaw (SOUL), Common (guardrails) |

## Data & Compliance Variables

| Variable | Description | Source | Used In |
|----------|-------------|--------|---------|
| `SECRETS_MECHANISM` | How secrets are accessed | Architecture S7 | OpenClaw (SOUL), Common (guardrails) |
| `SECRET_EXPOSURE_PROTOCOL` | What to do on accidental exposure | Architecture S7 | OpenClaw (SOUL), Common (guardrails) |
| `{{#DATA_CLASSIFICATIONS}}` | Block: data classification table | Architecture S7 | OpenClaw (SOUL), Common (guardrails) |
| `{{#COMPLIANCE_REGULATIONS}}` | Block: applicable regulations | Research + Discovery B | OpenClaw (SOUL), Common (guardrails) |
| `AUDIT_WHAT` | What gets logged | Architecture S7 | OpenClaw (SOUL), Common (guardrails) |
| `AUDIT_FORMAT` | Log format | Architecture S7 | OpenClaw (SOUL), Common (guardrails) |
| `AUDIT_RETENTION` | Retention period | Architecture S7 | OpenClaw (SOUL), Common (guardrails) |

## Channel Routing Variables (OpenClaw config.yaml)

| Variable | Description | Source | Used In |
|----------|-------------|--------|---------|
| `HAS_DISCORD` | Boolean: agent uses Discord | Discovery C | OpenClaw (config.yaml) |
| `DISCORD_GUILD_ID` | Discord server ID | Discovery C | OpenClaw (config.yaml) |
| `DISCORD_CHANNELS` | Discord channel routing YAML | Discovery C | OpenClaw (config.yaml) |
| `HAS_SLACK` | Boolean: agent uses Slack | Discovery C | OpenClaw (config.yaml) |
| `SLACK_WORKSPACE` | Slack workspace ID | Discovery C | OpenClaw (config.yaml) |
| `SLACK_CHANNELS` | Slack channel routing YAML | Discovery C | OpenClaw (config.yaml) |
| `HAS_CLI` | Boolean: CLI-accessible agent | Discovery C | OpenClaw (config.yaml) |

## Hermes Display & Performance Variables

| Variable | Description | Source | Used In |
|----------|-------------|--------|---------|
| `TERMINAL_BACKEND` | local, docker, ssh | Architecture | Hermes (config.yaml) |
| `TERMINAL_TIMEOUT` | Command timeout in seconds | Architecture | Hermes (config.yaml) |
| `TERMINAL_EXTRA_CONFIG` | Additional terminal YAML | Architecture | Hermes (config.yaml) |
| `COMPRESSION_ENABLED` | true/false | Architecture | Hermes (config.yaml) |
| `COMPRESSION_THRESHOLD` | Float threshold | Architecture | Hermes (config.yaml) |
| `TOOL_PROGRESS` | off, new, all, verbose | Architecture | Hermes (config.yaml) |
| `SKIN` | Terminal skin name | Architecture | Hermes (config.yaml) |
| `STREAMING_ENABLED` | true/false | Architecture | Hermes (config.yaml) |
| `SHOW_REASONING` | true/false | Architecture | Hermes (config.yaml) |
| `EXTRA_CONFIG` | Additional YAML sections | Architecture | Hermes (config.yaml), OpenClaw (config.yaml) |

## Hermes Skills Variables

| Variable | Description | Source | Used In |
|----------|-------------|--------|---------|
| `SKILLS_INSTALL_LIST` | YAML list of skills to install | Architecture | Hermes (skills-manifest) |
| `SKILLS_CREATE_LIST` | YAML list of custom skills | Architecture | Hermes (skills-manifest) |
| `SKILLS_INSTALL_COMMANDS` | Bash commands for installation | Architecture | Hermes (setup.sh) |

## Claude Code Specific Variables

| Variable | Description | Source | Used In |
|----------|-------------|--------|---------|
| `LANGUAGE` | Default communication language | Discovery B | Claude Code |
| `TECH_LANGUAGE` | Language for technical artifacts | Discovery B | Claude Code |
| `DOMAIN` | Primary domain | Discovery A | Claude Code |
| `PROJECT_ROOT` | Absolute path to working directory | Architecture | Claude Code |
| `FOLDER_STRUCTURE` | ASCII tree of project structure | Architecture S2 | Claude Code |
| `COMMANDS_LIST` | Table of available commands | Architecture | Claude Code |
| `SKILLS_LIST` | Installed skills with descriptions | Architecture | Claude Code |
| `TOOLS_ALLOWED` | Permitted tools | Architecture S5 | Claude Code |
| `TOOLS_DENIED` | Denied tools | Architecture S7 | Claude Code |
| `KNOWLEDGE_HOT` | Files to load every session | Architecture S3 | Claude Code |
| `KNOWLEDGE_VAULT` | Path to deep knowledge | Architecture S3 | Claude Code |
| `SHORTHAND_TABLE` | Domain abbreviation table | Discovery B | Claude Code |
| `WORKFLOWS` | Defined workflows with triggers | Architecture S6 | Claude Code |
| `EVAL_CRITERIA` | Output quality criteria | Architecture | Claude Code |

## Claude Code Permissions Variables (settings.json)

| Variable | Description | Source | Used In |
|----------|-------------|--------|---------|
| `{{#ALLOWED_BASH_COMMANDS}}` | Block: permitted bash commands | Architecture S7 | Claude Code (settings.json) |
| `COMMAND` | A single bash command pattern | - | Claude Code (settings.json) |
| `{{#ALLOWED_FILE_READ_PATTERNS}}` | Block: readable file patterns | Architecture S7 | Claude Code (settings.json) |
| `{{#ALLOWED_FILE_EDIT_PATTERNS}}` | Block: editable file patterns | Architecture S7 | Claude Code (settings.json) |
| `{{#DENIED_BASH_COMMANDS}}` | Block: denied bash commands | Architecture S7 | Claude Code (settings.json) |
| `{{#DENIED_FILE_PATTERNS}}` | Block: denied file patterns | Architecture S7 | Claude Code (settings.json) |
| `PATTERN` | A single file glob pattern | - | Claude Code (settings.json) |
| `{{#ALLOWED_MCP_TOOLS}}` | Block: permitted MCP tools | Architecture S5 | Claude Code (settings.json) |
| `{{#DENIED_MCP_TOOLS}}` | Block: denied MCP tools | Architecture S7 | Claude Code (settings.json) |
| `MCP_TOOL` | A single MCP tool pattern | - | Claude Code (settings.json) |
| `SESSION_START_HOOK` | Session start hook command | Architecture | Claude Code (settings.json) |
| `POST_TOOL_HOOK` | Post-tool-use hook command | Architecture | Claude Code (settings.json) |
| `STATUS_LINE_COMMAND` | Status line command | Architecture | Claude Code (settings.json) |

## Claude Code Command Variables (command.md)

| Variable | Description | Source | Used In |
|----------|-------------|--------|---------|
| `COMMAND_NAME` | Command name (lowercase, hyphens) | Architecture | Claude Code (command.md) |
| `COMMAND_DESCRIPTION` | One-line description | Architecture | Claude Code (command.md) |
| `COMMAND_INSTRUCTIONS` | Detailed instructions | Architecture | Claude Code (command.md) |
| `COMMAND_INPUTS` | Expected inputs/arguments | Architecture | Claude Code (command.md) |
| `COMMAND_OUTPUT` | What the command produces | Architecture | Claude Code (command.md) |
| `COMMAND_GUARDRAILS` | Command-specific guardrails | Architecture S7 | Claude Code (command.md) |
| `COMMAND_EXAMPLES` | Usage examples | Architecture | Claude Code (command.md) |

## Embeddings Variables (common/embeddings-config)

| Variable | Description | Source | Used In |
|----------|-------------|--------|---------|
| `EMBEDDINGS_PROVIDER` | Provider: faiss, chromadb, pgvector, openai, gemini | Discovery C | Common (embeddings-config), OpenClaw (config.yaml) |
| `EMBEDDINGS_MODEL` | Model for generating embeddings | Discovery C | Common (embeddings-config), OpenClaw (config.yaml) |
| `EMBEDDINGS_DIMENSIONS` | Vector dimensions | Architecture | Common (embeddings-config) |
| `EMBEDDINGS_STORAGE_PATH` | Path to store vectors | Architecture S3 | Common (embeddings-config) |
| `CHUNK_SIZE` | Document chunk size (chars) | Architecture | Common (embeddings-config) |
| `CHUNK_OVERLAP` | Overlap between chunks (chars) | Architecture | Common (embeddings-config) |
| `TOP_K` | Results per search query | Architecture | Common (embeddings-config) |
| `SIMILARITY_THRESHOLD` | Minimum similarity score | Architecture | Common (embeddings-config) |
| `{{#COLLECTIONS}}` | Block: vector collections | Architecture S3 | Common (embeddings-config) |
| `CHUNKING_STRATEGY` | How to split documents | Architecture | Common (embeddings-config) |
| `SEARCH_METHOD` | similarity, mmr, hybrid | Architecture | Common (embeddings-config) |

## Org Profile Variables (common/org-profile)

| Variable | Description | Source | Used In |
|----------|-------------|--------|---------|
| `ORG_NAME` | Organization name | Discovery B | Common (org-profile, system-prompt) |
| `ORG_INDUSTRY` | Industry | Discovery B | Common (org-profile) |
| `ORG_SUBSECTOR` | Sub-sector | Discovery B | Common (org-profile) |
| `ORG_SIZE` | Employee count | Discovery B | Common (org-profile) |
| `ORG_MARKET` | Target market | Discovery B | Common (org-profile) |
| `ORG_DESCRIPTION` | What the org does | Discovery B | Common (org-profile) |
| `ORG_BUSINESS_MODEL` | Business model | Discovery B | Common (org-profile) |

---

## Variable Normalization Notes

### Same Concept, Different Names (by design)

Some variables intentionally differ between runtimes because the output format differs:

- **`AGENT_NAME`** (Hermes, Claude Code) vs **`AGENT_DISPLAY_NAME`** (OpenClaw) — OpenClaw distinguishes between slug and display name; Hermes uses one name for both.
- **`HARD_RULES`** (flat text, Hermes) vs **`{{#HARD_RULES}}`** (block, OpenClaw/Common) — Hermes templates use pre-formatted text; OpenClaw templates iterate over structured data.
- **`GUARDRAILS_HARD`** (Claude Code) vs **`HARD_RULES`** (Hermes) vs **`{{#HARD_RULES}}`** (OpenClaw) — Same concept, three formats. The build command must map from structured data to the format each runtime expects.

### Build Command Responsibility

The build command (`/ask:build`) must:
1. Read the accumulated state files (discovery.md, agent-spec.md, architecture.md)
2. Map state data to the appropriate variable format per runtime
3. Resolve all `{{VARIABLE}}` references in the target template
4. Verify no unresolved `{{` remains in the output
