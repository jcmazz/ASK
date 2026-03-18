# OpenFang — Agent Patterns for ASK

> Reference document extracting transferable patterns from OpenFang.
> Note: "OpenFang" refers to TWO distinct projects. Both are documented here.

---

## 1. Overview

There are two projects named OpenFang with different architectures but overlapping concepts:

### OpenFang OS (RightNow-AI/openfang)

A Rust-based **Agent Operating System** — 137K lines of code, compiled to a single ~32MB binary. Not a chatbot framework but a full OS for autonomous agents. Launched February 2026.

Key numbers: 14 crates, 53 tools, 40 channel adapters, 16 security layers, 140+ REST endpoints, 1,767+ tests.

### OpenFang Gateway (aidiss/openfang)

A Python-based **lightweight agent gateway** (~5K lines) connecting LLMs to messaging channels. Built on pydantic-ai, FastAPI, HTMX. Designed to be "understood in an afternoon."

Both share the concept of agents as configurable, skill-equipped entities with persistent memory — but at vastly different scales.

---

## 2. Agent Patterns

### OpenFang OS: "Hands" — Autonomous Capability Packages

The core innovation. Hands are NOT chatbot agents — they are autonomous processes that run on schedules, build knowledge, and report results.

Each Hand bundles:

| Component | Format | Purpose |
|-----------|--------|---------|
| **HAND.toml** | TOML manifest | Declares tools, settings, requirements, metrics |
| **System Prompt** | Multi-phase playbook | 500+ word expert procedures (not one-liners) |
| **SKILL.md** | Markdown | Domain expertise injected into context at runtime |
| **Guardrails** | Config | Approval gates for sensitive actions |
| **Dashboard Metrics** | Config | What gets shown in the monitoring UI |

All components compile into the binary — zero external downloads.

#### HAND.toml Structure

```toml
[hand]
name = "researcher"
version = "0.3.30"
description = "Deep autonomous research Hand"
tools = ["web_search", "browser", "file_writer"]

[settings]
default_model = "claude-3-opus"
max_research_depth = 5
source_credibility_threshold = 0.75

[dashboard]
# Metrics displayed in UI

[guardrails]
# Approval gates and safety constraints

[integrations]
# External service connections
```

#### The 7 Bundled Hands

| Hand | Domain | Key Pattern |
|------|--------|-------------|
| **Clip** | Content creation | 8-phase pipeline (download, identify moments, generate shorts, add captions, publish) |
| **Lead** | Sales intelligence | ICP matching, 0-100 scoring, deduplication, enrichment |
| **Collector** | OSINT | Continuous monitoring, change detection, knowledge graph construction |
| **Predictor** | Forecasting | Superforecasting methodology, Brier score tracking, contrarian mode |
| **Researcher** | Knowledge work | CRAAP credibility evaluation, multi-source cross-referencing, cited reports |
| **Twitter** | Social media | 7 content formats, engagement scheduling, mandatory approval queue |
| **Browser** | Web automation | Playwright-based, session persistence, purchase approval gate |

#### Agent Execution Loop

```
Trigger (schedule/user) -> Route to tools (53 built-in) -> WASM sandbox execution -> SQLite persistence -> Response via channel adapter -> Merkle audit trail
```

### OpenFang Gateway: YAML Agent Personas

Simpler, more ASK-aligned pattern. Agents are YAML files in an `agents/` directory.

Architecture:

```
agents/        # YAML persona definitions
capabilities/  # Adapters (files, memory, shell, web)
channels/      # Messaging platforms (Telegram, Discord)
skills/        # Markdown skill definitions
subagents/     # Specialized task delegation
messaging/     # Dispatch and session resolution
gateway/       # FastAPI + web UI
```

Key patterns:
- **Agent = YAML persona** — identity and behavior in a config file
- **Skills = Markdown files** — human-readable, no code required
- **Subagents** — specialized task delegation for complex workflows
- **Capabilities as adapters** — file ops, memory, shell, web are pluggable

Design principles:
1. **Readable first** — every file understandable independently
2. **Leverage existing libraries** — heavy lifting by pydantic-ai, FastAPI, Playwright
3. **Protocol-based testing** — in-memory fakes enable 2-second test cycles
4. **Progressive complexity** — basic chat works immediately; customization is optional

---

## 3. Key Conventions

### Agent Definition (OpenFang OS)

- **30 pre-built agent templates** organized by domain: development (coder, architect, debugger, code-reviewer), business (sales-assistant, recruiter, ops), specialized (data-scientist, legal-assistant, personal-finance), and a `hello-world` starter
- Each agent lives in its own directory under `agents/`
- Configuration via TOML files
- System prompts are multi-phase operational playbooks, not single instructions

### Agent Definition (OpenFang Gateway)

- YAML files in `agents/` directory
- Skills as standalone Markdown files in `skills/`
- Environment-based secrets (`.env` file)
- Single entrypoint: `openfang chat` or `openfang gateway`

### Memory Patterns

**OpenFang OS:**
- SQLite persistence with vector embeddings
- Canonical sessions with automatic 7-phase repair
- Automatic compaction to prevent growth
- Session corruption recovery

**OpenFang Gateway:**
- Persistent conversation memory across sessions
- Memory as a capability adapter (pluggable backend)

### Security (OpenFang OS)

Notable patterns relevant to any agent system:
- **WASM sandbox** — tool code runs in isolation with resource limits
- **Prompt injection scanner** — detects override attempts and exfiltration
- **Loop guard** — SHA256-based detection of tool call loops with circuit breaker
- **Taint tracking** — labels propagate through execution; secrets tracked source-to-sink
- **Audit trail** — Merkle hash-chain for cryptographic action history

---

## 4. Transferable Patterns for ASK

### From OpenFang OS

1. **Hands as autonomous capability packages** — the pattern of bundling manifest + system prompt + domain knowledge + guardrails into a single deployable unit is powerful. ASK agents could adopt a similar structure where each agent is a self-contained package with explicit declarations of what it needs and what it can do.

2. **HAND.toml as capability manifest** — declaring tools, settings, and requirements in a structured manifest (separate from the prompt) enables validation, dependency resolution, and tooling. ASK should consider a manifest format for agent capabilities.

3. **Multi-phase system prompts** — 500+ word operational playbooks with explicit phases are more effective than one-liner instructions. ASK's agent prompts should be structured as multi-phase procedures.

4. **SKILL.md as injectable knowledge** — domain expertise in Markdown, injected at runtime. This maps directly to ASK's skill system. One skill = one Markdown file with structured domain knowledge.

5. **Guardrails as first-class config** — approval gates for sensitive actions declared in the manifest, not buried in prompt instructions. ASK agents should declare their guardrails explicitly.

6. **30 agent templates by domain** — having a library of pre-built agent templates organized by function accelerates agent creation. ASK could ship common archetypes.

7. **Migration tooling** — OpenFang's `openfang migrate --from openclaw` pattern shows the value of import/export between runtimes. ASK's `/ask:export` should support multiple target formats.

### From OpenFang Gateway

1. **YAML agent personas** — simpler than JSON, more readable, easier to edit by hand. ASK should consider YAML as the primary agent definition format.

2. **Skills as Markdown** — no code, no schema, just Markdown. Maximum readability and portability. This aligns with ASK's "one skill = one folder" principle.

3. **Subagents for task delegation** — complex agents can delegate to specialized sub-agents. ASK should support agent composition.

4. **Progressive complexity** — works with zero config, scales with customization. ASK's `/ask:new` should produce a working agent immediately, with `/ask:iterate` adding complexity.

5. **"Understood in an afternoon" philosophy** — simplicity as a design goal. ASK agents should be readable and modifiable by anyone, not just the framework author.

### Patterns to Avoid

- **Compiling agents into binaries** (OpenFang OS) — impressive for performance but kills iteration speed. ASK agents should be hot-reloadable config files.
- **53 built-in tools** — tool bloat. ASK should follow the plugin model where agents declare only the tools they need.
- **Web3/crypto focus** — not relevant to ASK's goals. Keep the framework domain-agnostic.

---

## 5. Comparison Matrix

| Aspect | OpenFang OS | OpenFang Gateway | ASK Target |
|--------|-------------|------------------|------------|
| Language | Rust | Python | Agnostic (config-driven) |
| Agent format | TOML + directory | YAML | YAML/JSON (TBD) |
| Skill format | SKILL.md | Markdown | Markdown (one skill = one folder) |
| Memory | SQLite + vectors | Pluggable adapter | Memory layer anti-amnesia |
| Extensibility | Compiled crates | Python modules | Skills + plugins by runtime |
| Complexity | High (137K LOC) | Low (~5K LOC) | Low config, deep output |
| Target user | DevOps / infra | Developers | Anyone building agents |
| Philosophy | OS for agents | Gateway for LLMs | Framework for agent creation |

---

*Last updated: 2026-03-17*
*Sources: [OpenFang OS (RightNow-AI)](https://github.com/RightNow-AI/openfang), [OpenFang Gateway (aidiss)](https://github.com/aidiss/openfang), [OpenFang.ai](https://openfang.ai), [OpenFang.sh](https://www.openfang.sh)*
