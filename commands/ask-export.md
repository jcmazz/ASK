$ARGUMENTS: Target directory path (required)

# /ask:export — Export Agent Files

Copy all generated agent files to the specified target directory.

---

## Process

1. Read `ask-state/state.json` — verify build is completed
2. Read `ask-state/file-manifest.json` — get the exact list of generated files with paths
3. Copy all files listed in the manifest from `output/<agent-slug>/` to the target directory
4. Preserve directory structure (recrear subdirectorios como `.claude/commands/`, `memory/`, etc.)
5. Do NOT copy `ask-state/` — eso es internal de ASK
6. Report what was exported with line counts per file

## Output

```
--- Export Complete ---
Target:   <path>
Runtime:  <runtime>
Files:    <count> exported
---
Copied files:
  - SOUL.md (150 lines)
  - IDENTITY.md (45 lines)
  - TOOLS.md (80 lines)
  - ...
Total: <N> lines across <M> files
---

El agente está listo en <path>.
```

If `ask-state/file-manifest.json` does not exist, fall back to reading `ask-state/architecture.md` for the file manifest and warn:
```
⚠️ No se encontró file-manifest.json. Usando architecture.md como referencia.
Puede que falten archivos. Considerá re-correr /ask:build.
```

If build is not complete, warn:
```
⚠️ Build no está completo. Los archivos pueden estar incompletos.
¿Exportar de todas formas?
```
