# Deployment & Operations Patterns

Reference for ASK — how to deploy AI agents to production, monitor them, and keep them running reliably.

**Last updated:** 2026-03-17

---

## Why Deployment Matters for Agent Builders

An agent that works in development but fails in production is a failed agent. The gap between "it works on my machine" and "it runs reliably at scale" is where most agent projects die. ASK-built agents need deployment thinking from the architecture phase, not as an afterthought.

---

## Containerization Patterns

### Why Containerize Agents

Agents have complex dependency chains: LLM SDKs, tool libraries, MCP servers, vector databases, custom scripts. Containers freeze these dependencies into a reproducible image.

### Docker Best Practices for Agents

**Multi-stage builds** — Keep images small by separating build dependencies from runtime.

```dockerfile
# Build stage
FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Runtime stage
FROM python:3.12-slim
WORKDIR /app
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY . .
CMD ["python", "agent.py"]
```

**One agent per container** — Each agent runs in its own container. Multi-agent crews use container orchestration (Docker Compose, Kubernetes) to coordinate.

**Health check endpoints** — Every agent container exposes a health check:
```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD curl -f http://localhost:8080/healthz || exit 1
```

**Version pinning** — Pin every dependency, including LLM SDK versions, MCP server versions, and model versions. Model drift causes 40% of production agent failures.

### What Goes in the Container

| Include | Exclude |
|---|---|
| Agent code and configuration files | API keys and secrets |
| System prompt and persona files | User data |
| Tool definitions and MCP configs | Logs and temporary files |
| Memory structure (empty directories) | Training data |
| Health check scripts | Development tools |

---

## Secrets Management

### Principles

1. **Never hardcode credentials** — Not in code, not in config files, not in Docker images
2. **Use a secrets manager** — HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, or similar
3. **Rotate regularly** — Automated rotation for API keys and tokens
4. **Least privilege** — Each agent gets only the credentials it needs
5. **Audit access** — Log every secret retrieval

### Implementation Patterns

#### Environment Variables (Minimum Viable)
```yaml
# docker-compose.yml
services:
  agent:
    image: my-agent:v1.2
    environment:
      - LLM_API_KEY=${LLM_API_KEY}
      - DB_CONNECTION=${DB_CONNECTION}
    env_file:
      - .env  # Never committed to git
```

#### External Vault (Production)
```python
# Agent startup reads secrets from vault
import hvac
client = hvac.Client(url='https://vault.internal:8200')
api_key = client.secrets.kv.v2.read_secret_version(
    path='agents/my-agent/llm-api-key'
)['data']['data']['key']
```

#### Ephemeral Identities (Best Practice)
Replace long-lived API keys with short-lived, identity-based tokens. The agent authenticates with a cryptographic identity, receives a time-limited token, and the token auto-expires.

### Secrets Checklist for ASK-Built Agents

- [ ] LLM API key (OpenAI, Anthropic, etc.)
- [ ] MCP server credentials
- [ ] Database connection strings
- [ ] External API tokens (GitHub, Slack, etc.)
- [ ] Embedding provider API key
- [ ] Monitoring/observability API keys
- [ ] Webhook signing secrets

---

## Health Checks and Monitoring

### Health Check Levels

#### Level 1: Liveness
"Is the agent process running?"
- HTTP endpoint returns 200
- Process is not crashed or hung

#### Level 2: Readiness
"Can the agent accept and process requests?"
- LLM API is reachable
- Required MCP servers are connected
- Database connections are healthy
- Memory layer is accessible

#### Level 3: Operational
"Is the agent performing well?"
- Response latency within thresholds
- Error rate below threshold
- Token consumption within budget
- Tool call success rate acceptable

### Monitoring Stack

| Layer | What to Track | Tools |
|---|---|---|
| **Infrastructure** | CPU, memory, disk, network | Prometheus, Grafana, Datadog |
| **Application** | Request rate, error rate, latency | OpenTelemetry, custom metrics |
| **Agent-specific** | Task completion, tool usage, token consumption | LangSmith, LangFuse, Arize Phoenix |
| **Business** | User satisfaction, escalation rate, task value | Custom dashboards, feedback loops |

### Key Metrics for Agent Monitoring

| Metric | What It Tells You | Alert Threshold |
|---|---|---|
| **Error rate** | System health | > 5% over 5 minutes |
| **P95 latency** | User experience | > 30s for interactive agents |
| **Token consumption** | Cost trajectory | > 150% of budget estimate |
| **Tool call failure rate** | Integration health | > 10% for any tool |
| **Task completion rate** | Agent effectiveness | < 80% over 1 hour |
| **Escalation rate** | Autonomy boundaries | > 20% of interactions |
| **Memory usage** | Context management | > 90% of context window |

---

## Deployment Strategies

### Blue-Green Deployment
Run two identical environments. "Blue" is current production, "green" is the new version.

1. Deploy new version to green environment
2. Run validation suite against green
3. Switch traffic from blue to green
4. Monitor for issues
5. If problems: switch back to blue (instant rollback)
6. Decommission blue after confidence period

**Best for:** Agents where downtime is unacceptable and rollback must be instant.

### Canary Deployment
Route a small percentage of traffic to the new version.

1. Deploy new version alongside current
2. Route 5% of traffic to new version
3. Monitor metrics: error rate, latency, completion rate
4. Gradually increase to 25%, 50%, 100%
5. If problems at any stage: route all traffic back to current version

**Best for:** High-traffic agents where you need statistical confidence before full rollout.

### Shadow Deployment
Run new version in parallel but only return current version's responses.

1. Deploy new version alongside current
2. Send all requests to both versions
3. Return only current version's response to users
4. Compare outputs between versions
5. Promote new version when outputs are equivalent or better

**Best for:** Agents where response quality changes are subtle and need comparison.

### Rolling Update
Replace instances one at a time.

1. Take one instance out of rotation
2. Update it to new version
3. Validate and add it back
4. Repeat for remaining instances

**Best for:** Stateless agents with multiple replicas.

---

## Rollback Procedures

### Fast Rollback Checklist

1. **Pre-deploy:** Tag the current version. Verify rollback procedure works.
2. **Detect:** Automated alerts fire on error rate, latency, or completion rate degradation.
3. **Decide:** Rollback if any critical metric exceeds threshold for > 5 minutes.
4. **Execute:** Switch traffic to previous version (blue-green) or scale down canary to 0%.
5. **Verify:** Confirm previous version is serving correctly.
6. **Investigate:** Root cause analysis on the failed deployment.

### Keep Ready

- Last 2-3 container images tagged and available
- Database migrations must be backward-compatible (no destructive schema changes)
- Configuration changes must be reversible
- Memory layer changes must be compatible across versions

---

## Logging and Observability

### Structured Logging

Agents must log in structured format (JSON) for queryability:

```json
{
  "timestamp": "2026-03-17T14:30:00Z",
  "level": "info",
  "agent_id": "support-agent-v2",
  "session_id": "sess_abc123",
  "event": "tool_call",
  "tool": "search_knowledge_base",
  "input_tokens": 450,
  "output_tokens": 120,
  "latency_ms": 1200,
  "status": "success",
  "trace_id": "trace_xyz789"
}
```

### What to Log

| Event | Required Fields | Why |
|---|---|---|
| **Request received** | session_id, user_id, input_length | Volume and usage tracking |
| **Tool call** | tool_name, parameters, status, latency | Tool health and efficiency |
| **LLM call** | model, input_tokens, output_tokens, latency | Cost and performance |
| **Guardrail triggered** | rule, input_summary, action_taken | Safety monitoring |
| **Error** | error_type, message, stack_trace | Debugging |
| **Task completed** | task_type, success, total_latency, total_cost | Business metrics |

### Distributed Tracing

For multi-agent systems, use distributed tracing (OpenTelemetry) to follow requests across agents:

- Each request gets a trace ID
- Each agent operation gets a span
- Tool calls, LLM calls, and handoffs are child spans
- Trace visualization shows the complete request lifecycle

### What NOT to Log

- Full user messages (PII risk) — log summaries or hashes
- API keys or credentials
- Full LLM responses (cost of storage) — log summaries for high-volume agents
- Personal data without consent and retention policies

---

## Cost Monitoring and Alerts

### Cost Components for Agents

| Component | How to Estimate | Typical Range |
|---|---|---|
| **LLM API calls** | (input_tokens + output_tokens) * price_per_token * calls_per_day | 60-80% of total |
| **Embedding generation** | tokens * price_per_token (usually cheaper model) | 5-10% |
| **Infrastructure** | Container hours * instance price | 10-20% |
| **MCP server calls** | Per API call pricing for external services | 5-15% |
| **Storage** | Memory layer, logs, vector DB | 2-5% |

### Cost Optimization Strategies

1. **Prompt caching** — Reuse cached prompts for repeated system instructions (Anthropic supports this natively)
2. **Model tiering** — Use cheaper models for simple subtasks (classification, extraction), expensive models for reasoning
3. **Token reduction** — Compress context, trim unnecessary instructions, use concise output formats
4. **Batching** — Group non-urgent requests for batch API processing
5. **Result caching** — Cache tool call results for frequently-asked queries
6. **Context window management** — Prune old context aggressively to stay in cheaper token tiers

### Alert Thresholds

| Alert | Trigger | Action |
|---|---|---|
| **Daily cost > 150% estimate** | Budget breach | Investigate usage spike, throttle if needed |
| **Cost per task > 2x average** | Efficiency degradation | Check for tool call loops or excessive retries |
| **Token consumption trending up** | Context growth | Review memory management, prune policy |
| **External API costs spike** | Integration issue | Check tool call frequency, validate caching |

---

## Agent Versioning Strategies

### What to Version

| Artifact | Versioning Method | Example |
|---|---|---|
| **Agent code** | Semantic versioning | v1.2.3 |
| **System prompt** | Hash-based or date-based | prompt-2026-03-17-abc123 |
| **Model** | Pin exact model ID | claude-sonnet-4-20250514 |
| **Tool definitions** | Alongside agent code | Included in v1.2.3 |
| **MCP server versions** | Pin in config | @anthropic/mcp-github@1.4.0 |
| **Memory schema** | Migration-based | migration-005 |
| **Configuration** | Alongside agent code | Included in v1.2.3 |

### Version Everything Together

An agent "release" is the complete bundle:
```
release-v1.2.3/
├── agent-code/
├── prompts/
├── tools/
├── config/
├── memory-schema/
└── manifest.json  # Lists all components and their versions
```

### Compatibility Matrix

Maintain a compatibility matrix for multi-agent crews:
```
Agent A v1.2 <-> Agent B v2.0 ✓ (tested)
Agent A v1.2 <-> Agent B v2.1 ✗ (handoff format changed)
Agent A v1.3 <-> Agent B v2.1 ✓ (updated handoff)
```

---

## Key Takeaways for ASK

1. **Deployment thinking starts at architecture.** ASK's architecture phase should include deployment topology, not just agent design. Where will it run? How will it scale? What happens when it fails?

2. **Secrets management belongs in Discovery Block C.** Ask: "Where will secrets be stored? What credentials does the agent need? Who manages rotation?" This informs both the build and deploy phases.

3. **Health checks are part of the agent build.** The build phase should generate a health check endpoint or script, not leave it for the operator to figure out.

4. **Structured logging is non-negotiable.** Every ASK-built agent should have logging configuration in its build output. The template should include logging format and what to capture.

5. **Cost estimation validates architecture.** If the architecture estimates $50/day but production shows $200/day, the architecture was wrong. Cost monitoring closes this feedback loop.

6. **Blue-green is the safest deployment strategy for agents.** Instant rollback matters more for agents than traditional software because agent failures are often subtle (quality degradation, not crashes).

7. **Version pinning prevents drift.** Model updates can silently change agent behavior. Pin the model version in the agent's configuration and test before upgrading.

8. **Multi-agent crews need coordination for deployment.** You cannot deploy Agent B v2.0 if Agent A still expects the v1.x handoff format. The compatibility matrix is essential.

9. **Monitoring and observability should be part of the validate phase output.** The validation report should include recommended monitoring setup, key metrics to track, and alert thresholds.

10. **Rollback procedures must be documented and tested.** Include rollback steps in the agent's operational documentation. A rollback that has never been tested is not a rollback.

---

## Sources

- [n8n: Best Practices for Deploying AI Agents in Production](https://blog.n8n.io/best-practices-for-deploying-ai-agents-in-production/)
- [Machine Learning Mastery: Deploying AI Agents to Production](https://machinelearningmastery.com/deploying-ai-agents-to-production-architecture-infrastructure-and-implementation-roadmap/)
- [GoFast.ai: Agent Versioning and Rollbacks](https://www.gofast.ai/blog/agent-versioning-rollbacks)
- [NJ Raman: Versioning, Rollback & Lifecycle Management of AI Agents](https://medium.com/@nraman.n6/versioning-rollback-lifecycle-management-of-ai-agents-treating-intelligence-as-deployable-deac757e4dea)
- [LangChain: State of Agent Engineering](https://www.langchain.com/state-of-agent-engineering)
- [Maxim: Top AI Agent Observability Platforms 2026](https://www.getmaxim.ai/articles/top-5-ai-agent-observability-platforms-in-2026/)
- [AI Agents Plus: Agent Monitoring and Observability](https://www.ai-agentsplus.com/blog/ai-agent-monitoring-observability-2026)
- [Clustox: AI Agent Security for CTOs 2026](https://www.clustox.com/blog/ai-agent-security-ctos-guide/)
- [Monte Carlo: Best AI Observability Tools 2025](https://www.montecarlodata.com/blog-best-ai-observability-tools/)
