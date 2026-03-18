# OpenClaw Conventions Reference

Reference document for ASK build templates. Covers OpenClaw's file structure, naming conventions, memory architecture, and runtime behavior.

Last updated: 2026-03-17

---

## Overview

OpenClaw is a local-first, open-source AI agent framework. Agents are defined by plain Markdown files in a workspace directory. No database, no API for configuration — just files you can edit, version, and diff. The framework hit 214k+ GitHub stars by February 2026.

Key properties:
- **Local-first:** Memory stored as Markdown on disk. The model only "remembers" what gets written to files.
- **File-driven identity:** SOUL.md, IDENTITY.md, USER.md, etc. define who the agent is.
- **Autonomous scheduling:** A heartbeat daemon runs tasks without user prompting.
- **Multi-agent capable:** Multiple agents coordinate via AGENTS.md and handoff protocols.

---

## Workspace Structure

Default workspace: `~/.openclaw/workspace` (configurable per agent via `openclaw.json`).

```
workspace/
  SOUL.md            # Behavioral philosophy, operating principles, guardrails
  IDENTITY.md        # Name, personality, role description, communication rules
  USER.md            # Operator profile, preferences, team context
  TOOLS.md           # Environment-specific configuration (local notes)
  AGENTS.md          # Session boot sequence, behavior rules, multi-agent coordination
  HEARTBEAT.md       # Autonomous/scheduled tasks, nightly maintenance
  MEMORY.md          # Curated long-term memory (optional, loaded in main sessions)
  regressions.md     # Past failures converted to permanent guardrails (optional)
  friction-log.md    # Open conflicts in instructions or business rules (optional)
  memory/
    YYYY-MM-DD.md    # Daily logs (append-only, one per day)
    archive.md       # Demoted entries from MEMORY.md
    bank/
      decisions.md   # All decisions, including archived
      research.md    # Research findings and domain knowledge
      incidents.md   # Post-mortems and error learnings
    conflicts.md     # Contradictions found during integrity checks
```

### File Hierarchy

Files load in a specific order. The first three are mandatory for all agents:

1. **SOUL.md** (required) — The constitution. Behavioral philosophy, not metadata.
2. **IDENTITY.md** (required) — Presentation layer. Name, role, personality.
3. **USER.md** (required) — Operator profile. Who the agent serves.
4. **AGENTS.md** (required) — Boot sequence and workspace behavior.
5. **TOOLS.md** (required) — Local environment configuration.
6. **HEARTBEAT.md** (required, can be empty) — Autonomous tasks. Empty file = no heartbeat.
7. **MEMORY.md** (optional) — Long-term curated memory. Only loaded in main/private sessions.

### Created by Default

When you run `openclaw setup` or create a new agent, the framework generates starter versions of: AGENTS.md, SOUL.md, TOOLS.md, IDENTITY.md, USER.md, HEARTBEAT.md.

---

## File Conventions

### SOUL.md

The agent's behavioral constitution. Defines HOW it thinks, not WHAT it does.

**Sections:**
- **Core** — Fundamental identity statement. Direct address ("You are..."). 2-4 paragraphs.
- **Vibe** — Communication personality. Brevity, humor, formality level.
- **Operating Principles** — Non-negotiable behavioral rules. Actionable, specific.
- **Guardrails** — Hard boundaries (NEVER), mandatory behaviors (ALWAYS), approval gates.
- **Autonomy** — Confidence thresholds and decision-making protocol.
- **Self-Evolution** — How the agent proposes improvements to its own files.

**Key conventions:**
- Write in direct address ("You have opinions", not "The agent has opinions").
- Avoid generic "helpful AI" language. Be specific to this agent's domain.
- Guardrails override everything — including direct user requests.
- The agent can propose changes to SOUL.md but NEVER edits it without approval.
- Security lockdown: core workspace files never leave the environment.

### IDENTITY.md

The agent's presentation layer. Who it IS in the world.

**Sections:**
- Header with Name, Emoji, Channel (if applicable)
- **Role** — Elevator pitch. One paragraph of what the agent does.
- **What I Do** — Numbered list of core responsibilities.
- **Character Notes** — Personality traits as adjective + explanation.
- **Communication Rules** — Concrete directives for how to communicate.
- **Reading and Analysis Rules** — How to handle documents and data.

**Key conventions:**
- The emoji is part of the agent's identity — used naturally, not as decoration.
- Character notes are descriptors, not rules (rules live in SOUL.md).
- Communication rules should include a filter question (e.g., "Does this have a concrete action or is it noise?").

### USER.md

The operator profile. Helps the agent calibrate to the human.

**Sections:**
- Header with Name, Pronouns, Timezone, Role
- **Context** — What the operator does and how the agent fits in.
- **Work Style** — How the operator prefers to work.
- **Communication Preferences** — Language, format, length preferences.
- **Team and Stakeholders** — Other people in the ecosystem.

**Key conventions:**
- Starts sparse, grows over time as the agent learns.
- The agent should propose additions when it notices patterns.
- Privacy: USER.md is only loaded in main/private sessions.

### MEMORY.md

Curated long-term memory. The stable counterpart to daily logs.

**Sections:**
- **Active Context** — Current state of the world.
- **Decisions** — Key decisions with dates and rationale.
- **Learnings** — Patterns and calibrations from experience.
- **Preferences** — Operator preferences discovered through interaction.

**Key conventions:**
- Maximum 80 lines. Enforced by nightly maintenance.
- Mark critical entries as `[permanent]` to protect from demotion.
- Only loads in main/private sessions (never in group contexts).
- If both MEMORY.md and memory.md exist, only MEMORY.md loads.

### TOOLS.md

Environment-specific local notes. The agent's cheat sheet.

**Key conventions:**
- Skills (shared) vs TOOLS.md (local). Keep them separate.
- Infrastructure details, service endpoints, channel routing.
- Security rules about what never gets committed.
- "Add whatever helps you do your job."

### HEARTBEAT.md

Autonomous tasks and nightly maintenance.

**Key conventions:**
- Empty file (or comments only) = heartbeat daemon skips API calls.
- Default cycle: every 30 minutes (configurable).
- Checkpoint protocol: structured log entries to daily log file.
- Nightly maintenance: memory promotion, demotion, cap check, integrity.

### AGENTS.md

Boot sequence and workspace coordination.

**Key conventions:**
- Defines the "Every Session" boot order (what files to read first).
- Memory file locations and their purposes.
- Multi-agent section only when applicable.
- Security rules for the workspace.

---

## Memory Architecture

OpenClaw uses a two-layer memory system:

### Layer 1: Daily Logs (`memory/YYYY-MM-DD.md`)

- **Append-only** — never modify past entries.
- **One file per day** — created automatically.
- **Loaded at session start:** today's + yesterday's logs.
- **Format:** Checkpoints with timestamp, discussed, decided, open, changed.
- **Ephemeral** — not meant for long-term storage.

### Layer 2: Long-Term Memory (`MEMORY.md`)

- **Curated** — only important, stable information.
- **Capped** — 80 lines max (enforced by nightly maintenance).
- **Permanent entries** — marked `[permanent]`, immune to demotion.
- **Only in private sessions** — never loaded in group/shared contexts.

### Memory Banks (`memory/bank/`)

- `decisions.md` — All decisions, including those demoted from MEMORY.md.
- `research.md` — Research findings, domain knowledge.
- `incidents.md` — Post-mortems, error learnings.

### Lifecycle

```
Daily log entry
    |
    v (appears in 2+ daily logs)
Promoted to MEMORY.md
    |
    v (older than 14 days, not [permanent])
Demoted to memory/archive.md
    |
    v (categorized)
Sorted into memory/bank/
```

---

## Multi-Agent Patterns

### Agent Registration

Agents are registered via `openclaw agents add <name>`. Configuration lives in `~/.openclaw/openclaw.json`:

```json
{
  "agents": {
    "named": {
      "agent-name": {
        "model": { "primary": "anthropic/claude-sonnet-4-6" },
        "workspace": "~/.openclaw/agents/agent-name/workspace"
      }
    }
  }
}
```

### Coordination

- Each agent has its own workspace with its own SOUL/IDENTITY/USER files.
- Orchestrator pattern: one agent coordinates, sub-agents execute.
- Handoffs use a structured format (task, context, input, expected output, priority).
- Quality control: orchestrator rejects low-confidence sub-agent output.
- Status flows up to orchestrator, not laterally between sub-agents.

### Channels

Agents can be assigned to specific Discord/Slack channels:

```json
{
  "channels": {
    "discord": {
      "guilds": {
        "guild-id": {
          "channels": {
            "agent-name": { "allow": true }
          }
        }
      }
    }
  }
}
```

---

## Runtime Configuration

### openclaw.json

Central configuration at `~/.openclaw/openclaw.json`. Key settings:

- `agents.defaults.workspace` — Default workspace path
- `agents.defaults.model` — Default model for all agents
- `agents.named.<name>.model.primary` — Per-agent model override
- `agents.named.<name>.workspace` — Per-agent workspace path
- `channels.discord.guilds` — Discord channel routing

### Models

Common model options:
- `anthropic/claude-sonnet-4-6` — Default, recommended for most agents
- `anthropic/claude-haiku-4-5` — Faster and cheaper, for high-throughput tasks

### Skills

Skills are shared tool definitions that agents can use. They live separately from workspace files and define HOW tools work. TOOLS.md in the workspace captures the local/environment-specific configuration.

---

## Template Variable Mapping

How ASK Discovery/Architecture outputs map to OpenClaw template variables:

| Discovery Source | Architecture Source | OpenClaw File | Template Variable |
|---|---|---|---|
| Block A: function/mission | Section 6: role definition | SOUL.md | `SOUL_CORE_STATEMENT` |
| Block A: personality/tone | Section 6: personality | SOUL.md | `SOUL_VIBE` |
| Block A: guardrails | Section 7: guardrails | SOUL.md | `HARD_RULES`, `ALWAYS_RULES`, `ASK_FIRST_RULES` |
| Block A: autonomy | Section 7: confidence | SOUL.md | `AUTONOMOUS_CONDITIONS`, `CONFIDENCE_THRESHOLD_*` |
| Block A: personality | Section 6: personality | IDENTITY.md | `CHARACTER_NOTES`, `COMMUNICATION_RULES` |
| Block A: function | Section 2: file manifest | IDENTITY.md | `AGENT_ROLE_DESCRIPTION`, `CORE_RESPONSIBILITIES` |
| Block B: team/stakeholders | — | USER.md | `TEAM_MEMBERS`, `OPERATOR_CONTEXT` |
| Block B: processes | — | USER.md | `WORK_STYLE_NOTES` |
| Block C: memory | Section 3: knowledge layer | MEMORY.md | `MEMORY_CATEGORIES`, `MEMORY_DIRECTORY_STRUCTURE` |
| Block C: integrations | Section 5: integrations | TOOLS.md | `INFRASTRUCTURE`, `INTEGRATIONS`, `CHANNELS` |
| Block C: cron/heartbeat | Section 6: autonomous tasks | HEARTBEAT.md | `SCHEDULED_TASKS`, `MONITORS` |
| Block A: interactions | Section 8: architecture | AGENTS.md | `AGENT_ROSTER`, `COORDINATION_RULES` |

---

## Sources

- [OpenClaw Official Documentation](https://docs.openclaw.ai)
- [SOUL.md Template Reference](https://docs.openclaw.ai/reference/templates/SOUL)
- [IDENTITY Template Reference](https://docs.openclaw.ai/reference/templates/IDENTITY)
- [USER Template Reference](https://docs.openclaw.ai/reference/templates/USER)
- [AGENTS.md Template Reference](https://docs.openclaw.ai/reference/templates/AGENTS)
- [HEARTBEAT.md Template Reference](https://docs.openclaw.ai/reference/templates/HEARTBEAT)
- [TOOLS.md Template Reference](https://docs.openclaw.ai/reference/templates/TOOLS)
- [Memory Concepts](https://docs.openclaw.ai/concepts/memory)
- [Multi-Agent Routing](https://docs.openclaw.ai/concepts/multi-agent)
- [Agent Workspace Concepts](https://docs.openclaw.ai/concepts/agent-workspace)
- [Heartbeat Gateway](https://docs.openclaw.ai/gateway/heartbeat)
- [Configuration Reference](https://docs.openclaw.ai/gateway/configuration-reference)
- [Default AGENTS.md](https://docs.openclaw.ai/reference/AGENTS.default)
- [OpenClaw Memory Architecture Guide](https://zenvanriel.com/ai-engineer-blog/openclaw-memory-architecture-guide/)
- [OpenClaw Memory Explained](https://lumadock.com/tutorials/openclaw-memory-explained)
- [Awesome OpenClaw Agents](https://github.com/mergisi/awesome-openclaw-agents)
- [OpenClaw Complete 2026 Guide](https://alphatechfinance.com/productivity-app/openclaw-ai-agent-2026-guide/)
