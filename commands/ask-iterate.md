$ARGUMENTS: Optional — specific issue to address (from validation report) or free-text feedback

# /ask:iterate — Adjust Based on Feedback

The operator provides feedback. You modify the relevant files and re-validate.

---

## Prerequisites

1. Read `ask-state/state.json`
2. Read `ask-state/validation-report.md` for known issues
3. Read the relevant agent files that need modification

---

## Process

1. **Parse feedback:** What needs to change? Map it to specific files.
2. **Propose changes:** Explain what you'll modify and why.
3. **Get approval:** Wait for operator confirmation.
4. **Make changes:** Edit the files.
5. **Re-validate:** Run the relevant validation checks on the changed components.
6. **Report:** Show what changed and new validation results.

## Feedback Types

| Feedback | Action |
|----------|--------|
| "Change the tone" | Update SOUL.md / IDENTITY.md, re-generate system prompt |
| "Add a tool" | Update TOOLS.md, architecture.md, install if needed |
| "Fix guardrail X" | Update guardrails in SOUL.md, re-run smoke test |
| "The agent doesn't know about Y" | Add to knowledge layer, update org-profile |
| "Scope is wrong" | Go back to Discovery, update agent-spec |

## Regression Protection

Antes de hacer cambios, protegé los escenarios que ya pasaban:

1. **Cargar baselines:** Leé `ask-state/validation-report.md` y `ask-state/test-scenarios.md`. Todos los escenarios con resultado PASS son baselines de regresión.
2. **Registrar baselines:** Si no existe, creá `ask-state/regressions.md` con la lista de escenarios que pasaban y su comportamiento esperado.
3. **Hacer los cambios:** Editá los archivos según el feedback del operador.
4. **Re-test completo:** Después de cada cambio, re-evaluá TODOS los baselines de regresión más los escenarios nuevos/modificados.
5. **Detectar regresiones:** Si un baseline que antes pasaba ahora falla:
   - Flaggealo explícitamente: "⚠️ REGRESIÓN: Escenario '<nombre>' pasaba antes y ahora falla"
   - Mostrá el before/after: qué respondía antes, qué responde ahora
   - Preguntá al operador: "¿Aceptás esta regresión o revertimos el cambio?"
6. **Actualizar regressions.md:** Mantené el tracking actualizado con cada iteración.

Formato de `ask-state/regressions.md`:
```markdown
# Regression Baselines: <agent_name>
Last updated: <timestamp>

## Passing Scenarios
| Scenario | Category | Expected Behavior | Status |
|----------|----------|-------------------|--------|
| Normal query | happy-path | Responde con info del dominio | PASS |
| Sensitive data request | guardrail | Rechaza y escala | PASS |
| ... | ... | ... | ... |

## Regression History
### Iteration 1 — <timestamp>
- Changed: SOUL.md (tone adjustment)
- Regressions: none
### Iteration 2 — <timestamp>
- Changed: TOOLS.md (added new tool)
- Regressions: "Scenario X" — accepted by operator
```

## Loop

This phase loops until the operator says "listo" / "done" / "ship it":

```
Feedback → Changes → Regression Check → Re-validate → Report → More feedback?
```

When done, update state: `iterate.status = "completed"`, `current_phase = "done"`

```bash
cmux set-progress 1.0 --workspace $CMUX_WORKSPACE_ID
cmux notify --title "ASK" --body "Agent <name> listo para producción."
```
