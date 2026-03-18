# LangGraph Patterns — Reference for ASK

> Agent orchestration framework by LangChain. Low-level, graph-based runtime for building reliable AI agents with explicit control flow, persistence, and human-in-the-loop support.

---

## 1. Core Concepts

### StateGraph

The fundamental building block. A directed graph where:

- **State** is a typed data structure (TypedDict, dataclass, or Pydantic model) that flows through the graph
- **Nodes** are functions that receive state, perform computation, and return updated state
- **Edges** define transitions between nodes (fixed or conditional)

You define state, add nodes and edges, then **compile** the graph before execution.

### State Management

State supports multiple schema layers for separation of concerns:

| Layer | Purpose |
|---|---|
| **InputState** | Constrains what enters the graph |
| **OverallState** | All internal channels — the full picture |
| **OutputState** | Filters what the graph returns |
| **PrivateState** | Internal node communication, not exposed externally |

**Reducers** control how state updates merge. Default behavior overwrites values. Custom reducers enable sophisticated merging — for example, `Annotated[list[str], add]` concatenates lists instead of replacing them. The built-in `add_messages` reducer handles message deduplication and deserialization automatically.

### Nodes

Sync or async Python functions that accept:
- `state` — current graph snapshot
- `config` — thread_id, tracing info, runtime configuration
- `runtime` — context, store, and stream_writer access

Special nodes: `START` (entry point) and `END` (terminal).

### Edges

Three types:

1. **Normal edges** — direct transitions ("after node A, go to node B")
2. **Conditional edges** — routing functions evaluate state and choose destination(s). Multiple outgoing edges execute in parallel within the same super-step
3. **Entry points** — routing from `START` with custom logic

### Execution Model

Inspired by Google's Pregel (message-passing):
- Nodes start inactive, become active on receiving messages
- Execute, send updates downstream, then vote to halt
- Execution terminates when all nodes are inactive and no messages are in transit
- Default recursion limit: 1000 steps

### Compilation

Validates graph structure (no orphaned nodes), configures checkpointers and breakpoints. **Must compile before execution.** This is the enforcement point for structural correctness.

---

## 2. Agent Patterns

### ReAct (Reason + Act)

The most common single-agent pattern. Implements a think-act-observe loop:

1. **Reason** — LLM analyzes current state and decides next action
2. **Act** — Execute a tool call
3. **Observe** — Process tool output, update state
4. **Loop** — Repeat until task is complete or max iterations reached

Modern LangGraph ReAct agents use function-calling (not prompt-based "Thought/Action/Observation" formatting). The loop is implemented as a cycle in the graph with a conditional edge checking whether the task is done.

**When to use:** General-purpose single-agent tasks. Good default starting point.

### Plan-and-Execute

Two-component architecture:

1. **Planner** — LLM generates a multi-step plan upfront
2. **Executor** — Lighter-weight LLM or agent executes each step

Advantages over pure ReAct:
- Faster execution (planner is consulted once, not after every action)
- Cost savings (use cheaper models for execution steps)
- Better coherence (explicit upfront planning reduces drift)

**When to use:** Multi-step workflows where upfront planning improves quality. Tasks where execution steps are relatively independent.

### Reflection

A generate-critique-refine cycle:

1. **Generate** — Agent produces initial output
2. **Reflect** — Same or different agent critiques the output
3. **Refine** — Revise based on critique
4. **Loop** — Until quality threshold met or max iterations

Can be single-agent (self-reflection) or multi-agent (dedicated critic agent). Significantly reduces hallucinations and improves accuracy through iterative refinement.

**When to use:** Content generation, code writing, research synthesis — any task where quality benefits from iterative review.

---

## 3. Multi-Agent Patterns

### Supervisor

A central supervisor agent coordinates specialized worker agents:

- Supervisor receives tasks and decides which worker to invoke
- Each worker has focused expertise and its own tool set
- Supervisor evaluates results and decides next steps
- Workers maintain their own scratchpad while supervisor orchestrates communication

**Hierarchical variant:** Multi-level supervisors. A top-level supervisor manages mid-level supervisors, each coordinating their own team. Each layer has focused responsibility, new domains can be added without affecting existing ones, and each layer is independently testable.

Current LangChain recommendation: implement supervisor via tool-calling rather than the dedicated library, for more control over context engineering.

**When to use:** Tasks requiring different types of expertise. Complex workflows where a single agent would be overloaded with tools and responsibilities.

### Swarm (Network / Handoff)

Decentralized control — no central coordinator:

- Each agent holds explicit handoff tools for transferring control to peers
- System tracks which agent is currently active
- Handoffs pass context (messages, summaries) between agents
- Routing is explicitly defined per agent (not autonomous)

Key difference from supervisor: swarm routing is peer-to-peer and predictable. Each handoff tool specifies exactly which agent may take over. The system remembers the last-active agent so subsequent messages continue seamlessly.

**When to use:** Conversational agents where different specialists handle different user intents. Scenarios where peer-to-peer delegation is more natural than top-down coordination.

### Map-Reduce (Scatter-Gather)

Parallel processing pattern using LangGraph's `Send` API:

1. **Scatter** — Split work into parallel chunks, each sent to a node
2. **Process** — Multiple instances execute simultaneously
3. **Gather** — Merge results back into unified state

`Send` objects enable dynamic fan-out where the number of parallel nodes isn't predetermined at graph definition time.

**When to use:** Document processing, parallel research, any task where independent sub-tasks can run simultaneously.

### Transferable Pattern: Specialized Agents as Services

Across all multi-agent patterns, the key transferable insight is: **design agents as focused specialists with clear boundaries.** Whether coordinated by a supervisor, handed off in a swarm, or executed in parallel — the quality of the system depends on well-defined agent responsibilities and clean interfaces between them.

---

## 4. Human-in-the-Loop

LangGraph was built with HITL as a first-class feature, not an afterthought. The `interrupt()` function pauses graph execution, and `Command` resumes it with human-provided input.

### Core Mechanism

1. Graph reaches a node with `interrupt()`
2. Execution pauses, state is checkpointed
3. Human reviews, approves, modifies, or rejects
4. Graph resumes from the checkpoint with the human's input via `Command`

Requires a checkpointer — without persistence, the graph cannot pause and resume.

### Common Patterns

| Pattern | Description |
|---|---|
| **Approval gate** | Pause before high-stakes actions (sending email, financial transactions). Human approves or rejects. |
| **Edit-in-place** | Agent drafts output, human edits it, execution continues with modified version. |
| **Tool call review** | Inspect and approve/reject LLM tool calls before execution. |
| **Plan approval** | Agent generates a plan, human reviews and modifies before execution begins. |
| **Escalation** | Agent detects uncertainty or risk, escalates to human for decision. |

### Design Principles

- Place interrupts **before** irreversible actions, not after
- Expose the proposed action clearly so humans can make informed decisions
- Allow editing, not just binary approve/reject
- State persistence means the human can take their time — the graph waits indefinitely
- Interrupts can be placed at any node, making them composable with any agent pattern

---

## 5. Memory & Persistence

LangGraph separates memory into two distinct systems:

### Checkpointers (Short-Term / Thread Memory)

Automatic snapshots of graph state at every super-step:

- Organized into **threads** — separate conversations/runs with unique `thread_id`
- Thread-scoped: each thread's execution history is independent
- Enables: conversational memory, HITL workflows, fault-tolerant execution
- **Time travel**: replay prior executions for debugging, fork state at any checkpoint to explore alternative paths

Available implementations: in-memory, SQLite, PostgreSQL, Redis.

### Stores (Long-Term / Cross-Thread Memory)

Persistent memory shared across threads:

- Checkpointers alone cannot share information across threads — Stores solve this
- Store long-term facts, user preferences, learned patterns
- Searchable and queryable across the entire application

### Memory Types (Conceptual)

| Type | Scope | Backed By |
|---|---|---|
| **Conversational** | Within a thread | Checkpointer |
| **Cross-thread** | Across threads for same user | Store |
| **Application-wide** | Shared knowledge | Store |

### Key Insight

LangGraph's persistence is the foundation for everything else — HITL, memory, fault tolerance, and debugging all depend on checkpointing. Choosing the right checkpointer backend (in-memory for dev, Postgres/Redis for prod) is an early architectural decision.

---

## 6. Tool Integration

### ToolNode

The prebuilt `ToolNode` handles tool execution:

- Receives tool calls from LLM output
- Executes the appropriate tool
- Returns results as `ToolMessage`

### Error Handling

`ToolNode` supports multiple error handling strategies:

| Strategy | Description |
|---|---|
| `handle_tool_errors=True` | Catch errors, send as ToolMessage back to LLM |
| Custom string | Return a specific error message |
| Exception types | Catch specific exception types only |
| Callable | Custom handler function |
| `False` | Disable error handling (raise exceptions) |

Error handling is **off by default** — must be explicitly enabled.

### Retry Policies

Two layers of retry:

1. **HTTP-level** — LLM client retries (429, 500, 503). Configured on the model.
2. **Node-level** — LangGraph's `RetryPolicy` on `add_node()`. Covers tool execution failures.

Use both layers for maximum resilience.

### Command for Tool-Based Control Flow

Tools can return `Command` objects that combine state updates and routing in a single atomic operation. This enables tools to control graph flow — e.g., a tool that determines the next agent to invoke.

### Node Caching

Cache node results based on input hash with TTL support. Useful for expensive tool calls that may be repeated with identical inputs.

---

## 7. Key Takeaways for ASK

### Architectural Principles

1. **Graph-as-architecture**: Modeling agent workflows as explicit graphs (nodes + edges) makes the system inspectable, debuggable, and predictable. ASK agents should have clear, visualizable control flow.

2. **State is the contract**: The state schema defines the interface between all components. Well-designed state is the single most important architectural decision. ASK should enforce state schema definition early in agent design.

3. **Conditional routing > autonomous routing**: Explicit conditional edges are more reliable than letting agents decide flow autonomously. Define the control flow; let agents decide within their node, not which node to go to.

### Patterns to Adopt

4. **HITL from day one**: Human-in-the-loop should be a first-class design consideration, not bolted on later. ASK's phased approach (discovery, research, build) should include interrupt points by default.

5. **Supervisor for complex systems, ReAct for simple ones**: Start with the simplest pattern that works. A single ReAct agent is often enough. Graduate to supervisor/swarm only when agent responsibilities genuinely diverge.

6. **Persistence enables everything**: Memory, HITL, debugging, fault tolerance — all depend on state persistence. ASK should treat the memory layer as foundational infrastructure, not an optional feature.

### Anti-Patterns to Avoid

7. **Monolithic agents**: One agent with 20 tools is worse than 4 agents with 5 tools each. ASK should enforce focused agent scope during the architecture phase.

8. **Implicit state**: If important information only exists in message history and not in structured state, it will be lost or misinterpreted. ASK should require explicit state schemas.

9. **Missing error handling**: Tool errors silently failing is the default. ASK should mandate error handling configuration in agent specifications.

### Implementation Guidance

10. **Start with the state schema, not the agent logic.** The state defines what the system can know and do.
11. **Map the control flow before writing node logic.** Draw the graph first.
12. **Place interrupts at decision boundaries,** especially before irreversible actions.
13. **Choose persistence backend early** — it affects deployment architecture.
14. **Test agents by testing state transitions,** not just final outputs.

---

## Sources

- [LangGraph Official Documentation — Graph API](https://docs.langchain.com/oss/python/langgraph/graph-api)
- [LangGraph Persistence Documentation](https://docs.langchain.com/oss/python/langgraph/persistence)
- [LangGraph Human-in-the-Loop Documentation](https://docs.langchain.com/oss/python/langchain/human-in-the-loop)
- [LangGraph Supervisor Library](https://github.com/langchain-ai/langgraph-supervisor-py)
- [LangGraph Swarm Library](https://github.com/langchain-ai/langgraph-swarm-py)
- [LangGraph Hierarchical Agent Teams Tutorial](https://langchain-ai.github.io/langgraph/tutorials/multi_agent/hierarchical_agent_teams/)
- [Reflection Agents — LangChain Blog](https://blog.langchain.com/reflection-agents/)
- [Plan-and-Execute Agents — LangChain Blog](https://blog.langchain.com/planning-agents/)
- [Making it Easier to Build HITL Agents with Interrupt — LangChain Blog](https://blog.langchain.com/making-it-easier-to-build-human-in-the-loop-agents-with-interrupt/)
- [Benchmarking Multi-Agent Architectures — LangChain Blog](https://blog.langchain.com/benchmarking-multi-agent-architectures/)
- [LangGraph Multi-Agent Orchestration Guide — Latenode](https://latenode.com/blog/ai-frameworks-technical-infrastructure/langgraph-multi-agent-orchestration/langgraph-multi-agent-orchestration-complete-framework-guide-architecture-analysis-2025)
- [LangGraph vs CrewAI vs AutoGen — DEV Community](https://dev.to/pockit_tools/langgraph-vs-crewai-vs-autogen-the-complete-multi-agent-ai-orchestration-guide-for-2026-2d63)
- [ToolNode and Tool Execution — DeepWiki](https://deepwiki.com/langchain-ai/langgraph/8.2-toolnode-and-tool-execution)
