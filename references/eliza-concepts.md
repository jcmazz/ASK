# Eliza (ElizaOS) — Core Concepts for ASK

> Reference document extracting transferable patterns from the ElizaOS agent framework.
> Sources: ElizaOS docs, arxiv paper (2501.06781), GitHub (elizaOS/eliza, elizaOS/characterfile).

---

## 1. Core Architecture

ElizaOS is a TypeScript-based framework for autonomous AI agents. The central component is the **AgentRuntime**, which orchestrates:

- **Message processing** — receives input from clients (Discord, Telegram, Twitter, web)
- **State composition** — assembles context from memory, providers, and conversation history
- **Action execution** — decides and performs actions based on context
- **Response evaluation** — evaluators analyze completed interactions for learning

The runtime loop:

```
Input -> State Composition -> LLM Decision -> Action/Response -> Evaluation -> Memory Storage
```

Key architectural choices:
- **Plugin-based extensibility** — all capabilities (LLM providers, tools, integrations) are plugins
- **Character-driven identity** — personality is configuration, not code
- **Multi-client** — one agent can operate across multiple platforms simultaneously
- **Database-agnostic memory** — adapters for SQLite, PostgreSQL, and others

---

## 2. Character File Format

The character file is the DNA of an Eliza agent. It is a JSON configuration that defines identity, personality, knowledge, and behavior. Minimal viable character: `name` + `bio` + `plugins`.

### Full Field Reference

| Field | Type | Purpose |
|-------|------|---------|
| `name` | string | Display name (required) |
| `bio` | string \| string[] | Identity and personality description (required) |
| `id` | UUID | Unique identifier; auto-generated from name if omitted |
| `username` | string | Platform handle |
| `system` | string | Custom system prompt override |
| `lore` | string[] | Backstory elements the agent draws from indirectly |
| `knowledge` | string[] \| object[] | Facts, file references, or directory configs for RAG |
| `messageExamples` | array[][] | Sample conversations demonstrating desired interaction style |
| `postExamples` | string[] | Sample social media posts for platform-specific style |
| `topics` | string[] | Knowledge domain specializations |
| `adjectives` | string[] | Character trait descriptors |
| `style` | object | Writing rules by context (`all`, `chat`, `post`) |
| `templates` | object | Custom prompt templates (static strings or functions) |
| `plugins` | string[] | Plugin package identifiers |
| `settings` | object | Model config, temperature, timeouts, feature flags |
| `secrets` | object | Environment-sourced sensitive data (API keys) |
| `clients` | string[] | Platform clients to activate |
| `modelProvider` | string | LLM backend (OpenAI, Anthropic, Llama, etc.) |

### Example Character (Simplified)

```json
{
  "name": "Atlas",
  "bio": [
    "Senior data analyst with 15 years in fintech",
    "Believes in making complex data accessible to everyone"
  ],
  "lore": [
    "Built the first real-time fraud detection system at a major bank",
    "Once spent 3 months living in a cabin analyzing market patterns"
  ],
  "knowledge": [
    "Financial regulations require quarterly reporting",
    "Time series analysis is foundational for market prediction"
  ],
  "topics": ["data analysis", "fintech", "machine learning", "statistics"],
  "adjectives": ["analytical", "patient", "thorough", "pragmatic"],
  "style": {
    "all": ["Use precise language", "Back claims with data"],
    "chat": ["Ask clarifying questions before diving in", "Use examples"],
    "post": ["Lead with insight, not jargon", "Keep under 280 chars"]
  },
  "messageExamples": [
    [
      { "user": "{{user}}", "content": { "text": "Can you explain regression?" } },
      { "user": "Atlas", "content": { "text": "Think of regression as drawing the best-fit line through your data points..." } }
    ]
  ],
  "plugins": ["@elizaos/plugin-openai"],
  "modelProvider": "openai"
}
```

---

## 3. Memory System

Eliza uses a layered memory architecture with vector embeddings for semantic retrieval.

### Memory Interface

Each memory record contains:

- **entityId** — who created it (user or agent)
- **roomId** — conversation context
- **worldId** — broader system context
- **content** — text and metadata
- **embedding** — vector representation (auto-generated)
- **unique** — duplicate prevention flag

### Retrieval Strategies

| Strategy | Method | Use Case |
|----------|--------|----------|
| **Recency** | `getMemories()` with count | Recent conversation context |
| **Semantic** | `searchMemories()` with vector similarity (threshold 0.7-0.9) | Topically related memories |
| **Filtered** | Metadata queries combining time, entity, custom props | Complex targeted retrieval |

### State Composition

The runtime assembles state from multiple sources:

```
State = {
  values: {},          // Key-value from providers
  data: {              // Structured cache
    room, world, entity,
    providers,
    actionPlan, actionResults
  },
  text: string         // Formatted context string for LLM
}
```

Token management prevents context overflow by pruning older memories while preserving recent and important information.

### Key Pattern: Evaluator-Provider Loop

Evaluators extract insights from conversations and store them. Providers retrieve those insights and inject them into future context. This creates a continuous learning loop:

```
Conversation -> Evaluator extracts facts -> Stored in memory -> Provider retrieves -> Enriches future context
```

---

## 4. Actions & Evaluators

### Actions

Actions are the agent's capabilities — what it can DO beyond responding.

| Component | Purpose |
|-----------|---------|
| `name` | Unique identifier |
| `description` | When the LLM should invoke this action |
| `similes` | Alternative names improving selection accuracy |
| `validate()` | Determines if action is valid for current context |
| `handler()` | Core execution logic |

The LLM selects actions based on context, descriptions, and similes. This is intent-driven rather than keyword-driven.

### Evaluators

Evaluators are post-processing cognitive components that run AFTER interactions:

| Component | Purpose |
|-----------|---------|
| `handler()` | Analyzes completed interaction |
| `alwaysRun` | Force execution regardless of response |
| `shouldRun()` | Custom logic for conditional execution |

What evaluators do:
- Extract facts and insights from conversations
- Build long-term memory
- Track goal progress
- Maintain contextual awareness

---

## 5. Providers

Providers inject real-time context into the agent's state. They run in parallel during state composition.

Built-in providers:
- **Time Provider** — current date/time awareness
- **Facts Provider** — previously extracted facts about users and topics
- **Boredom Provider** — engagement level management (avoids repetitive responses)

Custom providers implement a `get()` method returning:
```typescript
{
  text: string,   // String for LLM context
  data: object    // Structured data for programmatic access
}
```

The provider pattern decouples data sourcing from agent logic. An agent doesn't need to know HOW to get stock prices — it just receives them from a provider.

---

## 6. Plugin System

Plugins are the unit of extensibility. A plugin bundles related actions, providers, evaluators, and services.

### Plugin Interface

```typescript
{
  name: string,
  dependencies: string[],      // Required plugins resolved first
  init(): void,                // Called during loading
  start(): void,               // Lifecycle: startup
  stop(): void,                // Lifecycle: shutdown
  actions: Action[],
  evaluators: Evaluator[],
  providers: Provider[],
  services: Service[],         // Long-running components
  models: Map<string, handler> // LLM provider flexibility
}
```

### Hooks & Middleware

Plugins can intercept execution at key points:
- `beforeMessage` — modify incoming messages
- `afterMessage` — log or analyze completed cycles
- `beforeAction` — validate or block actions
- `afterAction` — process action results

### Service Architecture

Services are long-running components (WebSocket servers, database connections) with managed lifecycles and dependency ordering.

---

## 7. Personality Design Patterns

Eliza defines personality through layered configuration, not a single prompt.

### The Layers

1. **Bio** — establishes credibility and expertise ("Senior data analyst with 15 years...")
2. **Lore** — backstory the agent references indirectly, never reveals directly
3. **Knowledge** — factual grounding via RAG or static facts
4. **Message Examples** — demonstrates desired conversational patterns
5. **Post Examples** — demonstrates platform-specific writing style
6. **Style Rules** — per-context guidelines (`all`, `chat`, `post`)
7. **Adjectives** — trait descriptors that shape tone
8. **Topics** — domain boundaries

### Documented Archetypes

| Archetype | Focus | Traits |
|-----------|-------|--------|
| **Helper** | User success | Patient, thorough, encouraging |
| **Expert** | Technical depth | Authoritative, citation-heavy |
| **Companion** | Emotional intelligence | Empathetic, supportive |
| **Analyst** | Data-driven reasoning | Objective, metrics-focused |

### Consistency Matrix

The key insight: personality must be consistent ACROSS contexts. A trait like "analytical" should manifest in bio (credentials), chat style (asks for data), and post style (leads with numbers). Contradictions between contexts break the character.

---

## 8. Key Takeaways for ASK

### Borrow These Patterns

1. **Character file as single source of truth** — one JSON/YAML file that defines identity, personality, knowledge, and capabilities. ASK should adopt this "one file = one agent identity" pattern.

2. **Layered personality definition** — bio + lore + style + examples + adjectives is more robust than a single system prompt. Each layer serves a different purpose and they compose well.

3. **Style context separation** — different rules for different contexts (`all`, `chat`, `post`) prevents one-dimensional agents. ASK agents need context-aware behavior.

4. **Evaluator-Provider feedback loop** — the pattern where evaluators extract knowledge that providers re-inject creates genuine agent learning. ASK's memory layer should implement this cycle.

5. **Plugin-based extensibility** — capabilities should be modular, composable, and independently testable. One skill = one plugin equivalent.

6. **Semantic memory with recency fallback** — vector search for relevance, chronological for recency. Both are needed.

7. **Message examples as behavioral anchoring** — showing the agent HOW to respond is more effective than telling it. ASK should include example interactions in agent definitions.

8. **Similes for action selection** — providing multiple names for the same action improves LLM tool selection accuracy. ASK skill definitions should include aliases.

### Diverge Here

- Eliza is Web3-heavy — ASK is runtime-agnostic
- Eliza's character file mixes identity AND infrastructure config (modelProvider, clients) — ASK should separate identity from deployment
- Eliza's plugin system is tightly coupled to its TypeScript runtime — ASK patterns need to be portable across runtimes (OpenClaw, Claude Code, Hermes)

---

*Last updated: 2026-03-17*
*Sources: [ElizaOS Documentation](https://docs.elizaos.ai), [ElizaOS GitHub](https://github.com/elizaOS/eliza), [Character File Spec](https://github.com/elizaOS/characterfile), [Eliza arxiv paper](https://arxiv.org/html/2501.06781v1)*
