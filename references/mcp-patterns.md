# MCP (Model Context Protocol) Patterns

Reference for ASK — how MCP enables agent tool interoperability and what it means for agent design.

**Last updated:** 2026-03-17

---

## What MCP Is

MCP (Model Context Protocol) is an open protocol that standardizes how LLM applications connect to external data sources and tools. Think of it as "USB-C for AI" — a universal connector between any AI model and any tool through a single interface.

Released by Anthropic in November 2024, MCP was adopted by OpenAI (March 2025), Google DeepMind, and Microsoft. By December 2025, Anthropic donated MCP to the Linux Foundation. As of 2026, the protocol has 97M+ monthly SDK downloads and is the de facto standard for agent-tool integration.

### Why It Matters for Agents

Before MCP, every agent needed custom integrations for every tool. An agent using 5 tools needed 5 separate integration implementations. MCP replaces this with a single protocol: implement MCP once, connect to any MCP-compatible tool.

For ASK-built agents, this means:
- **Tool design is simplified** — tools follow a standard interface
- **Integration is portable** — switch runtimes without rewriting tool integrations
- **Ecosystem access** — thousands of pre-built MCP servers for common services

---

## Architecture

MCP uses a client-server architecture inspired by the Language Server Protocol (LSP), with JSON-RPC 2.0 as the message format.

### Roles

| Role | What It Does | Example |
|---|---|---|
| **Host** | LLM application that initiates connections | Claude Code, IDE, chat app |
| **Client** | Connector within the host that manages a server connection | One client per server |
| **Server** | Service that provides context and capabilities | GitHub MCP server, DB server |

### Core Primitives

MCP servers expose three types of capabilities:

#### 1. Resources — Data the AI can read
Context and data sources for the model or user. Resources provide information without requiring active queries.

```
Example: A database MCP server exposes table schemas as resources.
The agent reads them to understand data structure before writing queries.
```

#### 2. Tools — Functions the AI can execute
Actions the server performs on behalf of the AI. Tools are the primary mechanism for agents to interact with the outside world.

```
Example: A GitHub MCP server exposes tools like create_pull_request,
list_issues, merge_branch. The agent calls these to perform actions.
```

#### 3. Prompts — Reusable templates and workflows
Templated messages and workflows that guide interactions. Prompts help standardize how the AI interacts with specific tools.

```
Example: A code review MCP server provides a "review_pr" prompt
template that structures how the agent should analyze code changes.
```

### Additional Capabilities

- **Sampling** — Server-initiated LLM interactions (the server can ask the AI to generate text)
- **Roots** — Server queries about filesystem/URI boundaries
- **Elicitation** — Server requests additional information from users
- **Progress tracking** — Long-running operations report progress
- **Cancellation** — Cancel in-flight operations

---

## Transport Protocols

### STDIO (Local)
The client spawns the server as a subprocess and communicates via stdin/stdout.

- **Best for:** Local tools, CLI integrations, development environments
- **Security:** Inherits local user permissions — no network exposure
- **Auth:** Retrieves credentials from the environment (not OAuth)
- **Latency:** Minimal — direct process communication

```bash
# Claude Code example: adding a stdio MCP server
claude mcp add filesystem -- npx @anthropic/mcp-filesystem /path/to/dir
```

### Streamable HTTP (Remote)
A single HTTP endpoint accepting GET and POST requests. Servers can stream responses using Server-Sent Events (SSE). Introduced March 2025, replacing the older HTTP+SSE dual-endpoint transport.

- **Best for:** Cloud-hosted services, shared team tools, production deployments
- **Security:** Requires HTTPS, authentication (OAuth 2.1 recommended)
- **Scalability:** Supports load balancing, horizontal scaling
- **Latency:** Network-dependent — suitable for most use cases

```bash
# Claude Code example: adding an HTTP MCP server
claude mcp add --transport http notion https://mcp.notion.com/mcp
```

### SSE (Legacy)
Server-Sent Events transport for remote servers. Still supported for backward compatibility but Streamable HTTP is recommended for new implementations.

---

## MCP in Agent Runtimes

### Claude Code
Claude Code is a native MCP client. Configuration via CLI or JSON:

```bash
# Add a server
claude mcp add <name> -- <command> [args...]

# List configured servers
claude mcp list

# Remove a server
claude mcp remove <name>
```

Configuration scopes:
- **Project** (`.mcp.json`) — Shared with the team, committed to repo
- **User** (`~/.claude.json`) — Personal servers and credentials
- **Enterprise** — Managed by organization admins

**Best practice for teams:** Commit `.mcp.json` with shared server definitions. Each developer adds auth tokens in their personal `~/.claude.json`.

### Hermes
Hermes supports MCP through its tool system. MCP tools appear alongside native tools in the agent's tool inventory. Configuration via `config.yaml`:

```yaml
mcp_servers:
  - name: github
    transport: stdio
    command: npx
    args: ["@anthropic/mcp-github"]
    env:
      GITHUB_TOKEN: "${GITHUB_TOKEN}"
```

### OpenClaw
OpenClaw agents reference MCP servers in their `config.yaml`. Tools from MCP servers appear in the agent's TOOLS.md as available capabilities.

---

## How MCP Maps to Agent Tools

When designing tools for ASK-built agents, MCP changes the design pattern:

### Without MCP (Traditional)
```
Discovery: "The agent needs to create GitHub PRs"
Architecture: Design a custom GitHub integration
Build: Write API calls, auth handling, error handling
```

### With MCP
```
Discovery: "The agent needs to create GitHub PRs"
Architecture: Use the GitHub MCP server
Build: Configure MCP server, reference tools in TOOLS.md
```

### Tool Design Implications

1. **Discovery captures MCP availability** — Block C should ask: "Are there MCP servers already configured in the environment?"
2. **Architecture references MCP servers** — Instead of designing custom tools, reference existing MCP servers when available
3. **TOOLS.md documents MCP tools** — List which tools come from MCP servers vs. native implementations
4. **config.yaml includes MCP configuration** — Server definitions, auth, transport settings

---

## Security Considerations

### Protocol-Level Security Principles

1. **User consent and control** — Users must explicitly approve all data access and tool execution
2. **Data privacy** — Hosts must get consent before exposing user data to servers
3. **Tool safety** — Tools represent arbitrary code execution and must be treated with caution
4. **LLM sampling controls** — Users must approve any server-initiated LLM requests

### Real-World Security Risks

Research by Knostic (July 2025) found that nearly 2,000 MCP servers exposed to the internet lacked authentication. The OWASP MCP Top 10 (2025) catalogs the most critical risks:

- **Session hijacking** — Attackers obtain session IDs to inject malicious events or impersonate sessions
- **Token passthrough** — Servers accept tokens issued for other services without validating audience claims
- **Prompt injection via tool descriptions** — Malicious servers craft tool descriptions that manipulate LLM behavior
- **Excessive permissions** — Servers request broader access than needed

### Mitigation for ASK-Built Agents

| Risk | Mitigation |
|---|---|
| Unauthenticated servers | Always configure auth for remote MCP servers |
| Session hijacking | Use secure, non-deterministic session IDs bound to user identity |
| Token passthrough | Verify tokens are issued for the specific server's canonical identifier |
| Excessive permissions | Apply principle of least privilege in MCP server configuration |
| Prompt injection | Treat tool descriptions from untrusted servers as untrusted input |
| Data exfiltration | Audit which data MCP servers can access; restrict via Roots |

---

## Popular MCP Servers

| Server | What It Does | Use Case |
|---|---|---|
| **GitHub** | Repo management, PRs, issues | Code agents, project management |
| **Playwright** | Browser automation | Testing, web scraping, UI agents |
| **PostgreSQL/Supabase** | Database access | Data analysis, CRUD operations |
| **Sentry** | Error monitoring | DevOps agents, incident response |
| **Figma** | Design access | Design-to-code workflows |
| **Notion** | Document/DB access | Knowledge management agents |
| **Slack** | Channel messaging | Communication agents |
| **Cloudflare** | Workers, R2, D1 | Infrastructure management |
| **PostHog** | Product analytics | Feature flags, A/B tests |
| **Sequential Thinking** | Structured reasoning | Complex problem decomposition |
| **Context7** | Documentation access | Up-to-date library docs |
| **Filesystem** | Local file access | File management agents |

---

## Key Takeaways for ASK

1. **Discovery Block C should capture MCP context.** Ask: "Are there MCP servers already available? Which services does the agent need that have MCP servers? What transport (local stdio vs. remote HTTP) is appropriate?"

2. **Architecture should prefer MCP over custom integrations** when servers exist. This reduces build complexity and maintenance burden. Custom tools are for capabilities where no MCP server exists.

3. **TOOLS.md should distinguish MCP tools from native tools.** This affects maintenance — MCP tools are upgraded by updating the server, not the agent files.

4. **Security must be explicit.** Every MCP server in the architecture needs documented auth method, permission scope, and data access boundaries. Add MCP security to the guardrails template.

5. **config.yaml must include MCP server definitions.** For OpenClaw and Hermes, the MCP configuration is part of the agent's operational configuration.

6. **Team configuration patterns matter.** Shared MCP server definitions (committed to repo) with personal auth tokens (local config) is the recommended pattern.

7. **Start small.** Each MCP server adds startup time and memory. Configure only the servers the agent actually needs. The audit should flag unused MCP connections.

8. **MCP does not replace tool design thinking.** The agent still needs to know when to use each tool, when NOT to use it, and how to handle errors. MCP standardizes the interface, not the decision logic.

---

## Sources

- [MCP Specification (2025-11-25)](https://modelcontextprotocol.io/specification/2025-11-25)
- [MCP 2026 Roadmap](http://blog.modelcontextprotocol.io/posts/2026-mcp-roadmap/)
- [IBM: What is MCP](https://www.ibm.com/think/topics/model-context-protocol)
- [Descope: What Is MCP and How It Works](https://www.descope.com/learn/post/mcp)
- [Claude Code MCP Documentation](https://code.claude.com/docs/en/mcp)
- [Builder.io: Claude Code MCP Servers](https://www.builder.io/blog/claude-code-mcp-servers)
- [MCP Enterprise Adoption Guide](https://guptadeepak.com/the-complete-guide-to-model-context-protocol-mcp-enterprise-adoption-market-trends-and-implementation-strategies/)
- [Thoughtworks: MCP Impact 2025](https://www.thoughtworks.com/en-us/insights/blog/generative-ai/model-context-protocol-mcp-impact-2025)
- [Data Science Dojo: MCP Guide 2025](https://datasciencedojo.com/blog/guide-to-model-context-protocol/)
