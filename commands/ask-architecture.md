$ARGUMENTS: Optional — specific aspect to (re)design (knowledge, skills, prompts, integrations)

# /ask:architecture — Design the Agent Architecture

You are designing the complete architecture for an ASK agent build. Nothing gets built until the operator approves this.

---

## Prerequisites

1. Read `ask-state/state.json`
2. Read `ask-state/agent-spec.md`, `ask-state/org-profile.md`, `ask-state/research.md`
3. If architecture was partially done, read `ask-state/architecture.md`

---

## What to Define

### 1. Runtime and Model
- Confirm the runtime chosen in Discovery (OpenClaw / Hermes / Claude Code / other)
- Confirm the model (default sonnet, or operator's choice)
- Document any runtime-specific constraints

### 2. File Manifest
List every file to be generated, with its purpose:
```
output/
├── SOUL.md          — Core identity and behavior
├── IDENTITY.md      — Name, personality, tone
├── ...
```

### 3. Knowledge Layer
- **Hot context** (injected every session): which files, what info
- **Deep context** (vault/knowledge base): structure, categories
- **Memory persistence**: how the agent remembers across sessions
- **Embeddings**: provider, paths, update cadence
- **Directory structure** for memory/vault

### 4. Skills
- Final list of skills to install (from Research)
- Skills to create custom (specify what each does)
- Skill dependencies and load order

### 5. Integrations
- APIs: endpoints, auth method, data format
- Databases: type, access method, schemas
- Channels: Discord, Slack, CLI, web — how each connects
- Configuration details for each

### 6. System Prompt (Draft)
Write a first draft based on Discovery + Research:
- Role definition
- Core instructions
- Guardrails and boundaries
- Output format expectations
- Escalation rules
- Personality directives

### 7. Guardrails
- Hard rules (NEVER do X)
- Approval-required actions
- Data sensitivity rules
- Error recovery procedures
- Escalation paths (who, when, how)

### 8. Architecture Diagram
ASCII diagram showing the agent in its ecosystem:
- Frontend/backend/DB connections
- API integrations
- Other agents in the system
- Data flow direction

### 9. Validation Plan
How the agent will be tested:
- Checklist items
- Smoke test scenarios
- Eval criteria

### 10. Cost & Performance Estimation
Estimá el costo y performance del agente en producción:
- **LLM calls por tarea típica:** ¿Cuántas llamadas al modelo por interacción?
- **Tokens promedio por llamada:** Input tokens y output tokens estimados
- **Volumen esperado:** Interacciones diarias/mensuales (del Discovery)
- **Costo mensual estimado:** Basado en pricing actual del modelo elegido
- **Latencia target:** Tiempo de respuesta aceptable por tarea
- **Oportunidades de optimización:** Modelos más baratos para subtareas, caching de respuestas frecuentes, compresión de prompts, batching
- **Token budget por interacción:** Máximo aceptable de tokens por request

### 11. Risk Assessment
Identificá qué puede salir mal:
- **Top 3 riesgos** del agente en producción (técnicos, operacionales, de negocio)
- **Probabilidad e impacto** de cada riesgo (alto/medio/bajo)
- **Mitigación** concreta para cada riesgo
- **Plan de contingencia** si un riesgo se materializa

### 12. Evolution Path
¿Cómo se adapta esta arquitectura a cambios futuros?
- **Cambios esperados** en los próximos 3-6 meses (del Discovery)
- **Extensibilidad:** ¿Qué tan fácil es agregar tools, skills, integraciones?
- **Migración de modelo:** ¿Qué cambia si se mueve a un modelo diferente?
- **Escalabilidad:** ¿Qué pasa si el volumen se 10x?

---

## Output

Write to `ask-state/architecture.md`:

```markdown
# Architecture: <agent_name>
Date: <timestamp>
Approved: pending

## Runtime & Model
...

## File Manifest
...

## Knowledge Layer
...

## Skills
...

## Integrations
...

## System Prompt (Draft)
...

## Guardrails
...

## Architecture Diagram
...

## Validation Plan
...

## Cost & Performance Estimation
...

## Risk Assessment
...

## Evolution Path
...
```

---

## Approval Gate

Present the full architecture and ask:

```
--- Architecture Propuesta ---
Runtime:       <runtime>
Archivos:      <count> files to generate
Skills:        <count> to install, <count> to create
Integraciones: <list>
Guardrails:    <count> rules
---

¿Aprobás esta arquitectura, querés modificar algo, o volvemos a Discovery/Research?
```

Only proceed to Build after explicit operator approval. Update `architecture.md` with `Approved: yes` and timestamp.

Update state: `architecture.status = "completed"`, `current_phase = "build"`

## cmux Integration
```bash
cmux set-status phase "Architecture" --workspace $CMUX_WORKSPACE_ID
cmux set-progress 0.33 --workspace $CMUX_WORKSPACE_ID
# On completion:
cmux set-progress 0.50 --workspace $CMUX_WORKSPACE_ID
cmux notify --title "ASK" --body "Architecture approved. Ready for Build."
```
