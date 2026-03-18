# Anthropic Agent-Building Guide — ASK Reference

> Comprehensive reference distilled from Anthropic's official guidance on building effective AI agents.
> Sources: anthropic.com/research, anthropic.com/engineering, Claude API docs, Anthropic blog posts.
> Last updated: 2026-03-17

---

## 1. Core Principles

Anthropic's agent-building philosophy rests on a clear hierarchy of preferences:

### Start Simple, Add Complexity Only When Justified

> "Success in the LLM space isn't about building the most sophisticated system. It's about building the right system for your needs."

The recommended progression:
1. Start with a single optimized LLM call + retrieval
2. Add prompt chaining or routing if that plateaus
3. Move to full agentic loops only when simpler solutions demonstrably fall short

Agentic systems trade **latency and cost for better task performance**. Evaluate this tradeoff explicitly before committing to agent architecture.

### Prefer Direct API Calls Over Frameworks

> "Start by using LLM APIs directly: many patterns can be implemented in a few lines of code."

Frameworks (Agent SDK, LangChain, etc.) create abstraction layers that:
- Obscure underlying prompts and responses, making debugging harder
- Tempt developers to add unnecessary complexity
- Lead to incorrect assumptions about what happens under the hood

If you use a framework, understand the underlying implementation. Incorrect assumptions about framework internals are "a common source of customer error."

### The Augmented LLM as Building Block

Every agentic system builds on the same foundation: an LLM enhanced with:
- **Retrieval** — access to relevant information
- **Tools** — ability to take actions in the world
- **Memory** — persistence across interactions

Current models actively use these capabilities: generating search queries, selecting tools, determining what to retain. Focus on tailoring these augmentations to your specific use case.

### Workflows vs. Agents — Know the Difference

| | Workflows | Agents |
|---|---|---|
| **Definition** | LLMs + tools orchestrated through predefined code paths | LLMs dynamically direct their own processes and tool usage |
| **Best for** | Well-defined tasks requiring predictability | Tasks requiring flexibility and model-driven decisions |
| **Control** | Developer controls the flow | Model controls the flow |
| **Tradeoff** | Predictable, lower cost | More capable, higher cost/latency |

---

## 2. Agent Architectures

Anthropic defines five core workflow patterns plus autonomous agents. These are composable building blocks, not mutually exclusive choices.

### 2.1 Prompt Chaining

Decompose a task into sequential steps where each LLM call processes the previous output.

**When to use:** Tasks that decompose cleanly into fixed subtasks. Trading latency for higher accuracy.

**Key practice:** Add programmatic gates (validation, checks) between steps. These gates can catch errors early before they propagate.

**Examples:**
- Generate marketing copy, then translate it
- Create document outline, then write full document from outline
- Generate code, then review it against criteria

### 2.2 Routing

Classify an input and direct it to a specialized handler. Each handler gets its own optimized prompt.

**When to use:** Complex tasks with distinct input categories that benefit from specialized handling.

**Key practice:** Route simple queries to smaller/cheaper models. Route complex queries to more capable models.

**Examples:**
- Customer service: categorize ticket type, route to specialized handler
- Model selection: triage by difficulty, send to appropriate model tier

### 2.3 Parallelization

Run tasks simultaneously and aggregate results. Two variants:

- **Sectioning:** Independent subtasks run in parallel (e.g., analyze different aspects of a document simultaneously)
- **Voting:** Same task executed multiple times for consensus (e.g., multiple code reviewers, content moderation via majority vote)

**When to use:** Subtasks are independent; multiple perspectives improve confidence.

**Examples:**
- Run guardrails screening in parallel with core response generation
- Multiple reviewers for the same code change
- Parallel search across different data sources

### 2.4 Orchestrator-Workers

A central LLM dynamically decomposes tasks and delegates to worker LLMs. Unlike parallelization, the subtasks are not predefined — they emerge from analyzing the input.

**When to use:** Unpredictable task structures where you cannot define subtasks in advance.

**Examples:**
- Multi-file code modifications (orchestrator decides which files need changes)
- Multi-source information gathering (orchestrator decides what to search for)

### 2.5 Evaluator-Optimizer

Two LLMs in a loop: one generates, the other evaluates and provides feedback. The generator refines based on feedback until quality criteria are met.

**When to use:** Clear evaluation criteria exist, and iterative improvement demonstrably helps.

**Examples:**
- Literary translation with quality feedback loops
- Iterative search: search, evaluate results, refine query, repeat

### 2.6 Autonomous Agents

Full agents where the LLM controls its own execution loop. The agent receives a goal, then independently plans, executes, verifies, and iterates.

**Critical design requirements:**
- Provide **ground truth feedback** at every step (tool results, test outputs, execution results)
- Include **stopping conditions** (iteration limits, token budgets) to prevent runaway execution
- Implement **extensive sandboxed testing** before deployment
- Build in **human checkpoints** for high-stakes or irreversible actions

**Warning:** Higher costs and compounding error risks demand careful implementation. Each step's errors compound into subsequent steps.

### 2.7 Subagent Orchestration

Spawn specialized subagents with isolated context windows. The orchestrator delegates tasks; subagents work independently and return condensed results.

**Benefits:**
- **Parallelization** — multiple subagents work simultaneously
- **Context isolation** — each subagent uses its own clean context window (thousands of tokens of exploration, condensed to 1,000-2,000 tokens of results)
- **Separation of concerns** — each subagent has a focused goal

**Caution:** Claude Opus 4.6 has "a strong predilection for subagents" and may overuse them. For simple tasks (single grep, single file edit), direct execution is faster and more efficient.

**Prompt guidance for subagent control:**
> "Use subagents when tasks can run in parallel, require isolated context, or involve independent workstreams. For simple tasks, sequential operations, single-file edits, or tasks where you need to maintain context across steps, work directly."

---

## 3. Tool Use Best Practices

Anthropic emphasizes: **tool definitions deserve as much prompt engineering attention as your system prompt.**

### 3.1 Strategic Tool Selection

More tools does not equal better performance. Build "a few thoughtful tools targeting specific high-impact workflows" rather than wrapping every API endpoint.

**Key insight:** Agents have limited context windows. Unlike a computer with abundant memory, every tool definition competes for attention.

**Example:** Instead of `list_contacts` (which forces reading every entry), build `search_contacts` (which jumps to relevant results, like searching an address book alphabetically).

### 3.2 Consolidate Functionality

Tools can handle multiple discrete operations internally:
- `schedule_event` (finds availability + books meeting) instead of separate `list_users`, `list_events`, `create_event`
- `search_logs` (returns relevant lines with context) instead of `read_logs`
- `get_customer_context` (compiles recent info) instead of separate customer, transaction, and notes tools

### 3.3 Tool Description Quality

Think of descriptions as documentation for a new team member. Include:
- What the tool does and when to use it
- Specialized query formats and syntax
- Definitions of domain-specific terminology
- Relationships between resources
- Clear input/output specifications
- Example usage and edge cases
- Boundaries between similar tools

> "Small refinements to tool descriptions can yield dramatic improvements." During SWE-bench development, precise tool description updates achieved state-of-the-art performance.

### 3.4 Parameter Design

- Use **unambiguous parameter names**: `user_id` not `user`
- Use **semantically meaningful names**: agents perform significantly better with clear naming
- Apply **Poka-yoke principles** — design parameters to make mistakes harder
  - Example: requiring absolute filepaths eliminated relative path errors that previously plagued agents

### 3.5 Namespace Tools Clearly

Group related tools under common prefixes: `asana_search`, `asana_projects_search`, `jira_search`. This prevents agent confusion about which tool to use.

> "Selecting between prefix- and suffix-based namespacing produces non-trivial effects on tool-use evaluations." Test both approaches.

### 3.6 Response Design

**Return high-signal information.** Prioritize human-friendly fields (`name`, `image_url`, `file_type`) over technical identifiers (`uuid`, `256px_image_url`, `mime_type`).

**Implement token efficiency.** Use pagination, filtering, truncation with sensible defaults. When truncating, steer agents toward more targeted queries rather than broad ones.

**Consider a `response_format` enum.** Let agents choose `"concise"` or `"detailed"` — concise format can use one-third the tokens of detailed format.

### 3.7 Error Handling in Tools

Provide **actionable error messages.** Instead of opaque codes or tracebacks:
- Specify what went wrong
- Explain which parameters were invalid
- Show correctly-formatted input examples

### 3.8 Advanced Tool Features

Three features for scaling tool use:

1. **Tool Search Tool** — Dynamic tool discovery. Instead of loading all tool definitions (55K+ tokens), agents search for relevant tools on-demand (~8.7K tokens). 85% context reduction.
2. **Programmatic Tool Calling** — Claude writes Python scripts to orchestrate multiple tools, keeping intermediate results out of context. 37% average token reduction.
3. **Tool Use Examples** — Provide concrete usage patterns beyond JSON schemas. Improved accuracy from 72% to 90% on complex parameter handling.

---

## 4. System Prompt Design

### 4.1 General Principles

**Be clear and direct.** Claude responds well to explicit instructions. Think of Claude as "a brilliant but new employee who lacks context on your norms and workflows."

> **Golden rule:** Show your prompt to a colleague with minimal context. If they'd be confused, Claude will be too.

**Add context and motivation.** Explain *why* instructions matter, not just *what* to do. Claude generalizes from explanations.

**Use XML tags for structure.** Wrap different content types in tags (`<instructions>`, `<context>`, `<input>`) to reduce misinterpretation. Use consistent, descriptive tag names.

**Give Claude a role.** Even a single sentence in the system prompt focuses behavior and tone for your use case.

### 4.2 The Right Altitude

System prompts should find the "right altitude" — specific enough to guide behavior effectively without becoming brittle or overly prescriptive:
- Use simple, direct language
- Avoid hardcoding complex conditional logic
- Provide concrete signals rather than vague guidance
- Organize into distinct sections (XML tags or Markdown headers)
- Strive for minimal yet sufficient information

**Process:** Start with a minimal prompt on the strongest model. Iteratively add instructions based on observed failure modes.

### 4.3 Examples (Few-Shot Prompting)

Include 3-5 diverse, relevant examples for best results. Make them:
- **Relevant** — mirror actual use cases
- **Diverse** — cover edge cases, avoid unintended pattern pickup
- **Structured** — wrap in `<example>` tags to distinguish from instructions

### 4.4 Long Context Handling

- Place long documents **at the top** of the prompt, above queries and instructions (up to 30% quality improvement)
- Structure documents with XML tags and metadata
- Ask Claude to **quote relevant sections** before answering — helps cut through noise

### 4.5 Agentic-Specific Prompt Patterns

**For proactive tool use:**
> "By default, implement changes rather than only suggesting them. If the user's intent is unclear, infer the most useful likely action and proceed."

**For conservative behavior:**
> "Do not jump into implementation unless clearly instructed. Default to providing information and recommendations rather than taking action."

**For parallel tool execution:**
> "If you intend to call multiple tools and there are no dependencies between the calls, make all independent calls in parallel."

**For safety-conscious action:**
> "Consider the reversibility and potential impact of your actions. Take local, reversible actions freely, but for hard-to-reverse or externally-visible actions, ask before proceeding."

### 4.6 Thinking and Reasoning Guidance

- Prefer **general instructions** ("think thoroughly") over prescriptive step-by-step plans — Claude's reasoning often exceeds what a human would prescribe
- Use `<thinking>` tags in few-shot examples to show reasoning patterns
- Ask Claude to **self-check**: "Before you finish, verify your answer against [test criteria]"
- For Claude 4.6, use **adaptive thinking** (`thinking: {type: "adaptive"}`) — it lets Claude calibrate reasoning depth per step

### 4.7 Avoiding Overtriggering (Claude 4.5/4.6)

Claude's latest models are more responsive to system prompts. If your prompts were designed to reduce undertriggering:

> Where you might have said "CRITICAL: You MUST use this tool when...", you can use more normal prompting like "Use this tool when..."

---

## 5. Context Engineering

Context engineering goes beyond prompt engineering. It addresses how to manage **all information** during multi-turn agent interactions.

### 5.1 Core Principle

> "Find the smallest set of high-signal tokens that maximize the likelihood of desired outcomes."

Context is a finite resource. Every token competes for the model's attention. Performance degrades as context grows ("context rot").

### 5.2 Dynamic Context Retrieval (Just-in-Time)

Instead of pre-loading all data, maintain lightweight identifiers and load data at runtime:
- **Progressive disclosure** — discover relevant context incrementally through exploration
- **Metadata as signal** — file hierarchies, naming conventions, timestamps provide direction without loading full objects
- **Hybrid approach** — retrieve some data upfront, enable autonomous exploration for the rest

### 5.3 Compaction

When context grows too large, summarize and reinitialize:
- Preserve critical decisions, unresolved issues, implementation details
- Discard redundant outputs
- **Safest form:** tool result clearing — remove already-processed output rather than summarizing conversation

### 5.4 Structured Note-Taking (Agentic Memory)

Agents maintain external memory files (e.g., `NOTES.md`, `progress.txt`) containing:
- Progress tracking
- Strategic decisions
- Learned patterns
- State that persists across context window resets

This enables multi-hour coherent work across many context windows.

### 5.5 Sub-Agent Architecture for Context

Specialized subagents handle focused tasks with clean context windows:
- Each explores extensively (thousands of tokens)
- Returns condensed summaries (1,000-2,000 tokens)
- Lead agent synthesizes results
- Achieves clear separation of concerns

---

## 6. Human-in-the-Loop

### 6.1 When to Involve Humans

Anthropic recommends human checkpoints for:
- **Irreversible actions** — file deletion, force pushes, database drops
- **Externally visible actions** — pushing code, commenting on PRs, sending messages, modifying infrastructure
- **High-stakes decisions** — financial transactions, medical recommendations
- **Confidence thresholds** — when the agent is uncertain about the correct approach
- **Competency limits** — when the task exceeds the agent's demonstrated capabilities

### 6.2 Implementation Patterns

**Reversibility-based classification:**
- **Take freely:** Local, reversible actions (editing files, running tests)
- **Ask first:** Hard-to-reverse, externally-visible, or destructive actions

**Dual-LLM guardrail pattern:**
- Run a guardrail classifier **in parallel** with the main response generation
- The classifier monitors inputs and outputs for policy violations
- If flagged, additional instructions or blocks are applied before the response reaches the user

**Escalation design:**
- Detect confidence levels and competency limits
- Implement rate limiting to prevent cascade failures
- Multi-factor authentication for critical actions

### 6.3 Trust Calibration

As agents prove reliable, human oversight can decrease:
> "As underlying models become more capable, the level of autonomy of agents can scale."

But human review remains crucial for high-stakes applications, especially coding (where automated tests provide some ground truth) and customer-facing interactions.

---

## 7. Guardrails and Safety

### 7.1 Multi-Layered Defense

Anthropic implements safety through multiple layers:

1. **Training-level safety** — model trained to follow behavioral guidelines
2. **Constitutional Classifiers** — safeguards monitoring inputs/outputs against a "constitution" of rules
3. **Response steering** — dynamic adjustment of system prompt based on classifier detection
4. **Two-stage screening** — cheap activation probe screens all traffic; suspicious exchanges escalated to full classifier

The Constitutional Classifiers approach reduced jailbreak success from 86% to 4.4%.

### 7.2 Agent-Specific Guardrails

**Parallelized guardrails:** Run safety classification simultaneously with main response generation. This adds safety without adding latency to the critical path.

**Tightly-scoped function calling:** Restrict agents to pre-defined, safe actions. Example from healthcare: schedule appointments (allowed) vs. prescribe medication (blocked).

**RAG for grounding:** Force agents to base answers on vetted document libraries, reducing hallucination risk.

### 7.3 Preventing Overaction

Claude 4.6 may take difficult-to-reverse actions without asking. Explicit prompt guidance is required:

> "Consider the reversibility and potential impact of your actions. For destructive operations (deleting files, force-pushing, dropping tables), hard-to-reverse operations, and operations visible to others — ask the user before proceeding."

### 7.4 Minimizing Hallucination

> "Never speculate about code you have not opened. If the user references a specific file, read it before answering. Investigate before answering questions about the codebase."

### 7.5 Agent Skills and Safety

Each skill should bundle its own guardrails alongside its instructions. A capability carries its own responsibility. When installing third-party skills, audit:
- Code dependencies
- Bundled resources (images, scripts)
- Instructions directing connection to external network sources

---

## 8. Long-Running Agent Patterns

### 8.1 The Two-Agent Architecture

For long-running tasks spanning multiple context windows:

**Initializer Agent (first session):**
- Creates `init.sh` for environment setup
- Writes `progress.txt` documenting agent activities
- Creates feature list (JSON with `passes` boolean per feature)
- Makes initial git commit as clean baseline

**Coding Agent (subsequent sessions):**
1. Run `pwd` to confirm location
2. Read git logs and progress files
3. Review feature list, select one incomplete feature
4. Start dev server, run basic tests
5. Work incrementally on selected feature
6. Commit with descriptive messages
7. Update progress documentation before session end

### 8.2 State Management

- **Feature list as source of truth** — JSON file with boolean completion flags
- **Git as rollback mechanism** — descriptive commits enable reverting failed changes
- **Progress file for context** — new sessions read recent activity to avoid duplication
- **Structured formats for state data** — JSON for test results, task status
- **Unstructured text for progress notes** — freeform notes for general tracking

### 8.3 Context Window Transitions

- Use a **different prompt** for the first context window (setup) vs. subsequent windows (iteration)
- Have agents **write tests in structured format** before starting work
- Create **setup scripts** (`init.sh`) to prevent repeated work
- Consider **starting fresh** over compaction — latest models are effective at discovering state from the filesystem
- **Encourage complete context usage** — prompt agents to work systematically until the task is done

### 8.4 Verification at Every Session Start

Without explicit prompting, agents tend to mark features complete without proper validation. Require:
- Browser automation tools for end-to-end testing
- Mandatory verification before marking features as passing
- Start each session by testing core functionality

---

## 9. Agent Skills Framework

### 9.1 What Skills Are

Agent Skills are organized folders containing instructions, scripts, and resources that agents discover and load dynamically. They transform general-purpose agents into specialized ones by packaging domain expertise into composable resources.

### 9.2 Skill Anatomy

Every skill requires a `SKILL.md` file with YAML frontmatter:
- `name`: Skill identifier
- `description`: Purpose and use cases

Metadata is pre-loaded into the agent's system prompt at startup.

### 9.3 Progressive Disclosure (Three Tiers)

**Level 1:** Name and description load automatically — just enough for Claude to know when the skill applies, without consuming full context.

**Level 2:** `SKILL.md` body loads when Claude determines the skill is relevant to the current task.

**Level 3+:** Additional bundled files (`forms.md`, `reference.md`) load only when Claude encounters specific scenarios requiring that context.

This enables "unbounded" skill complexity since agents with filesystem access don't need everything in context simultaneously.

### 9.4 Best Practices

- **Start with evaluation** — identify where agents struggle, then build skills to address gaps
- **Structure for scale** — when `SKILL.md` becomes unwieldy, split into separate files
- **Name and description matter critically** — these fields determine whether Claude triggers the skill
- **Iterate collaboratively** — work with Claude to capture successful approaches; request self-reflection when skills underperform
- **Bundle executable scripts** — Python scripts Claude executes directly, without loading code into context (deterministic reliability)

---

## 10. Common Pitfalls

### 10.1 Over-Engineering

The most common mistake. Adding complexity beyond what demonstrably improves outcomes. Signs:
- Using a full agent framework when a single LLM call suffices
- Multi-agent architectures for tasks a single prompt handles well
- Creating abstractions and flexibility that were never requested
- Claude Opus 4.6 in particular tends to overengineer — add prompt guidance to keep solutions minimal

### 10.2 Poor Tool Design

- Wrapping every API endpoint as a separate tool instead of building consolidated, high-impact tools
- Ambiguous tool names or overlapping functionality — "if a human engineer can't definitively say which tool should be used, an AI agent can't be expected to do better"
- Missing edge cases, examples, and boundary documentation in tool descriptions
- Using cryptic parameter names (`user` instead of `user_id`)

### 10.3 Context Window Overload

> "Every token you add to the context window competes for the model's attention — stuffing a hundred thousand tokens of history and the model's ability to reason about what matters degrades."

Solutions: progressive disclosure, compaction, subagent context isolation, just-in-time retrieval.

### 10.4 Framework Abstraction Blindness

Using frameworks without understanding their internals. This leads to:
- Debugging failures you can't trace
- Incorrect assumptions about how prompts are constructed
- Adding layers that obscure what the model actually receives

### 10.5 Missing Ground Truth Feedback

Agents without verifiable feedback at each step accumulate errors. Every action should produce observable output the agent can evaluate:
- Tool execution results
- Test pass/fail outputs
- File system state changes
- Explicit success/failure signals

### 10.6 Premature Victory Declaration

Without explicit prompting, agents mark tasks as complete without proper validation. Solutions:
- Structured feature lists with boolean completion flags
- Mandatory verification steps before declaring success
- Browser automation for end-to-end testing

### 10.7 Guardrail Inconsistency

> "It is extraordinarily difficult to get an AI agent to follow guardrails consistently — the agent reinterprets the rules, finds edge cases you didn't anticipate, and applies reasoning that is technically logical but practically wrong."

Solution: Use parallelized classification (dual-LLM pattern) rather than relying solely on prompt-based guardrails.

### 10.8 Ignoring Overeagerness in New Models

Claude 4.5/4.6 may:
- Overtrigger tools that previous models undertriggered
- Spawn subagents unnecessarily
- Create extra files and unnecessary abstractions
- Take destructive actions without asking

Dial back aggressive prompting language. Add explicit constraints for minimal solutions.

---

## 11. Key Takeaways for ASK

These principles directly inform how ASK should build agents:

### Discovery Phase (`/ask:discovery`)

1. **Determine the right architecture level.** Not every agent needs full autonomy. During discovery, classify whether the use case needs a simple workflow (prompt chaining, routing) or a true autonomous agent. Start with the simplest viable pattern.

2. **Identify ground truth signals.** Every effective agent needs verifiable feedback. During discovery, map what observable outputs exist (test results, API responses, user confirmations) that the agent can use to self-correct.

3. **Define human-in-the-loop boundaries.** Classify which actions are reversible (agent acts freely) vs. irreversible (agent asks first). Bake this into the agent's design from day one.

### Architecture Phase (`/ask:architecture`)

4. **Choose composable patterns, not monoliths.** Use Anthropic's five workflow patterns as building blocks. Combine them based on task structure — routing for input classification, parallelization for independent subtasks, evaluator-optimizer for quality-critical output.

5. **Design tools as first-class citizens.** Tool definitions get as much attention as system prompts. Consolidate related operations, use clear naming, provide examples and edge cases, apply Poka-yoke principles to prevent misuse.

6. **Implement progressive disclosure for context.** Use the Agent Skills three-tier pattern: metadata loads first, full instructions load on relevance, specialized resources load on demand. Never front-load everything into context.

7. **Plan for multi-session work.** Design state management from the start: structured feature lists, progress files, git-based state tracking. Agents should be able to resume from a fresh context window without losing work.

### Build Phase (`/ask:build`)

8. **Write system prompts at the right altitude.** Specific enough to guide, not so specific they break. Use XML tags for structure. Start minimal, iterate based on observed failures.

9. **Bundle guardrails with capabilities.** Each skill/capability carries its own safety constraints. Don't bolt safety on after — design it in.

10. **Implement the verification loop.** Every agent needs: gather context, take action, verify work, iterate. Build verification tools (tests, screenshots, structured output checks) into the agent from day one.

### Validate Phase (`/ask:validate`)

11. **Test with realistic, complex scenarios.** Weak evals use oversimplified prompts. Strong evals require multiple tool calls, ambiguous inputs, and multi-step reasoning.

12. **Track metrics beyond accuracy.** Monitor: total runtime, tool call count, token consumption, error rates. These reveal workflow inefficiencies and tool consolidation opportunities.

13. **Use agents to analyze their own failures.** Concatenate evaluation transcripts and feed them to Claude. It excels at identifying inconsistencies between implementations and descriptions.

### Anti-Amnesia Principles

14. **Structured note-taking as memory layer.** External memory files (`progress.txt`, `NOTES.md`) persist across context windows. Agents read these at session start to restore state.

15. **Git as the ultimate state log.** Descriptive commits provide rollback capability and context for future sessions. Agents should commit incrementally with meaningful messages.

16. **Feature lists as source of truth.** JSON-structured task lists with completion flags prevent agents from losing track of what's done and what remains.

---

## Sources

- [Building Effective AI Agents](https://www.anthropic.com/research/building-effective-agents) — Anthropic's foundational agent guide
- [Writing Tools for Agents](https://www.anthropic.com/engineering/writing-tools-for-agents) — Tool design principles
- [Equipping Agents with Agent Skills](https://claude.com/blog/equipping-agents-for-the-real-world-with-agent-skills) — Agent Skills framework
- [Effective Context Engineering for AI Agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) — Context management
- [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) — Long-running agent patterns
- [Building Agents with the Claude Agent SDK](https://claude.com/blog/building-agents-with-the-claude-agent-sdk) — SDK architecture
- [Advanced Tool Use](https://www.anthropic.com/engineering/advanced-tool-use) — Tool Search, Programmatic Tool Calling, Tool Use Examples
- [Prompting Best Practices for Claude 4.6](https://platform.claude.com/docs/en/docs/build-with-claude/prompt-engineering/claude-4-best-practices) — System prompt and agentic prompt patterns
- [Building Safeguards for Claude](https://www.anthropic.com/news/building-safeguards-for-claude) — Constitutional Classifiers and safety architecture
- [Next-Generation Constitutional Classifiers](https://www.anthropic.com/research/next-generation-constitutional-classifiers) — Dual-stage safety screening
