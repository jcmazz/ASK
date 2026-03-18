# Prompt Engineering for AI Agents — ASK Reference

> The most-consulted reference in ASK. Every agent build uses this.
> Last updated: 2026-03-17

---

## Table of Contents

1. [Foundational Techniques](#1-foundational-techniques)
2. [Agent-Specific Techniques](#2-agent-specific-techniques)
3. [Output Control](#3-output-control)
4. [Advanced Patterns](#4-advanced-patterns)
5. [Anti-Patterns](#5-anti-patterns)
6. [Template Library](#6-template-library)
7. [Key Takeaways for ASK](#7-key-takeaways-for-ask)

---

## 1. Foundational Techniques

### 1.1 Role Prompting (Persona Assignment)

Role prompting sets the agent's identity, expertise, and behavioral frame. Even a single sentence makes a measurable difference in output quality, tone, and adherence to constraints.

**When to use:** Always. Every agent needs an identity anchor.

**How to do it well:**

- Define WHO the agent is, not just WHAT it does
- Include expertise domain, communication style, and values
- Be specific about what the role implies (and what it excludes)
- Combine role with explicit constraints to prevent drift

**Example — Weak:**
```
You are a helpful assistant.
```

**Example — Strong:**
```
You are a senior financial analyst specializing in SaaS metrics.
You communicate with precision, back claims with data, and flag
uncertainty explicitly. You never speculate about legal or tax
implications — you redirect those to qualified professionals.
```

**Example — Agent-grade:**
```
<identity>
You are Mara, a customer success agent for Acme Corp.
Tone: warm, professional, solution-oriented.
Expertise: subscription management, billing, product features.
You do NOT handle: legal disputes, security incidents, refunds > $500.
When asked about those, escalate to a human agent with context summary.
</identity>
```

**Key insight from Anthropic:** Setting a role in the system prompt focuses the model's behavior and tone for your use case. Roles work as behavioral anchors that persist across turns.

---

### 1.2 Chain of Thought (CoT)

Chain-of-Thought prompting makes the model reason step-by-step before producing a final answer. Introduced by Wei et al. (2022), it remains one of the most impactful techniques for complex reasoning tasks.

**When to use:**
- Multi-step reasoning (math, logic, analysis)
- Tasks requiring evidence evaluation
- Decision-making with trade-offs
- Debugging or root-cause analysis
- High-stakes outputs that need auditability

**When NOT to use:**
- Simple factual lookups
- Single-step tasks (greetings, formatting)
- When latency matters more than accuracy
- When token budget is severely constrained

**Variants:**

| Variant | Description | Use When |
|---|---|---|
| Zero-Shot CoT | Add "Think step by step" | Quick boost, no examples available |
| Few-Shot CoT | Provide worked examples with reasoning | Complex domain-specific reasoning |
| Auto-CoT | Model generates its own diverse examples | Automating prompt construction |
| Structured CoT | Use XML tags to separate thinking from output | Agent architectures needing parseable reasoning |

**Example — Zero-Shot CoT:**
```
Before answering, think through this step by step.
What are the implications of switching from monthly to annual billing
for a customer with 3 months remaining on their current plan?
```

**Example — Structured CoT for agents:**
```
<instructions>
When handling a customer request:
1. First, identify the customer's core need in <thinking> tags
2. Check what tools/data you need
3. Execute the necessary actions
4. Verify the result before responding
</instructions>
```

**Trade-offs:**
- Increases token consumption 2-4x
- Only yields significant gains with capable models (GPT-4 class and above)
- Smaller models may produce illogical reasoning chains that hurt accuracy
- For modern reasoning models (o1, Claude with extended thinking), explicit CoT instructions are less necessary — the model reasons internally

---

### 1.3 Few-Shot Examples

Few-shot prompting steers the model by showing 2-5 input/output pairs before the actual task. Research shows that the format and distribution of examples matters more than whether individual labels are technically correct (Min et al., 2022).

**When to use:**
- Establishing a specific output format
- Teaching domain-specific classification
- Showing tone, style, or reasoning patterns
- Complex tasks where instructions alone are ambiguous

**Selection principles:**

1. **Diversity over quantity** — Cover different edge cases rather than repeating similar examples
2. **Representative distribution** — Examples should reflect the actual variety of inputs the agent will face
3. **Relevance** — Irrelevant examples confuse the model more than having fewer examples
4. **Difficulty gradient** — Include at least one easy case and one edge case

**Formatting rules:**

- Maintain IDENTICAL formatting across all examples (punctuation, capitalization, structure)
- Use clear delimiters between examples (`---`, XML tags, or numbered sections)
- Place examples after the task description but before the actual input
- Start with 2-3 examples; add more only to address specific failure modes

**Example — Classification with few-shot:**
```
Classify customer messages into: billing, technical, feature_request, escalation.

<examples>
<example>
<input>I was charged twice for my subscription this month</input>
<output>billing</output>
</example>

<example>
<input>The API returns a 500 error when I try to upload files over 10MB</input>
<output>technical</output>
</example>

<example>
<input>It would be great if you supported SSO with Okta</input>
<output>feature_request</output>
</example>

<example>
<input>I've been waiting 5 days and nobody has responded. I want to speak to a manager.</input>
<output>escalation</output>
</example>
</examples>

Now classify this message:
<input>{{customer_message}}</input>
```

**Example — Tone calibration with few-shot:**
```
<examples>
<example>
<customer>This is ridiculous, I've been waiting forever!</customer>
<response>I completely understand your frustration — waiting is never fun. Let me look into this right now and get you a clear answer within the next few minutes.</response>
</example>

<example>
<customer>Hey, quick question about my plan</customer>
<response>Of course! What would you like to know about your plan?</response>
</example>
</examples>
```

---

### 1.4 Zero-Shot with Instructions

The simplest technique: clear, explicit instructions without examples. Works well for capable models when the task is well-defined.

**When to use:**
- Simple, well-understood tasks
- When context window space is limited
- When the model already understands the domain
- Rapid prototyping before adding few-shot examples

**Principles for effective zero-shot:**

1. **Be explicit** — Say exactly what you want, not what you don't want
2. **Specify format** — Describe the output structure before the task
3. **Set boundaries** — Define scope, length, and constraints
4. **Use positive framing** — "Respond only with..." instead of "Don't include..."

**Example:**
```
Summarize the following support ticket in exactly 2 sentences.
Sentence 1: The customer's problem.
Sentence 2: The resolution status.
Use past tense. Do not include the customer's name.

<ticket>
{{ticket_content}}
</ticket>
```

---

## 2. Agent-Specific Techniques

### 2.1 System Prompt Structure for Agents

A well-structured agent system prompt follows a layered architecture. The order matters — models attend differently to content at the beginning vs. end of the prompt.

**The 5-Block Pattern:**

```
┌─────────────────────────────────┐
│  1. IDENTITY                    │  Who the agent is, expertise, tone
├─────────────────────────────────┤
│  2. RULES & CONSTRAINTS         │  Guardrails, boundaries, policies
├─────────────────────────────────┤
│  3. TOOLS & CAPABILITIES        │  Available tools, when to use each
├─────────────────────────────────┤
│  4. CONTEXT & KNOWLEDGE         │  Domain data, reference material
├─────────────────────────────────┤
│  5. EXAMPLES & OUTPUT FORMAT    │  Few-shot examples, format specs
└─────────────────────────────────┘
```

**Why this order:**

- **Identity first** — anchors all downstream behavior
- **Rules before tools** — constraints shape tool usage decisions
- **Tools before context** — the agent needs to know its capabilities before processing domain data
- **Context before examples** — large data blocks go high in the prompt (Anthropic recommendation: longform data above queries)
- **Examples last** — closest to where output begins, maximizing format adherence

**Concrete skeleton:**
```xml
<identity>
You are [Name], a [role] for [organization].
[Tone description]. [Expertise description].
[What you handle]. [What you don't handle].
</identity>

<rules>
- Always [core behavior]
- Never [hard constraint]
- When uncertain, [uncertainty protocol]
- If asked about [out-of-scope], [redirect behavior]
</rules>

<tools>
You have access to the following tools:
- search_knowledge_base: Use when the user asks a factual question about [domain]
- create_ticket: Use when the user reports a problem that requires follow-up
- escalate_to_human: Use when [escalation criteria]

Tool usage rules:
- Always search before answering factual questions
- Never call create_ticket without confirming the details with the user
- Prefer search_knowledge_base over generating answers from memory
</tools>

<context>
{{injected_domain_knowledge}}
{{user_profile}}
{{conversation_history_summary}}
</context>

<output_format>
Respond conversationally. Use markdown only when sharing structured data.
Keep responses under 150 words unless the user asks for detail.
When sharing action results, use this format:
[Action taken]: [brief description]
[Result]: [outcome]
[Next step]: [what happens next or what the user should do]
</output_format>
```

---

### 2.2 Tool Use Prompting

How you describe tools directly impacts how well the agent uses them. This is one of the highest-leverage areas in agent prompt engineering.

**Core principles:**

1. **Use the native tool/function API** — Don't manually inject tool descriptions into prompts. Using the platform's tools field increases performance by ~2% on benchmarks (OpenAI research) and reduces formatting errors.

2. **Describe WHEN, not just WHAT** — Every tool description should include the trigger condition.

3. **Keep tool count low** — Aim for fewer than 20 tools available at any time. More tools = lower accuracy in tool selection.

4. **Add parameter descriptions** — Describe every parameter, its type, and valid values.

5. **Handle errors gracefully** — Never raise exceptions on bad tool calls. Return descriptive error messages so the model can self-correct.

**Tool description template:**
```json
{
  "name": "search_orders",
  "description": "Search customer orders by order ID, email, or date range. Use this when the customer asks about an existing order, shipment status, or order history. Do NOT use for product searches or general inquiries.",
  "parameters": {
    "query": {
      "type": "string",
      "description": "Order ID (format: ORD-XXXXX), customer email, or natural language date range (e.g., 'last 30 days')"
    },
    "status_filter": {
      "type": "string",
      "enum": ["all", "pending", "shipped", "delivered", "cancelled"],
      "description": "Filter results by order status. Default: 'all'"
    }
  }
}
```

**System prompt tool guidance:**
```xml
<tool_usage_rules>
- Before calling any tool, state your reasoning for choosing that tool
- If a tool returns an error, explain to the user what happened and try an alternative approach
- Never call the same tool twice with identical parameters
- When multiple tools could work, prefer the most specific one
- If you're unsure which tool to use, ask the user for clarification rather than guessing
</tool_usage_rules>
```

**Anti-pattern — vague tool description:**
```
"description": "Searches for stuff in the database"
```

**Better:**
```
"description": "Searches the product catalog by name, category, or SKU. Returns up to 10 results sorted by relevance. Use when the customer asks about product availability, pricing, or specifications."
```

---

### 2.3 Planning Prompts

Planning prompts instruct the agent to formulate a strategy before acting. This prevents premature tool calls and improves success rates on multi-step tasks.

**Two main patterns:**

#### ReAct (Reasoning + Acting)

The agent alternates between thinking and acting in a loop:

```
Thought: [What I know and what I need to figure out]
Action: [Tool call or information request]
Observation: [Result of the action]
Thought: [Updated understanding]
... (repeat until solved)
Answer: [Final response to the user]
```

**Best for:** Tasks where the next step depends on the result of the previous step. Exploratory tasks. Debugging.

#### Plan-then-Execute

The agent creates a complete plan first, then executes it step by step:

```
<instructions>
Before taking any action:
1. Analyze the user's request
2. List the steps needed to complete it (as a numbered plan)
3. Identify which tools you'll need for each step
4. Execute the plan step by step
5. After each step, verify the result before proceeding
6. If a step fails, revise the remaining plan
</instructions>
```

**Best for:** Well-defined multi-step tasks. Workflows with known sequences. Tasks where you want the user to approve the plan before execution.

**Comparison:**

| Aspect | ReAct | Plan-then-Execute |
|---|---|---|
| Flexibility | High — adapts each step | Medium — plan can be revised |
| Predictability | Lower | Higher |
| Token usage | Higher (reasoning each step) | Lower (plan once, execute) |
| Best for | Exploratory tasks | Procedural tasks |
| Failure recovery | Natural (just re-reason) | Requires explicit re-planning |

**Planning prompt example for ASK agents:**
```xml
<planning>
When you receive a complex request:
1. Break it into sub-tasks (list them in <plan> tags)
2. For each sub-task, identify: input needed, tool to use, expected output
3. Present the plan to the user for approval before executing
4. Execute step by step, reporting progress after each
5. If any step fails or produces unexpected results, pause and propose a revised plan
</planning>
```

---

### 2.4 Reflection Prompts

Reflection prompts enable agents to evaluate their own outputs and self-correct. Research shows this can improve performance by up to 18.5 percentage points when properly implemented.

**Important caveat:** External verification significantly outperforms pure self-correction. Models cannot reliably self-correct reasoning intrinsically (ICLR 2024). The best approach combines self-reflection with external validation.

**Two types of reflection:**

| Type | When | What |
|---|---|---|
| **Pre-execution (intra-reflection)** | Before responding | Agent critiques its planned response |
| **Post-execution (inter-reflection)** | After receiving feedback | Agent analyzes what went wrong and adjusts |

**Pre-execution reflection prompt:**
```xml
<reflection_protocol>
Before sending your final response, check:
- Does this actually answer the user's question?
- Am I making any unsupported assumptions?
- Is there a simpler or more direct way to achieve this?
- Did I follow all the rules in my instructions?
- Could this response cause harm or confusion?
If any check fails, revise before responding.
</reflection_protocol>
```

**Post-execution reflection (Reflexion pattern):**
```
You attempted [action] and got [result].
This was [successful/unsuccessful] because [analysis].
For next time, remember: [lesson learned].
Revised approach: [new strategy].
```

**Lightweight reflection for every-turn use:**
```xml
<check>
After generating your response, silently verify:
1. Factual accuracy — is everything grounded in provided context?
2. Completeness — did I address all parts of the request?
3. Constraints — did I follow all rules and guardrails?
If any verification fails, regenerate before outputting.
</check>
```

---

### 2.5 Guardrail Embedding

Guardrails are explicit constraints encoded in the system prompt that shape and limit agent behavior. They act as a safety net that persists across all interactions.

**Guardrail layers:**

```
┌──────────────────────────────────────┐
│  Layer 1: Identity guardrails        │  What the agent IS and ISN'T
├──────────────────────────────────────┤
│  Layer 2: Topic guardrails           │  What topics are in/out of scope
├──────────────────────────────────────┤
│  Layer 3: Action guardrails          │  What the agent can/cannot do
├──────────────────────────────────────┤
│  Layer 4: Output guardrails          │  Format, tone, content rules
├──────────────────────────────────────┤
│  Layer 5: Escalation guardrails      │  When to hand off to humans
└──────────────────────────────────────┘
```

**Implementation pattern:**
```xml
<guardrails>
HARD RULES (never violate):
- Never share other customers' data
- Never make promises about pricing without checking the rate card
- Never execute destructive actions without explicit user confirmation
- Never generate or share code that could be used maliciously

SOFT RULES (prefer but can override with justification):
- Keep responses under 200 words
- Use formal tone with enterprise customers
- Suggest at most 3 options when presenting choices

ESCALATION TRIGGERS:
- Customer mentions legal action → escalate immediately
- Customer requests refund > $500 → escalate with context summary
- Agent cannot resolve after 3 attempts → offer human handoff
- Customer expresses distress or safety concerns → escalate to priority queue

UNCERTAINTY PROTOCOL:
- If unsure about a fact, say "Let me check that for you" and use a tool
- If no tool can answer, say "I don't have that information" — never fabricate
- If a question is ambiguous, ask for clarification before acting
</guardrails>
```

**Positive vs. negative framing:**

Models follow positive instructions ("always do X") more reliably than negative ones ("never do Y"). When possible, reframe:

| Instead of... | Write... |
|---|---|
| Don't make up information | Only state facts from provided context |
| Don't be rude | Maintain a warm, professional tone |
| Don't share personal data | Share only the current user's data |
| Don't answer off-topic questions | Redirect off-topic questions to the appropriate channel |

---

## 3. Output Control

### 3.1 Structured Output (JSON, Markdown, Specific Formats)

Structured output transforms agent responses from free text into parseable, reliable data structures.

**Techniques by reliability (highest to lowest):**

1. **Model JSON mode** — Use the API's native JSON mode or `response_format` parameter when available. Strongest guarantee of valid output.
2. **Schema in system prompt + few-shot examples** — Define the exact schema and show 2-3 completed examples.
3. **Instructions-only** — Describe the format in words. Least reliable for complex structures.

**JSON output prompt:**
```xml
<output_format>
Respond ONLY with valid JSON matching this schema:
{
  "intent": "billing | technical | feature_request | escalation",
  "confidence": 0.0 to 1.0,
  "summary": "One sentence summary of the customer's request",
  "action_needed": "tool_name or 'none'",
  "requires_human": true | false
}

Do not include any text outside the JSON object.
No markdown code fences. No explanatory text. Just the JSON.
</output_format>
```

**Key tips:**
- Place format instructions near the END of the prompt, just before where output begins
- Show the exact structure, not just a description of it
- Start simple — overly complex schemas increase error rates
- For critical integrations, validate output programmatically and retry on parse failure

---

### 3.2 Tone and Style Control

Tone is best controlled through a combination of role prompting and explicit style guidelines.

**Tone specification template:**
```xml
<style>
Tone: [warm | professional | casual | authoritative | empathetic]
Register: [formal | conversational | technical]
Personality traits: [patient, direct, encouraging]
Avoid: [jargon | slang | passive voice | hedging language]
Mirror: [match the customer's energy level and formality]
</style>
```

**Dynamic tone adjustment:**
```xml
<tone_rules>
- If the customer is frustrated → be empathetic first, then solution-oriented
- If the customer is technical → match their technical level, skip basics
- If the customer is new → be welcoming, explain terms, offer more guidance
- Default → warm professional
</tone_rules>
```

---

### 3.3 Length and Verbosity Control

Without explicit length constraints, models tend to be verbose. Be specific.

**Techniques:**
```
- Respond in 1-3 sentences.
- Keep your response under 100 words.
- Use bullet points, maximum 5.
- Answer in one paragraph.
- Be concise. Omit unnecessary qualifiers.
```

**Adaptive verbosity:**
```xml
<verbosity>
- Quick factual questions → 1-2 sentences
- How-to questions → numbered steps, no more than 7
- Complex analysis → structured response with headers, max 300 words
- When the user says "explain" or "detail" → expand fully
- When the user says "tl;dr" or "quick" → compress to essentials
</verbosity>
```

---

### 3.4 Error Message Formatting

Agents need a consistent error communication pattern.

```xml
<error_format>
When something goes wrong, respond with:
1. Acknowledgment: "I ran into an issue with [what you were trying to do]"
2. Explanation: Brief, non-technical explanation of what happened
3. Next step: What you'll try next OR what the user can do
4. Never expose: raw error codes, stack traces, internal system details, or tool names

Example:
"I tried to look up your order but the system didn't return any results
for that order number. Could you double-check the number? It should
start with ORD- followed by 5 digits. You can find it in your
confirmation email."
</error_format>
```

---

## 4. Advanced Patterns

### 4.1 Meta-Prompting (Prompts That Generate Prompts)

Meta-prompting uses prompts to create, refine, or analyze other prompts. This is core to ASK's `/ask:build` command.

**Key techniques:**

| Technique | Description | ASK Use Case |
|---|---|---|
| **Prompt generation** | Generate a full prompt from requirements | Building new agent system prompts |
| **Prompt refinement** | Improve an existing prompt | Iterating on agent behavior |
| **Prompt analysis** | Evaluate a prompt's strengths/weaknesses | Validation phase |
| **Contrastive prompting** | Compare good vs. bad examples | Teaching prompt quality |
| **Recursive refinement** | Model improves its own generated prompt | Automated optimization |

**Meta-prompt for generating agent system prompts:**
```
Given the following agent specification:
- Name: {{agent_name}}
- Purpose: {{purpose}}
- Domain: {{domain}}
- Tools available: {{tools}}
- Key constraints: {{constraints}}
- Tone: {{tone}}
- Target users: {{users}}

Generate a complete system prompt following this structure:
1. Identity block (who the agent is, expertise, personality)
2. Rules block (hard constraints, soft preferences, uncertainty protocol)
3. Tools block (when to use each tool, tool selection logic)
4. Output format block (response structure, length, formatting)
5. Examples block (2-3 representative interactions)

Requirements:
- Use XML tags to separate blocks
- Write rules as positive statements where possible
- Include at least one escalation trigger
- Include an uncertainty handling protocol
- Keep the total prompt under 2000 tokens
```

**Meta-prompt for prompt refinement:**
```
Review this system prompt for an AI agent:
<prompt>
{{existing_prompt}}
</prompt>

Evaluate against these criteria:
1. Clarity — Are instructions unambiguous?
2. Completeness — Are there gaps in behavior specification?
3. Consistency — Do any rules contradict each other?
4. Conciseness — Is there unnecessary verbosity?
5. Guardrails — Are safety boundaries adequate?

For each issue found, provide:
- The problematic section
- Why it's a problem
- A concrete rewrite
```

---

### 4.2 Dynamic Context Injection

Rather than stuffing everything into a static system prompt, inject only the relevant context for each interaction.

**Strategies:**

```
┌─────────────────────────────────────────────────┐
│  STATIC (always present)                         │
│  - Identity, rules, tools, output format         │
├─────────────────────────────────────────────────┤
│  SEMI-STATIC (session-level)                     │
│  - User profile, preferences, plan details       │
│  - Current session goal                          │
├─────────────────────────────────────────────────┤
│  DYNAMIC (per-turn)                              │
│  - Retrieved knowledge base results              │
│  - Recent conversation summary                   │
│  - Tool call results                             │
│  - Current state/status data                     │
└─────────────────────────────────────────────────┘
```

**Implementation pattern:**
```xml
<context>
<!-- Injected dynamically before each turn -->

<user_profile>
Name: {{user.name}}
Plan: {{user.plan}}
Account age: {{user.tenure}}
Open tickets: {{user.open_tickets}}
Sentiment trend: {{user.sentiment}}
</user_profile>

<recent_context>
{{summarized_last_5_turns}}
</recent_context>

<retrieved_knowledge>
{{rag_results_if_any}}
</retrieved_knowledge>
</context>
```

**Key principles:**
- Inject context ABOVE the query (Anthropic recommendation)
- Summarize rather than include full history when context is long
- Only include information relevant to the current turn
- Use selective retrieval — not all context is equally useful

---

### 4.3 Memory-Aware Prompting

For agents that maintain state across sessions, memory must be explicitly referenced in the prompt.

**Memory layers:**

| Layer | Scope | Content | Injection Point |
|---|---|---|---|
| **Working memory** | Current turn | Tool results, intermediate reasoning | Dynamic, per-turn |
| **Session memory** | Current conversation | Conversation history, stated goals | Semi-static |
| **Persistent memory** | Across sessions | User preferences, past decisions, learned facts | Semi-static |
| **Organizational memory** | Shared across agents | Policies, knowledge base, procedures | Static |

**Memory-aware prompt pattern:**
```xml
<memory>
You have access to the following information about this user from previous interactions:

<past_interactions>
{{retrieved_memory_entries}}
</past_interactions>

Rules for using memory:
- Reference past interactions naturally, don't announce "I remember that..."
- If memory conflicts with what the user is saying now, trust the current statement
- Do not reference memories that are irrelevant to the current conversation
- If you learn something new and important, flag it for memory storage
</memory>
```

---

### 4.4 Multi-Turn Conversation Management

Managing context across turns is critical for agent coherence.

**Techniques:**

1. **Conversation summarization** — Compress prior turns into structured summaries
2. **Goal tracking** — Maintain explicit state of what the user is trying to accomplish
3. **Turn-level context signals** — Mark what's resolved, what's pending
4. **Graceful context loss** — Handle situations where context is truncated

**Prompt pattern:**
```xml
<conversation_management>
At the start of each response:
1. Identify if the user's message continues the current topic or introduces a new one
2. If continuing: reference relevant prior context naturally
3. If new topic: acknowledge the shift, don't lose prior commitments
4. If you've made a commitment (e.g., "I'll look into that"), track it until resolved

If conversation history seems incomplete:
- Don't pretend to remember what you don't
- Ask: "Just to make sure I have the full picture — could you remind me of [specific detail]?"
</conversation_management>
```

---

### 4.5 Escalation Triggers in Prompts

Well-defined escalation logic prevents agents from handling situations beyond their capability.

```xml
<escalation>
IMMEDIATE ESCALATION (stop and hand off):
- User mentions: lawsuit, lawyer, legal action, regulatory complaint
- User expresses: self-harm, threats, abuse
- Security: suspected account breach, fraud indicators
- Data: request for bulk data export, GDPR/privacy requests

CONDITIONAL ESCALATION (try first, then hand off):
- If you cannot resolve after 3 tool attempts → offer human handoff
- If confidence in your answer is low → caveat and offer handoff
- If the user explicitly asks for a human → comply immediately

ESCALATION FORMAT:
"I want to make sure you get the best help with this. Let me connect
you with [team/person] who specializes in [topic]. I'll include a
summary of our conversation so you don't have to repeat anything."

Include in handoff:
- Summary of customer's issue
- Steps already attempted
- Relevant account details
- Customer sentiment assessment
</escalation>
```

---

## 5. Anti-Patterns

### 5.1 Common Mistakes in Agent Prompting

| Anti-Pattern | Problem | Fix |
|---|---|---|
| **"Be helpful"** | Too vague, no behavioral anchor | Define specific helpful behaviors |
| **Instruction overload** | Single prompt doing 10 things | Decompose into focused blocks |
| **Negative-only rules** | "Don't do X, don't do Y" | Reframe as positive: "Do Z instead" |
| **Missing edge cases** | Agent improvises in gaps | Explicitly cover uncertainty and escalation |
| **Assuming business knowledge** | Model doesn't know your policies | Include all relevant rules and constraints |
| **No examples** | Agent guesses at format | Add 2-3 representative examples |
| **Conflicting instructions** | Rules that contradict each other | Review prompt as a whole for consistency |
| **Invisible constraints** | Important rules buried in long text | Use structure (XML tags, headers, lists) |
| **Testing-free deployment** | First prompt rarely works | Iterate empirically with diverse scenarios |

---

### 5.2 Over-Constraining vs. Under-Constraining

**Over-constraining:**
- Agent becomes robotic and unhelpful
- Cannot handle reasonable variations in user requests
- Responds with "I can't help with that" too often
- Symptoms: user frustration, high escalation rate

**Under-constraining:**
- Agent hallucates, goes off-topic, or takes unwanted actions
- Makes up information, prices, or policies
- No consistent output format
- Symptoms: incorrect information, inconsistent behavior

**The sweet spot:**
```
HARD CONSTRAINTS  → few, clear, non-negotiable (safety, accuracy, scope)
SOFT GUIDELINES   → many, flexible, adjustable (tone, length, style)
EXPLICIT DEFAULTS → what to do when no rule covers the situation
```

**Test for balance:** If more than 30% of test interactions hit a constraint wall, you're over-constraining. If more than 10% of test interactions produce undesirable behavior, you're under-constraining.

---

### 5.3 Prompt Bloat

Prompt bloat is when a system prompt grows so large it degrades performance.

**Causes:**
- Adding rules reactively to fix one-off issues
- Duplicate instructions in different sections
- Examples that are too long or too numerous
- Context that could be dynamically injected instead of always-present

**Symptoms:**
- Model ignores instructions at the beginning (recency bias)
- Inconsistent behavior across turns
- Higher latency and cost
- Model "forgets" rules it followed earlier

**Remedies:**

1. **Audit regularly** — Remove rules that haven't triggered in testing
2. **Deduplicate** — Merge overlapping instructions
3. **Compress** — Use concise language; the model doesn't need prose
4. **Externalize** — Move domain knowledge to retrieval (RAG) rather than prompt
5. **Tier your rules** — Only essential rules in the system prompt; edge cases in a retrievable knowledge base
6. **Measure** — Track prompt token count over time; set a budget (e.g., system prompt < 3000 tokens)

**Before (bloated):**
```
When the customer asks about refunds, you should check if they have a
valid order first. Look up their order in the system. If they don't
have an order, tell them you can't find one. If they do have an order,
check the refund policy. The refund policy says refunds are available
within 30 days of purchase. If it's been more than 30 days, explain
that the refund window has passed. If it's within 30 days, proceed
with the refund process...
```

**After (lean):**
```xml
<refund_flow>
1. Look up order → if not found, ask for order ID
2. Check purchase date → if > 30 days, deny with explanation
3. If eligible → confirm amount with user → process refund
4. Always: state the outcome and expected timeline
</refund_flow>
```

---

## 6. Template Library

### 6.1 System Prompt Skeleton — General Agent

```xml
<identity>
You are {{agent_name}}, a {{role_description}} for {{organization}}.
You communicate with a {{tone}} tone.
Your expertise: {{expertise_areas}}.
You handle: {{in_scope}}.
You do NOT handle: {{out_of_scope}}.
</identity>

<rules>
HARD RULES:
- {{hard_rule_1}}
- {{hard_rule_2}}
- {{hard_rule_3}}

GUIDELINES:
- {{guideline_1}}
- {{guideline_2}}

UNCERTAINTY:
- If unsure about a fact → {{uncertainty_behavior}}
- If the question is ambiguous → ask for clarification
- If outside your scope → {{redirect_behavior}}
</rules>

<tools>
Available tools:
{{tool_descriptions}}

Tool selection rules:
- {{tool_selection_rule_1}}
- {{tool_selection_rule_2}}
</tools>

<context>
{{dynamic_context_placeholder}}
</context>

<output_format>
{{format_instructions}}
</output_format>

<examples>
{{few_shot_examples}}
</examples>
```

### 6.2 System Prompt Skeleton — Customer Support Agent

```xml
<identity>
You are {{name}}, a customer support agent for {{company}}.
Tone: empathetic, solution-oriented, professional.
You help customers with: {{support_topics}}.
</identity>

<rules>
- Greet the customer warmly on first message
- Always verify the customer's identity before accessing account data
- Never share information about other customers
- Never promise outcomes you cannot guarantee
- If you can solve the problem, do it. If you can't, escalate gracefully.
- Always end with: "Is there anything else I can help with?"
</rules>

<tools>
- lookup_customer: Find customer by email or ID. Use first to verify identity.
- search_orders: Search orders by customer ID, order number, or date range.
- search_knowledge_base: Search help articles. Use for policy questions.
- create_ticket: Create a support ticket. Always confirm details before creating.
- escalate: Hand off to human agent. Include conversation summary.
</tools>

<escalation>
Escalate when:
- Refund > ${{refund_threshold}}
- Customer mentions legal action
- Unable to resolve after 3 attempts
- Customer explicitly requests human agent
</escalation>

<output_format>
- Keep responses concise (2-4 sentences unless explaining a process)
- Use bullet points for multi-step instructions
- Never expose internal tool names, system IDs, or error codes
</output_format>
```

### 6.3 System Prompt Skeleton — Research/Analysis Agent

```xml
<identity>
You are {{name}}, a research analyst specializing in {{domain}}.
You provide evidence-based analysis with clear reasoning.
Tone: precise, balanced, data-driven.
</identity>

<rules>
- Always cite sources for factual claims
- Distinguish between facts, analysis, and speculation — label each clearly
- When evidence is conflicting, present both sides
- Quantify uncertainty when possible ("high confidence", "moderate confidence", "speculative")
- Never present opinion as fact
</rules>

<methodology>
For each research question:
1. Define the scope and key terms
2. Gather evidence from available sources
3. Analyze and synthesize findings
4. Present conclusions with confidence levels
5. Note limitations and gaps in the available data
</methodology>

<output_format>
Structure analysis as:
## Summary
[1-2 sentence key finding]

## Evidence
[Organized findings with sources]

## Analysis
[Interpretation and synthesis]

## Confidence & Limitations
[What you're confident about, what's uncertain, what data is missing]
</output_format>
```

### 6.4 Common Prompt Fragments

**Guardrails Block:**
```xml
<guardrails>
- Only state facts from provided context — never fabricate
- If you don't know, say "I don't have that information"
- Never impersonate a human or claim to be one
- Respect privacy — only discuss the current user's data
- Do not provide medical, legal, or financial advice
</guardrails>
```

**Tool Usage Block:**
```xml
<tool_usage>
- Search before answering factual questions
- Confirm destructive actions with the user before executing
- If a tool fails, try an alternative approach before giving up
- Never call the same tool with the same parameters twice
- Explain what you're doing: "Let me look that up for you"
</tool_usage>
```

**Error Handling Block:**
```xml
<error_handling>
- If a tool returns an error → explain in plain language, suggest next step
- If input is ambiguous → ask for clarification (provide options when possible)
- If you can't complete a task → explain what you tried and what the user can do
- Never show: raw errors, system internals, stack traces, or tool names
</error_handling>
```

**Context Awareness Block:**
```xml
<context_awareness>
- Read all provided context before responding
- If context conflicts with your training data, trust the provided context
- If the user corrects you, accept the correction and adjust
- Reference relevant context naturally, don't dump it verbatim
</context_awareness>
```

**Conversation Closing Block:**
```xml
<closing>
- After resolving an issue, confirm the resolution
- Ask if there's anything else the user needs
- If the conversation is complete, end warmly
- Never abruptly end a conversation
</closing>
```

### 6.5 Effective vs. Ineffective Prompts — Side by Side

**Scenario: Order lookup agent**

Ineffective:
```
You are a helpful assistant. Help customers with their orders.
You can look up orders and process refunds. Be nice.
```

Effective:
```xml
<identity>
You are OrderBot, a support agent for ShopCo.
You handle order inquiries, shipment tracking, and refund requests.
Tone: friendly, efficient, and clear.
</identity>

<rules>
- Verify customer identity (email or order ID) before sharing order details
- Only process refunds for orders within the 30-day return window
- Refunds > $200 require human approval — escalate with context
- Never share order details if customer identity doesn't match
</rules>

<tools>
- lookup_order(order_id): Returns order details. Use when customer provides order ID.
- search_by_email(email): Returns all orders for an email. Use when customer provides email.
- process_refund(order_id, reason): Initiates refund. Only after verifying eligibility.
- escalate(summary): Hands off to human agent with conversation summary.
</tools>

<examples>
<example>
User: "Where's my order? It's been a week."
Assistant: "I'd be happy to check on that for you! Could you share your order number or the email you used to place the order?"
</example>

<example>
User: "I want a refund for order ORD-12345"
Assistant: "Let me pull up that order for you."
[calls lookup_order("ORD-12345")]
"I found your order from March 3rd for $89.99. Since it's within our 30-day return window, I can process this refund. Could you let me know the reason for the return? This helps us improve."
</example>
</examples>
```

---

## 7. Key Takeaways for ASK

### How `/ask:build` Should Apply These Techniques

The `/ask:build` command generates system prompts for agents. Here is how it should use this reference:

#### 1. Always use the 5-Block structure
Every generated system prompt must include: Identity, Rules, Tools, Context, and Output Format. No block should be skipped, even if minimal.

#### 2. Start with identity, end with examples
The prompt order matters. Identity anchors behavior; examples nearest to output maximize format adherence.

#### 3. Embed guardrails as first-class citizens
Guardrails are not optional add-ons. Every agent gets:
- At least 3 hard rules
- An uncertainty protocol
- An escalation trigger
- A scope boundary (what the agent does NOT handle)

#### 4. Use XML tags for structure
ASK should generate prompts using `<identity>`, `<rules>`, `<tools>`, `<context>`, `<output_format>`, and `<examples>` tags. This reduces misinterpretation and makes prompts auditable.

#### 5. Tool descriptions include WHEN, not just WHAT
Every tool must have a trigger condition in its description, not just a functional summary.

#### 6. Include planning instructions for complex agents
If the agent handles multi-step tasks, include a planning block. Default to Plan-then-Execute for predictable workflows, ReAct for exploratory tasks.

#### 7. Add reflection for high-stakes agents
Agents that make decisions with consequences (financial, account changes, data modifications) should include a pre-execution reflection check.

#### 8. Default to few-shot examples
Always generate at least 2 representative examples showing the expected interaction pattern. This is the single highest-leverage improvement for output quality and format consistency.

#### 9. Keep prompts lean
Target system prompts under 2500 tokens for simple agents, under 4000 for complex ones. Use dynamic context injection for variable data rather than stuffing everything into the system prompt.

#### 10. Generate with meta-prompting, validate with anti-pattern checks
The build phase should use meta-prompting to generate the initial system prompt, then run it against the anti-patterns checklist:
- [ ] No vague instructions ("be helpful")
- [ ] No instruction overload (single block doing too many things)
- [ ] No conflicting rules
- [ ] Positive framing preferred over negative
- [ ] Edge cases covered (uncertainty, out-of-scope, errors)
- [ ] Examples included
- [ ] Prompt under token budget
- [ ] All tools have trigger conditions
- [ ] Escalation path defined
- [ ] Output format specified

#### 11. Adapt to runtime
Generated prompts should be structured for the target runtime:
- **OpenClaw**: Split across SOUL.md, IDENTITY.md, MEMORY.md
- **Claude Code**: Single CLAUDE.md with structured sections
- **Hermes**: Agent file with separate tool definitions

#### 12. Treat prompts as code
Version them. Review them. Test them. Iterate empirically. The first prompt is never the final prompt.

---

## Sources

- [Anthropic — Prompting Best Practices (Claude 4.x)](https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/claude-4-best-practices)
- [Anthropic — Prompt Engineering Overview](https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/overview)
- [OpenAI — Prompt Engineering Guide](https://platform.openai.com/docs/guides/prompt-engineering)
- [OpenAI — GPT-4.1 Prompting Guide](https://cookbook.openai.com/examples/gpt4-1_prompting_guide)
- [Prompt Engineering Guide — Chain of Thought](https://www.promptingguide.ai/techniques/cot)
- [Prompt Engineering Guide — Few-Shot Prompting](https://www.promptingguide.ai/techniques/fewshot)
- [Prompt Engineering Guide — ReAct Prompting](https://www.promptingguide.ai/techniques/react)
- [Prompt Engineering Guide — Meta Prompting](https://www.promptingguide.ai/techniques/meta-prompting)
- [Prompt Engineering Guide — Reflexion](https://www.promptingguide.ai/techniques/reflexion)
- [Prompt Engineering Guide — Function Calling](https://www.promptingguide.ai/agents/function-calling)
- [IBM — The 2026 Guide to Prompt Engineering](https://www.ibm.com/think/prompt-engineering)
- [Lakera — The Ultimate Guide to Prompt Engineering 2026](https://www.lakera.ai/blog/prompt-engineering-guide)
- [Augment Code — 11 Prompting Techniques for Better AI Agents](https://www.augmentcode.com/blog/how-to-build-your-agent-11-prompting-techniques-for-better-ai-agents)
- [PromptHub — Prompt Engineering for AI Agents](https://www.prompthub.us/blog/prompt-engineering-for-ai-agents)
- [Google Cloud — Choose a Design Pattern for Agentic AI](https://docs.cloud.google.com/architecture/choose-design-pattern-agentic-ai-system)
- [LangChain — Reflection Agents](https://blog.langchain.com/reflection-agents/)
- [Weaviate — Context Engineering for AI Agents](https://weaviate.io/blog/context-engineering)
- [Cloud Security Alliance — How to Build AI Prompt Guardrails](https://cloudsecurityalliance.org/blog/2025/12/10/how-to-build-ai-prompt-guardrails-an-in-depth-guide-for-securing-enterprise-genai)
