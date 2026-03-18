# ASK — Agent Setup Kit

ASK is for agents what GSD is for code. A phased framework that takes you from "I need an agent that does X" to a fully configured agent with context, memory, skills, prompts, guardrails — tested and ready to operate.

## Quick Start

```bash
# 1. Start a new agent build
/ask:new my-agent-name

# 2. The system enters Discovery automatically
# Answer the interview questions — this is the most important phase

# 3. When Discovery is done, continue through phases:
/ask:research        # Deep research on domain, skills, architecture
/ask:architecture    # Design the complete agent system
/ask:build           # Generate all files
/ask:validate        # Test the agent
/ask:iterate         # Adjust based on feedback

# Check progress at any time:
/ask:progress
```

## How It Works

```
/ask:new → Discovery → Research → Architecture → [APPROVAL] → Build → Validate → Iterate → Done
```

**Discovery** is the most critical phase. ASK conducts an adaptive interview across three blocks:
- **Block A** — The agent: mission, autonomy, interactions, personality, guardrails
- **Block B** — The organization: company, team, processes, stakeholders
- **Block C** — Technical: runtime, model, integrations, memory, embeddings

The quality of the agent depends directly on the quality of this interview.

**Research** investigates the domain, audits available skills, identifies architecture patterns, and compiles prompt engineering techniques.

**Architecture** designs the complete system — files, knowledge layer, skills, integrations, system prompt, guardrails, validation plan. Requires explicit approval before proceeding.

**Build** generates all production-ready files. No placeholders, no TODOs — every file is complete.

**Validate** runs three levels: technical checklist, smoke test with representative messages, and optional eval suite.

**Iterate** adjusts based on feedback until the operator says "ship it."

## Commands

| Command | Description |
|---|---|
| `/ask:new <name>` | Start a new agent build |
| `/ask:discovery` | Run or resume the adaptive interview |
| `/ask:research` | Deep research (domain, skills, architecture, prompts) |
| `/ask:architecture` | Design the complete agent system |
| `/ask:build` | Generate all agent files |
| `/ask:validate` | Test the agent (checklist + smoke test + eval) |
| `/ask:iterate` | Adjust based on feedback |
| `/ask:progress` | Show current build status |
| `/ask:skip` | Skip current phase (with quality warning) |
| `/ask:resume` | Resume from where you left off |
| `/ask:export <path>` | Export agent files to a target directory |
| `/ask:crew <name> <n>` | Build a coordinated multi-agent crew of N agents |

## Supported Runtimes

| Runtime | Generated Files |
|---|---|
| **OpenClaw** | SOUL.md, IDENTITY.md, USER.md, MEMORY.md, TOOLS.md, HEARTBEAT.md, AGENTS.md, config.yaml |
| **Claude Code** | CLAUDE.md, .claude/settings.json, commands/, skills/ |
| **Hermes** | AGENTS.md, SOUL.md, config.yaml, MEMORY.md, tool-definitions.json, system-prompt.md |

All runtimes include a knowledge layer: `memory/vault/`, `memory/hot-context/`, `memory/.embeddings/`

## Multi-Agent Crew Support

ASK supports building coordinated multi-agent crews via `/ask:crew`. The crew builder orchestrates:

- **Shared Discovery** — Organizational context (Block B) and shared technical context (Block C) are captured once for the entire crew
- **Per-Agent Discovery** — Each agent gets its own Block A interview for mission, personality, and guardrails
- **Interaction Matrix** — Defines who talks to whom, about what, using what protocol
- **Coordination Topology** — Supervisor, peer-to-peer, sequential, or hybrid patterns
- **Crew Architecture** — All agents designed together with interaction diagrams, shared memory, and cost estimation
- **Batch Build** — All agent files generated in one pass with shared assets and handoff protocols
- **Crew Validation** — Individual agent validation plus systemic checks (handoff consistency, naming, circular dependencies)

Crew state is managed in `ask-state/crew-state.json`. Output goes to `output/<crew-name>/` with per-agent directories and shared assets.

## Pre-Flight Check

Before starting a build, verify ASK is ready:

```bash
./scripts/preflight-check.sh
```

This checks:
- Directory structure integrity (commands, templates, references)
- All required templates exist per runtime
- Reference library has content
- Required tools are available (python3, node, git)
- Optional tools status (hermes, openclaw, claude, docker)
- Whether there is an active build in progress

## Project Structure

```
ask/
├── commands/          # 12 command specs (the pipeline logic, including crew)
├── templates/         # File templates per runtime
│   ├── openclaw/      # 7 templates (SOUL, IDENTITY, USER, MEMORY, TOOLS, HEARTBEAT, AGENTS)
│   ├── hermes/        # Multi-file agent template
│   ├── claude-code/   # CLAUDE.md + settings.json templates
│   └── common/        # Shared: guardrails, system-prompt, org-profile
├── references/        # Best practices library (12 reference docs)
├── scripts/           # skill-audit.sh, validate-agent.sh, preflight-check.sh
└── ask-state/         # Per-build state (created during agent builds)
```

## State Management

Each agent build persists state in `ask-state/`:

| File | Purpose |
|---|---|
| `state.json` | Phase tracking, decisions, runtime, model |
| `discovery.md` | Complete interview transcript |
| `agent-spec.md` | Agent behavior specification |
| `org-profile.md` | Organizational context |
| `research.md` | Domain research, skills audit, patterns |
| `architecture.md` | Approved design document |
| `build-log.md` | What was generated |
| `validation-report.md` | Test results |

## Reference Library

ASK consults these during the Research phase:

| Reference | Covers |
|---|---|
| `anthropic-agent-guide.md` | Building effective agents, tool use, safety, 6 architecture patterns |
| `openai-agent-patterns.md` | Agent SDK, function calling, Swarm, guardrails |
| `langgraph-patterns.md` | StateGraph, ReAct, multi-agent (supervisor/swarm), human-in-the-loop |
| `crewai-patterns.md` | Role-based design, crew composition, memory system |
| `openclaw-conventions.md` | File structure, memory architecture, multi-agent patterns |
| `hermes-conventions.md` | Agent file format, tool use XML tags, config |
| `eliza-concepts.md` | Character files, personality layers, memory, plugins |
| `openfang-patterns.md` | Hands system, capability manifests, skills as markdown |
| `prompt-engineering.md` | CoT, few-shot, system prompt architecture, anti-patterns |
| `mcp-patterns.md` | Model Context Protocol, tool interoperability, transport, security |
| `evaluation-frameworks.md` | Agent evaluation metrics, frameworks (Braintrust, DeepEval, RAGAS), testing patterns |
| `deployment-patterns.md` | Production deployment, containerization, secrets, monitoring, versioning |

## Design Principles

1. **Discovery-driven** — Better interview = better agent
2. **Sequential with stops** — Each phase pauses. The operator decides what's next.
3. **Skippable** — You can skip phases, but the system warns about quality impact
4. **Conversational** — Commands are shortcuts, not walls
5. **Anti-amnesia by design** — Memory layer from minute zero
6. **Runtime-agnostic** — Best practices adapt to the chosen runtime
7. **Always reviewable** — Go back and modify at any point

## Language

Communication in Spanish (Argentina) by default. Code and technical files in English.
