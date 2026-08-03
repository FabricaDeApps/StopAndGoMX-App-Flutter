# BRD — Programa de Méritos (Módulo de Organización)

**Documento:** 2026-08-02_BRD_Programa_Meritos_Organization.md
**Fecha:** 2026-08-02
**Estado:** Borrador
**Proyecto:** StopAndGoMX
**Fuente:** `docs/rewards/rewards-bears.pdf`, `docs/rewards/1.jpg`, `docs/rewards/2.jpg` (especificación del cliente BEARS)
**Autor:** Luis Carlín / Equipo StopAndGoMX

---

## 1. Resumen Ejecutivo

Se propone construir el **Programa de Méritos**: un módulo de evaluación de jugadores (100 puntos, 4 rubros) que reconoce compromiso y disciplina — no solo talento — y que determina mensualmente un **nivel de mérito** (Pardo / Polar / Grizly) y la elegibilidad para un **Fondo de Mérito** calculado como el 15% de las colegiaturas efectivamente cobradas ese mes, distribuido entre jugadores elegibles como **saldo a favor** (nunca efectivo) aplicable a colegiaturas, viajes o equipo.

El requerimiento se originó con el club BEARS, pero como StopAndGoMX es una plataforma multi-tenant, el módulo se diseña **genérico y configurable por organización** — no hardcodeado a los parámetros de BEARS — y debe poder **habilitarse o deshabilitarse por organización desde Organization Settings**, siguiendo el mismo patrón que módulos existentes (`gazetta_enabled`, `social_module`, `checkin_enabled`).

**Viabilidad: SÍ es viable.** El sistema ya cuenta con la infraestructura multi-tenant, de pagos, asistencia y temporadas necesaria para soportar el 70% del insumo de datos del programa. El trabajo nuevo se concentra en: evaluación/captura de puntos, cálculo del fondo, un ledger de saldo a favor (no existe hoy), reclutamiento y auditoría dedicada de cambios de puntaje.

---

## 2. Contexto y Motivación

BEARS entregó una especificación funcional que pide que la app registre, calcule y audite automáticamente un sistema de méritos. El documento fue escrito pensando en un solo club, pero StopAndGoMX aloja múltiples organizaciones con reglas de cobro, temporadas y categorías propias — por lo que este BRD adapta la especificación a un **módulo activable por organización**, con los valores de BEARS como configuración por defecto en lugar de reglas fijas del sistema.

### 2.1 Qué ya existe en el sistema y se puede aprovechar

| Necesidad del programa | Componente existente | Notas |
|---|---|---|
| Aislamiento y configuración por organización | `Organization` + `OrganizationSetting` (`app/Models/Organization.php`, `app/Models/OrganizationSetting.php`, tabla `organization_settings`) | Ya tiene el patrón de toggles booleanos por módulo (`checkin_enabled`, `gazetta_enabled`, `social_module`) gestionado desde `app/Http/Controllers/Admin/OrganizationSettingsController.php`. |
| Temporada de 20 semanas | `Season` (`app/Models/Season.php`, tabla `seasons`) | Ya es org-scoped, con `starts_at`/`ends_at` y `status` (`active|closed|completed`). |
| Categorías de equipo | `Category` (`app/Models/Category.php`) | Org-scoped, ya relacionada con `Attendance` y `Payment` vía `category_id`. |
| Asistencia (15 pts del rubro "Compromiso y disciplina") | `Attendance` (`app/Models/Attendance.php`, tabla `attendances`) | Ya cubre asistencia a nivel club (entrenamientos y juegos, `status`: `present\|absent\|late\|justified`), distinta de `league_match_attendances` (nivel liga). El % mensual de asistencia se puede calcular agregando esta tabla sin construir nada nuevo. |
| Colegiaturas cobradas (base del Fondo) | `Payment` / `PaymentReceipt` (`app/Models/Payment.php`, `app/Models/PaymentReceipt.php`, tabla `payments`) | Ya tiene `organization_id`, `player_id`, `season_id`, `category_id`, `amount`, `status` (`pending\|paid\|verified\|partial\|canceled`), `paid_at`. Falta el query de "total cobrado por organización por mes", pero es lógica nueva sobre datos existentes, no un modelo nuevo. |
| Coaches | `User` con rol `coach` + pivot `coach_category` (`app/Models/CoachCategory.php`) | No existe modelo `Coach` dedicado; no hace falta crear uno. |

### 2.2 Qué falta y debe construirse

- **Evaluación de puntos por rubro** (captura diaria/mensual, snapshot y validación) — no existe ningún modelo de evaluación/score de jugador hoy.
- **Saldo a favor / wallet de jugador** ("saldo a favor" aplicable a colegiaturas, viajes, equipo) — confirmado que no existe ningún ledger de crédito en el sistema; los "balances" actuales (`Payment::getBalanceAttribute`, `Admin\BalanceController`) son *accessors* calculados (adeudo - pagado), no un crédito acumulable y aplicable.
- **Cálculo y distribución del Fondo mensual** — no existe.
- **Reclutamiento de prospectos** (registro, exclusividad coach/jugador, dos etapas de pago) — no existe.
- **Auditoría dedicada de cambios de puntaje** (usuario, fecha, motivo, evidencia) — existen `AdminActivityLog`/`AppActivityLog`, pero son logs genéricos de request HTTP sin campos estructurados de motivo/evidencia; no alcanzan el requisito del PDF.
- **Incidencias disciplinarias de coaches** — no existe.

---

## 3. Alcance

### 3.1 Dentro del alcance (v1)

- Flag de habilitación por organización en Organization Settings (`merit_program_enabled`).
- Configuración por organización de: % del fondo, puntaje mínimo de participación, pesos de cada rubro, umbrales de nivel (Pardo/Polar/Grizly), modelo de distribución (`equal` o `by_participation`), día de corte mensual — con los valores del PDF de BEARS como default.
- Captura de puntos por rubro (compromiso y disciplina, desarrollo individual, contribución a la manada, rendimiento deportivo), incluyendo los 15 puntos extra de reclutamiento.
- Cálculo automático del sub-rubro de asistencia (15 pts) a partir de `Attendance`.
- Corte mensual con snapshot de puntaje total, nivel de mérito y elegibilidad al fondo.
- Validación final de puntaje exclusiva del comité de mérito (Head Coach + Manager); ningún coach puede modificar el puntaje final.
- Cálculo del Fondo mensual (15% configurable de colegiaturas cobradas) y distribución entre jugadores elegibles (igualitaria o por participación según nivel, configurable por organización).
- Registro de saldo a favor por jugador (`player_credit_ledger`), con **aplicación manual por parte del staff** al registrar/editar un pago (no automática en v1).
- Registro de prospectos de reclutamiento (coach o jugador reclutador, nunca ambos), con seguimiento de las dos etapas (inscripción efectiva, permanencia mínima de 4 semanas). El **pago real al coach se gestiona fuera del sistema** (nómina/efectivo); el sistema solo audita cuándo se cumple cada etapa.
- Registro de incidencias disciplinarias de coaches (agresión física/verbal, sanción, reincidencia → expulsión).
- Auditoría obligatoria (usuario, fecha/hora, motivo, evidencia) de toda modificación de puntaje.
- Reportes: ranking mensual, historial por jugador, asistencia, pagos, puntos por rubro, saldo acumulado del fondo, reporte de coaches reclutadores.
- **Interfaces v1**: panel Admin/Manager web (configuración, captura, validación, fondo, reportes) **y** apps móviles de jugador (ver puntaje/nivel/saldo) y coach (registrar prospectos e incidencias, capturar puntos donde aplique).

### 3.2 Fuera de alcance (v1)

- Aplicación **automática** del saldo a favor en el flujo de creación/pago de `Payment` (v1 es aplicación manual por staff).
- Pago automatizado/generado por el sistema hacia coaches por reclutamiento (v1 es solo seguimiento/auditoría de etapas cumplidas).
- Definir si los 15 puntos extra de reclutamiento generan saldo adicional del fondo o solo mejoran ranking/desempate — **explícitamente diferido a v2 por el propio PDF del cliente**. El modelo de datos se construye listo para soportarlo (flag `is_extra_point`), pero la regla de negocio no se activa en v1.
- Catálogo de pruebas físicas específicas por posición — **diferido a v2 por el propio PDF**.
- Notificaciones push automáticas al jugador cuando se le asigna una estadística/puntaje (puede añadirse después, no es requisito v1).

---

## 4. Usuarios y Roles

| Actor | Rol en sistema | Permisos |
|---|---|---|
| **Admin de organización** | `role:admin` | Habilita/deshabilita el módulo y configura sus parámetros en Organization Settings. Ve todos los reportes. |
| **Manager** | `role:manager` | Miembro del comité de mérito. Valida el snapshot mensual final junto con Head Coach. Gestiona cálculo y distribución del fondo. Aplica saldo a favor manualmente a un pago. |
| **Head Coach** | `role:coach` (con bandera de "head coach" en la categoría, vía `coach_category`) | Miembro del comité de mérito. Co-valida el snapshot final. Puede capturar puntos. |
| **Coach** | `role:coach` | Captura puntos de sus categorías asignadas (no valida el puntaje final). Registra prospectos e incidencias disciplinarias. Ve montos de reclutamiento solo si además tiene rol admin. |
| **Jugador** | `role:player` / app móvil | Solo lectura: su propio puntaje, desglose por rubro, nivel de mérito y saldo a favor. Puede registrarse como "jugador reclutador" de un prospecto. |

---

## 5. Reglas de Negocio

### 5.1 Configuración y elegibilidad

1. **El módulo solo opera si `organization_settings.merit_program_enabled = true`** para esa organización.
2. **Puntaje base máximo: 100 puntos**, configurable por organización (`merit_program_configs.max_base_score`, default 100).
3. **Puntaje mínimo para participar en el Fondo: 80 puntos**, configurable (`min_score_to_participate`, default 80). Jugadores por debajo no participan en la distribución del fondo ese mes, aunque conserven su evaluación.
4. **Niveles de mérito**, configurables vía `level_thresholds` (default BEARS): Pardo 80-84, Polar 85-89, Grizly 90-100.
5. El corte de puntos es **mensual**; el registro/captura de eventos puede ser diario.

### 5.2 Evaluación

6. Rubros y pesos por defecto (configurables por organización vía `rubric_weights`): Compromiso y disciplina 30 (Asistencia 15, Puntualidad/administración 10 todo-o-nada, Responsabilidad con instalaciones 5), Desarrollo individual 25 (físico 10, técnico 10, conocimiento del sistema 5), Contribución a la manada 25 base (trabajo en equipo 10, servicio y apoyo 7, representación 8) + hasta 15 puntos EXTRA de reclutamiento responsable, Rendimiento deportivo 20 (asignaciones 8, esfuerzo 5, producción 5, rol/disponibilidad 2).
7. **Los puntos extra de reclutamiento no cuentan para el máximo de 100** — se almacenan por separado (`is_extra_point = true`) y en v1 solo sirven para mejorar promedio/desempate, nunca para superar el máximo ni (en v1) para calcular saldo adicional.
8. **La sub-regla de "Puntualidad/administración" es todo-o-nada**: requiere pagos al corriente, documentos completos, uniforme correcto y llegada máxima configurable (default 10 min) tarde; si falla cualquiera, el sub-rubro completo es 0.
9. **Ningún coach puede modificar el puntaje final** — solo puede capturar entradas (`merit_score_entries`); el snapshot mensual requiere validación del comité de mérito (Head Coach + Manager) antes de considerarse definitivo.
10. Toda evaluación debe estar respaldada por evidencia cuando se trate de una modificación posterior al registro original.

### 5.3 Fondo de Mérito y saldo a favor

11. **Fondo mensual = % configurable (default 15%) del total de colegiaturas efectivamente cobradas ese mes** en la organización (`Payment.status = 'paid'`/`verified` con `paid_at` dentro del mes).
12. **Cada fondo mensual es independiente** — montos no distribuidos en un mes no se acumulan automáticamente a meses posteriores salvo ajuste manual explícito.
13. **Distribución**: igualitaria (fondo ÷ jugadores elegibles) o por participaciones ponderadas por nivel (Grizly/Polar/Pardo), según `distribution_model` configurado por la organización.
14. **El beneficio se aplica como saldo a favor, nunca como efectivo.** El saldo se registra en `player_credit_ledger` y se **aplica manualmente por el staff** a un pago existente/futuro; no hay descuento automático en v1.
15. Si un jugador no tiene adeudos pendientes al momento de la distribución, el saldo permanece disponible para su siguiente temporada mientras continúe en la organización.

### 5.4 Reclutamiento

16. **Un prospecto solo puede asignarse a un coach reclutador o a un jugador reclutador, nunca a ambos** (regla de exclusividad, análoga al patrón ya usado en `attendances` para `game_id`/`training_id`).
17. El pago al coach por reclutamiento tiene **dos etapas**: (1) inscripción efectiva del prospecto, (2) permanencia mínima configurable (default 4 semanas). El sistema registra cuándo se cumple cada etapa; **el pago en sí se gestiona fuera del sistema**.
18. El coach debe mantener al menos 80% de asistencia (configurable) para conservar el beneficio de reclutamiento.
19. Un prospecto en estatus `enrolled` debe poder vincularse al `player_id` real una vez que se registra formalmente.

### 5.5 Disciplina y auditoría

20. Las incidencias disciplinarias de coaches (agresión física o verbal) generan sanción; la reincidencia implica expulsión del staff — el sistema debe registrar el historial para detectar reincidencia.
21. **Toda modificación de puntos debe guardar usuario, fecha, hora, motivo y evidencia** (`merit_score_audit_logs`).
22. El acceso a montos de reclutamiento configurados por la organización está restringido a roles `admin`/`manager`; no se expone a coaches ni en la app.

---

## 6. Requerimientos Funcionales

### 6.1 Configuración (Organization Settings)

| ID | Requerimiento |
|---|---|
| RF-01 | El admin de organización puede habilitar/deshabilitar el módulo desde Organization Settings (`merit_program_enabled`). |
| RF-02 | Con el módulo deshabilitado, ningún endpoint del módulo debe quedar accesible para esa organización (fail closed). |
| RF-03 | El admin puede configurar % del fondo, puntaje mínimo, pesos de rúbrica, umbrales de nivel, modelo de distribución y día de corte mensual por organización/temporada. |
| RF-04 | Al crear la configuración por primera vez, el sistema precarga los valores por defecto (los de BEARS) editables antes de guardar. |

### 6.2 Evaluación / captura de puntos

| ID | Requerimiento |
|---|---|
| RF-05 | Coach/Head Coach/Manager puede registrar una entrada de puntos por jugador, rubro y sub-rubro, con motivo y evidencia opcional. |
| RF-06 | El sistema calcula automáticamente el sub-rubro de asistencia (15 pts) agregando `Attendance` del mes para ese jugador/categoría. |
| RF-07 | Al llegar el día de corte configurado, el sistema genera un snapshot mensual por jugador con el total, nivel de mérito y elegibilidad al fondo. |
| RF-08 | El snapshot mensual requiere validación explícita de Head Coach y Manager antes de considerarse definitivo (`locked_at`). |
| RF-09 | Un coach no puede editar ni validar el snapshot final; solo puede crear/editar entradas mientras el snapshot no esté bloqueado. |
| RF-10 | El sistema registra puntos extra de reclutamiento por separado del puntaje base de 100. |

### 6.3 Fondo de Mérito y saldo a favor

| ID | Requerimiento |
|---|---|
| RF-11 | El sistema calcula el fondo mensual = % configurado × total de colegiaturas cobradas ese mes en la organización. |
| RF-12 | El sistema distribuye el fondo entre jugadores elegibles (≥ puntaje mínimo) según el modelo configurado (igualitario o por participación). |
| RF-13 | El sistema registra el resultado de la distribución como entradas de crédito en `player_credit_ledger` por jugador. |
| RF-14 | El staff puede aplicar manualmente el saldo disponible de un jugador a un pago pendiente/futuro, reduciendo el saldo y quedando trazado en el ledger. |
| RF-15 | El jugador puede consultar su saldo a favor disponible desde la app. |

### 6.4 Reclutamiento

| ID | Requerimiento |
|---|---|
| RF-16 | Coach o jugador puede registrar un prospecto, y el sistema exige que se asigne a exactamente uno de los dos (nunca ambos). |
| RF-17 | El sistema permite marcar cuándo un prospecto cumple la etapa de inscripción efectiva y, posteriormente, la de permanencia mínima. |
| RF-18 | El monto configurado por etapa es visible solo para roles admin/manager, nunca para coach ni en la app. |
| RF-19 | El sistema valida la asistencia mínima del coach antes de considerar vigente el beneficio de reclutamiento. |

### 6.5 Disciplina y auditoría

| ID | Requerimiento |
|---|---|
| RF-20 | El sistema permite registrar incidencias disciplinarias de coaches con tipo, descripción y evidencia. |
| RF-21 | El sistema marca automáticamente una incidencia como reincidencia si existe una previa del mismo coach, y señala que corresponde evaluar expulsión. |
| RF-22 | Toda creación/edición/eliminación de una entrada de puntaje genera un registro de auditoría con usuario, fecha/hora, motivo y evidencia. |

### 6.6 Reportes

| ID | Requerimiento |
|---|---|
| RF-23 | Ranking mensual de jugadores por puntaje/nivel. |
| RF-24 | Historial de un jugador: puntos por rubro, evolución mensual, asistencia, pagos y saldo acumulado. |
| RF-25 | Reporte de coaches reclutadores con prospectos y etapas cumplidas. |

---

## 7. Requerimientos No Funcionales

| ID | Requerimiento |
|---|---|
| RNF-01 | Todos los endpoints del módulo se autentican vía Sanctum, consistente con el resto de la API. |
| RNF-02 | Todas las tablas nuevas incluyen `organization_id` con índice, garantizando aislamiento multi-tenant. |
| RNF-03 | El cálculo del fondo mensual y los snapshots deben poder recalcularse de forma idempotente (reproducible) mientras no estén bloqueados. |
| RNF-04 | Los pesos de rúbrica y umbrales de nivel deben poder ampliarse/ajustarse por organización sin requerir migración destructiva. |
| RNF-05 | El endpoint de consulta del jugador (`player/merit/me`) debe responder en menos de 500ms. |
| RNF-06 | El módulo no debe afectar el rendimiento de `Payment`/`Attendance` existentes (solo lectura agregada, sin cambios a esos flujos en v1). |

---

## 8. Modelo de Datos Propuesto

### 8.1 Extensión a `organization_settings`

```
organization_settings
└── merit_program_enabled (boolean, default false)  -- nueva columna, mismo patrón que gazetta_enabled / social_module
```

Migración: `add_merit_program_enabled_to_organization_settings_table.php`, controlador extendido: `app/Http/Controllers/Admin/OrganizationSettingsController.php` (mismo `firstOrCreate` + `$request->boolean('merit_program_enabled')`).

### 8.2 Tablas nuevas

```
merit_program_configs
├── id
├── organization_id (FK → organizations, cascade)
├── season_id (FK → seasons, nullable = default de la organización)
├── fund_percentage (decimal 5,2, default 15.00)
├── min_score_to_participate (smallint, default 80)
├── max_base_score (smallint, default 100)
├── distribution_model (enum: 'equal', 'by_participation')
├── level_thresholds (json)            -- [{name, min, max, participation_weight}]
├── rubric_weights (json)              -- pesos por rubro/sub-rubro
├── cutoff_day_of_month (tinyint)
├── is_active (boolean)
└── timestamps

merit_score_entries
├── id
├── organization_id (FK → organizations)
├── player_id (FK → players)
├── category_id (FK → categories, nullable)
├── season_id (FK → seasons)
├── rubric_category (enum: compromiso_disciplina, desarrollo_individual, contribucion_manada, rendimiento_deportivo)
├── rubric_item (enum: asistencia, puntualidad, instalaciones, fisico, tecnico, sistema, trabajo_equipo, servicio_apoyo, representacion, reclutamiento_extra, asignaciones, esfuerzo, produccion, rol)
├── points (decimal 5,2)
├── is_extra_point (boolean, default false)
├── period_month (date, primer día del mes)
├── entered_by (FK → users)
├── reason (text, nullable)
├── evidence_path (string, nullable)
└── timestamps

merit_monthly_snapshots
├── id
├── organization_id
├── player_id
├── season_id
├── period_month (date)
├── total_score (decimal)
├── extra_points (decimal)
├── merit_level (enum: pardo, polar, grizly, none)
├── is_fund_eligible (boolean)
├── validated_by_head_coach_id (FK → users, nullable)
├── validated_by_manager_id (FK → users, nullable)
├── validated_at (timestamp, nullable)
├── locked_at (timestamp, nullable)
└── timestamps
   unique(player_id, period_month)

merit_monthly_score_breakdowns
├── id
├── snapshot_id (FK → merit_monthly_snapshots, cascade)
├── rubric_item
├── points_earned (decimal)
└── points_possible (decimal)

merit_funds
├── id
├── organization_id
├── season_id
├── period_month (date)
├── total_collected_mxn (decimal 10,2)
├── fund_amount_mxn (decimal 10,2)
├── eligible_players_count (int)
├── distribution_model_used (enum: equal, by_participation)
├── status (enum: draft, calculated, distributed)
├── calculated_by (FK → users)
├── calculated_at (timestamp)
└── timestamps
   unique(organization_id, period_month)

merit_fund_distributions
├── id
├── fund_id (FK → merit_funds, cascade)
├── player_id (FK → players)
├── merit_level
├── participation_weight (decimal, nullable)
├── share_amount_mxn (decimal 10,2)
├── credit_ledger_entry_id (FK → player_credit_ledger, nullable, se llena al aplicarse)
└── timestamps

player_credit_ledger
├── id
├── organization_id
├── player_id (FK → players)
├── entry_type (enum: credit, debit)
├── amount_mxn (decimal 10,2)
├── balance_after_mxn (decimal 10,2)
├── source_type (enum: merit_fund, manual_adjustment, refund)
├── source_id (bigint, nullable — referencia a merit_fund_distributions.id u otro origen)
├── applied_to_type (enum: payment, trip, equipment, other, nullable)
├── applied_to_payment_id (FK → payments, nullable)
├── notes (text, nullable)
├── created_by (FK → users)
└── timestamps

recruitment_prospects
├── id
├── organization_id
├── full_name
├── contact_info (json/string)
├── recruited_by_coach_id (FK → users, nullable)
├── recruited_by_player_id (FK → players, nullable)   -- CHECK: exactamente uno de los dos no-nulo
├── status (enum: registered, trial, enrolled, retained, rejected)
├── enrolled_player_id (FK → players, nullable)
├── enrolled_at (timestamp, nullable)
├── retention_confirmed_at (timestamp, nullable)
└── timestamps

recruitment_payment_stages
├── id
├── prospect_id (FK → recruitment_prospects, cascade)
├── stage (enum: enrollment, retention_4wk)
├── amount_mxn (decimal, visible solo admin/manager)
├── status (enum: pending, eligible, paid, forfeited)
├── eligible_at (timestamp, nullable)
├── paid_at (timestamp, nullable)      -- informativo, pago real gestionado fuera del sistema
├── paid_by (FK → users, nullable)
└── timestamps

coach_disciplinary_incidents
├── id
├── organization_id
├── coach_id (FK → users)
├── player_id (FK → players, nullable)
├── incident_type (enum: physical, verbal, other)
├── description (text)
├── sanction_applied (text, nullable)
├── is_repeat (boolean, calculado al insertar)
├── resulted_in_expulsion (boolean, default false)
├── reported_by (FK → users)
├── occurred_at (timestamp)
└── timestamps

merit_score_audit_logs
├── id
├── organization_id
├── auditable_type (string)            -- 'merit_score_entry' | 'merit_monthly_snapshot' | 'merit_program_config'
├── auditable_id (bigint)
├── action (enum: create, update, delete, validate)
├── changed_by (FK → users)
├── old_value (json, nullable)
├── new_value (json, nullable)
├── reason (text)
├── evidence_path (string, nullable)
└── created_at
```

### 8.3 Relaciones con modelos existentes

```
MeritProgramConfig    belongsTo Organization, belongsTo Season (nullable)
MeritScoreEntry        belongsTo Organization, Player, Category (nullable), Season, belongsTo User (entered_by)
MeritMonthlySnapshot   belongsTo Organization, Player, Season; hasMany MeritMonthlyScoreBreakdown
MeritFund              belongsTo Organization, Season; hasMany MeritFundDistribution
MeritFundDistribution  belongsTo MeritFund, Player
PlayerCreditLedger     belongsTo Organization, Player, belongsTo Payment (applied_to_payment_id, nullable)
RecruitmentProspect    belongsTo Organization, belongsTo User (recruited_by_coach_id, nullable), belongsTo Player (recruited_by_player_id / enrolled_player_id, nullable)
RecruitmentPaymentStage belongsTo RecruitmentProspect
CoachDisciplinaryIncident belongsTo Organization, User (coach), Player (nullable)
MeritScoreAuditLog     belongsTo Organization; morphTo auditable
```

### 8.4 Reuso vs. nuevo (resumen)

| Se reusa tal cual | Se construye nuevo |
|---|---|
| `Organization`, `OrganizationSetting` (+1 columna) | `merit_program_configs` |
| `Season`, `Category` | `merit_score_entries`, `merit_monthly_snapshots`, `merit_monthly_score_breakdowns` |
| `Attendance` (input del sub-rubro de asistencia) | `merit_funds`, `merit_fund_distributions` |
| `Payment` / `PaymentReceipt` (input del fondo) | `player_credit_ledger` |
| `User` + `coach_category` (no hace falta modelo `Coach`) | `recruitment_prospects`, `recruitment_payment_stages` |
| `Player` | `coach_disciplinary_incidents`, `merit_score_audit_logs` |

---

## 9. Endpoints de API Propuestos

Nuevo archivo `routes/api/merit-program.php`, incluido desde `routes/api.php`, Sanctum + resolución de organización vía header `X-Organization-Id` (convención existente). Todos los endpoints deben verificar `organization_settings.merit_program_enabled` antes de responder.

### 9.1 Admin (`role:admin`)

| Método | Ruta | Descripción |
|---|---|---|
| `GET` | `/api/admin/merit/config` | Ver configuración del programa para la organización |
| `PUT` | `/api/admin/merit/config` | Crear/actualizar configuración (fondo %, mínimos, pesos, umbrales, modelo de distribución) |
| `GET` | `/api/admin/merit/reports/{ranking\|attendance\|payments\|fund-balance\|recruitment}` | Reportes agregados |

### 9.2 Manager / Head Coach (`role:manager`, `role:coach`)

| Método | Ruta | Descripción |
|---|---|---|
| `GET/POST/PUT` | `/api/manager/merit/players/{player}/scores` | Captura/edición de entradas de puntaje (coach: sin validar final) |
| `GET` | `/api/manager/merit/snapshots` | Listar snapshots mensuales / ranking |
| `POST` | `/api/manager/merit/snapshots/{snapshot}/validate` | Validación final (solo `manager` + `head coach`, doble aprobación) |
| `GET/POST` | `/api/manager/merit/funds` | Ver / calcular fondo mensual |
| `POST` | `/api/manager/merit/funds/{fund}/distribute` | Distribuir fondo a jugadores elegibles |
| `GET/POST` | `/api/manager/merit/credit-ledger/{player}` | Ver saldo, aplicar saldo manualmente a un pago |

### 9.3 Coach (`role:coach`)

| Método | Ruta | Descripción |
|---|---|---|
| `GET/POST` | `/api/coach/merit/prospects` | Registrar/consultar prospectos propios |
| `GET/POST` | `/api/coach/merit/prospects/{prospect}/stages` | Ver etapas de un prospecto (montos ocultos salvo rol admin) |
| `POST` | `/api/coach/merit/incidents` | Registrar incidencia disciplinaria |

### 9.4 Jugador / App (`role:player`)

| Método | Ruta | Descripción |
|---|---|---|
| `GET` | `/api/player/merit/me` | Puntaje actual, desglose por rubro, nivel de mérito, historial |
| `GET` | `/api/player/merit/me/credit-balance` | Saldo a favor disponible y movimientos |
| `POST` | `/api/player/merit/prospects` | Registrarse como jugador reclutador de un prospecto |

---

## 10. Flujos de Usuario

### 10.1 Captura y cierre mensual

```
1. Coach/Head Coach captura entradas de puntos durante el mes (rubro por rubro)
2. El sub-rubro de asistencia se calcula automáticamente desde Attendance
3. Al llegar el día de corte configurado, el sistema genera el snapshot mensual por jugador
4. Head Coach y Manager validan el snapshot (doble aprobación) → queda bloqueado
5. Jugadores con snapshot ≥ puntaje mínimo quedan marcados como elegibles al fondo
```

### 10.2 Fondo y saldo a favor

```
1. Manager calcula el fondo del mes (% configurado × colegiaturas cobradas)
2. El sistema distribuye el fondo entre jugadores elegibles (igualitario o por participación)
3. Cada distribución genera una entrada de crédito en player_credit_ledger
4. El jugador ve su saldo disponible en la app
5. El staff aplica manualmente el saldo a un pago pendiente cuando corresponda
```

### 10.3 Reclutamiento

```
1. Coach o jugador registra un prospecto (nunca ambos a la vez)
2. El prospecto avanza de estatus: registered → trial → enrolled → retained
3. Al cumplirse cada etapa (inscripción, retención 4 semanas), se marca en recruitment_payment_stages
4. El pago real al coach se gestiona fuera del sistema; el reporte de reclutamiento resume lo pendiente/cumplido
```

### 10.4 Consulta del jugador en la app

```
1. Jugador abre la sección "Mis Méritos"
2. Ve su puntaje total, nivel (Pardo/Polar/Grizly), desglose por rubro
3. Ve su saldo a favor disponible y el historial de movimientos
```

---

## 11. Criterios de Aceptación

| CA | Criterio |
|---|---|
| CA-01 | Con `merit_program_enabled = false`, ningún endpoint del módulo responde datos para esa organización. |
| CA-02 | Un coach no puede validar ni bloquear un snapshot mensual; solo Manager + Head Coach pueden hacerlo. |
| CA-03 | El sub-rubro de asistencia se calcula correctamente a partir de `Attendance` sin captura manual duplicada. |
| CA-04 | Un jugador con puntaje < mínimo configurado no aparece en la distribución del fondo, aunque sí en el ranking general. |
| CA-05 | El fondo mensual calculado coincide con % configurado × total de `Payment` cobrados (`status` pagado/verificado) ese mes. |
| CA-06 | Un prospecto no puede guardarse con `recruited_by_coach_id` y `recruited_by_player_id` ambos no-nulos (ni ambos nulos). |
| CA-07 | El monto de `recruitment_payment_stages.amount_mxn` no aparece en ninguna respuesta de API para rol `coach`. |
| CA-08 | Toda edición de una `merit_score_entry` posterior a su creación genera un registro en `merit_score_audit_logs` con motivo. |
| CA-09 | Aplicar saldo a favor a un pago reduce el `balance_after_mxn` del ledger y queda trazado con `applied_to_payment_id`. |
| CA-10 | Una segunda incidencia disciplinaria del mismo coach se marca automáticamente `is_repeat = true`. |

---

## 12. Dependencias Técnicas

| Dependencia | Tipo | Descripción |
|---|---|---|
| `organization_settings` | Existente | Flag de habilitación del módulo |
| `payments` / `payment_receipts` | Existente | Input del cálculo del fondo mensual |
| `attendances` | Existente | Input del sub-rubro de asistencia |
| `seasons` | Existente | Acotar la temporada de evaluación |
| `categories` | Existente | Acotar entradas de puntaje por equipo/categoría |
| `users` + `coach_category` | Existente | Identificación de coaches y su categoría |
| `players` | Existente | Sujeto de la evaluación y del saldo a favor |

---

## 13. Fases de Implementación Sugeridas

### Fase 1 — Configuración y flag
- Migración `merit_program_enabled` en `organization_settings`
- Tabla y modelo `MeritProgramConfig`
- Endpoint admin de configuración + UI en Organization Settings

### Fase 2 — Evaluación mensual
- `merit_score_entries`, `merit_monthly_snapshots`, `merit_monthly_score_breakdowns`
- Job de agregación automática del sub-rubro de asistencia desde `Attendance`
- Flujo de validación (Head Coach + Manager) y bloqueo del snapshot
- Endpoints manager/coach de captura

### Fase 3 — Fondo y saldo a favor
- `merit_funds`, `merit_fund_distributions`, `player_credit_ledger`
- Job de agregación de colegiaturas cobradas por mes (`Payment`)
- Endpoint de cálculo/distribución del fondo y de aplicación manual de saldo

### Fase 4 — Reclutamiento (en paralelo con Fase 2)
- `recruitment_prospects`, `recruitment_payment_stages`
- Endpoints coach/jugador de registro de prospectos

### Fase 5 — Auditoría, disciplina y reportes
- `merit_score_audit_logs`, `coach_disciplinary_incidents`
- Retrofit de auditoría en los flujos de escritura de Fases 2 y 4
- Endpoints de reportes (ranking, historial, reclutamiento, saldo)

### Fase 6 — Interfaces
- Panel Admin/Manager web: configuración, captura, validación, fondo, reportes
- App jugador: puntaje/nivel/saldo (`player/merit/me`)
- App coach: registro de prospectos e incidencias, captura de puntos donde aplique

---

## 14. Preguntas Abiertas

| # | Pregunta | Estado |
|---|---|---|
| P-01 | ¿Los 15 puntos extra de reclutamiento generan saldo adicional del fondo o solo mejoran ranking/desempate? | Pendiente — diferido a v2 por el propio PDF del cliente |
| P-02 | ¿Se requiere un catálogo de pruebas físicas específicas por posición para el sub-rubro de desarrollo físico? | Pendiente — diferido a v2 por el propio PDF del cliente |
| P-03 | ¿`merit_program_configs` necesita su propia validación de duración de temporada (20 semanas) independiente de `Season.starts_at/ends_at`, o basta con acotarla a la `Season` vinculada? | Pendiente |
| P-04 | ¿En qué momento (si alguno) pasará v2 la aplicación de saldo a favor de manual a automática dentro del flujo de `Payment`? | Pendiente, fuera de alcance v1 por decisión explícita |
| P-05 | ¿El "jugador reclutador" requiere algún incentivo/registro simétrico al del coach (más allá de exclusividad), o solo se rastrea informativamente en v1? | Pendiente |

---

## 15. Riesgos y Mitigaciones

| Riesgo | Impacto | Mitigación |
|---|---|---|
| Confusión entre asistencia de club (`attendances`) y asistencia de liga (`league_match_attendances`) | Medio | Documentar explícitamente en el código/endpoints que el rubro de asistencia usa solo `attendances` (nivel club) |
| Cálculo del fondo inconsistente si se recalcula tras cambios en `Payment` ya distribuido | Alto | Bloquear (`status = distributed`) el fondo del mes una vez distribuido; solo permitir ajustes manuales explícitos posteriores |
| Exposición accidental de montos de reclutamiento a coaches vía un endpoint mal restringido | Alto | Filtrar el campo `amount_mxn` a nivel de Resource/Transformer según rol, no solo en frontend |
| Saldo a favor aplicado manualmente por error o duplicado | Medio | El ledger es append-only con `balance_after_mxn` calculado; toda aplicación queda trazada y reversible mediante entrada de ajuste, no edición directa |
| Configuración por organización mal definida (pesos que no suman 100) | Bajo | Validación de suma de `rubric_weights` al guardar la configuración |

---

## 16. Conclusión

El Programa de Méritos **es viable** sobre la arquitectura actual de StopAndGoMX: aprovecha directamente `OrganizationSetting` (flag de habilitación por organización), `Attendance` (insumo de asistencia), `Payment`/`PaymentReceipt` (insumo del fondo), `Season` y `Category` (alcance temporal/de equipo), y el rol `coach` existente sin necesidad de un modelo `Coach` nuevo. El esfuerzo de construcción nuevo se concentra en 10 tablas (evaluación, snapshots, fondo, saldo a favor, reclutamiento, disciplina y auditoría) y las agregaciones que las alimentan, todo aislado por `organization_id` y activable/desactivable por organización desde el día uno, cumpliendo el requisito explícito de que viva en Organization Settings.

---

*Documento generado: 2026-08-02*
*Próximo paso: revisión y aprobación antes de iniciar Fase 1 (migraciones y configuración)*
