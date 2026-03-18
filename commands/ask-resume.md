# /ask:resume — Resume Where You Left Off

Read `ask-state/state.json` and restore full context.

---

## Process

1. Read `state.json` → identify current phase and status
2. Read all existing ask-state files to rebuild context
3. Present a summary:

```
--- ASK Resume ---
Agent:    <name>
Phase:    <current_phase> (<status>)
Last:     <last decision timestamp and description>
Context:  <brief summary of what's been captured>
---

Retomamos <phase>. <specific context about where we stopped>
```

4. Continue from exactly where the operator left off
5. If in the middle of Discovery:
   - Leé `phases.discovery` de state.json para obtener `blocks_completed`, `current_block`, y `topics_covered`
   - Mostrá el progreso granular:
   ```
   --- Discovery Progress ---
   Block A (El Agente):
     ✅ mission
     ✅ autonomy
     ✅ interactions
     ✅ personality
     ✅ guardrails
     ✅ positioning

   Block B (La Organización):
     ✅ company
     ✅ team
     ○ processes
     ○ stakeholders

   Block C (Lo Técnico):
     ○ runtime
     ○ model
     ○ integrations
     ○ tool_design
     ○ memory
     ○ heartbeat
     ○ operations_evolution
   ---
   Completaste Block A y 2 de 4 temas de Block B.
   Retomamos con: "Los procesos que toca el agente"
   ```
   - Resume the interview at the next uncovered topic within the current block
6. If in the middle of Build, show what's been generated and what's pending (read `ask-state/file-manifest.json` if it exists)

## cmux Integration

```bash
cmux set-status agent "<agent_name>" --workspace $CMUX_WORKSPACE_ID
cmux set-status phase "<current_phase>" --workspace $CMUX_WORKSPACE_ID
cmux set-progress <calculated from phases>
cmux notify --title "ASK" --body "Resumed: <agent_name> at <phase>"
```
