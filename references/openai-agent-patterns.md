# OpenAI Agent Patterns — Reference for ASK

> Compiled from OpenAI's official documentation, Practical Guide to Building Agents, Agents SDK docs, Swarm framework, and developer cookbooks.
> Last updated: 2026-03-17

---

## 1. Agent Architecture Patterns

### What Is an Agent

OpenAI defines an agent as a system where an LLM operates in a loop, autonomously using tools to accomplish tasks. An agent consists of three foundational components:

- **Model** — The LLM powering reasoning and decision-making
- **Tools** — External functions or APIs the agent can invoke
- **Instructions** — Explicit guidelines and guardrails defining behavior

The distinction matters: a chatbot answering questions is not an agent. An agent is connected to systems and takes action based on input.

### When to Build Agents

Agents are suited to workflows where deterministic, rule-based approaches fall short:

- Complex decision-making with judgment calls (refund approvals, risk assessment)
- Systems with intricate, overlapping rule sets (vendor security reviews)
- Processes dependent on unstructured data (insurance claims, document analysis)
- Workflows requiring multi-step reasoning with conditional branching

**Key recommendation**: Start with the most capable model to establish a performance baseline. Optimize for cost later by scaling down to lighter models for specific subtasks.

### Single-Agent Architecture

A single agent loops through tool calls until an exit condition is met. This is the recommended starting point.

**When to use:**
- The task domain is bounded
- The instruction set fits within a single coherent prompt
- Tool count is manageable (the model can reliably select the right one)

**Pattern:**
```
User Input -> Agent (instructions + tools) -> [Tool Call -> Result]* -> Output
```

The agent loop: receive input, reason, call tools, process results, repeat until done.

### Multi-Agent Architecture

Distribute workflow execution across multiple coordinated agents. Implement only when a single agent struggles with instruction complexity or tool selection accuracy.

**Signals you need multiple agents:**
- Agent fails to follow complicated instructions consistently
- Agent selects incorrect tools when many are available
- Distinct domains require fundamentally different instructions or personas
- Different tasks need different model capabilities (cost optimization)

**Two primary patterns:**

#### Manager Pattern (Agents as Tools)
A central orchestrator invokes specialist agents as tools and retains conversation control.

- The manager decides what to ask each specialist
- Specialists return results to the manager
- The manager synthesizes and responds to the user
- Best when: one agent should own the final answer, combine outputs from multiple specialists, or enforce shared guardrails in one place

#### Handoff Pattern (Peer Delegation)
Agents transfer conversation ownership to other agents.

- A triage agent routes to specialists
- The specialist becomes the active agent for that turn
- Full conversation history travels with the handoff
- Best when: the specialist should respond directly, prompts need to stay focused, or you want to swap full instruction sets

### Swarm Pattern (Legacy, now Agents SDK)

OpenAI's Swarm framework (now superseded by the Agents SDK) introduced two foundational concepts:

- **Routines**: A set of natural language instructions paired with the tools needed to execute them. Keep routines focused (5-15 steps maximum).
- **Handoffs**: The action of one agent transferring a conversation to another, loading the corresponding routine while preserving accumulated context.

**Key insight from Swarm**: Let the LLM decide handoff timing. It handles this robustly without explicit state machines. Provide `transfer_to_XXX` functions and the model naturally calls them when appropriate.

---

## 2. Function Calling Best Practices

### Schema Design

Each tool needs a clear JSON schema definition containing:

- **Name**: Descriptive identifier (e.g., `get_order_status`, not `tool_1`)
- **Description**: What it does AND when to use it. The description is critical for model tool selection.
- **Parameters**: Expected types, which are required, and constraints
- **Return value semantics**: What the model should expect back

### Naming and Description Guidelines

- Use descriptive, action-oriented function names
- Write descriptions that help the model understand both capability and appropriate usage context
- Include edge cases in descriptions (e.g., "Use this when the user asks about order status. Do not use for return requests.")
- Document parameter constraints in the description, not just the schema

### Strict Mode

Enable `strict: true` in function definitions to use Structured Outputs for tool calls. This guarantees the model's arguments match your schema exactly.

**Important limitation**: Structured Outputs is not compatible with parallel function calls. Set `parallel_tool_calls: false` when using strict mode.

### Parameter Design

- All fields must be `required` when using strict mode (use Union types with null for optional semantics)
- Use enums to constrain parameter values where possible
- Prefer Pydantic (Python) or Zod (TypeScript) to define schemas natively, then convert to JSON Schema — this prevents schema drift

### Error Handling

- Assume responses can include zero, one, or multiple tool calls
- Always handle the case where the model calls no tools
- Implement timeout and retry logic for tool execution
- Return clear error messages the model can reason about

### Security

- Be aware of the real-world impact of function calls that trigger actions
- Include a confirmation step before executing high-impact operations
- Never let untrusted user input directly parameterize dangerous operations without validation

---

## 3. Agent SDK Patterns

The OpenAI Agents SDK (Python and TypeScript) provides production-ready primitives for building agentic systems. It is the official evolution of Swarm.

### Core Primitives

| Primitive | Purpose |
|-----------|---------|
| **Agent** | LLM-based entity with instructions, tools, and handoffs |
| **Runner** | Executes agents (sync or async), manages the full lifecycle |
| **Handoff** | Delegation mechanism between agents |
| **Guardrails** | Input/output/tool validation that runs in parallel |
| **Tracing** | Built-in observability for debugging and monitoring |
| **Sessions** | Persistent memory layer for working context |

### Agent Configuration

Key parameters:

- `name`: Human-readable identifier
- `instructions`: System prompt (string or dynamic callback receiving context)
- `tools`: Callable capabilities (Python functions auto-converted to tool schemas)
- `handoffs`: List of agents this agent can delegate to
- `handoff_description`: Text describing the agent when offered as a handoff target
- `output_type`: Structured response format (Pydantic model, dataclass, TypedDict)
- `input_guardrails` / `output_guardrails`: Validation rules
- `model_settings`: Temperature, top_p, tool_choice tuning
- `hooks`: Lifecycle callbacks (`on_agent_start`, `on_tool_end`, `on_handoff`, etc.)

### Dynamic Instructions

Instructions can be a static string or a callable function that receives the run context and returns a string. This enables context-aware prompting at runtime.

### Output Types

When `output_type` is specified, the agent uses Structured Outputs mode instead of plain text. Supports Pydantic models, dataclasses, lists, and TypedDict.

### Tool Use Behavior

Controls what happens after a tool returns:

- `"run_llm_again"` (default): LLM processes the tool result and continues
- `"stop_on_first_tool"`: First tool output becomes the final response
- `StopAtTools([...])`: Stop on specific tool invocations
- Custom function: Programmatic stop/continue logic

### Tool Choice

- `"auto"`: Model decides whether to use tools (default)
- `"required"`: Model must call at least one tool
- `"none"`: No tool calls allowed
- Specific tool name: Force a particular tool

### Agent Cloning

`agent.clone()` duplicates an agent with optional property overrides. Useful for creating variants (e.g., same agent with different instructions for A/B testing).

### Runner

The Runner manages execution:

- `Runner.run()` — async execution
- `Runner.run_sync()` — synchronous execution
- `Runner.run_streamed()` — streaming with partial results

### MCP Integration

Model Context Protocol servers can be registered as tool sources, using the same patterns as function tools. This enables interoperability with external tool ecosystems.

---

## 4. Structured Outputs

### When to Use

Use Structured Outputs whenever agent output feeds into downstream systems. This guarantees the output matches a defined JSON Schema.

Two contexts:
- **Function calling** (`strict: true`): Ensures tool call arguments match the schema
- **Response format**: Ensures the model's final response matches a schema

### Schema Design Best Practices

- Define schemas in Pydantic (Python) or Zod (TypeScript) first, then derive JSON Schema — never handwrite JSON schemas
- Use `strict: true` exclusively (JSON Mode is legacy)
- All fields must be `required` (use `Union[Type, None]` for optional semantics)
- Handle refusals as first-class errors (the model may refuse to generate output matching the schema)
- Root objects cannot use `anyOf` type

### Chain of Thought Pattern

Include a dedicated `reasoning` or `chain_of_thought` field in the schema to improve output quality:

```python
class AgentOutput(BaseModel):
    reasoning: str  # Model explains its thinking here
    decision: str
    confidence: float
```

This gives the model space to reason before committing to structured fields. However, for reasoning models (o1, o3), this is unnecessary as they reason internally.

### Key Limitations

- Not compatible with parallel function calls
- 16k output token limit for complex extractions
- First request with a new schema incurs a latency penalty (schema compilation)
- Optional fields require explicit Union types with null

---

## 5. Multi-Agent Coordination

### LLM-Driven Orchestration

The model decides which agent to invoke or hand off to. Best practices:

1. Write clear prompts describing available tools, usage patterns, and constraints
2. Build specialists that excel at single tasks rather than generalists
3. Enable self-critique loops for quality improvement
4. Monitor performance and iterate based on failure patterns
5. Implement evaluations to train agents progressively

### Code-Based Orchestration

The application code decides agent routing. Patterns:

- **Classification-driven routing**: Use structured outputs to classify the task, then route to the appropriate agent in code
- **Sequential chaining**: Agent A's output feeds into Agent B, with transformation between steps
- **Evaluation loops**: Run an agent, evaluate output, feed back for improvement until criteria are met
- **Parallel execution**: Use `asyncio.gather` for independent subtasks

### Handoff Mechanics (Agents SDK)

Handoffs appear as tools to the LLM. A handoff to "Refund Agent" becomes a `transfer_to_refund_agent` tool.

**Configuration options:**
- `tool_name_override`: Custom tool name
- `tool_description_override`: Custom description for when to hand off
- `on_handoff`: Callback executed when handoff occurs
- `input_type`: Pydantic model for handoff metadata (e.g., escalation reason)
- `input_filter`: Modifies conversation history the receiving agent sees
- `is_enabled`: Boolean or function controlling availability dynamically

**Context preservation**: All agents operate on the same message history by default, eliminating context loss during handoffs. Use `input_filter` to trim or transform history when needed.

**History nesting** (beta): Collapses prior conversation into a summary wrapped in `<CONVERSATION_HISTORY>` blocks, reducing token usage for long conversations.

**Critical constraint**: Handoffs stay within a single run. Input guardrails apply only to the first agent; output guardrails only to the final agent. Use tool guardrails for validation during intermediate steps.

### Triage + Specialist Pattern

The most common multi-agent pattern:

1. A triage agent receives user input
2. Triage classifies the intent
3. Triage hands off to the appropriate specialist (billing, refunds, FAQ, etc.)
4. The specialist owns the conversation from that point
5. Each specialist can hand back to triage if the request shifts domains

---

## 6. Guardrails and Tracing

### Guardrail Types

#### Input Guardrails
- Validate user input before agent execution
- Run in parallel with agent execution (default) or in blocking mode
- Only apply to the first agent in a chain
- Common uses: jailbreak detection, PII redaction, relevance filtering

#### Output Guardrails
- Validate final agent output
- Run after agent completion (always blocking)
- Only apply to the agent that produces the final output
- Common uses: safety classification, format validation, policy compliance

#### Tool Guardrails
- Wrap function tools with before/after validation
- Input guardrails run before tool execution (can skip calls, replace output, or trigger tripwires)
- Output guardrails run after execution (can replace output or trigger tripwires)
- Only apply to function tools (not handoffs or hosted tools)

### Tripwire Mechanism

When a guardrail detects a violation, it triggers a tripwire that immediately raises an exception and halts agent execution. This is the "fail fast" principle — better to abort than to continue with bad input/output.

### Implementation Pattern

Guardrails can be simple prompt-based checks or use a dedicated agent underneath:

1. Receive the input/output to validate
2. Run the guardrail function (can be another LLM call)
3. Return `GuardrailFunctionOutput` with `tripwire_triggered` flag
4. If triggered, the SDK raises the appropriate exception

### Layered Defense

OpenAI recommends defense in depth:

- **Input layer**: Relevance classifiers, jailbreak detection, PII sanitization
- **Tool layer**: Risk assessment before execution, parameter validation
- **Output layer**: Safety classification, policy compliance
- **Human layer**: Approval for high-risk actions, escalation for repeated failures
- **Architecture layer**: Structured outputs between nodes to eliminate freeform attack channels

### Safety-Specific Recommendations

- Pass untrusted inputs through user messages (not developer messages) to limit influence
- Use structured outputs with fixed schemas and enums between workflow nodes
- Keep tool approvals enabled so users review and confirm operations
- Use built-in guardrails to redact PII and detect jailbreak attempts
- Run trace graders and evals to catch mistakes across decision points
- Never let untrusted data directly drive behavior

### Tracing

The Agents SDK automatically traces:

- Entire Runner operations (`trace()`)
- Individual agent executions (`agent_span()`)
- LLM generations (`generation_span()`)
- Function tool calls (`function_span()`)
- Guardrail evaluations (`guardrail_span()`)
- Agent handoffs (`handoff_span()`)

**Trace structure**: Traces represent end-to-end workflows. Spans represent discrete operations within a trace, organized in parent-child hierarchies with timestamps.

**Custom traces**: Use `trace()` as a context manager. Custom spans via `custom_span()`. Spans auto-nest under the current trace using Python contextvars.

**Sensitive data**: Controlled via `RunConfig.trace_include_sensitive_data`. Default is to capture everything — disable for production/compliance.

**External integrations**: 20+ partners including Weights & Biases, Langfuse, LangSmith, MLflow, PostHog, Braintrust, and others.

---

## 7. Common Patterns

### Routing Pattern
A front-door agent classifies the request and routes to the appropriate specialist. Can be LLM-driven (handoffs) or code-driven (structured output classification + if/else).

### Delegation Pattern
A manager agent breaks a complex task into subtasks, delegates each to a specialist (using `Agent.as_tool()`), collects results, and synthesizes a final answer.

### Escalation Pattern
An agent recognizes it cannot handle a request and escalates — either to a more capable agent, to a human operator, or back to a triage agent. Implement via handoff with `input_type` carrying escalation metadata (reason, priority).

### Sequential Pipeline
Agent A processes input, produces structured output, which feeds into Agent B. Each agent has focused instructions and tools. Use code-based orchestration to connect them.

### Parallel Fan-Out
Multiple agents process the same input independently (e.g., different analysis perspectives). Results are collected and merged by a coordinator. Use `asyncio.gather` for execution.

### Self-Critique Loop
An agent produces output, a critic agent evaluates it, and if quality thresholds aren't met, the original agent iterates. Continue until the critic passes or max iterations are reached.

### Human-in-the-Loop
The SDK supports involving humans across agent runs. Use for: high-risk actions, ambiguous situations, quality assurance, and compliance requirements. Implement by pausing execution and awaiting human input before proceeding.

### Memory / Sessions
The Agents SDK provides Sessions as a persistent memory layer. Implementations include SQLAlchemy, Redis, and encrypted variants. Use for maintaining working context within and across agent runs.

---

## 8. Key Takeaways for ASK

### Transferable Principles (Runtime-Agnostic)

1. **Three pillars are universal**: Every agent, regardless of runtime, needs a model, tools, and instructions. ASK's architecture phase should always produce these three clearly.

2. **Start single, split when needed**: Always design for a single agent first. Multi-agent should be a response to observed failure, not a default architecture. ASK's discovery should assess whether multi-agent is warranted.

3. **Routines > monolithic prompts**: Break agent behavior into focused routines (5-15 steps). Each routine is a coherent set of instructions + tools. This maps directly to skill design in ASK.

4. **Handoffs need explicit design**: When multiple agents are needed, design the handoff protocol explicitly: what context travels, who owns the conversation, what metadata accompanies the transition. ASK's architecture phase should include a handoff specification.

5. **Guardrails are architectural, not afterthoughts**: Input, output, and tool guardrails should be designed during architecture, not bolted on. ASK should include guardrail specification in every agent build.

6. **Defense in depth**: Layer multiple validation strategies. No single guardrail is sufficient. ASK should generate guardrail configs at multiple layers.

7. **Structured outputs for inter-agent communication**: When agents pass data to each other or to downstream systems, always use structured schemas. This eliminates freeform attack surfaces and parsing errors.

8. **Tools are first-class citizens**: Well-documented, thoroughly tested, reusable tools with standardized definitions. ASK's skill system aligns perfectly — each skill is a well-defined tool.

9. **Dynamic instructions over static**: Instructions that adapt to context at runtime produce better agents. ASK should support dynamic instruction generation.

10. **Observability from day one**: Tracing, logging, and monitoring should be built in from the start, not added later. ASK should include tracing configuration in every agent build.

### Mapping to ASK Runtimes

| OpenAI Pattern | OpenClaw | Claude Code | Hermes |
|---|---|---|---|
| Instructions | SOUL.md + IDENTITY.md | CLAUDE.md | Agent file |
| Tools | Skills directory | Commands + Skills | Tool definitions |
| Handoffs | Agent-to-agent config | N/A (single agent) | Agent handoff spec |
| Guardrails | MEMORY.md + constraints | Settings + hooks | Input/output filters |
| Structured Output | Output schemas | Response format | Return types |
| Tracing | Run logs | Debug logs | Trace config |

### What ASK Should Generate

For every agent build, ASK should produce:

1. **Identity spec** — Who the agent is, what it does, its boundaries
2. **Instruction set** — Broken into focused routines, not monolithic blocks
3. **Tool manifest** — Every tool with name, description, parameters, and when-to-use guidance
4. **Guardrail config** — Input validation, output validation, tool safety, escalation rules
5. **Handoff protocol** (if multi-agent) — Transfer functions, context preservation rules, routing logic
6. **Memory layer** — What to persist, how to recall, anti-amnesia mechanisms
7. **Evaluation criteria** — How to measure if the agent is working correctly
8. **Tracing setup** — What to observe, what's sensitive, where traces go

---

## Sources

- [A practical guide to building agents — OpenAI](https://openai.com/business/guides-and-resources/a-practical-guide-to-building-ai-agents/)
- [Building agents — OpenAI Developer Track](https://developers.openai.com/tracks/building-agents/)
- [OpenAI Agents SDK Documentation](https://openai.github.io/openai-agents-python/)
- [Agents SDK — Agents](https://openai.github.io/openai-agents-python/agents/)
- [Agents SDK — Handoffs](https://openai.github.io/openai-agents-python/handoffs/)
- [Agents SDK — Guardrails](https://openai.github.io/openai-agents-python/guardrails/)
- [Agents SDK — Tracing](https://openai.github.io/openai-agents-python/tracing/)
- [Agents SDK — Multi-Agent Orchestration](https://openai.github.io/openai-agents-python/multi_agent/)
- [Agents SDK — GitHub Repository](https://github.com/openai/openai-agents-python)
- [Orchestrating Agents: Routines and Handoffs — OpenAI Cookbook](https://developers.openai.com/cookbook/examples/orchestrating_agents/)
- [OpenAI Swarm — GitHub (educational, superseded by Agents SDK)](https://github.com/openai/swarm)
- [Function Calling — OpenAI API](https://platform.openai.com/docs/guides/function-calling)
- [Structured Model Outputs — OpenAI API](https://platform.openai.com/docs/guides/structured-outputs)
- [Safety in Building Agents — OpenAI API](https://developers.openai.com/api/docs/guides/agent-builder-safety/)
- [Introducing Structured Outputs in the API — OpenAI](https://openai.com/index/introducing-structured-outputs-in-the-api/)
- [Building Governed AI Agents — OpenAI Cookbook](https://developers.openai.com/cookbook/examples/partners/agentic_governance_guide/agentic_governance_cookbook)
