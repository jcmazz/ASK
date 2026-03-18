# CrewAI Patterns — Reference for ASK

> Framework for orchestrating role-playing, autonomous AI agents. High-level, declarative approach where you define agents by role/goal/backstory and assemble them into crews with defined processes.

---

## 1. Core Concepts

### Agents

The fundamental unit. Each agent is defined by three pillars:

| Attribute | Purpose |
|---|---|
| **Role** | Function and expertise within the crew ("Senior Researcher", "Content Writer") |
| **Goal** | Individual objective that guides decision-making |
| **Backstory** | Context and personality that shapes behavior and tone |

Additional configuration: tools, memory, LLM selection, delegation permissions, max iterations, rate limits, reasoning mode, multimodal support, and code execution.

### Tasks

Discrete units of work assigned to agents:

- Have a description, expected output format, and assigned agent
- Can depend on other tasks (output of one becomes context for the next)
- Support async execution
- Can include callback functions for post-completion processing

### Crews

A collaborative group of agents working together on a set of tasks:

- Defines the **process type** (how tasks flow)
- Configures shared resources (memory, tools, LLM)
- Controls execution parameters (max RPM, verbose mode, planning)

### Processes

The orchestration strategy that governs how tasks flow through the crew. CrewAI supports two primary processes: Sequential and Hierarchical.

---

## 2. Role-Based Design

CrewAI's core philosophy: **agents are defined by their organizational role, not their technical capabilities.** This mirrors how human teams work — you hire a "researcher" or "editor," not a "GPT-4 instance with search tools."

### Effective Role Definition

**Role** should be specific and domain-scoped:
- Good: "Senior Financial Analyst specializing in risk assessment"
- Bad: "AI assistant"

**Goal** should be measurable and aligned with the crew's mission:
- Good: "Identify the top 3 investment risks in the portfolio and quantify potential impact"
- Bad: "Help with financial analysis"

**Backstory** provides behavioral anchoring:
- Establishes expertise level, communication style, decision-making approach
- Acts as a persistent system prompt that shapes all agent interactions
- More detailed backstories produce more consistent agent behavior

### Role Archetypes

Common roles that appear across CrewAI implementations:

| Archetype | Characteristics |
|---|---|
| **Manager** | Oversees task distribution, monitors progress, validates quality |
| **Researcher** | Information gathering, data analysis, insight generation |
| **Writer/Creator** | Content production, synthesis, formatting |
| **Reviewer/Critic** | Quality assurance, fact-checking, standard enforcement |
| **Specialist** | Deep domain expertise for specific sub-tasks |

### Delegation

When `allow_delegation=True`, an agent can assign sub-tasks to other crew members. This is **off by default** — enabling it should be a deliberate design decision, typically reserved for manager-type agents.

### Reasoning Mode

Setting `reasoning=True` enables agents to reflect and plan before executing tasks. The agent generates an internal reasoning chain before acting, with `max_reasoning_attempts` controlling planning iterations. Useful for complex tasks where upfront thinking improves output quality.

---

## 3. Crew Composition

### Design Principles

**Treat crews as engineered workflows, not chat experiments.** Each crew should have:

1. Clear mission — what is the crew trying to accomplish?
2. Minimal viable team — fewest agents that cover all required capabilities
3. Explicit task boundaries — no overlapping responsibilities
4. Defined information flow — how does output from one agent become input for another?

### Composition Patterns

#### Pipeline Crew
Linear chain of specialists, each refining the previous agent's output:
```
Researcher -> Analyst -> Writer -> Editor
```
Best for: content production, report generation, data processing pipelines.

#### Hub-and-Spoke Crew
One coordinator distributing work to specialists:
```
Manager -> [Researcher, Analyst, Writer]
```
Best for: complex projects requiring parallel workstreams.

#### Review Loop Crew
Creator-reviewer pairs with iterative refinement:
```
Writer <-> Editor (loop until quality threshold)
```
Best for: high-quality content, code review, compliance checking.

#### Assembly Line Crew
Each agent adds a specific component to a shared artifact:
```
Outliner -> Drafter -> Illustrator -> Formatter
```
Best for: multi-format deliverables, structured documents.

### Scaling Considerations

- Multi-agent systems amplify complexity — watch for loops, tool misuse, and cost blowups
- More agents != better results. Start with 2-3 and add only when you hit a clear capability gap
- Each additional agent increases token usage, latency, and failure surface
- Use continuous monitoring for cost, latency, and quality

---

## 4. Process Types

### Sequential Process

Tasks execute one after another in a predefined order:

- Output of task N becomes context for task N+1
- Every task **must** have an explicit agent assigned (enforced at initialization)
- Predictable, easy to debug, straightforward to reason about
- Default process type

**When to use:** Linear workflows where each step depends on the previous one. When predictability and debuggability are priorities.

**Limitation:** Cannot parallelize independent tasks. Bottlenecked by the slowest step.

### Hierarchical Process

A manager agent coordinates the workflow:

- Manager allocates tasks to agents based on roles and capabilities
- Tasks do **not** require explicit agent assignment — the manager assigns dynamically
- Manager validates outcomes against quality standards
- Can be auto-generated by CrewAI or explicitly defined by the user

Configuration:
- Set `process=Process.hierarchical`
- Provide `manager_llm` (e.g., "gpt-4o") or a custom `manager_agent`
- Custom manager should have `allow_delegation=True`

**When to use:** Complex projects where task assignment benefits from dynamic decision-making. When you want a quality validation layer. When the optimal agent for a task depends on runtime context.

**Limitation:** Additional LLM calls for manager reasoning increase cost and latency. Manager quality depends heavily on LLM capability.

### Choosing Between Processes

| Factor | Sequential | Hierarchical |
|---|---|---|
| Predictability | High — deterministic order | Medium — manager decides |
| Cost | Lower — no manager overhead | Higher — manager LLM calls |
| Flexibility | Low — fixed task assignment | High — dynamic delegation |
| Debugging | Easy — linear trace | Harder — manager decisions opaque |
| Quality control | None built-in | Manager validates outputs |
| Best for | Pipelines, known workflows | Complex projects, variable tasks |

---

## 5. Tool Integration

### Creating Tools

Two approaches:

1. **`@tool` decorator** — for simple, stateless functions. Quick to create, minimal boilerplate.
2. **`BaseTool` subclass** — for complex tools needing state management, input validation via `args_schema`, and custom error handling.

### Tool Sharing

Tools are defined once and can be assigned to any agent. This modular approach means:

- Same search tool can be used by Researcher and Fact-Checker agents
- Tools are independently testable
- Adding a new tool doesn't require modifying agents

### Tool Assignment Strategy

| Strategy | When to Use |
|---|---|
| **Agent-level tools** | Tools specific to an agent's role (writer gets formatting tools) |
| **Task-level tools** | Tools needed only for a specific task, regardless of agent |
| **Shared tools** | General utilities all agents need (search, file I/O) |

### Built-in Tool Ecosystem

CrewAI provides pre-built tools for common needs: web search, web scraping, file operations, code execution, RAG, and more. Custom tools extend this for domain-specific capabilities.

### Caching

Tool caching is **enabled by default**. Cache keys are generated from tool name + input parameters. This reduces redundant API calls when multiple agents or tasks invoke the same tool with the same inputs.

### Best Practices

- Ground key steps with tools — don't rely solely on LLM knowledge
- Set `max_iter` and `max_execution_time` to prevent runaway tool usage
- Use `max_rpm` to respect API rate limits
- Enable code execution in "safe" mode (Docker isolation) for production

---

## 6. Memory System

### Unified Memory Architecture

CrewAI uses a single `Memory` class that replaces separate memory types with one intelligent API. The system uses an LLM to analyze content when saving — automatically inferring scope, categories, and importance.

### The Remember/Recall Pattern

Core operations:

| Operation | Purpose |
|---|---|
| **Remember** | Store information; LLM infers optimal placement |
| **Recall** | Retrieve relevant memories ranked by composite scoring |
| **Extract** | Break raw text into discrete facts before storage |

### Composite Scoring

Three signals determine retrieval ranking:

| Signal | Default Weight | Description |
|---|---|---|
| **Semantic similarity** | 0.5 | Vector distance between query and memory |
| **Recency** | 0.3 | Exponential decay based on age |
| **Importance** | 0.2 | Significance rating assigned at storage |

Weights are tunable: sprints favor recency; knowledge bases favor importance.

### Hierarchical Scopes

Memories organize into a filesystem-like tree:

```
/project/alpha
/project/alpha/architecture
/agent/researcher
/company/engineering
/customer/acme-corp
```

Design guidelines:
- Use `/{entity_type}/{identifier}` patterns
- Keep depth shallow (2-3 levels maximum)
- Start flat and let hierarchy emerge organically
- Scope by concern, not by entity first

### Scope Operations

1. **Automatic inference** — LLM suggests placement when scope is unspecified
2. **Explicit assignment** — Manually specify for known categories
3. **Subscopes** — Create narrower views with `subscope()`

### Memory Slices

Unlike scopes (single subtree), slices combine multiple branches. Useful for agents needing access to private scope plus shared knowledge without write permissions.

### Consolidation

Automatic deduplication: the system detects similar records (threshold: 0.85 similarity) and decides whether to keep, update, delete, or insert alongside existing entries.

### Integration Levels

| Level | How |
|---|---|
| **Standalone** | `Memory()` instance, manual remember/recall |
| **With Crews** | `Crew(memory=True)` — agents auto-load and persist |
| **With Agents** | Shared crew memory or scoped views for private context |
| **With Flows** | Built-in `self.remember()` and `self.recall()` |

### Best Practices

1. Start with `memory=True` on the Crew — it just works
2. Use explicit scopes for architectural decisions and facts that must not be lost
3. Let automatic inference handle freeform content
4. Monitor memory storage growth — consolidation helps but doesn't eliminate growth
5. Tag memories with `source` for provenance tracking
6. Use `private` flag for sensitive information

---

## 7. Key Takeaways for ASK

### Design Philosophy

1. **Role-first thinking**: CrewAI's greatest insight is that agent design starts with organizational roles, not technical capabilities. ASK's discovery phase should identify roles before tools or prompts.

2. **Crews as workflows**: A crew is not a chatroom — it's an engineered pipeline. ASK should frame agent teams as designed systems with clear inputs, outputs, and quality gates.

3. **Declarative > imperative**: CrewAI's high-level API means you declare what you want (roles, goals, tasks) and the framework handles execution. ASK should capture agent intent, not just implementation details.

### Patterns to Adopt

4. **Role/Goal/Backstory triad**: This three-attribute definition is a powerful design tool even outside CrewAI. ASK should require all three for every agent, regardless of target runtime.

5. **Process selection as architecture decision**: Sequential vs. hierarchical is not just a config flag — it reflects fundamental assumptions about task dependencies and agent autonomy. ASK's architecture phase should make this explicit.

6. **Memory as organizational knowledge**: CrewAI's unified memory with scopes mirrors how organizations store and retrieve knowledge. ASK's memory layer should use scope patterns for organizing agent knowledge.

### Practical Guidance

7. **Start sequential, graduate to hierarchical**: Sequential is predictable, debuggable, and cheap. Only add a manager agent when dynamic task allocation genuinely improves outcomes.

8. **Minimal viable crew**: Start with 2-3 agents. Every additional agent adds cost, latency, and failure modes. The temptation to add agents is strong — resist it until the bottleneck is clearly about missing capability.

9. **Ground with tools**: LLM knowledge alone is not enough. Every critical step should have a tool that provides real data. ASK should flag agent designs that rely too heavily on LLM-internal knowledge.

10. **Monitor everything**: Multi-agent systems amplify cost and latency unpredictably. ASK should include observability requirements (cost tracking, latency monitoring, quality metrics) in every agent specification.

### Anti-Patterns to Avoid

11. **Vague roles**: "AI Assistant" is not a role. ASK should enforce specificity during discovery.

12. **Over-delegation**: If every agent can delegate to every other agent, you get infinite loops. Delegation should be intentional and constrained.

13. **No quality gates**: Without validation (either manager-based or explicit review steps), errors compound through the pipeline. ASK should require at least one quality checkpoint per workflow.

14. **Ignoring context windows**: Long task chains accumulate tokens. ASK should plan for context management from the start — either through summarization, selective memory, or explicit context pruning.

### Comparison with LangGraph

| Dimension | CrewAI | LangGraph |
|---|---|---|
| Abstraction level | High (declarative roles) | Low (explicit graph) |
| Control flow | Process types | Custom graph edges |
| Learning curve | Lower | Higher |
| Flexibility | Constrained by patterns | Maximum control |
| Best for | Role-based teams, rapid prototyping | Complex custom workflows |
| Memory | Built-in unified system | Checkpointers + Stores |
| HITL | Limited | First-class support |

ASK should support both paradigms: CrewAI-style role definitions for rapid agent prototyping, and LangGraph-style explicit control flow for production systems requiring fine-grained orchestration.

---

## Sources

- [CrewAI Agents Documentation](https://docs.crewai.com/en/concepts/agents)
- [CrewAI Memory Documentation](https://docs.crewai.com/en/concepts/memory)
- [CrewAI Hierarchical Process Documentation](https://docs.crewai.com/en/learn/hierarchical-process)
- [CrewAI Custom Tools Documentation](https://docs.crewai.com/en/learn/create-custom-tools)
- [CrewAI GitHub Repository](https://github.com/crewAIInc/crewAI)
- [CrewAI Framework 2025 Review — Latenode](https://latenode.com/blog/ai-frameworks-technical-infrastructure/crewai-framework/crewai-framework-2025-complete-review-of-the-open-source-multi-agent-ai-platform)
- [CrewAI Practical Guide — DigitalOcean](https://www.digitalocean.com/community/tutorials/crewai-crash-course-role-based-agent-orchestration)
- [How We Built Cognitive Memory — CrewAI Blog](https://blog.crewai.com/how-we-built-cognitive-memory-for-agentic-systems/)
- [Deep Dive into CrewAI Memory Systems — SparkCo](https://sparkco.ai/blog/deep-dive-into-crewai-memory-systems)
- [AI Agent Memory Comparative Analysis — DEV Community](https://dev.to/foxgem/ai-agent-memory-a-comparative-analysis-of-langgraph-crewai-and-autogen-31dp)
- [CrewAI vs LangGraph vs AutoGen — DataCamp](https://www.datacamp.com/tutorial/crewai-vs-langgraph-vs-autogen)
- [Agent Orchestration Frameworks 2026 — Iterathon](https://iterathon.tech/blog/ai-agent-orchestration-frameworks-2026)
- [Design, Develop, and Deploy Multi-Agent Systems with CrewAI — DeepLearning.AI](https://www.deeplearning.ai/courses/design-develop-and-deploy-multi-agent-systems-with-crewai/)
