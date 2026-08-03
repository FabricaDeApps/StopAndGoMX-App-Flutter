# Programa de Méritos — Contrato de API para Frontend

**Fecha:** 2026-08-02
**Módulo:** Programa de Méritos (evaluación de jugadores, Fondo de Mérito, saldo a favor, reclutamiento)
**BRD de referencia:** `docs/2026-08-02_BRD_Programa_Meritos_Organization.md`
**Autenticación:** Bearer Token (Sanctum) en todos los endpoints

---

## Índice

1. [Resumen y flag de habilitación](#1-resumen-y-flag-de-habilitación)
2. [Convenciones generales](#2-convenciones-generales)
3. [Resumen de accesos por rol](#3-resumen-de-accesos-por-rol)
4. [Objetos reutilizables](#4-objetos-reutilizables)
5. [API — Config del programa](#5-api--config-del-programa)
6. [API — Manager (panel admin/manager)](#6-api--manager-panel-adminmanager)
7. [API — Coach](#7-api--coach)
8. [API — Player (app jugador)](#8-api--player-app-jugador)
9. [Códigos de error frecuentes](#9-códigos-de-error-frecuentes)
10. [Pantallas esperadas por rol](#10-pantallas-esperadas-por-rol)
11. [Notas de implementación importantes](#11-notas-de-implementación-importantes)

---

## 1. Resumen y flag de habilitación

El Programa de Méritos es un módulo **opt-in por organización**. Antes de mostrar cualquier pantalla de este módulo, el frontend debe verificar el flag `merit_program_enabled` de la organización activa:

```
GET /api/public/organization/{orgId}
GET /api/public/organizations
```

Ambos ya devuelven el campo `merit_program_enabled: boolean` junto a `gazetta_enabled` y `social_module`. **Si es `false`, todos los endpoints de este módulo responden `403`** — no debe navegarse a ninguna pantalla del programa.

El flag lo activa/desactiva el equipo de StopAndGoMX desde el panel super-admin (no es autoservicio de la organización).

---

## 2. Convenciones generales

- **Headers requeridos:** `Authorization: Bearer {token}` + `X-Organization-Id: {orgId}`.
- **Formato de fechas:** `period_month` siempre es el primer día del mes (`YYYY-MM-01`). Se puede enviar cualquier fecha del mes en los filtros; el backend normaliza a `startOfMonth()`.
- **Montos:** todos los campos `*_mxn` son `decimal` (string o número según el driver de JSON; tratarlos como número con 2 decimales).
- **Envoltura de respuesta:** la mayoría de endpoints regresan `{ "data": ..., "message"?: "..." }`. Los que no siguen ese shape exacto están marcados explícitamente abajo.
- **Rol `admin`/`superadmin`** tiene acceso equivalente a `manager` en todos los endpoints de este módulo (se valida con el mismo helper `userHasAnyRole`).

---

## 3. Resumen de accesos por rol

| Rol | Base URL | Puede |
|---|---|---|
| **Admin/Manager** | `/api/manager/merit/*` (+ `/api/admin/merit/config` para escritura de config) | Ver config (solo `admin` puede **editarla**), capturar y validar puntaje de cualquier jugador, calcular/distribuir el fondo, aplicar saldo a favor, gestionar reclutamiento y disciplina, ver reportes |
| **Coach** | `/api/coach/merit/*` | Capturar puntaje de sus categorías asignadas (sin validar el snapshot final salvo que sea Head Coach), validar snapshot solo si es Head Coach de la categoría del jugador, registrar y ver sus propios prospectos, reportar incidencias |
| **Player** | `/api/player/merit/*` | Ver su propio puntaje/nivel/historial, ver su saldo a favor, registrarse como jugador reclutador de un prospecto y ver los suyos |

**Ningún coach puede modificar el puntaje final ni validar el snapshot en solitario** — se requiere aprobación de Head Coach **y** Manager por separado (dos llamadas independientes a `snapshots/{id}/validate`).

**Los montos de reclutamiento (`amount_mxn` en `payment_stages`) nunca se exponen a `coach` ni `player`** — el backend los devuelve como `null` para esos roles, incluso dentro del mismo objeto que sí ve un admin/manager.

---

## 4. Objetos reutilizables

### Config Object (`GET .../merit/config`)

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | `integer\|undefined` | Ausente si `is_default = true` (org sin config guardada aún) |
| `organization_id` | `integer` | |
| `season_id` | `integer\|null` | `null` = config default de la organización (no ligada a una temporada específica) |
| `fund_percentage` | `decimal` | % del fondo mensual (default `15.00`) |
| `min_score_to_participate` | `integer` | Puntaje mínimo para el fondo (default `80`) |
| `max_base_score` | `integer` | Puntaje base máximo (default `100`) |
| `distribution_model` | `string` | `equal` \| `by_participation` |
| `level_thresholds` | `array` | `[{ name, min, max, participation_weight }]` — ver ejemplo abajo |
| `rubric_weights` | `object` | Estructura anidada por rubro/sub-rubro — ver ejemplo abajo |
| `cutoff_day_of_month` | `integer` | Día del mes del corte (1-28) |
| `coach_min_attendance_percentage` | `decimal` | % mínimo de asistencia (check-in) que debe mantener un coach para conservar el beneficio de reclutamiento (default `80.00`) |
| `is_active` | `boolean` | |

```json
{
  "data": {
    "organization_id": 1,
    "season_id": null,
    "fund_percentage": "15.00",
    "min_score_to_participate": 80,
    "max_base_score": 100,
    "distribution_model": "equal",
    "level_thresholds": [
      { "name": "pardo", "min": 80, "max": 84, "participation_weight": 1 },
      { "name": "polar", "min": 85, "max": 89, "participation_weight": 2 },
      { "name": "grizly", "min": 90, "max": 100, "participation_weight": 3 }
    ],
    "rubric_weights": {
      "compromiso_disciplina": {
        "total": 30,
        "items": { "asistencia": 15, "puntualidad": 10, "instalaciones": 5 }
      },
      "desarrollo_individual": {
        "total": 25,
        "items": { "fisico": 10, "tecnico": 10, "sistema": 5 }
      },
      "contribucion_manada": {
        "total": 25,
        "items": { "trabajo_equipo": 10, "servicio_apoyo": 7, "representacion": 8 },
        "extra_max": 15
      },
      "rendimiento_deportivo": {
        "total": 20,
        "items": { "asignaciones": 8, "esfuerzo": 5, "produccion": 5, "rol": 2 }
      }
    },
    "cutoff_day_of_month": 1,
    "coach_min_attendance_percentage": "80.00",
    "is_active": true
  },
  "is_default": false
}
```

> `rubric_weights.contribucion_manada.extra_max` es el tope de los puntos **extra** de reclutamiento (`reclutamiento_extra`), que **no cuentan** para `max_base_score`.

### Rubric Item — valores válidos

`asistencia` (auto-calculado, no capturable a mano) · `puntualidad` · `instalaciones` · `fisico` · `tecnico` · `sistema` · `trabajo_equipo` · `servicio_apoyo` · `representacion` · `reclutamiento_extra` · `asignaciones` · `esfuerzo` · `produccion` · `rol`

### Score Entry Object

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | `integer` | |
| `player_id` | `integer` | |
| `category_id` | `integer` | |
| `season_id` | `integer` | |
| `rubric_category` | `string` | `compromiso_disciplina` \| `desarrollo_individual` \| `contribucion_manada` \| `rendimiento_deportivo` |
| `rubric_item` | `string` | ver tabla arriba |
| `points` | `decimal` | |
| `is_extra_point` | `boolean` | `true` solo para `reclutamiento_extra` |
| `period_month` | `date` | |
| `entered_by` | `object` | `{ id, name }` (via `with('enteredBy:id,name')`) |
| `reason` | `string\|null` | |
| `evidence_path` | `string\|null` | |

### Snapshot Object

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | `integer` | |
| `player_id` | `integer` | |
| `period_month` | `date` | |
| `total_score` | `decimal` | Suma de rubros, tope en `max_base_score` |
| `extra_points` | `decimal` | Puntos extra de reclutamiento (fuera del total) |
| `merit_level` | `string` | `pardo` \| `polar` \| `grizly` \| `none` |
| `is_fund_eligible` | `boolean` | `total_score >= min_score_to_participate` |
| `validated_by_head_coach_id` / `validated_by_manager_id` | `integer\|null` | |
| `validated_at` / `locked_at` | `datetime\|null` | `locked_at != null` ⇒ **inmutable**, ya no admite nuevas entradas de puntaje |
| `breakdowns` | `array` | `[{ rubric_item, points_earned, points_possible }]` |
| `player` | `object` | `{ id, first_name, last_name, photo }` (solo en listados manager/coach) |
| `validated_by_head_coach` / `validated_by_manager` | `object\|null` | `{ id, name }` |

### Fund Object

| Campo | Tipo | Descripción |
|---|---|---|
| `id`, `organization_id`, `season_id` | | |
| `period_month` | `date` | |
| `total_collected_mxn` | `decimal` | Suma de `payment_receipts` del mes (no el nominal de `Payment`) |
| `fund_amount_mxn` | `decimal` | `total_collected_mxn × fund_percentage / 100` |
| `eligible_players_count` | `integer` | Jugadores con snapshot **validado y bloqueado** + `is_fund_eligible=true` al momento del cálculo |
| `distribution_model_used` | `string` | |
| `status` | `string` | `calculated` \| `distributed` |
| `distributions` | `array` | Solo presente tras distribuir — `[{ player, merit_level, participation_weight, share_amount_mxn }]` |

### Credit Ledger Entry Object

| Campo | Tipo | Descripción |
|---|---|---|
| `id`, `player_id` | | |
| `entry_type` | `string` | `credit` \| `debit` |
| `amount_mxn` | `decimal` | |
| `balance_after_mxn` | `decimal` | Saldo corriente después de este movimiento (usar el más reciente para el saldo actual) |
| `source_type` | `string` | `merit_fund` \| `manual_adjustment` \| `refund` |
| `applied_to_type` | `string\|null` | `payment` cuando se aplicó a un pago |
| `applied_to_payment_id` | `integer\|null` | |
| `created_at` | `datetime` | |

### Prospect Object

| Campo | Tipo | Descripción |
|---|---|---|
| `id`, `full_name`, `status` | | `status`: `registered` \| `trial` \| `enrolled` \| `retained` \| `rejected` |
| `recruited_by_coach` | `object\|null` | `{ id, name }` — exclusivo con `recruited_by_player` |
| `recruited_by_player` | `object\|null` | `{ id, first_name, last_name }` |
| `enrolled_player_id`, `enrolled_at`, `retention_confirmed_at` | | |
| `payment_stages` | `array` | ver Payment Stage Object |

### Payment Stage Object

| Campo | Tipo | Descripción |
|---|---|---|
| `id`, `stage` | | `stage`: `enrollment` \| `retention_4wk` |
| `status` | `string` | `pending` \| `eligible` \| `paid` \| `forfeited` |
| `eligible_at`, `paid_at` | `datetime\|null` | |
| `amount_mxn` | `decimal\|null` | **`null` siempre para `coach`/`player`**, visible solo para `admin`/`manager` |

### Incident Object

| Campo | Tipo | Descripción |
|---|---|---|
| `id`, `coach`, `player`, `reported_by` | | `coach`/`player`/`reported_by` son `{ id, name }` / `{ id, first_name, last_name }` |
| `incident_type` | `string` | `physical` \| `verbal` \| `other` |
| `description`, `sanction_applied` | `string\|null` | |
| `is_repeat` | `boolean` | Calculado automáticamente (¿existe una incidencia previa del mismo coach?) |
| `resulted_in_expulsion` | `boolean` | Lo marca manualmente el manager/admin al resolver |
| `occurred_at` | `datetime` | |

---

## 5. API — Config del programa

| Método | Ruta | Rol |
|---|---|---|
| `GET` | `/api/admin/merit/config` | `admin` |
| `PUT` | `/api/admin/merit/config` | `admin` (**la escritura de config es exclusiva de `admin`**, ver BRD §4) |
| `GET` | `/api/manager/merit/config` | `manager`/`admin` (solo lectura) |
| `GET` | `/api/coach/merit/config` | `coach` (solo lectura, para pintar niveles/rúbrica en la app) |
| `GET` | `/api/player/merit/config` | `player` (solo lectura) |

Si la organización no ha guardado configuración, `GET` regresa `is_default: true` con los valores por defecto de BEARS — el formulario de admin debe precargarlos como editables, no como placeholder vacío.

### `PUT /api/admin/merit/config` — body

```json
{
  "season_id": null,
  "fund_percentage": 15,
  "min_score_to_participate": 80,
  "max_base_score": 100,
  "distribution_model": "equal",
  "level_thresholds": [
    { "name": "pardo", "min": 80, "max": 84, "participation_weight": 1 },
    { "name": "polar", "min": 85, "max": 89, "participation_weight": 2 },
    { "name": "grizly", "min": 90, "max": 100, "participation_weight": 3 }
  ],
  "rubric_weights": { "...": "mismo shape que el Config Object" },
  "cutoff_day_of_month": 1,
  "coach_min_attendance_percentage": 80,
  "is_active": true
}
```

**Validación crítica:** la suma de `rubric_weights.*.total` debe ser exactamente igual a `max_base_score`, si no, `422` con:

```json
{ "message": "La suma de los totales por rubro (95) debe ser igual al puntaje base maximo (100)." }
```

---

## 6. API — Manager (panel admin/manager)

Base: `/api/manager/merit`

### 6.1 Captura de puntaje

| Método | Ruta | Descripción |
|---|---|---|
| `GET` | `players/{player}/scores?period_month=` | Lista entradas del jugador en el mes |
| `POST` | `players/{player}/scores` | Crea una entrada |
| `PUT` | `scores/{entry}` | Edita una entrada (requiere `reason`) |

**`POST players/{player}/scores` — body:**

```json
{
  "category_id": 7,
  "season_id": 12,
  "rubric_item": "puntualidad",
  "points": 10,
  "is_extra_point": false,
  "period_month": "2026-08-01",
  "reason": "Cumplio con todos los requisitos administrativos",
  "evidence_path": null
}
```

- `rubric_item = "asistencia"` es **rechazado con 422** — ese rubro se calcula solo desde el módulo de check-in de jugadores (`attendances`).
- Si el snapshot del jugador para ese `period_month` ya está `locked_at != null`, cualquier `POST`/`PUT` regresa **422**.

**`PUT scores/{entry}` — body:** `{ points, reason (requerido), evidence_path? }`. El `reason` es obligatorio para toda edición — queda auditado.

### 6.2 Snapshots mensuales (ranking + validación)

| Método | Ruta | Descripción |
|---|---|---|
| `GET` | `snapshots?period_month=` | Ranking del mes, ordenado por `total_score desc` |
| `POST` | `snapshots/generate` | Genera/recalcula snapshots (idempotente mientras no estén bloqueados) |
| `POST` | `snapshots/{snapshot}/validate` | Registra la aprobación del comité |

**`POST snapshots/generate` — body:**

```json
{
  "period_month": "2026-08-01",
  "season_id": 12,
  "category_id": null,
  "player_id": null
}
```

`season_id` es opcional — si se omite, usa la temporada `active` de la organización. `category_id`/`player_id` opcionales para acotar el recálculo. Respuesta:

```json
{
  "message": "23 snapshot(s) generado(s).",
  "generated_snapshot_ids": [101, 102, "..."],
  "skipped_locked_player_ids": [98],
  "period_month": "2026-08-01",
  "season_id": 12
}
```

**`POST snapshots/{snapshot}/validate`** — no requiere body. La respuesta indica si quedó bloqueado:

```json
{
  "data": { "...Snapshot Object con locked_at ya seteado o no..." },
  "message": "Snapshot validado y bloqueado (aprobacion completa)."
}
```

o, si falta la segunda aprobación:

```json
{ "message": "Aprobacion registrada. Falta la aprobacion del otro miembro del comite." }
```

> El backend detecta automáticamente si quien llama es Head Coach (`coach_category.coach_role = 'head_coach'` en la categoría del jugador) y/o Manager/Admin, y aplica la aprobación correspondiente. Un mismo usuario **no puede** completar las dos aprobaciones si no cumple ambos roles.

### 6.3 Fondo de Mérito

| Método | Ruta | Descripción |
|---|---|---|
| `GET` | `funds?period_month=` | Lista fondos (con `distributions` si ya se distribuyó) |
| `POST` | `funds` | Calcula/recalcula el fondo del mes |
| `POST` | `funds/{fund}/distribute` | Distribuye entre jugadores elegibles (una sola vez) |

**`POST funds` — body:** `{ period_month: "2026-08-01", season_id?: 12 }`.

- Recalcular un fondo ya `status: "distributed"` regresa **422**.
- `eligible_players_count` solo cuenta jugadores con snapshot **validado y bloqueado**; si aún no validas snapshots, el fondo se calcula con `eligible_players_count: 0` (el total/monto sí se calcula igual, es independiente).

**`POST funds/{fund}/distribute`** — sin body. Si no hay snapshots elegibles+bloqueados, `422 "No hay jugadores elegibles con snapshot validado para distribuir el fondo."`.

### 6.4 Saldo a favor (crédito)

| Método | Ruta | Descripción |
|---|---|---|
| `GET` | `credit-ledger/{player}` | Historial + saldo actual |
| `POST` | `credit-ledger/{player}` | Aplica saldo a un pago pendiente |

**`GET credit-ledger/{player}`:**

```json
{
  "data": [ "...Credit Ledger Entry Object[]..." ],
  "current_balance_mxn": 150
}
```

**`POST credit-ledger/{player}` — body:**

```json
{ "payment_id": 9001, "amount_mxn": 100, "notes": "Aplicado a mensualidad de septiembre" }
```

`amount_mxn` es opcional — si se omite, el backend aplica `min(saldo_disponible, balance_del_pago)` automáticamente. Esto **crea un `PaymentDiscount` real** sobre el `Payment` (el balance del pago baja de verdad, no es solo una anotación). Respuesta:

```json
{
  "data": { "...Credit Ledger Entry (debit)..." },
  "current_balance_mxn": 50,
  "payment_balance_mxn": 400,
  "message": "Saldo a favor aplicado al pago."
}
```

Errores 422 posibles: `"El monto a aplicar debe ser mayor a cero."`, `"El jugador no tiene saldo a favor suficiente."`, `"El monto excede el saldo pendiente de este pago."`.

### 6.5 Reclutamiento

| Método | Ruta | Descripción |
|---|---|---|
| `GET` | `prospects` | Todos los prospectos de la organización |
| `PATCH` | `prospects/{prospect}/status` | Confirma inscripción / retención / rechazo |
| `GET` | `prospects/{prospect}/stages` | Etapas con `amount_mxn` visible |
| `POST` | `prospects/{prospect}/stages/{stage}/mark-paid` | Marca etapa pagada (solo auditoría, el pago real es externo) |

**`PATCH prospects/{prospect}/status` — body:**

```json
{ "status": "enrolled", "enrolled_player_id": 456 }
```

`status`: `enrolled` | `retained` | `rejected`. `enrolled_player_id` opcional, solo aplica con `enrolled`.

- `retained` antes de cumplirse **4 semanas** desde `enrolled_at` regresa `422` con la fecha exacta en que estará disponible.

**`POST prospects/{prospect}/stages/{stage}/mark-paid` — body:** `{ amount_mxn?: 500 }`.

- Si el prospecto fue reclutado por un **coach** y ese coach no cumple `coach_min_attendance_percentage` (calculado sobre los últimos 30 días de check-ins), regresa **422** con el detalle del % actual vs. el mínimo requerido. No aplica esta validación si fue reclutado por un jugador.

### 6.6 Disciplina

| Método | Ruta | Descripción |
|---|---|---|
| `GET` | `incidents?coach_id=` | Todas las incidencias (filtro opcional por coach) |
| `PATCH` | `incidents/{incident}` | Resuelve: `{ sanction_applied?, resulted_in_expulsion? }` |

### 6.7 Reportes

| Método | Ruta | Descripción |
|---|---|---|
| `GET` | `reports/players/{player}` | Historial completo: todos los snapshots + ledger + saldo |
| `GET` | `reports/recruitment` | Agrupado por coach: `{ coach, prospects_count, enrolled_count, retained_count, stages_paid, stages_eligible_unpaid }` |

---

## 7. API — Coach

Base: `/api/coach/merit`

Mismos endpoints que Manager para **captura de puntaje** y **snapshots**, con permisos reducidos:

| Método | Ruta | Diferencia vs. Manager |
|---|---|---|
| `GET/POST` | `players/{player}/scores` | Solo si el coach está asignado (`coach_category`) a una categoría del jugador |
| `PUT` | `scores/{entry}` | Idem |
| `GET` | `snapshots` | Ranking, solo lectura |
| `POST` | `snapshots/{snapshot}/validate` | Solo cuenta como aprobación si el coach es **Head Coach** de la categoría del jugador; si no lo es, la llamada regresa `403` |
| `GET/POST` | `prospects` | El `GET` solo regresa los prospectos que **el propio coach** registró |
| `GET` | `prospects/{prospect}/stages` | `amount_mxn` siempre `null` |
| `GET/POST` | `incidents` | El `GET` solo regresa incidencias donde el coach es el sujeto (`coach_id`) o quien reportó (`reported_by`) — nunca ve incidencias de otros coaches |
| `GET` | `config` | Solo lectura |

**`POST prospects` — body (coach):**

```json
{ "full_name": "Juan Perez", "contact_info": { "phone": "4421234567" } }
```

El backend asigna `recruited_by_coach_id` automáticamente al coach autenticado — **no se envía** en el body.

**`POST incidents` — body:**

```json
{
  "coach_id": 45,
  "player_id": 456,
  "incident_type": "verbal",
  "description": "Discusion con un jugador durante el entrenamiento",
  "occurred_at": "2026-08-01T18:30:00"
}
```

`coach_id` es el sujeto de la incidencia (puede ser distinto de quien reporta). Respuesta incluye aviso si es reincidencia:

```json
{
  "data": { "...Incident Object, is_repeat: true..." },
  "message": "Incidencia registrada. Es una reincidencia: corresponde evaluar expulsion del staff."
}
```

---

## 8. API — Player (app jugador)

Base: `/api/player/merit`

| Método | Ruta | Descripción |
|---|---|---|
| `GET` | `config` | Solo lectura, para pintar nombres de nivel / reglas del programa |
| `GET` | `me` | Puntaje actual + historial (últimos 12 meses) |
| `GET` | `me/credit-balance` | Saldo a favor + movimientos |
| `GET/POST` | `prospects` | Ver y registrar prospectos como jugador reclutador |

**`GET me`** (nota: **no** usa el envoltorio `{data: ...}`, es un shape propio):

```json
{
  "current": { "...Snapshot Object del mes mas reciente, con breakdowns..." },
  "history": [
    {
      "id": 101, "period_month": "2026-08-01", "total_score": "92.00",
      "extra_points": "5.00", "merit_level": "grizly",
      "is_fund_eligible": true, "locked_at": "2026-09-02T10:00:00Z"
    }
  ]
}
```

`current` puede ser `null` si el jugador todavía no tiene ningún snapshot generado.

**`GET me/credit-balance`** (tampoco usa `{data}`):

```json
{
  "current_balance_mxn": 150,
  "entries": [ "...Credit Ledger Entry Object[] (max 50, mas reciente primero)..." ]
}
```

**`POST prospects` — body (jugador):**

```json
{ "full_name": "Maria Lopez", "contact_info": { "phone": "4429998877" } }
```

El backend resuelve el `Player` propio del usuario autenticado (por email dentro de la organización) y asigna `recruited_by_player_id` automáticamente. Si el usuario no tiene perfil de jugador en la organización, regresa `404`.

**`GET prospects`** — regresa solo los prospectos donde `recruited_by_player_id` es el jugador propio.

---

## 9. Códigos de error frecuentes

| Código | Cuándo | Mensaje típico |
|---|---|---|
| `403` | Módulo deshabilitado para la organización | `"El Programa de Meritos no esta habilitado para esta organizacion."` |
| `403` | Rol sin permiso para la acción | `"Solo Manager o Admin pueden ..."` / `"No autorizado."` |
| `403` | Coach sin asignación a la categoría del jugador | `"No estas asignado como coach a la categoria de este jugador."` |
| `404` | Sin organización activa (`X-Organization-Id` faltante o inválido) | `"No se detecto organizacion activa."` |
| `404` | Usuario `player`/`coach` sin `Player` vinculado en la organización | `"No se encontro el perfil de jugador del usuario."` |
| `422` | Captura/edición sobre un periodo ya validado y bloqueado | `"El periodo de este jugador ya fue validado y bloqueado por el comite de merito."` |
| `422` | Intentar capturar `asistencia` manualmente | `"El rubro de asistencia se calcula automaticamente y no admite captura manual."` |
| `422` | Recalcular/distribuir un fondo ya distribuido | `"Este fondo ya fue distribuido."` |
| `422` | Retener un prospecto antes de las 4 semanas | `"Aun no se cumple la permanencia minima de 4 semanas. Disponible a partir de {fecha}."` |
| `422` | Pagar etapa de reclutamiento con coach sin asistencia mínima | `"El coach no conserva el beneficio: su asistencia de los ultimos 30 dias es {pct}% (minimo requerido {min}%)."` |
| `422` | Rúbrica configurada no suma el máximo | `"La suma de los totales por rubro ({x}) debe ser igual al puntaje base maximo ({y})."` |

Todos siguen el shape estándar de Laravel: `{ "message": "..." }` (403/404/422 simples) o `{ "message": "...", "errors": { "campo": ["..."] } }` (422 de validación de formulario).

---

## 10. Pantallas esperadas por rol

### 10.1 Admin / Manager (panel web)

1. **Configuración del programa** (`GET/PUT admin/merit/config`)
   - Formulario con: % del fondo, puntaje mínimo, puntaje máximo, día de corte, modelo de distribución (radio: igualitario / por participación), % mínimo de asistencia de coach.
   - Editor de niveles (nombre, min, max, peso de participación) — 3 filas por defecto (Pardo/Polar/Grizly), permitir agregar/quitar.
   - Editor de rúbrica (4 categorías × sub-rubros con su puntaje) con **validador en vivo** de que la suma = puntaje máximo antes de permitir guardar.

2. **Captura y ranking mensual** (`GET/POST players/{player}/scores`, `GET snapshots`, `POST snapshots/generate`)
   - Selector de mes + botón "Generar/Recalcular snapshots".
   - Tabla ranking (jugador, nivel, puntaje total, elegible al fondo, estado de validación).
   - Vista de detalle por jugador: captura por rubro (con el rubro de asistencia mostrado como **solo lectura**, calculado), historial de entradas con motivo/evidencia.
   - Indicador visual claro de "bloqueado" (candado) cuando `locked_at != null`.

3. **Validación del comité**
   - Desde el detalle del snapshot: botón "Aprobar" visible solo si el usuario puede aprobar como Head Coach y/o Manager (mostrar qué falta: "Falta aprobación de Manager" / "Falta aprobación de Head Coach").

4. **Fondo de Mérito**
   - Selector de mes → botón "Calcular fondo" (muestra `total_collected_mxn`, `fund_amount_mxn`, `eligible_players_count`).
   - Botón "Distribuir" (deshabilitado si `status = distributed` o si `eligible_players_count = 0`) → tabla de resultado por jugador (`merit_level`, `participation_weight`, `share_amount_mxn`).

5. **Saldo a favor**
   - Buscador de jugador → saldo actual + historial de movimientos.
   - Acción "Aplicar a un pago": selector de pago pendiente del jugador + monto (prellenado con el máximo aplicable) + notas.

6. **Reclutamiento**
   - Lista de prospectos con filtro por estatus y por coach/jugador reclutador.
   - Acciones: "Marcar inscrito", "Confirmar retención" (deshabilitada hasta cumplir 4 semanas, mostrar countdown), "Rechazar".
   - Vista de etapas por prospecto con montos (visibles solo aquí) y botón "Marcar pagada" — **si el backend rechaza por asistencia del coach, mostrar el mensaje de error tal cual** (incluye el % actual).

7. **Disciplina**
   - Lista de incidencias por coach, con badge de "Reincidencia" cuando `is_repeat = true`.
   - Formulario de resolución: sanción aplicada + checkbox "resultó en expulsión".

8. **Reportes**
   - Historial de jugador (línea de tiempo de snapshots + ledger).
   - Reporte de reclutamiento por coach (tabla agregada).

### 10.2 Coach (app)

1. **Mis categorías → Captura de puntaje**: por jugador de sus categorías asignadas, formulario por rubro (sin "asistencia"). Mostrar aviso si el periodo está bloqueado (no permitir edición).
2. **Ranking del mes** (solo lectura) — mismo listado que manager pero sin acciones de edición fuera de sus jugadores.
3. **Validar snapshot** — botón visible **solo** si el coach es Head Coach de esa categoría (el backend igual lo valida, pero ocultar el botón si no aplica mejora la UX).
4. **Reclutamiento** — "Registrar prospecto" (formulario simple: nombre + contacto), lista de "Mis prospectos" con estatus y etapas (sin montos).
5. **Incidencias** — "Reportar incidencia" (coach involucrado, tipo, descripción, fecha) + lista de "Mis incidencias" (donde es sujeto o reportó).

### 10.3 Player (app)

1. **"Mis Méritos"**: tarjeta con nivel actual (Pardo/Polar/Grizly con su icono/color), puntaje total, barra de progreso hacia el siguiente nivel, desglose por rubro (`breakdowns`), y gráfica/lista de evolución mensual (`history`).
2. **"Mi saldo a favor"**: monto disponible + historial de movimientos (créditos del fondo, débitos aplicados a pagos).
3. **"Reclutar amigos"**: formulario para registrar un prospecto + lista de "Mis prospectos registrados" con su estatus (sin montos, ya que esos son solo para coach admin/manager).

---

## 11. Notas de implementación importantes

- **El rubro `asistencia` nunca se envía en `POST/PUT` de scores** — el backend lo calcula agregando el módulo de asistencia de jugadores (`attendances`, no confundir con `checkins` que es para coaches) del mes. Si el frontend intenta mostrarlo como editable, ocultar/deshabilitar ese campo específico y mostrarlo como informativo dentro del `breakdown`.
- **Snapshot bloqueado = inmutable.** Una vez `locked_at != null`, ni captura de puntos ni recálculo de snapshot son posibles para ese jugador/mes. El único camino es un ajuste manual explícito fuera de este flujo (no expuesto en v1).
- **El saldo a favor se aplica manualmente por el staff en v1** — no hay descuento automático al crear un pago nuevo. El frontend de manager debe dejar claro que es una acción explícita, no un proceso automático.
- **El pago real de reclutamiento a coaches ocurre fuera del sistema** (nómina/efectivo) — `mark-paid` es solo un registro de auditoría, no dispara ninguna transferencia.
- **Los 15 puntos extra de reclutamiento (`reclutamiento_extra`) no suman al `total_score`** ni afectan el nivel en v1 — se muestran por separado (`extra_points`). Está pendiente de definición de producto si en v2 generarán saldo adicional (ver BRD, sección "Preguntas Abiertas").
- **`coach_min_attendance_percentage` se calcula sobre check-ins de los últimos 30 días corridos**, no hay concepto de "días esperados" por coach en el sistema — es una aproximación documentada, no una asistencia contra un calendario de trabajo.
