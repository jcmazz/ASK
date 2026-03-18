# /ask:progress — Show Current State

Read `ask-state/state.json` and present a clear status overview.

---

## Output Format

```
--- ASK Progress: <agent_name> ---

Phase         Status        Notes
─────         ──────        ─────
1. Discovery  ✅ Completed   Blocks A, B, C done
2. Research   🔄 In Progress Domain + skills done, architecture pending
3. Architecture ⏳ Pending
4. Build      ⏳ Pending
5. Validate   ⏳ Pending
6. Iterate    ⏳ Pending

Runtime:  <chosen or "Not decided">
Model:    <chosen or "Not decided">
Skipped:  <list or "None">

Key Decisions:
  - [timestamp] <decision description>
  - [timestamp] <decision description>

Files Generated:
  - ask-state/discovery.md (X lines)
  - ask-state/agent-spec.md (X lines)
  - ask-state/org-profile.md (X lines)
  ...

Next: /ask:<next_phase> to continue
```

## Status Icons

- ⏳ Pending
- 🔄 In Progress
- ✅ Completed
- ⏭️ Skipped

## Additional Context

If files exist in `ask-state/`, show their size (line count) to give a sense of how much content has been captured.

If inside cmux, update the sidebar:
```bash
cmux set-status phase "<current_phase>" --workspace $CMUX_WORKSPACE_ID
cmux set-progress <0.0-1.0 based on phases completed>
```

Progress mapping:
- Discovery complete = 0.17
- Research complete = 0.33
- Architecture complete = 0.50
- Build complete = 0.67
- Validate complete = 0.83
- Iterate complete = 1.0
