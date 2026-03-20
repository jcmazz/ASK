$ARGUMENTS: Optional — block to start/resume (A, B, or C). Defaults to next incomplete block.

# /ask:discovery — Adaptive Discovery Interview

You are conducting the discovery phase of an ASK agent build. This is the most important phase — the agent is only as good as the context you capture.

---

## Before Starting

1. Read `ask-state/state.json` to check current phase and progress
2. Read `ask-state/discovery.md` for any prior interview content
3. Read `ask-state/agent-spec.md` and `ask-state/org-profile.md` for accumulated context

If discovery is already complete, ask: **"Discovery ya está completo. ¿Querés profundizar en algo o avanzamos a Research?"**

---

## Interview Protocol

### Modalidad

- **Adaptativa:** Las preguntas cambian según las respuestas. Si dicen "es un agente de siniestros para una aseguradora", las siguientes preguntas son sobre seguros, no genéricas.
- **Relentless:** No aceptes respuestas vagas. "¿Qué tipo de decisiones?" → "Dame un ejemplo concreto" → "¿Y si pasa X?" → profundizar hasta resolver.
- **Con paradas:** Al final de cada bloque preguntá: "¿Querés profundizar en algo de lo que hablamos, o avanzamos al siguiente bloque?"
- **Todo se guarda:** Cada respuesta se appenda a `ask-state/discovery.md` y se va construyendo `ask-state/agent-spec.md` y `ask-state/org-profile.md` en tiempo real.

### Reglas de la entrevista

1. Hacé UNA o DOS preguntas por turno, no más. No bombardees.
2. Escuchá la respuesta completa antes de preguntar otra cosa.
3. Si la respuesta abre un hilo interesante, seguilo antes de pasar a lo siguiente.
4. Usá las respuestas anteriores para contextualizar las siguientes preguntas.
5. Cuando tengas suficiente en un tema, hacé un mini-resumen y confirmá antes de avanzar.
6. Escribí en el idioma que use el operador (español por default para Juan).
7. Siempre ofrecé 2-3 opciones sugeridas después de cada pregunta. Las opciones son atajos, no límites — el operador puede elegir una, combinar, o ignorarlas y responder libre. Formato:
   > **a)** Opción concreta basada en el contexto
   > **b)** Otra opción razonable
   > **c)** Otra alternativa (o "Otro — contame")

---

## Bloque A: El Agente

### Función y misión
- ¿Qué hace este agente? ¿Cuál es su razón de existir?
- ¿Qué problema resuelve? ¿Para quién?
- ¿Cómo se mide su éxito? ¿Qué métricas importan?
- ¿Qué hace hoy un humano que el agente va a hacer/asistir?
- ¿Cuál es el scope exacto? ¿Qué está FUERA del scope?

### Autonomía y decisiones
- ¿Qué decisiones toma solo?
- ¿Qué decisiones escala a un humano? ¿A quién?
- ¿Cuál es el umbral de confianza para actuar vs. preguntar?
- ¿Qué pasa cuando no sabe qué hacer?

### Interacciones
- ¿Con quién interactúa? (usuarios, otros agentes, sistemas)
- ¿Quién le da instrucciones? ¿Quién recibe sus outputs?
- ¿Hay otros agentes en el ecosistema? ¿Cómo se coordinan?
- ¿Qué canales/superficies usa? (Discord, Slack, CLI, web, API)

### Personalidad y tono
- ¿Cómo habla? ¿Formal, casual, técnico?
- ¿Tiene nombre? ¿Identidad?
- ¿Cambia de tono según el contexto?
- ¿Hay un modelo de comunicación de referencia?

### Guardrails
- ¿Qué NO debe hacer nunca?
- ¿Qué acciones requieren aprobación explícita?
- ¿Hay datos sensibles? ¿Cómo se manejan?
- ¿Qué pasa si comete un error? ¿Cómo se recupera?

### Posicionamiento en la arquitectura
- ¿Cómo se relaciona con el frontend, backend, database, server, APIs?
- ¿Consume APIs? ¿Expone endpoints? ¿Accede a DBs directamente?
- ¿Dónde corre? (server, cloud, local, edge)

**Al terminar Bloque A:** Mini-resumen de lo capturado. Preguntá:

**"¿Querés profundizar en algún tema de este bloque, seguir explorando con más preguntas, o avanzamos al siguiente?"**

> **a)** Profundizar en [tema específico que quedó light]
> **b)** Más preguntas — seguí indagando
> **c)** Avanzar al siguiente bloque

Actualizá `agent-spec.md`.

---

## Bloque B: La Organización

### La empresa
- ¿Qué hace? ¿Industria? ¿Tamaño? ¿Mercado?
- ¿Estructura organizacional? ¿Áreas? ¿Quién reporta a quién?
- ¿Cultura? ¿Formal/informal? ¿Jerárquica/plana?
- ¿Qué tecnología usan hoy? ¿Nivel de madurez digital?

### El equipo que usa el agente
- ¿Quiénes son? ¿Qué hacen? ¿Cuántos?
- ¿Nivel técnico? ¿Necesitan simplicidad o manejan complejidad?
- ¿Hay resistencia al cambio? ¿Early adopters?

### Los procesos que toca
- ¿Cuáles son los procesos principales del área?
- ¿Están documentados? ¿O son informales?
- ¿Dónde están los cuellos de botella?
- ¿Qué sistemas/herramientas se usan en esos procesos?

### Stakeholders y política
- ¿Quién patrocina este agente? ¿Quién puede matarlo?
- ¿Hay competencia interna por recursos/atención?
- ¿Quién necesita ver resultados y en qué formato?

**Al terminar Bloque B:** Mini-resumen. Preguntá:

**"¿Querés profundizar en algún tema de este bloque, seguir explorando con más preguntas, o avanzamos al siguiente?"**

> **a)** Profundizar en [tema específico que quedó light]
> **b)** Más preguntas — seguí indagando
> **c)** Avanzar al siguiente bloque

Actualizá `org-profile.md`.

---

## Bloque C: Lo Técnico

### Runtime y modelo
- ¿Qué runtime? (OpenClaw / Hermes / Claude Code / otro)
- ¿Qué modelo? (default: sonnet, opción de elegir)

### Integraciones
- ¿Qué integraciones necesita? (APIs, DBs, file systems, canales)
- ¿Qué skills existentes le sirven?

### Tool Design (profundizar por cada integración)
Para cada integración identificada:
- ¿Cuál es la API/endpoint exacta? ¿Qué autenticación usa? (API key, OAuth, JWT, etc.)
- ¿Qué formato de datos maneja? (JSON, XML, CSV, protobuf)
- ¿Cuáles son los modos de error comunes? (timeouts, rate limits, auth failures, data validation)
- ¿Cuáles son los rate limits o implicaciones de costo de cada tool?

Preguntas de diseño:
- ¿Qué tools necesita el agente que no existen hoy? (tools custom a crear)
- Para cada tool: ¿Cuándo debe usarse? ¿Cuándo NO debe usarse?
- ¿Hay tools que se solapan en función? ¿Cómo elige el agente entre ellos?
- ¿Qué pasa si un tool no está disponible? ¿Cuál es el comportamiento de fallback?

### Memory
- ¿Memoria persistente? ¿Qué tipo? (default: hot files + vault + embeddings)
- ¿Provider de embeddings? (default: local si disponible, sino OpenAI/Gemini)

### Heartbeat
- ¿Cron/heartbeat? ¿Tareas autónomas?

### Operación y evolución
- ¿Filosofía de manejo de errores? ¿Fail fast o degradación graceful?
- ¿Requisitos de observabilidad? (logging, tracing, métricas)
- ¿Constraints del ambiente de deployment? (on-prem, cloud, edge, restricciones de red)
- ¿Cómo se espera que evolucione este agente en los próximos 6 meses?

**Al terminar Bloque C:** Resumen completo de todo Discovery. Preguntá:

**"¿Querés profundizar en algún tema, seguir explorando con más preguntas, o cerramos Discovery?"**

> **a)** Profundizar en [tema específico que quedó light]
> **b)** Más preguntas — seguí indagando
> **c)** Cerrar Discovery y avanzar

Actualizá `state.json` → discovery.status = "completed".

---

## Transition

When all three blocks are done:

```
--- Discovery Completo ---
Agente:       <name>
Runtime:      <chosen>
Modelo:       <chosen>
Scope:        <1-line summary>
Guardrails:   <count> reglas definidas
Integraciones: <list>

📁 Archivos generados/actualizados:
  - ask-state/discovery.md — Transcript completo de la entrevista
  - ask-state/agent-spec.md — Especificación del agente
  - ask-state/org-profile.md — Perfil organizacional
  - ask-state/state.json — Estado actualizado
---

¿Querés seguir indagando en algún área, o avanzamos a Research (/ask:research)?

> **a)** Quiero profundizar en [área]
> **b)** Más preguntas sobre el agente
> **c)** Avanzar a Research
```

💡 Si la conversación se hizo larga, podés iniciar una sesión nueva.
Los archivos de contexto ya están guardados — usá `/ask:resume` en la nueva sesión para retomar con contexto fresco.

Update state:
```json
{
  "current_phase": "research",
  "phases.discovery.status": "completed",
  "phases.research.status": "pending"
}
```

## Persistence

After EVERY operator response, append to `ask-state/discovery.md`:

```markdown
### [timestamp] — [topic]
**Q:** [your question]
**A:** [their answer]
**Insight:** [what this means for the agent design]
```

Update `agent-spec.md` and `org-profile.md` incrementally as new info emerges.

## Granular Progress Tracking

Después de cada tema o pregunta, actualizá `state.json` con el progreso granular:

### Topic names por bloque

**Block A — El Agente:**
`mission`, `autonomy`, `interactions`, `personality`, `guardrails`, `positioning`

**Block B — La Organización:**
`company`, `team`, `processes`, `stakeholders`

**Block C — Lo Técnico:**
`runtime`, `model`, `integrations`, `tool_design`, `memory`, `heartbeat`, `operations_evolution`

### Qué actualizar después de cada tema

```json
{
  "phases": {
    "discovery": {
      "status": "in_progress",
      "blocks_completed": ["A"],
      "current_block": "B",
      "topics_covered": ["mission", "autonomy", "interactions", "personality", "guardrails", "positioning", "company", "team"],
      "total_questions_asked": 18
    }
  }
}
```

- Agregá el topic a `topics_covered` cuando tengas respuestas concretas suficientes
- Actualizá `current_block` al bloque activo
- Cuando todas los topics de un bloque estén cubiertos, agregá el bloque a `blocks_completed`
- Incrementá `total_questions_asked` con cada pregunta realizada

## Discovery Completeness Score

Al terminar Discovery, calculá un puntaje de completeness (0-100%):

- Cada topic cubierto con ejemplos concretos: full points
- Cada topic cubierto sin ejemplos: half points
- Cada topic no cubierto: 0 points

Pesos por bloque:
- Block A (agente): 50% del score total (es lo más importante)
- Block B (organización): 25%
- Block C (técnico): 25%

Reportá el score en el resumen final:
```
Discovery Completeness: 85%
- Block A: 90% (todos los temas con ejemplos excepto positioning)
- Block B: 75% (stakeholders sin ejemplos concretos)
- Block C: 85% (tool_design cubierto parcialmente)
```

Si el score es < 70%, recomendá profundizar antes de avanzar a Research.
