$ARGUMENTS: Optional — phase to skip. Defaults to current phase.

# /ask:skip — Skip Current Phase

Read `ask-state/state.json` to determine the current phase.

## Warning

Always warn before skipping:

```
⚠️ Saltear <phase_name> va a reducir la calidad del agente.

Lo que te perdés:
- Discovery: El agente no va a tener contexto profundo. Las respuestas van a ser genéricas.
- Research: No vas a saber qué skills existen ni qué patrones usar. Vas a reinventar la rueda.
- Architecture: Vas a construir sin planos. Más refactoring después.
- Validate: No sabés si funciona hasta que lo uses en producción.

¿Seguro que querés saltear <phase_name>?
```

## If Confirmed

1. Update `state.json`: current phase status → "skipped"
2. Add phase to `skipped_phases` array
3. Add decision: `"Skipped <phase> — operator choice"`
4. Advance to next phase
5. Warn once more at the start of the next phase about missing context
