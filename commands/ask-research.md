$ARGUMENTS: Optional — specific area to research (domain, skills, architecture, prompts, org)

# /ask:research — Deep Research Phase

You are conducting the research phase of an ASK agent build. Research is always deep — there is no shallow mode.

---

## Prerequisites

1. Read `ask-state/state.json` — verify discovery is completed (or warn if skipped)
2. Read `ask-state/discovery.md`, `ask-state/agent-spec.md`, `ask-state/org-profile.md`
3. If research was partially done, read `ask-state/research.md` to continue

---

## Step 0: Research Question Generation

Antes de investigar, generá preguntas de investigación específicas basadas en Discovery:

1. Leé `ask-state/discovery.md`, `ask-state/agent-spec.md`, `ask-state/org-profile.md`
2. Generá 5-10 preguntas de investigación concretas y direccionadas, derivadas de lo capturado

**Ejemplo:** Si Discovery reveló que el agente procesa siniestros para Libra Seguros en Argentina:
- ¿Qué regulaciones rigen el procesamiento de siniestros en Argentina? (SSN, CNV)
- ¿Qué APIs exponen las plataformas de seguros argentinas?
- ¿Qué taxonomías de clasificación de siniestros existen en el mercado?
- ¿Qué soluciones de automatización de claims existen? ¿Qué funcionó y qué no?
- ¿Cuáles son los SLAs típicos para resolución de siniestros en Argentina?

Escribí las preguntas generadas al inicio de `ask-state/research.md` bajo un header `## Research Questions`. Estas preguntas guían toda la investigación — no investigues genéricamente, investigá respondiendo estas preguntas.

---

## Research Areas

### 1. Domain Research

Based on the generated research questions and what was captured in Discovery, research the agent's domain:
- How the industry/domain works
- Existing automations and tools in the space
- Regulations, compliance requirements
- Data formats and standards
- Common workflows and edge cases
- Real implementations and case studies

Use WebSearch and WebFetch to find papers, repos, documentation, and case studies.

### 2. Skills Audit

Scan for relevant skills:
- List installed skills in `~/.claude/skills/`
- Search skills.sh / marketplace for relevant packages
- Check known repos (gstack, pm-skills, agency-agents)
- Evaluate relevance and quality of each
- Note which need customization vs. use as-is

### 3. Architecture Patterns

Consult the `references/` directory (if populated) and research:
- Anthropic's building effective agents guide
- LangGraph patterns (multi-agent, supervisor, human-in-the-loop)
- CrewAI patterns (role-based design, crew composition)
- OpenClaw conventions (file structure, memory layers)
- Hermes conventions (agent file format)
- Eliza concepts (character files, memory patterns)

Identify the best pattern for this agent:
- Single agent vs. multi-agent
- Supervisor vs. sequential vs. parallel
- Human-in-the-loop requirements
- Memory architecture

### 4. Prompt Engineering

Research best practices for this agent's task type:
- Chain-of-thought for complex reasoning
- Few-shot examples for consistent output format
- Role prompting for personality/expertise
- Structured output for reliable data extraction
- Planning patterns for multi-step tasks

Find examples of successful system prompts for similar agents.

### 5. Organization Profile Enhancement

Supplement Discovery findings with public research:
- Company information, industry position
- Competitors and market dynamics
- Technology stack indicators
- Regulatory environment

---

## Output

Write everything to `ask-state/research.md` structured as:

```markdown
# Research: <agent_name>
Date: <timestamp>

## Domain Research
[findings with sources]

## Skills Audit
### Recommended
- skill_name — why it's relevant, any customization needed
### Considered but Rejected
- skill_name — why not

## Architecture Pattern
**Recommended:** <pattern name>
**Why:** <justification>
**Alternatives considered:** <list with tradeoffs>

## Prompt Engineering
**Techniques to use:** <list>
**Reference prompts:** <examples>

## Organization Context (supplemental)
[anything new beyond Discovery]
```

Update `ask-state/org-profile.md` with new findings.
Update `ask-state/state.json` → research.status = "completed"

---

## Transition

```
--- Research Completo ---
Dominio:      <key findings>
Skills:       <N> recomendados, <M> a crear
Arquitectura: <recommended pattern>
Prompts:      <techniques identified>

📁 Archivos generados/actualizados:
  - ask-state/research.md — Hallazgos de investigación
  - ask-state/org-profile.md — Perfil organizacional actualizado
  - ask-state/state.json — Estado actualizado
---

¿Querés que profundice en algo o avanzamos a Architecture?
```

💡 Si la conversación se hizo larga, podés iniciar una sesión nueva.
Los archivos de contexto ya están guardados — usá `/ask:resume` en la nueva sesión para retomar con contexto fresco.

## cmux Integration

```bash
cmux set-status phase "Research" --workspace $CMUX_WORKSPACE_ID
cmux set-progress 0.17 --workspace $CMUX_WORKSPACE_ID
```

When complete:
```bash
cmux set-progress 0.33 --workspace $CMUX_WORKSPACE_ID
cmux notify --title "ASK" --body "Research completo. <N> skills recomendados."
```
