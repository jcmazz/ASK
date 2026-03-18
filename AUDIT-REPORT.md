# ASK Expert Audit Report

**Date:** 2026-03-17
**Auditor perspective:** Senior AI agent architect with production multi-agent system experience
**Scope:** Full project audit — all commands, templates, references, scripts

---

## Executive Summary

ASK is a well-architected agent build framework with exceptional discovery depth and production-quality templates for OpenClaw. The 6-phase pipeline is sound and mirrors how experienced agent builders actually work. However, ASK has three structural weaknesses that will cause problems in real use: (1) the build command has no mechanism to actually populate templates from state data — there is no template engine or variable resolution logic, (2) multi-agent support is theoretically present but practically incomplete for building agent crews, and (3) the validation layer checks file existence but cannot test whether the agent actually behaves correctly because there is no runtime invocation mechanism.

---

## Strengths

1. **Discovery interview is elite.** The 3-block adaptive interview (Agent, Org, Technical) with relentless follow-up protocol is better than what most agent consultancies do. The "1-2 questions per turno, exigir ejemplos concretos" rule prevents the most common discovery failure mode: accepting vague answers and producing generic agents.

2. **OpenClaw templates are production-quality.** The SOUL.md, IDENTITY.md, MEMORY.md, HEARTBEAT.md, and AGENTS.md templates are thorough, well-commented, and match actual OpenClaw conventions accurately. The inline HTML comments explaining what each section does and where data comes from are especially valuable — they function as a build guide within the template itself.

3. **Reference library is comprehensive and actionable.** Nine reference documents covering Anthropic, LangGraph, CrewAI, OpenAI, OpenClaw, Hermes, Eliza, OpenFang, and prompt engineering. Each ends with a "Key Takeaways for ASK" section that translates framework-specific knowledge into ASK-actionable guidance. The anthropic-agent-guide.md alone is a standalone resource.

4. **State management design is clean.** The `ask-state/` directory with persistent state.json, incremental discovery.md, and accumulated agent-spec.md creates a clear audit trail. The decisions array with timestamps makes every choice traceable.

5. **The approval gate placement is correct.** Putting the hard gate between architecture and build — not between discovery and research, or build and validate — is the right call. Architecture is where bad decisions crystallize into bad files.

6. **Template variable tracing.** The openclaw-conventions.md reference includes a "Template Variable Mapping" table that traces every template variable back to its Discovery block and Architecture section. This is excellent documentation that most frameworks lack.

7. **The Hermes template is impressively comprehensive.** A single file that generates 8 output files (AGENTS.md, SOUL.md, config.yaml, MEMORY.md, USER.md, tool-definitions.json, skills-manifest.yaml, system-prompt.md, setup.sh) with a complete variable reference. This is the most thorough Hermes agent generator I have seen.

---

## Critical Issues (must fix)

### C1. No Template Engine — Build Cannot Actually Populate Templates

**What is wrong:** The build command (`ask-build.md`) says "Read the runtime from architecture.md and generate files using templates" but there is no template rendering logic anywhere. Templates use `{{VARIABLE}}` and `{{#BLOCK}}...{{/BLOCK}}` Mustache-style syntax, but no script, no code, and no instruction tells the LLM how to resolve these variables from the accumulated state files (discovery.md, agent-spec.md, org-profile.md, research.md, architecture.md).

**Why it matters:** When `/ask:build` runs, the LLM will see templates full of `{{SOUL_CORE_STATEMENT}}` and have to guess what to do. Some LLMs will fill them in intelligently from context; others will output the raw template syntax. This is the single most fragile point in the entire framework.

**Fix:** Add explicit instructions to `ask-build.md` that:
1. List the exact mapping from state files to template variables (leverage the mapping table already in openclaw-conventions.md)
2. Tell the LLM to read each template file, resolve every `{{VARIABLE}}` from accumulated state data, and output the fully populated file
3. Include a post-generation check: "Scan every generated file for `{{` — if any unresolved variables remain, resolve them or flag them as missing data"

Alternatively, add a `scripts/render-template.sh` that takes a template and a JSON/YAML data file and performs Mustache rendering.

### C2. Smoke Test is Conceptual, Not Executable

**What is wrong:** The validate command says "generate 5-10 representative messages that a real user would send to this agent" and "evaluate the agent's response" — but there is no mechanism to actually send a message to the agent and get a response. The LLM running ASK is not the agent being built. There is no invocation of the target runtime.

**Why it matters:** The smoke test as written will produce a hallucinated validation report. The LLM will imagine what the agent "would" respond and grade that imaginary response. This is theater, not testing.

**Fix:** Two options:
- **Option A (realistic):** Rename Level 2 from "Smoke Test" to "Scenario Review" and reframe it as: "The operator manually tests these scenarios and reports results back via `/ask:iterate`." Generate a test script the operator can run.
- **Option B (ambitious):** Add runtime-specific invocation logic. For OpenClaw: `openclaw --agent <name> --message "<test>"`. For Claude Code: spin up a subagent. For Hermes: `hermes --message "<test>"`. Add response capture and actual evaluation.

### C3. No config.yaml Template for OpenClaw

**What is wrong:** The CLAUDE.md lists `config.yaml` as an OpenClaw build output ("OpenClaw (primary): SOUL.md, IDENTITY.md, USER.md, MEMORY.md, TOOLS.md, AGENTS.md, HEARTBEAT.md, config.yaml"), but there is no `templates/openclaw/config.yaml.tmpl`. The build command has no guidance on generating this file.

**Why it matters:** Without config.yaml, the OpenClaw agent has no model configuration, no workspace path, no channel routing. The agent literally will not run.

**Fix:** Create `templates/openclaw/config.yaml.tmpl` with the OpenClaw `openclaw.json` structure including model selection, workspace path, and channel configuration. Use variables captured during Discovery Block C (model, runtime) and Architecture (integrations).

---

## Important Improvements (should fix)

### I1. Discovery Does Not Capture Enough for Tool Design

**What is wrong:** Discovery Block C asks about "integraciones" (APIs, DBs, file systems) at a surface level. It does not ask the specific questions needed to design tools well: What are the exact API endpoints? What authentication method? What are the rate limits? What are the error modes? What data format does each return?

**Why it matters:** Anthropic's guide (already in references!) emphasizes that "tool definitions deserve as much prompt engineering attention as your system prompt." If Discovery does not capture tool design details, the build phase will produce vague tool definitions that cause agent failures.

**Fix:** Add a "Tool Design" sub-section to Block C:
- For each integration: What is the exact API? What auth? What format? What errors?
- What tools does the agent need that do not exist today?
- For each tool: When should it be used? When should it NOT be used?
- Are there tools that overlap? How does the agent choose between them?

### I2. The Research Phase is Too Passive

**What is wrong:** The research command instructs the LLM to "use WebSearch and WebFetch to find papers, repos, documentation" — but the research questions are generic. It does not build on the specific Discovery findings to ask targeted research questions.

**Why it matters:** Generic research produces generic findings. If Discovery reveals the agent is for insurance claims processing, the research should be looking at specific insurance automation tools, regulatory requirements, and existing claim processing patterns — not generic "how the industry works."

**Fix:** Add a "Research Question Generation" step at the start of `/ask:research` that reads Discovery output and generates 5-10 specific, targeted research questions. Example: "Discovery revealed the agent processes insurance claims for Libra Seguros in Argentina. Research questions: What regulations govern insurance claim processing in Argentina (SSN, CNV)? What APIs do Argentine insurance platforms expose? What are the common claim classification taxonomies?"

### I3. Architecture Has No Cost/Latency Estimation

**What is wrong:** The architecture command defines 9 components but none include cost or latency analysis. There is no estimation of: How many LLM calls per task? What is the expected token consumption? What is the target response time? What is the monthly cost at expected volume?

**Why it matters:** Anthropic's guide explicitly warns that "agentic systems trade latency and cost for better task performance" and recommends evaluating this tradeoff explicitly. An architecture that looks good on paper but costs $500/day at production volume is a failed architecture.

**Fix:** Add a "Section 10: Cost and Performance Estimation" to the architecture command:
- Estimated LLM calls per typical task
- Average input/output tokens per call
- Expected daily volume
- Estimated monthly cost at current model pricing
- Target latency per task
- Identify cost optimization opportunities (cheaper models for subtasks, caching, etc.)

### I4. Memory Layer Missing Embeddings Implementation

**What is wrong:** The CLAUDE.md says "Todos los runtimes incluyen knowledge layer: memory/vault/, memory/hot-context/, memory/.embeddings/" and Discovery Block C asks about "Provider de embeddings" — but no template generates an embeddings configuration, no script initializes a vector store, and no build step configures embedding generation.

**Why it matters:** The anti-amnesia promise is central to ASK's value proposition. Without embeddings, the agent is limited to file-based memory (MEMORY.md, daily logs). For agents dealing with large document corpora or accumulated knowledge, this is insufficient. The framework promises embeddings but does not deliver them.

**Fix:** Either:
- **Descope it:** Remove embeddings from the promise. File-based memory is fine for most agents. Be honest about what the framework delivers.
- **Implement it:** Add a `templates/common/embeddings-config.tmpl` and a setup script that initializes a vector store (ChromaDB, FAISS local, or Neon pgvector) based on Discovery choices.

### I5. Export Command is Underdefined

**What is wrong:** The export command says "Copy all generated agent files (NOT ask-state/) to the target directory" but does not specify which files to copy. The build command generates files in an unspecified location. Is it `output/`? Is it the current directory? There is no `AGENT_OUTPUT_DIR` variable defined in the build step for OpenClaw or Claude Code (only Hermes has it).

**Why it matters:** After a successful build, the operator will run `/ask:export ~/agents/my-agent` and the command will not know which files to copy. The file manifest is in architecture.md as text, not as structured data that the export command can parse.

**Fix:**
1. Define a standard output directory in the build command: `output/<agent-slug>/`
2. Have the build command write a `ask-state/file-manifest.json` with the exact list of generated files and their paths
3. Have the export command read that manifest and copy exactly those files

### I6. Resume Command Has No Granularity for In-Progress Phases

**What is wrong:** The resume command reads state.json and shows a summary, but if Discovery was interrupted mid-interview (e.g., Block A complete, Block B half done), the resume command says "Continue from exactly where the operator left off" without a mechanism to determine where "exactly" that was.

**Why it matters:** Discovery is the longest phase — it can span multiple sessions. If the operator stops after 5 questions in Block B, the resume command needs to know which questions were asked and which were not. Currently, it relies on the LLM reading discovery.md and inferring, which is unreliable.

**Fix:** Add a `blocks_completed` array to `state.json.phases.discovery` (already in the `ask-new.md` template but unused). Track per-question progress within each block. When resuming, the discovery command should explicitly show: "Completaste Block A y 3 de 6 temas de Block B. Retomamos con: 'Los procesos que toca'."

### I7. No Regression Testing for Iterate Phase

**What is wrong:** The iterate command modifies files and "re-validates" but there is no mechanism to check that a change to fix Issue X did not break previously-passing behavior Y. The smoke test is re-run from scratch each time, but since it is conceptual (see C2), there is no regression safety net.

**Why it matters:** In real agent development, fixing one behavior often breaks another. "Change the tone to be more formal" might make the agent stop using colloquial domain terms. Without regression tracking, the iterate loop degrades agent quality.

**Fix:** Add a `regressions.md` concept to the iterate phase. When a smoke test passes, record the passing scenarios as regression baselines. When changes are made, re-test all baselines plus the new scenarios. Flag any regression explicitly.

---

## Nice-to-Have Enhancements

### N1. Agent Archetype Library

ASK would benefit from a library of 5-10 pre-built agent archetypes (customer support, data analyst, code reviewer, orchestrator, document processor) with partially-completed discovery answers. This would let operators start from a template instead of a blank slate, dramatically reducing time-to-first-agent.

### N2. Diff View for Iterate Changes

When `/ask:iterate` modifies files, show a before/after diff for each change, not just "what changed." This helps the operator understand the impact and catch unintended modifications.

### N3. Version History for Agent Files

Add a simple versioning mechanism: before each iterate modification, copy the previous version to `ask-state/versions/<filename>.<timestamp>`. This provides rollback without requiring git.

### N4. Agent Lifecycle Commands

Add `/ask:deploy` (deployment instructions per runtime), `/ask:monitor` (observability checklist and dashboard setup), and `/ask:retire` (graceful agent decommission). These cover the post-build lifecycle that production teams need.

### N5. Cost Tracking Across ASK Sessions

Track the total LLM tokens consumed during the ASK build process itself (not the agent's runtime). This helps operators understand the cost of building agents with ASK and optimize the process.

### N6. Discovery Fast Mode

Add a "fast discovery" option for experienced operators who already have a clear spec. Instead of the adaptive interview, accept a structured input document (YAML or Markdown) with the key discovery answers pre-filled, validate completeness, and proceed to research.

### N7. Cross-Agent Knowledge Sharing

When building multiple agents for the same org, the org-profile.md should be reusable. Add a mechanism to import an existing org-profile and skip Block B of Discovery.

---

## Template-Specific Findings

### OpenClaw Templates

**SOUL.md.tmpl** — Excellent. The section structure (Core, Vibe, Operating Principles, Guardrails, Autonomy, Escalation, Error Recovery, Data Handling, Self-Evolution, Compliance) is comprehensive. The inline comments with examples are particularly helpful. One gap: the "Self-Evolution" section mentions proposing improvements but does not define a format or cadence for self-review proposals.

**IDENTITY.md.tmpl** — Good. The Role, What I Do, Character Notes, Communication Rules structure is clean. Missing: a "What I Don't Do" section that explicitly states scope boundaries (currently only in SOUL.md guardrails, should be echoed here for quick reference).

**MEMORY.md.tmpl** — Strong. The promotion/demotion lifecycle, 80-line cap, and `[permanent]` marking system are well-designed. The directory structure documentation is clear. Gap: no guidance on initial memory seeding. When the agent boots for the first time, MEMORY.md is empty. There should be a "Day Zero" section pre-loaded with Discovery context.

**AGENTS.md.tmpl** — Good multi-agent section. The Agent Roster table, Coordination Rules, Handoff Format, and Conflict Resolution are the right abstractions. Gap: no guidance on how agents discover each other at runtime. The roster is static — there is no protocol for a new agent joining the ecosystem.

**HEARTBEAT.md.tmpl** — Solid. Checkpoint protocol, scheduled tasks, nightly maintenance, monitoring, and reminders cover the autonomous operation space well. Gap: no error budget concept. How many consecutive failures before the heartbeat task is disabled? The "On failure" field per task is good but there is no system-level circuit breaker.

**TOOLS.md.tmpl** — Adequate. Infrastructure, Integrations, Channels, Scripts, Security sections cover the basics. Gap: no tool capability matrix. For agents with many tools, there should be a quick-reference table: "Tool | When to Use | When NOT to Use | Auth Required."

**USER.md.tmpl** — Good. The progression from sparse to rich over time is a sound design. Gap: no mechanism for the operator to review and approve changes the agent proposes to USER.md. The template says "the agent should propose additions" but does not define the approval flow.

### Hermes Template

**agent-file.tmpl** — Comprehensive to the point of being overwhelming. At 495 lines, it generates 8 files plus a setup script, all from a single template. This is powerful but creates a maintenance risk: any change to Hermes conventions requires updating one massive file.

**Specific issues:**
- The MEMORY.md section specifies a 2,200 character limit but does not include tooling to enforce it
- The config.yaml section has placeholder variables (`{{TERMINAL_EXTRA_CONFIG}}`) that could produce invalid YAML if not filled or if filled with wrong formatting
- The setup.sh script copies files to `~/.hermes/` which may conflict with existing Hermes installations
- The system-prompt.md output includes both ChatML and Llama 3 format headers — should be conditional based on the target Hermes model version

**Recommendation:** Split into separate template files per output file, matching the OpenClaw pattern. One file = one template.

### Claude Code Templates

**CLAUDE.md.tmpl** — Good coverage with Identity, Language, Shorthand, Project Structure, Commands, Skills, Output Rules, Tools, Knowledge Layer, Memory, Guardrails, Escalation, Integrations, Workflows, Quality Criteria, State, and Principles. This is the most complete single-file agent definition I have reviewed.

**Specific issues:**
- The template has 42 variables. Some are structurally different from OpenClaw variables for the same concept (`{{GUARDRAILS_HARD}}` vs `{{#HARD_RULES}}...{{/HARD_RULES}}`). This means the build command needs runtime-specific variable resolution logic, adding complexity.
- No template for `.claude/commands/` — the build command mentions generating custom commands but there is no template for them
- The `settings.json.tmpl` has a flawed permissions structure: `"Bash({{ALLOWED_BASH_COMMANDS}})"` assumes the variable is a comma-separated string of commands, but Claude Code's settings.json expects each permission as a separate array entry. This will produce invalid JSON.

### Common Templates

**guardrails.md.tmpl** — Thorough. PII rules, secrets management, graceful degradation, scope boundaries, adjacent systems, compliance, and audit trail. This is the most complete guardrails template I have seen in any agent framework.

**org-profile.md.tmpl** — Excellent depth. Company overview, organizational structure, team profiles, adoption profile, key processes, technology stack, digital maturity, culture, stakeholder map, power dynamics, domain glossary, and constraints. This exceeds what most enterprise software projects capture about their client.

**system-prompt.md.tmpl** — Well-structured but has variable overlap with SOUL.md.tmpl and IDENTITY.md.tmpl. Variables like `{{AGENT_ROLE_DESCRIPTION}}`, `{{HARD_RULES_SUMMARY}}`, `{{COMMUNICATION_STYLE}}` appear in both. The build command needs to ensure consistency, but there is no mechanism for that.

---

## Reference Library Gaps

### What is Missing

1. **Autogen/AG2 patterns.** AutoGen is one of the major multi-agent frameworks and is not covered. Its conversation-based agent coordination pattern (agents as participants in a group chat) is distinct from supervisor or swarm patterns and would expand ASK's multi-agent vocabulary.

2. **MCP (Model Context Protocol) reference.** MCP is becoming the standard for tool interoperability. ASK should have a reference on how MCP servers map to agent tools, how to configure MCP in Claude Code and Hermes, and how MCP changes tool design patterns.

3. **Evaluation frameworks reference.** The prompt-engineering.md covers techniques but there is no reference on agent evaluation frameworks (Braintrust, Patronus, LangSmith evals, RAGAS). The validate phase would benefit from knowing how production teams evaluate agents.

4. **Deployment patterns reference.** No reference covers how to deploy agents to production: containerization, secrets management, health checks, blue-green deployment, rollback procedures, monitoring stacks.

5. **Cost optimization reference.** No reference covers model selection strategies, prompt caching, token reduction techniques, batching, or when to use smaller models for subtasks.

### What Needs Updating

The references are dated 2026-03-17 (today), so they appear current. However:

- **crewai-patterns.md** references CrewAI's "unified Memory class" but does not cover CrewAI Flows, which are the recommended pattern for production orchestration as of 2026. Flows replace the older process-based model.
- **langgraph-patterns.md** does not cover LangGraph Cloud or the deployment story, which is increasingly important for production use.
- **hermes-conventions.md** is based on the open-source Hermes agent but should clarify compatibility with the latest versions. Configuration options may have changed.

### What is Good

- **anthropic-agent-guide.md** is the standout. 600+ lines covering agent architecture, tool use, system prompts, context engineering, human-in-the-loop, guardrails, long-running agents, and agent skills. The "Key Takeaways for ASK" section with 16 numbered points is directly actionable.
- **prompt-engineering.md** is comprehensive with foundational techniques, agent-specific patterns, output control, advanced patterns, anti-patterns, and a template library. This is a genuine reference document, not a summary.
- **openclaw-conventions.md** includes the template variable mapping table, which is operationally critical for the build phase.

---

## Multi-Agent Assessment

### Current State

ASK has the conceptual framework for multi-agent support but lacks the operational depth to build a functioning multi-agent system:

1. **Discovery captures multi-agent info** — Block A asks "Hay otros agentes en el ecosistema? Como se coordinan?" This is good but insufficient. It does not ask: How many agents? What is the coordination topology (supervisor, peer, sequential)? What is the handoff protocol? What happens when an agent fails mid-handoff?

2. **AGENTS.md.tmpl has a multi-agent section** — Agent Roster, Coordination Rules, Handoff Format, and Conflict Resolution are present. This is the right structure. But it is conditional (`{{#HAS_MULTI_AGENT}}`) and only generates if the flag is set. There is no guidance on when to set it.

3. **Architecture includes an architecture diagram** — But the multi-agent topology (supervisor vs. swarm vs. sequential) is not an explicit design decision. It is mentioned in research but not formalized in the architecture output.

### What is Missing for Multi-Agent

**M1. No multi-agent discovery protocol.** When the operator says "I need 5 agents that work together," ASK has no protocol for capturing the interactions between them. It would need:
- Agent-by-agent discovery (abbreviated — same org, shared context)
- Interaction matrix: who talks to whom, about what, using what protocol
- Dependency map: which agents must exist before others
- Shared vs. agent-specific knowledge boundaries

**M2. No batch build for agent crews.** `/ask:build` generates one agent at a time. For a 5-agent crew, the operator would need to run the full pipeline 5 times. ASK should support:
- Shared Discovery (blocks B and C are org-level, not agent-level)
- Per-agent Discovery for Block A
- Shared Research (same domain, same org)
- Crew Architecture (all agents designed together, showing interactions)
- Batch Build (generate all agent files in one pass)

**M3. No shared memory layer.** Multi-agent systems need shared knowledge. The memory templates are per-agent. There is no template for a shared knowledge base that multiple agents access. CrewAI's scoped memory pattern (in the references) would apply here.

**M4. No handoff testing.** The validate phase does not test inter-agent handoffs. A crew validation should verify: Agent A can invoke Agent B, the handoff carries correct context, Agent B can return results to Agent A, failure modes are handled.

**M5. No orchestrator template.** The references cover supervisor patterns extensively, but there is no specific template for an orchestrator agent. An orchestrator has different needs than a worker: it needs an agent roster, routing logic, quality validation, and escalation paths. AGENTS.md.tmpl partially covers this, but a dedicated orchestrator template would be more effective.

### Recommendation

Multi-agent is currently a secondary feature of ASK. This is fine — single-agent builds are the 80% use case. But the framework should either:
- **Option A:** Explicitly scope multi-agent as "future" and remove the implicit promises (the agent roster in templates, the multi-agent questions in discovery). Build single-agent excellently first.
- **Option B:** Add a `/ask:crew` command that handles the multi-agent workflow with shared discovery, interaction mapping, crew architecture, and batch build.

Option B is the better path because the templates already have the right structure — they just need orchestration at the command level.

---

## Recommended Priority Order

1. **[C1] Add template resolution instructions to build command.** This is blocking — without it, the build phase produces raw templates instead of populated files. Estimated effort: 2-3 hours to add explicit variable resolution instructions and a post-generation placeholder check.

2. **[C3] Create OpenClaw config.yaml template.** Without this, OpenClaw agents do not run. Estimated effort: 1 hour.

3. **[C2] Reframe smoke test as scenario review.** The current smoke test is misleading. Renaming it and adding a test script the operator can run manually is a 1-hour fix that prevents false confidence.

4. **[I5] Define output directory and file manifest in build.** Export depends on this. Estimated effort: 1 hour.

5. **[I1] Add tool design questions to Discovery Block C.** Better discovery produces better tools. Estimated effort: 30 minutes to add 5-6 targeted questions.

6. **[I3] Add cost/latency estimation to architecture.** This prevents architecture designs that are financially unviable. Estimated effort: 1 hour.

7. **[I4] Decide on embeddings: descope or implement.** Stop promising what is not delivered. Estimated effort: 30 minutes to descope, 4-6 hours to implement.

8. **[I6] Add granular progress tracking for Discovery resume.** This improves the most-used phase. Estimated effort: 1 hour.

9. **[I2] Add targeted research question generation.** Improves research quality significantly. Estimated effort: 1 hour.

10. **[I7] Add regression baseline tracking to iterate.** Prevents quality degradation during iteration. Estimated effort: 2 hours.

11. **[Hermes template] Split into separate files.** Maintenance improvement. Estimated effort: 2 hours.

12. **[Settings.json template] Fix permissions array format.** The current template will produce invalid JSON. Estimated effort: 30 minutes.

13. **[N7] Cross-agent org-profile reuse.** Quick win for teams building multiple agents. Estimated effort: 1 hour.

14. **[N1] Agent archetype library.** Medium effort, high impact for adoption. Estimated effort: 4-6 hours for 5 archetypes.

15. **[M2-M5] Multi-agent crew support.** Large effort, high value for complex deployments. Estimated effort: 8-12 hours for the `/ask:crew` command and supporting templates.

---

*Audit conducted 2026-03-17. All file paths reference the project at `/Users/juanmazzochi/Documents/Projects/AI-Workspace/projects/ASK/`.*
