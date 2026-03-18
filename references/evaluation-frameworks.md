# Agent Evaluation Frameworks

Reference for ASK — how to evaluate AI agents beyond simple prompt testing, with frameworks, metrics, and patterns for the validate phase.

**Last updated:** 2026-03-17

---

## Why Agent Evaluation Is Different

Traditional LLM evaluation tests input-output pairs. Agent evaluation is harder because agents:
- Execute multi-step workflows with branching logic
- Use tools that change external state
- Make decisions across multiple turns
- Operate with varying degrees of autonomy
- Must satisfy safety constraints while completing tasks

An agent can produce the right answer via the wrong path (inefficient tool use), or follow the right path but fail at the final step. Both need to be caught.

---

## Evaluation Levels

### Level 1: Component Evaluation
Test individual components in isolation before testing the system.

| Component | What to Test | Method |
|---|---|---|
| **System prompt** | Does the agent understand its role? | Single-turn Q&A |
| **Tool selection** | Does it pick the right tool? | Scenario-based eval |
| **Tool execution** | Do tool calls have correct parameters? | Input validation |
| **Retrieval (RAG)** | Are retrieved docs relevant? | Contextual relevancy metrics |
| **Guardrails** | Are boundaries respected? | Adversarial testing |
| **Memory** | Is context retained correctly? | Multi-turn state checks |

### Level 2: Trajectory Evaluation
Evaluate the complete path the agent takes, not just the final output.

**Trajectory metrics:**
- `trajectory_exact_match` — Predicted trajectory identical to reference (same tools, same order)
- `trajectory_in_order_match` — Contains all reference tool calls in the same order (allows extras)
- `trajectory_any_order_match` — Contains all reference tool calls regardless of order

**When to use each:**
- Exact match for deterministic workflows (e.g., "always check inventory before pricing")
- In-order match for flexible workflows with required sequencing
- Any-order match for outcome-focused evaluation

### Level 3: End-to-End Task Evaluation
Test whether the agent accomplishes the user's goal.

- **Task completion rate** — Binary: did it complete the task?
- **Task quality** — Graded: how well did it complete the task?
- **Consistency** — Does it complete the task reliably across multiple runs?

---

## Core Metrics

### Task Completion
Measures whether the agent successfully accomplishes the user's intent.

```
Implementation: Define clear success criteria per task.
Use an LLM judge or deterministic check to verify.
Threshold: typically 0.7+ for production readiness.
```

### Tool Correctness
Verifies the agent selects and executes the right tools with correct parameters.

Three strictness levels:
1. **Tool selection** — Were the right tools called?
2. **Input parameters** — Were parameters correct?
3. **Output accuracy** — Did tool outputs match expectations?

### Tool Efficiency
Measures unnecessary or redundant tool calls.

- **Redundant tool usage** — Percentage of tool calls that did not contribute to the outcome
- **Tool frequency** — Penalizes exceeding a threshold for calls needed to complete a task

### Guardrail Compliance
Tests whether the agent respects its defined boundaries.

- Does it refuse out-of-scope requests?
- Does it handle PII correctly?
- Does it escalate when required?
- Does it respect rate limits and permissions?

### Latency
Time from user input to agent response, including all tool calls and reasoning steps.

- **Per-step latency** — Time for each tool call or reasoning step
- **End-to-end latency** — Total time for task completion
- **Time-to-first-response** — How quickly the agent acknowledges the request

### Cost
Token consumption and API costs per task.

- **Input tokens** — Context window usage
- **Output tokens** — Generation costs
- **Tool call overhead** — Additional tokens for tool formatting
- **Cost per task** — Total cost at current model pricing

---

## Evaluation Frameworks

### Braintrust
Full-lifecycle evaluation platform with production monitoring and team collaboration.

**Strengths:**
- Automated release enforcement — blocks deploys that fail eval thresholds
- Production monitoring with real-time scoring
- Dataset management and versioning
- Supports custom scorers alongside built-in metrics

**Best for:** Teams that need evaluation integrated into CI/CD pipelines.

### LangSmith
Tracing and evaluation tightly integrated with LangChain.

**Strengths:**
- Deep integration with LangGraph agent traces
- Visual trace inspection for debugging
- Online evaluation of production traces
- Annotation queues for human review

**Limitations:** Framework coupling (strongest with LangChain/LangGraph), per-seat pricing.

**Best for:** Teams already using LangChain/LangGraph.

### DeepEval
Open-source evaluation framework with agent-specific metrics.

**Strengths:**
- Agent-specific metrics: ToolCorrectness, TaskCompletion, ToolEfficiency (built-in)
- DAG-based metric evaluation reduces LLM judge calls (40% cost reduction)
- Red teaming metrics for adversarial testing
- Tracing integration for component-level evaluation

**Best for:** Teams wanting open-source with agent-native metrics.

### RAGAS
Research-backed RAG evaluation metrics.

**Strengths:**
- Rigorous metrics for retrieval quality (precision, recall, relevancy)
- Groundedness and faithfulness scoring
- Well-established in academic and production contexts

**Limitations:** Focused on RAG — no native agent orchestration metrics.

**Best for:** Agents with heavy retrieval components.

### Patronus AI
Enterprise evaluation with hallucination detection.

**Strengths:**
- Multimodal LLM-as-judge
- Industry benchmarks (FinanceBench for financial agents)
- Hallucination detection scoring
- Compliance-oriented evaluation

**Best for:** Regulated industries needing hallucination guarantees.

### Arize Phoenix
Observability-first evaluation platform.

**Strengths:**
- Trace-based evaluation from production data
- Visual debugging of agent trajectories
- Open-source core with cloud offering

**Best for:** Teams prioritizing observability alongside evaluation.

---

## Grading Approaches

Anthropic's engineering team identifies three complementary grading strategies:

### 1. Code-Based Graders
Fast, deterministic, and objective. Use for:
- String matching and regex validation
- JSON schema validation
- Unit test execution (for coding agents)
- State verification (database changed? file created?)

### 2. Model-Based Graders (LLM-as-Judge)
Flexible and scalable for nuanced assessment. Use for:
- Response quality evaluation with rubrics
- Conversation tone and style compliance
- Complex reasoning validation
- Domain-specific accuracy

**Pitfall:** LLM judges need calibration against human judgments. Always validate with a sample of human-graded cases.

### 3. Human Graders
Gold standard for calibration and subjective quality. Use for:
- Initial evaluation suite development
- Periodic calibration of automated graders
- Edge cases that automated graders disagree on
- User satisfaction assessment

---

## Agent-Specific Evaluation Patterns

### Pattern 1: Scenario-Based Evaluation
Define representative scenarios with expected outcomes.

```
Scenario: "User asks to refund an order placed 45 days ago"
Expected behavior:
  - Agent checks refund policy (tool: check_policy)
  - Agent finds order is past 30-day window
  - Agent explains policy to user
  - Agent offers alternative (store credit)
Success criteria: Policy correctly applied, alternative offered
```

### Pattern 2: Adversarial Testing (Red Teaming)
Test agent behavior under adversarial conditions.

- Prompt injection attempts
- Out-of-scope requests disguised as in-scope
- Attempts to extract system prompt
- Social engineering to bypass guardrails
- Contradictory or ambiguous instructions

### Pattern 3: Regression Testing
Track passing scenarios as baselines. When the agent changes, re-run all baselines.

```
Baseline v1.0: 47/50 scenarios pass
Change: "Make tone more formal"
Regression check: 45/50 pass — 2 regressions detected
  - Scenario 12: Agent stopped using domain-specific colloquial terms
  - Scenario 31: Greeting became overly stiff
```

### Pattern 4: A/B Testing
Compare agent versions using production traffic.

- Route percentage of traffic to new version
- Compare metrics: completion rate, latency, user satisfaction
- Statistical significance before promoting
- Track both immediate metrics and downstream effects

### Pattern 5: Multi-Turn Evaluation
Test the agent across conversation sequences.

- State consistency across turns
- Context retention over long conversations
- Graceful handling of topic switches
- Recovery from misunderstandings

---

## Production vs. Pre-Production Evaluation

### Pre-Production (Before Deploy)

| Method | What It Catches |
|---|---|
| Unit evals | Component-level regressions |
| Scenario evals | Workflow-level failures |
| Adversarial evals | Safety and guardrail gaps |
| Trajectory evals | Efficiency and path problems |
| Cost estimation | Financial viability issues |

### Production (After Deploy)

| Method | What It Catches |
|---|---|
| Online scoring | Real-world quality degradation |
| User feedback | Satisfaction and usability issues |
| Error rate monitoring | System-level failures |
| Cost tracking | Budget overruns |
| Transcript review | Edge cases missed by automated evals |

### Swiss Cheese Model
Anthropic recommends a layered approach: "No single evaluation layer catches every issue. With multiple methods combined, failures that slip through one layer are caught by another."

---

## Building an Eval Suite: Zero to Production

Anthropic's recommended workflow:

1. **Start with 20-50 real failures** converted to test cases
2. **Write unambiguous tasks** — two domain experts should independently reach the same pass/fail verdict
3. **Build balanced problem sets** — test both positive and negative cases
4. **Ensure stable, isolated environments** — clean state between trials
5. **Grade outputs, not paths** — avoid overly rigid step-sequence validation
6. **Read transcripts regularly** — catch grader bugs and discover new failure modes
7. **Monitor eval saturation** — when scores plateau, refresh difficulty

### Key Metrics for Eval Suite Health

- **pass@k** — Probability of at least one success in k trials (for "one working solution" requirements)
- **pass^k** — Probability all k trials succeed (for "reliable every time" requirements)

---

## Key Takeaways for ASK

1. **The validate phase should use Level 1 + Level 2 + Level 3 evaluation.** Component checks (current checklist), trajectory evaluation (tool call sequences), and end-to-end task completion. ASK currently only does Level 1.

2. **Generate evaluation scenarios from Discovery output.** The discovery interview contains the real-world scenarios the agent will face. Convert these directly into eval cases.

3. **Tool correctness is a critical metric.** If Discovery identifies 5 tools, the eval suite should verify the agent selects the right tool for each scenario, uses correct parameters, and handles errors.

4. **Guardrail testing must be adversarial.** Generate scenarios that try to bypass each guardrail defined in architecture. A guardrail that is not tested is a guardrail that does not exist.

5. **Regression baselines are essential for the iterate phase.** Before any change, record passing scenarios. After changes, re-run all baselines and flag regressions. This prevents the iterate loop from degrading quality.

6. **Production monitoring is separate from pre-production testing.** ASK's validate phase is pre-production. The deploy phase (N4 from audit) should include production monitoring setup.

7. **Start with code-based graders, add LLM judges for nuance.** Deterministic checks first (file exists, JSON valid, tool called correctly). LLM judges for response quality and tone compliance.

8. **Cost evaluation belongs in the validate phase.** Estimate tokens per task, calculate monthly cost at expected volume. Flag if cost exceeds architecture estimates.

9. **Red teaming should be part of every validation.** Generate 5-10 adversarial scenarios that test guardrail boundaries. This catches the most dangerous failures.

10. **Eval suites are living infrastructure.** They need maintenance, refreshing, and calibration. Build this expectation into the iterate phase.

---

## Sources

- [Anthropic: Demystifying Evals for AI Agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)
- [DeepEval: AI Agent Evaluation Guide](https://deepeval.com/guides/guides-ai-agent-evaluation)
- [Confident AI: LLM Agent Evaluation Complete Guide](https://www.confident-ai.com/blog/llm-agent-evaluation-complete-guide)
- [Google Cloud: A Methodical Approach to Agent Evaluation](https://cloud.google.com/blog/topics/developers-practitioners/a-methodical-approach-to-agent-evaluation)
- [AWS: Evaluating AI Agents at Amazon](https://aws.amazon.com/blogs/machine-learning/evaluating-ai-agents-real-world-lessons-from-building-agentic-systems-at-amazon/)
- [Braintrust: DeepEval Alternatives 2026](https://www.braintrust.dev/articles/deepeval-alternatives-2026)
- [Arize: Comparing LLM Evaluation Platforms 2025](https://arize.com/llm-evaluation-platforms-top-frameworks/)
- [DataTalks.Club: Open Source Agent Evaluation Tools](https://datatalks.club/blog/open-source-free-ai-agent-evaluation-tools.html)
- [Maxim: Top Agent Evaluation Tools 2025](https://www.getmaxim.ai/articles/top-agent-evaluation-tools-in-2025-best-platforms-for-reliable-enterprise-evals/)
