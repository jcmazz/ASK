# /ask:crew — Multi-Agent Crew Builder

Orquesta la creación de un crew de agentes que trabajan juntos. Capa de orquestación sobre los comandos existentes de ASK.

## Uso

```
/ask:crew <crew-name> <num-agents>
/ask:crew support-team 3
```

## Pre-requisitos

- No hay un crew build activo (verificar `ask-state/crew-state.json`)
- ASK framework intacto (correr `preflight-check.sh` si hay dudas)

## Flujo completo

```
crew:init → crew:shared-discovery → crew:agent-discovery → crew:interaction-matrix
    → crew:research → crew:architecture → [APPROVAL GATE] → crew:build → crew:validate
```

---

## Fase 1: Crew Init

### Al recibir el comando:

1. **Leer** `ask-state/crew-state.json` si existe — verificar que no hay un crew build activo
2. **Crear** `ask-state/crew-state.json` con la estructura inicial:

```json
{
  "crew_name": "<crew-name>",
  "created_at": "<timestamp>",
  "current_phase": "init",
  "num_agents": <num-agents>,
  "agents": [],
  "topology": null,
  "shared_context": {
    "org_profile_complete": false,
    "technical_context_complete": false,
    "research_complete": false
  },
  "phases": {
    "init": { "status": "in_progress", "started_at": "<timestamp>" },
    "shared_discovery": { "status": "pending" },
    "agent_discovery": { "status": "pending" },
    "interaction_matrix": { "status": "pending" },
    "research": { "status": "pending" },
    "architecture": { "status": "pending", "approved": false },
    "build": { "status": "pending" },
    "validate": { "status": "pending" }
  },
  "decisions": []
}
```

3. **Pedir** al operador:
   - Descripción general del crew (qué problema resuelve como sistema)
   - Nombre y rol de cada agente (puede ser tentativo)
   - Runtime (todos los agentes del crew deben compartir runtime, o especificar por agente)

4. **Registrar** cada agente en `crew-state.json.agents[]`:

```json
{
  "id": "agent-1",
  "name": "<nombre>",
  "role": "<rol tentativo>",
  "runtime": "<runtime>",
  "discovery_complete": false,
  "build_complete": false,
  "validated": false
}
```

5. **Marcar** init como completado. Avanzar a shared discovery.

---

## Fase 2: Shared Discovery (Block B + Block C compartido)

### Contexto organizacional compartido

Los agentes de un crew comparten contexto organizacional. No tiene sentido preguntar 5 veces sobre la empresa.

1. **Ejecutar Discovery Block B** (organización) — una sola vez para todo el crew
   - Empresa, equipo, procesos, stakeholders, cultura
   - Guardar en `ask-state/org-profile.md` (compartido)

2. **Ejecutar Discovery Block C parcial** (técnico compartido) — una sola vez
   - Infraestructura compartida
   - Modelo(s) LLM disponibles
   - Integraciones existentes (APIs, DBs, MCP servers)
   - Políticas de seguridad y compliance
   - Guardar contexto técnico compartido en `ask-state/shared-technical.md`

3. **Actualizar** `crew-state.json.shared_context`

### Reglas de Discovery compartido

- Misma calidad que Discovery individual: 1-2 preguntas por turno, exigir ejemplos
- Si el operador ya tiene un `org-profile.md` de un build anterior, ofrecer reutilizarlo
- Preguntar: "Hay algo específico del contexto organizacional que difiera entre agentes?"

---

## Fase 3: Agent Discovery (Block A por agente)

### Discovery individual para cada agente

Para cada agente registrado en `crew-state.json.agents[]`:

1. **Anunciar**: "Vamos con el agente X de Y: [nombre] ([rol])"
2. **Ejecutar Discovery Block A** completo:
   - Misión y propósito específico
   - Nivel de autonomía
   - Interacciones con usuarios
   - Personalidad y tono
   - Guardrails específicos del agente
   - **ADICIONAL para crews**: "Qué necesita este agente de los otros agentes del crew? Qué les provee?"

3. **Ejecutar Discovery Block C parcial** (técnico específico):
   - Tools específicos de este agente
   - Integraciones únicas (no compartidas)
   - Memory requirements específicos

4. **Guardar** en `ask-state/agent-<id>-discovery.md`
5. **Marcar** `agents[].discovery_complete = true`

### Optimización

- Si dos agentes tienen roles similares, preguntar: "El agente X tiene un rol parecido a Y. Qué los diferencia específicamente?"
- Compartir el contexto de agentes previos: "Ya sabemos que el agente A maneja [X]. Este agente cómo se relaciona con eso?"

---

## Fase 4: Interaction Matrix

### Definir cómo se comunican los agentes

1. **Generar la matriz de interacción**:

```markdown
## Interaction Matrix

| From → To | Agent A | Agent B | Agent C |
|---|---|---|---|
| Agent A | — | Escala casos complejos | Pide datos del cliente |
| Agent B | Devuelve resolución | — | Consulta historial |
| Agent C | Responde consultas | Provee datos | — |

## Detalle por interacción

### Agent A → Agent B: Escalación
- **Trigger**: Caso excede autonomía de Agent A
- **Data transferida**: ID caso, contexto conversación, intento previo
- **Formato**: JSON handoff con schema definido
- **Protocolo**: Asíncrono vía cola de mensajes
- **Fallback**: Si Agent B no responde en 30s, notificar al operador

### Agent B → Agent A: Devolución
- **Trigger**: Agent B resuelve el caso escalado
- **Data transferida**: Resolución, acciones tomadas, recomendaciones
- **Formato**: JSON response con schema definido
```

2. **Definir la topología de coordinación**:

| Topología | Cuándo usar | Cómo funciona |
|---|---|---|
| **Supervisor** | Un agente dirige a los demás | Orchestrator recibe todo, delega, valida |
| **Peer-to-peer** | Agentes autónomos que colaboran | Cada agente decide cuándo consultar a otro |
| **Sequential** | Pipeline de procesamiento | Output de uno es input del siguiente |
| **Hybrid** | Combinación según el flujo | Supervisor para routing, P2P para colaboración |

3. **Preguntar al operador**:
   - "Qué topología describe mejor cómo deberían coordinarse?"
   - "Hay un agente que funciona como 'jefe' o coordinador?"
   - "Qué pasa si un agente del crew no está disponible?"
   - "Hay interacciones que deben ser síncronas (esperar respuesta) vs asíncronas?"

4. **Definir handoff protocol**:

```json
{
  "handoff_schema": {
    "from_agent": "string",
    "to_agent": "string",
    "type": "escalation|delegation|query|response",
    "priority": "high|medium|low",
    "context": {
      "session_id": "string",
      "conversation_summary": "string",
      "relevant_data": "object",
      "previous_attempts": "array"
    },
    "timeout_seconds": "number",
    "fallback_action": "string"
  }
}
```

5. **Guardar** en `ask-state/interaction-matrix.md`
6. **Registrar** topología en `crew-state.json.topology`

---

## Fase 5: Crew Research

### Investigación compartida + específica

1. **Research compartido** (una sola vez):
   - Dominio del crew (industria, mercado, regulaciones)
   - Patrones de multi-agente relevantes (supervisor, swarm, pipeline)
   - MCP servers disponibles para las integraciones identificadas
   - Usar las mismas fuentes que `/ask:research` pero con foco en el crew como sistema

2. **Research por agente** (breve, solo lo específico):
   - Skills y tools únicos del agente
   - Patrones de agent design relevantes al rol
   - Benchmarks o referencias para el tipo de agente

3. **Guardar**:
   - `ask-state/crew-research.md` (compartido)
   - `ask-state/agent-<id>-research.md` (por agente, solo deltas)

4. **Marcar** `crew-state.json.shared_context.research_complete = true`

---

## Fase 6: Crew Architecture

### Diseño del sistema completo

Generar `ask-state/crew-architecture.md` con:

1. **System overview** — El crew como un todo, qué problema resuelve
2. **Agent roster** — Tabla con todos los agentes, roles, runtime, modelo
3. **Interaction diagram** — Diagrama ASCII mostrando conexiones y flujos
4. **Per-agent architecture** (las 9 secciones de `/ask:architecture` pero condensadas):
   - File structure, system prompt strategy, tools, guardrails
   - Referencia a shared context vs. agent-specific context
5. **Coordination layer**:
   - Topología seleccionada con justificación
   - Handoff protocol detallado
   - Error handling entre agentes
   - Timeout y fallback strategies
6. **Shared memory layer**:
   - Qué se comparte entre agentes (shared vault, shared hot-context)
   - Qué es privado por agente
   - Protocolo de escritura concurrente (quién puede escribir dónde)
7. **Cost and performance estimation** (del crew completo):
   - Cost per agent + cost de coordinación
   - Latency analysis (path más largo del crew)
   - Volumen esperado y costo mensual total
8. **Deployment topology**:
   - Cómo se despliegan los agentes (mismo host, containers separados, etc.)
   - Orden de deployment (dependencias)
   - Health check del crew (no solo agentes individuales)

### Approval Gate

**BLOQUEAR avance a build hasta aprobación explícita del operador.**

Mostrar:
- Resumen del crew architecture
- Cost estimation
- Interaction matrix
- Riesgos identificados

Preguntar: "Aprobás esta arquitectura para el crew [nombre]? (sí/no/ajustes)"

---

## Fase 7: Crew Build

### Generación batch de archivos

1. **Generar archivos compartidos** primero:
   - `shared/org-profile.md`
   - `shared/guardrails-base.md` (guardrails comunes)
   - `shared/handoff-protocol.md`
   - `shared/memory/` directory structure

2. **Para cada agente**, ejecutar la lógica de `/ask:build`:
   - Leer templates del runtime correspondiente
   - Resolver variables desde discovery + research + architecture del agente
   - Incorporar referencia a archivos compartidos
   - Generar en `output/<crew-name>/<agent-name>/`

3. **Generar archivos de coordinación**:
   - `output/<crew-name>/CREW.md` — Overview del crew, roster, topología
   - `output/<crew-name>/HANDOFFS.md` — Protocolo de handoffs con schemas
   - `output/<crew-name>/shared-memory/` — Estructura de memoria compartida

4. **Generar file manifest**:
   - `ask-state/crew-file-manifest.json` con todos los archivos generados

5. **Post-check**: Verificar que no haya `{{VARIABLE}}` sin resolver en ningún archivo

6. **Marcar** cada agente como `build_complete = true`

---

## Fase 8: Crew Validate

### Validación individual + sistémica

1. **Validación por agente** — Ejecutar `validate-agent.sh` para cada agente:
   ```bash
   for agent_dir in output/<crew-name>/*/; do
     ./scripts/validate-agent.sh "$agent_dir"
   done
   ```

2. **Validación de crew** — Checks adicionales:

| Check | Qué verifica |
|---|---|
| **Handoff consistency** | Si Agent A dice "escalo a Agent B", Agent B tiene handler para eso |
| **Shared memory access** | Todos los agentes referencian el shared memory correctamente |
| **Guardrail alignment** | Guardrails base están presentes en todos los agentes |
| **Tool coverage** | Cada interacción del matrix tiene las tools necesarias en ambos lados |
| **No circular dependencies** | El grafo de dependencias no tiene ciclos sin exit condition |
| **Fallback coverage** | Cada handoff tiene fallback definido |
| **Naming consistency** | Los agentes se refieren unos a otros con los mismos nombres |

3. **Generar crew validation report**:
   - Individual results per agent
   - Crew-level results
   - Interaction test scenarios (manual — el operador los ejecuta)

4. **Marcar** `crew-state.json.phases.validate.status = "completed"`

---

## State Management

### crew-state.json

El estado del crew se persiste en `ask-state/crew-state.json`. Siempre leerlo antes de cualquier operación del crew.

### Archivos generados durante el crew build

```
ask-state/
├── crew-state.json              # Estado del crew build
├── org-profile.md               # Compartido
├── shared-technical.md          # Contexto técnico compartido
├── interaction-matrix.md        # Matriz de interacciones
├── crew-research.md             # Research compartido
├── crew-architecture.md         # Arquitectura del crew
├── crew-file-manifest.json      # Manifest de archivos generados
├── agent-<id>-discovery.md      # Discovery por agente
├── agent-<id>-research.md       # Research específico por agente
└── crew-validation-report.md    # Reporte de validación del crew

output/
└── <crew-name>/
    ├── CREW.md                  # Overview del crew
    ├── HANDOFFS.md              # Protocolo de handoffs
    ├── shared-memory/           # Memoria compartida
    │   ├── vault/
    │   └── hot-context/
    ├── <agent-1>/               # Archivos del agente 1 (runtime-specific)
    ├── <agent-2>/               # Archivos del agente 2
    └── <agent-N>/               # Archivos del agente N
```

---

## Reglas

1. **Shared context first** — Siempre resolver contexto compartido antes del específico
2. **No duplicar** — Si algo es compartido, se genera una vez y se referencia
3. **Approval gate** — El crew architecture requiere aprobación explícita, igual que agent architecture
4. **Validación sistémica** — Validar agentes individuales Y el crew como sistema
5. **Handoffs son contracts** — El handoff protocol es un contrato entre agentes; ambos lados deben implementarlo
6. **Fallback siempre** — Cada interacción del crew debe tener fallback definido
7. **Un crew, un runtime** — Recomendado pero no obligatorio. Si hay mixed runtimes, documentar el protocolo de comunicación cross-runtime

---

## Integración con comandos existentes

| Comando ASK | Comportamiento con crew activo |
|---|---|
| `/ask:progress` | Muestra estado del crew + estado por agente |
| `/ask:skip` | Permite saltar fase del crew (con warning reforzado) |
| `/ask:resume` | Retoma el crew build donde quedó |
| `/ask:export <path>` | Exporta todo el crew (todos los agentes + shared files) |
| `/ask:iterate` | Puede iterar un agente específico o el crew completo |
| `/ask:validate` | Re-ejecuta validación del crew completo |
