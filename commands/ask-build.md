$ARGUMENTS: Optional — specific component to (re)build (files, skills, memory, prompts)

# /ask:build — Generate the Agent

You are building the agent based on the approved architecture. Generate all files, install skills, configure the knowledge layer.

---

## Prerequisites

1. Read `ask-state/state.json` — verify architecture is approved
2. Read ALL ask-state files: agent-spec, org-profile, research, architecture
3. Architecture MUST be approved. If not, redirect to `/ask:architecture`

---

## Output Directory Convention

All generated files go to `output/<agent-slug>/` (relative to the project where ASK is invoked). The `<agent-slug>` is the agent name from state.json, lowercased and with spaces replaced by hyphens.

Example: agent name "Finance Agent" → `output/finance-agent/`

---

## Build Steps

### Step 1: Generate Base Files

Read the runtime from architecture.md and generate files using templates.

**For OpenClaw:**
- `SOUL.md` — Core identity, behavior rules, guardrails
- `AGENTS.md` — Agent coordination (if multi-agent)
- `IDENTITY.md` — Name, personality, communication style
- `USER.md` — Who the operator is, preferences
- `MEMORY.md` — Memory index and structure
- `TOOLS.md` — Available tools, when to use each
- `HEARTBEAT.md` — Cron/autonomous tasks (if applicable)
- `config.yaml` — Runtime configuration

**For Claude Code standalone:**
- `CLAUDE.md` — Combined instructions
- `.claude/settings.json` — Permissions and config
- `.claude/commands/` — Custom slash commands
- `.claude/skills/` — Custom skills

**For Hermes:**
- Agent file in Hermes format
- Tool definitions
- System prompt file

Fill every file with the actual content from Discovery + Research + Architecture. NO placeholders. NO "TODO: fill this in". Every file should be production-ready.

### Template Resolution Protocol

Para cada archivo a generar, seguí este proceso exacto:

**Paso 1: Cargar fuentes de datos**
Leé todos los archivos de estado acumulados:
- `ask-state/discovery.md` — Transcript completo de la entrevista
- `ask-state/agent-spec.md` — Especificación del agente
- `ask-state/org-profile.md` — Perfil organizacional
- `ask-state/research.md` — Hallazgos de investigación
- `ask-state/architecture.md` — Arquitectura aprobada

**Paso 2: Leer el template**
Leé el template correspondiente al runtime desde `templates/<runtime>/`.

**Paso 3: Resolver variables**
Para cada `{{VARIABLE}}` en el template, resolvé desde la fuente correcta según esta tabla:

| Variable | Fuente | Sección |
|----------|--------|---------|
| `{{AGENT_NAME}}` | agent-spec.md | Header / nombre |
| `{{AGENT_ROLE}}` | agent-spec.md | Función y misión |
| `{{AGENT_ROLE_DESCRIPTION}}` | agent-spec.md | Función y misión (descripción extendida) |
| `{{SOUL_CORE_STATEMENT}}` | agent-spec.md | Razón de existir + scope |
| `{{SOUL_VIBE}}` | agent-spec.md | Personalidad y tono |
| `{{OPERATING_PRINCIPLES}}` | architecture.md | System Prompt (Draft) |
| `{{HARD_RULES}}` / `{{GUARDRAILS_HARD}}` | architecture.md | Guardrails → Hard rules |
| `{{SOFT_RULES}}` / `{{GUARDRAILS_SOFT}}` | architecture.md | Guardrails → Approval-required |
| `{{ESCALATION_PATHS}}` | architecture.md | Guardrails → Escalation paths |
| `{{ERROR_RECOVERY}}` | architecture.md | Guardrails → Error recovery |
| `{{DATA_HANDLING}}` | architecture.md | Guardrails → Data sensitivity |
| `{{COMMUNICATION_STYLE}}` | agent-spec.md | Personalidad y tono |
| `{{COMMUNICATION_RULES}}` | agent-spec.md | Personalidad y tono (reglas) |
| `{{AUTONOMY_RULES}}` | agent-spec.md | Autonomía y decisiones |
| `{{TOOLS_LIST}}` | architecture.md | Integrations |
| `{{TOOL_DEFINITIONS}}` | architecture.md | Integrations (detail) |
| `{{SKILLS_LIST}}` | architecture.md | Skills |
| `{{MEMORY_STRUCTURE}}` | architecture.md | Knowledge Layer |
| `{{MEMORY_HOT_CONTEXT}}` | architecture.md | Knowledge Layer → Hot context |
| `{{MEMORY_DEEP_CONTEXT}}` | architecture.md | Knowledge Layer → Deep context |
| `{{HEARTBEAT_TASKS}}` | architecture.md | Validation Plan / agent-spec → Cron |
| `{{ORG_NAME}}` | org-profile.md | Company name |
| `{{ORG_CONTEXT}}` | org-profile.md | Full profile summary |
| `{{ORG_INDUSTRY}}` | org-profile.md | Industry |
| `{{ORG_GLOSSARY}}` | org-profile.md | Domain glossary |
| `{{USER_NAME}}` | discovery.md | Operator info |
| `{{USER_ROLE}}` | discovery.md | Operator role |
| `{{MODEL_NAME}}` | architecture.md | Runtime & Model |
| `{{RUNTIME}}` | architecture.md | Runtime & Model |
| `{{CHANNELS}}` | agent-spec.md | Interacciones → Canales |
| `{{COMPLIANCE_RULES}}` | architecture.md / org-profile.md | Compliance requirements |
| `{{SELF_EVOLUTION_RULES}}` | architecture.md | System Prompt (Draft) |

**Paso 4: Resolver bloques condicionales**
Para cada `{{#BLOCK}}...{{/BLOCK}}`:
- Si la data relevante existe y es aplicable → expandir el bloque con el contenido concreto
- Si no aplica (ej: `{{#HAS_MULTI_AGENT}}` pero es single-agent) → eliminar el bloque entero
- Si es iterativo (ej: `{{#TOOLS}}`) → generar una entrada por cada ítem del array correspondiente

**Paso 5: Post-generation check**
Después de generar cada archivo:
1. Escaneá el contenido buscando `{{` — si queda alguna variable sin resolver:
   - Intentá resolverla buscando en TODOS los archivos de estado
   - Si no hay data suficiente, reemplazá con un valor por defecto razonable y logueá un warning en build-log.md
   - NUNCA dejés un `{{VARIABLE}}` sin resolver en el output final
2. Verificá que el archivo sea válido (markdown bien formado, YAML parseable, JSON válido)
3. Verificá consistencia: cada tool mencionado en SOUL.md debe existir en TOOLS.md, cada guardrail de architecture.md debe estar reflejado en los archivos generados

### Step 2: Configure Knowledge Layer

- Create the vault/memory directory structure per architecture
- Generate org-profile and entity files for the knowledge base
- Pre-load memory with Discovery context
- Configure embedding provider if applicable
- Set up any vector store initialization

### Step 3: Install Skills

- Install each skill from the architecture's skills list
- Run basic verification that each loads
- Create any custom skills specified in architecture
- Document what was installed in build-log

### Step 4: Generate Prompts

- Final system prompt (refined from architecture draft)
- Task-specific prompts for recurrent operations
- Few-shot examples where applicable
- Output format templates

### Step 5: Quality Gates

Antes de reportar el build como completo, verificá estas consistencias entre archivos:

1. **Tool consistency:** Cada tool mencionado en SOUL.md o el system prompt debe tener una entrada en TOOLS.md (OpenClaw) o en la sección tools de CLAUDE.md (Claude Code). Si falta, creá la entrada o removelo del prompt.
2. **Guardrail consistency:** Cada guardrail definido en architecture.md debe estar reflejado en los archivos generados. Compará la lista de architecture.md con lo que terminó en SOUL.md/CLAUDE.md.
3. **Skill consistency:** Cada skill listado en architecture.md debe estar instalado o documentado en el build log.
4. **Knowledge layer consistency:** Las rutas de memory/vault referenciadas en los archivos deben existir en la estructura de directorios creada.
5. **Cross-file references:** Si un archivo referencia otro (ej: "ver TOOLS.md para detalle"), verificá que ese archivo existe y tiene el contenido referenciado.

Si encontrás inconsistencias:
- Corregí automáticamente las que sean claras (ej: tool faltante en TOOLS.md → agregarlo)
- Logueá cada corrección en build-log.md bajo "## Quality Gate Fixes"
- Si la inconsistencia requiere decisión del operador, logueala como issue

### Step 6: Generate File Manifest

Escribí `ask-state/file-manifest.json` con el inventario exacto de archivos generados:

```json
{
  "runtime": "<runtime elegido>",
  "agent_name": "<nombre del agente>",
  "agent_slug": "<slug usado para output dir>",
  "built_at": "<ISO timestamp>",
  "output_dir": "output/<agent-slug>/",
  "files": [
    {
      "path": "output/<agent-slug>/SOUL.md",
      "type": "core",
      "description": "Core identity and behavior rules",
      "lines": 150
    },
    {
      "path": "output/<agent-slug>/IDENTITY.md",
      "type": "core",
      "description": "Name, personality, communication style",
      "lines": 45
    }
  ]
}
```

Tipos válidos: `core`, `config`, `skill`, `prompt`, `knowledge`, `memory`, `script`

---

## Output

Write a build log to `ask-state/build-log.md`:

```markdown
# Build Log: <agent_name>
Date: <timestamp>

## Files Generated
- path/to/file.md — description (N lines)
- ...

## Skills Installed
- skill_name — status

## Knowledge Layer
- Structure created at: path
- Files pre-loaded: N
- Embeddings: configured/skipped

## Prompts Generated
- System prompt: path
- Task prompts: N generated

## Issues
- [any problems encountered]
```

---

## Transition

```
--- Build Completo ---
Archivos:  <count> generados
Skills:    <count> instalados
Memory:    <structure summary>
Prompts:   <count> generados
---

¿Querés revisar los archivos antes de validar, o avanzamos a Validate?
```

## cmux Integration
```bash
cmux set-status phase "Build" --workspace $CMUX_WORKSPACE_ID
cmux set-progress 0.50 --workspace $CMUX_WORKSPACE_ID
# On completion:
cmux set-progress 0.67 --workspace $CMUX_WORKSPACE_ID
cmux notify --title "ASK" --body "Build completo. <N> files generated."
```
