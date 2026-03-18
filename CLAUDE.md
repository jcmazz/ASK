# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# ASK — Agent Setup Kit

ASK es para agentes lo que GSD es para código. Un framework por fases para crear agentes optimizados, con contexto organizacional profundo, memory layer anti-amnesia, y skills auditados.

## Idioma

Comunicar en español (Argentina) por default. Código y archivos técnicos en inglés.

## Comandos

Todos los comandos están en `commands/`. Usá `/ask:<comando>`:

| Comando | Qué hace |
|---|---|
| `/ask:new <nombre>` | Arranca un agente nuevo |
| `/ask:discovery` | Entrevista adaptativa de discovery (3 bloques: A=agente, B=org, C=técnico) |
| `/ask:research` | Deep research (dominio, skills, arquitectura) |
| `/ask:architecture` | Diseño completo del agente (9 componentes) |
| `/ask:build` | Genera archivos, skills, memory layer |
| `/ask:validate` | Testing (checklist + smoke test + eval) |
| `/ask:iterate` | Ajustes basados en feedback |
| `/ask:progress` | Estado actual del build |
| `/ask:skip` | Saltar fase (con warning) |
| `/ask:resume` | Retomar donde quedó |
| `/ask:export <path>` | Exportar archivos del agente |
| `/ask:crew <nombre> <n>` | Crear un crew de N agentes coordinados |

## Pipeline y dependencias

```
Single agent:
  new → discovery → research → architecture → [APPROVAL GATE] → build → validate → iterate → done

Multi-agent crew:
  crew:init → crew:shared-discovery → crew:agent-discovery → crew:interaction-matrix
      → crew:research → crew:architecture → [APPROVAL GATE] → crew:build → crew:validate
```

- **discovery** es el entry point obligatorio (new lo inicia automáticamente)
- **research** requiere discovery completado (avisa si se salteó)
- **architecture** requiere research completado
- **build** BLOQUEA si architecture no está aprobada — es el único hard gate
- **validate** corre automáticamente después de build
- **iterate** es un loop hasta que el operador diga "listo" / "ship it"
- **progress**, **skip**, **resume** son cross-cutting (funcionan en cualquier momento)
- **export** solo después de build
- **crew** es un flujo paralelo que orquesta los comandos existentes para multi-agente
  - Estado propio en `ask-state/crew-state.json`
  - Genera archivos compartidos + por agente en `output/<crew-name>/`

## Template Development

Los templates usan `{{VARIABLE}}` y `{{#BLOCK}}...{{/BLOCK}}` syntax. La referencia completa de variables y su mapeo a fases de Discovery está en `references/openclaw-conventions.md` (sección "Template Variable Mapping").

El build genera un `ask-state/file-manifest.json` con la lista exacta de archivos generados y sus paths — el export command lee este manifest.

## Pre-flight Check

Antes de arrancar un build, correr `./scripts/preflight-check.sh` para verificar que el framework está intacto y las tools necesarias están disponibles.

## Estado

El estado se persiste en `ask-state/state.json`. **Siempre leerlo antes de cualquier operación.**

### Archivos de estado (en `ask-state/`)

| Archivo | Cuándo se crea | Quién lo escribe |
|---|---|---|
| `state.json` | `new` | Todos los comandos |
| `discovery.md` | `new` (placeholder) | `discovery` (transcript con Q/A/Insight) |
| `agent-spec.md` | `new` (placeholder) | `discovery` (spec incremental) |
| `org-profile.md` | `new` (placeholder) | `discovery` + `research` |
| `research.md` | `research` | `research` |
| `architecture.md` | `architecture` | `architecture` (incluye `Approved: pending/yes`) |
| `build-log.md` | `build` | `build` |
| `validation-report.md` | `validate` | `validate` + `iterate` |

## Runtimes y outputs

Cada runtime genera archivos distintos:

- **OpenClaw** (primary): SOUL.md, IDENTITY.md, USER.md, MEMORY.md, TOOLS.md, AGENTS.md, HEARTBEAT.md, config.yaml
- **Claude Code standalone**: CLAUDE.md, .claude/settings.json, .claude/commands/, .claude/skills/
- **Hermes**: agent.json, tools.json, system-prompt.md

Todos los runtimes incluyen knowledge layer: `memory/vault/`, `memory/hot-context/`, `memory/.embeddings/`

Templates por runtime en `templates/{openclaw,claude-code,hermes,common}/`.

## Scripts

| Script | Qué hace |
|---|---|
| `scripts/validate-agent.sh` | Validación técnica de un agente construido (Level 1 checklist) |
| `scripts/skill-audit.sh` | Auditoría de skills disponibles |
| `scripts/preflight-check.sh` | Verificación pre-build del framework ASK |

## Principios

1. Discovery-driven — a mejor entrevista, mejor agente
2. Secuencial con paradas — nunca avanza solo
3. Salteable — pero advierte
4. Conversacional — los comandos son atajos, no muros
5. Anti-amnesia by design — memory layer desde el minuto cero
6. Best practices agnósticas — el output se adapta al runtime
7. Siempre revisable — se puede volver atrás

## Reglas críticas

- **No placeholders en build**: cada archivo generado debe ser production-ready con contenido real de Discovery+Research+Architecture
- **Architecture approval gate**: nunca avanzar a build sin aprobación explícita del operador
- **Discovery adaptativa**: 1-2 preguntas por turno, exigir ejemplos concretos, no aceptar respuestas vagas
- **State-first**: leer `state.json` antes de cualquier operación, actualizar después de completar fase o decisión
- **Decisiones auditables**: cada decisión se logea en `state.json.decisions[]` con timestamp
