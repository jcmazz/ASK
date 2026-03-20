$ARGUMENTS: Optional — validation level (checklist, smoke, eval). Default: checklist + smoke.

# /ask:validate — Test the Agent

Verify the built agent works as designed. Three levels, escalating in depth.

---

## Prerequisites

1. Read `ask-state/state.json` — verify build is completed
2. Read `ask-state/architecture.md` for validation plan
3. Read `ask-state/agent-spec.md` for expected behavior

---

## Level 1: Technical Checklist (always runs)

Verify each item and report pass/fail:

- [ ] All files from the file manifest exist
- [ ] All files are well-formed (valid markdown, valid YAML, valid JSON)
- [ ] Skills load without errors
- [ ] Memory directory structure exists and is accessible
- [ ] Model responds to a basic prompt
- [ ] Guardrails file is present and non-empty
- [ ] System prompt is present and non-empty
- [ ] Runtime-specific config is valid

## Level 2: Scenario Simulation & Review (default — runs after checklist)

Based on Discovery content, generate 5-10 representative test scenarios that a real user would send to this agent. These should cover:

- Normal operation (happy path)
- Edge cases from guardrails
- Escalation triggers
- Domain-specific questions
- Personality/tone expectations

### Sub-mode A: Simulated (default)

Generá los escenarios de test y evaluá el diseño del agente:

1. Para cada escenario, leé el system prompt generado, SOUL.md (o CLAUDE.md), guardrails, y knowledge layer del agente construido.
2. Usá un subagente para role-play: el subagente actúa como el agente construido, usando sus archivos como contexto. Evaluá sus respuestas.
3. Para cada respuesta simulada, evaluá contra:
   - **Tone:** ¿Coincide con la personalidad definida?
   - **Guardrails:** ¿Respeta los límites?
   - **Knowledge:** ¿Usa el contexto organizacional?
   - **Escalation:** ¿Escala cuando debe?
   - **Utility:** ¿La respuesta es útil?

Score each dimension: PASS / PARTIAL / FAIL

**⚠️ Disclaimer:** La simulación evalúa el diseño del prompt y la coherencia de los archivos, NO el comportamiento real en runtime. Se recomienda testing manual o live antes de producción.

### Sub-mode B: Live (si el runtime está disponible)

Si el runtime del agente está accesible, ejecutá los tests en vivo:

**Para OpenClaw:**
```bash
hermes --agent output/<agent-slug>/ --message "<test scenario>"
```

**Para Claude Code:**
Spawn un subagente con el CLAUDE.md generado como system prompt y enviá cada test como mensaje.

**Para Hermes:**
```bash
hermes --agent-file output/<agent-slug>/agent.yaml --message "<test scenario>"
```

Capturá la respuesta real y evaluala con los mismos criterios que el modo simulado.

### Test Scenarios Output

Escribí todos los escenarios a `ask-state/test-scenarios.md`:

```markdown
# Test Scenarios: <agent_name>
Date: <timestamp>

## Scenario 1: <nombre descriptivo>
**Category:** happy-path | edge-case | guardrail | escalation | domain | tone
**Input:** "<mensaje del usuario>"
**Expected behavior:** <qué debería hacer el agente>
**Expected tone:** <cómo debería sonar>
**Guardrails to verify:** <qué límites aplican>

## Scenario 2: ...
```

Este archivo sirve como referencia para que el operador pueda ejecutar los tests manualmente en cualquier momento.

## Level 3: Eval Suite (only if operator requests)

Generate formal test cases with expected outputs:
- Input → Expected output pairs
- Rubric for scoring
- Automated evaluation where possible
- Per-category metrics (precision, tone, guardrails, utility)

---

## Output

Write to `ask-state/validation-report.md`:

```markdown
# Validation Report: <agent_name>
Date: <timestamp>
Level: <1|2|3>

## Technical Checklist
| Check | Status | Notes |
|-------|--------|-------|
| Files exist | PASS | 12/12 files |
| ... | ... | ... |

## Smoke Test Results
| Test | Tone | Guardrails | Knowledge | Escalation | Utility |
|------|------|-----------|-----------|------------|---------|
| "Normal query" | PASS | PASS | PASS | N/A | PASS |
| ... | ... | ... | ... | ... | ... |

## Issues Found
1. [issue description + severity]
2. ...

## Recommendation
<Ready for production / Needs iteration on X, Y, Z>
```

---

## Transition

```
--- Validation Report ---
Checklist:  <X/Y> passed
Smoke Test: <X/Y> passed
Issues:     <count> found
Verdict:    <Ready / Needs work>

📁 Archivos generados/actualizados:
  - ask-state/validation-report.md — Reporte de validación
  - ask-state/test-scenarios.md — Escenarios de test
  - ask-state/state.json — Estado actualizado
---

¿Iteramos sobre los issues (/ask:iterate) o el agente está listo?
```

💡 Si la conversación se hizo larga, podés iniciar una sesión nueva.
Los archivos de contexto ya están guardados — usá `/ask:resume` en la nueva sesión para retomar con contexto fresco.

## cmux Integration
```bash
cmux set-status phase "Validate" --workspace $CMUX_WORKSPACE_ID
cmux set-progress 0.67 --workspace $CMUX_WORKSPACE_ID
# On completion:
cmux set-progress 0.83 --workspace $CMUX_WORKSPACE_ID
cmux notify --title "ASK" --body "Validation complete. <verdict>."
```
