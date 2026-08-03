# Recompensas — Admin/Manager (Pendiente)

**Documento:** 2026-08-02_recompensas_admin_manager_pendiente.md
**Fecha:** 2026-08-02
**Estado:** Pendiente — no implementado en esta app
**Proyecto:** StopAndGoMX-App-Flutter
**Referencias:** `docs/2026-08-02_BRD_Programa_Meritos_Organization.md`, `docs/api/2026-08-02_merit_program_api_contract.md`

---

## 1. Contexto

El módulo "Recompensas" (Programa de Méritos) se implementó en esta app Flutter solo para los roles **Player** y **Coach** (Fase 1, completada el 2026-08-02):

- `lib/modules/recompensas_player/` — Mis Recompensas, Mi saldo a favor, Reclutar amigos.
- `lib/modules/recompensas_coach/` — Captura de puntos, Ranking del mes, Prospectos, Incidencias.
- `lib/modules/recompensas_coach_score_entry/` — captura de puntos por jugador/mes.

Las funciones de **Admin/Manager** (configuración del programa, cálculo/distribución del fondo, saldo a favor a nivel staff, gestión de reclutamiento, disciplina, reportes) se decidió que vivan en un **panel web administrativo aparte**, no en esta app. El backend (Laravel) ya expone los endpoints correspondientes bajo `/api/admin/merit/*` y `/api/manager/merit/*` (ver contrato de API), pero esta app no los consume.

Este documento queda como referencia por si en el futuro se decide construir esas pantallas también aquí.

---

## 2. Funciones pendientes (si se implementaran en la app)

| # | Función | Endpoints (contrato) | Rol |
|---|---|---|---|
| 1 | Configuración del programa: % del fondo, puntaje mínimo/máximo, día de corte, modelo de distribución, % mínimo de asistencia de coach; editor de niveles (Pardo/Polar/Grizly); editor de rúbrica con validador de suma = puntaje máximo | `GET/PUT /api/admin/merit/config`, `GET /api/manager/merit/config` (solo lectura) | Admin (edita) / Manager (lee) |
| 2 | Captura y ranking a nivel manager (todas las categorías, no solo la propia); generar/recalcular snapshots | `GET/POST /api/manager/merit/players/{player}/scores`, `PUT /api/manager/merit/scores/{entry}`, `GET /api/manager/merit/snapshots`, `POST /api/manager/merit/snapshots/generate` | Manager/Admin |
| 3 | Validación del comité como Manager (contraparte del botón que ya existe para Head Coach en la app) | `POST /api/manager/merit/snapshots/{snapshot}/validate` | Manager/Admin |
| 4 | Fondo de Recompensas: calcular (total cobrado, monto del fondo, jugadores elegibles) y distribuir (tabla de resultado por jugador) | `GET/POST /api/manager/merit/funds`, `POST /api/manager/merit/funds/{fund}/distribute` | Manager/Admin |
| 5 | Saldo a favor: buscador de jugador, historial, aplicar saldo manualmente a un pago pendiente | `GET/POST /api/manager/merit/credit-ledger/{player}` | Manager/Admin |
| 6 | Reclutamiento: lista completa de prospectos (filtro por estatus/coach/jugador), confirmar inscripción/retención/rechazo, ver etapas con montos, marcar etapa pagada | `GET /api/manager/merit/prospects`, `PATCH /api/manager/merit/prospects/{prospect}/status`, `GET /api/manager/merit/prospects/{prospect}/stages`, `POST /api/manager/merit/prospects/{prospect}/stages/{stage}/mark-paid` | Manager/Admin |
| 7 | Disciplina: lista de incidencias por coach (badge de reincidencia), resolver (sanción + expulsión) | `GET /api/manager/merit/incidents`, `PATCH /api/manager/merit/incidents/{incident}` | Manager/Admin |
| 8 | Reportes: historial de jugador (snapshots + ledger), reporte de reclutamiento por coach | `GET /api/manager/merit/reports/players/{player}`, `GET /api/manager/merit/reports/recruitment` | Manager/Admin |

---

## 3. Notas técnicas si se retoma

- **Patrón a seguir**: mismo enfoque que Player/Coach — modelos en `lib/core/models/merit/` (ya existen y son reutilizables tal cual: `MeritConfig`, `MeritSnapshot`, `MeritFund` *(nuevo, no existe todavía)*, `MeritCreditLedgerEntry`, `MeritProspect`, `MeritPaymentStage`, `MeritIncident`), métodos nuevos en `ApiRepository` bajo la sección `/// ---- MERIT PROGRAM (RECOMPENSAS) ----` ya existente, gating por `org.meritProgramEnabled` + rol admin/manager (`isAdminRole`/`hasManagerPrivileges` de `lib/core/utils/role_utils.dart`).
- **Falta un modelo `MeritFund`/`MeritFundDistribution`** — no se creó en la Fase 1 porque no era necesario para Player/Coach.
- **Gaps ya documentados en la Fase 1** que también aplicarían aquí:
  - No hay endpoint de subida de archivo para `evidence_path` (se maneja como texto libre en las pantallas de coach).
  - No hay forma de saber desde el frontend si un usuario es Head Coach de una categoría — para Manager esto no aplica igual, pero si se construye la vista combinada de aprobación conviene revisar si el backend ahora expone algún campo adicional.
- **Endpoints de reclutamiento/disciplina para manager** son de solo lectura ampliada + acciones de resolución — no requieren nuevos modelos, los ya creados (`MeritProspect`, `MeritPaymentStage`, `MeritIncident`) ya incluyen los campos con montos, que en la vista de coach se ocultan pero para manager sí deben mostrarse.

---

## 4. Siguiente paso si se decide construirlo aquí

Repetir el ciclo de planeación (EnterPlanMode) tomando este documento como punto de partida, ya que el contrato de API y los modelos base ya existen — el trabajo se concentraría en las 8 pantallas nuevas y su gating por rol, no en la capa de datos desde cero.
