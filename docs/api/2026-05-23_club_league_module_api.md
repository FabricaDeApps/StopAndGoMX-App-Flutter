# Club App League Module API

Fecha: 2026-05-23

Base path: `/api/club/league`

Auth:
- `Authorization: Bearer {access_token}` de la app de clubes
- Header requerido: `X-Organization-Id: {organization_id}`

## Objetivo

Exponer en la app de clubes un módulo de ligas/torneos sin usar los endpoints de `league/team`.

Este módulo permite:
- detectar si la organización está enrolada en una o varias ligas
- listar sus equipos competitivos (`league_club_links`) dentro de esas ligas
- consultar torneos, standings y fixtures
- gestionar el roster competitivo que se envía por `club_link_id`

## Reglas generales

- La identidad principal sigue siendo la `organization` autenticada.
- Una misma organización puede tener varios `club_link_id` activos en la misma liga o torneo.
- `club_link_id` representa un equipo competitivo específico.
- Los nombres de equipo visibles para front deben salir de `league_club_links.team_name` cuando exista.
- Consulta del módulo:
  - cualquier usuario autenticado con membresía activa en la organización
- Gestión de roster competitivo:
  - solo roles `admin`, `manager`, `coach`
- Si el front quiere resaltar un equipo competitivo concreto en standings o fixtures, puede mandar `club_link_id` como query param.

## 1) GET `/overview`

Devuelve el mapa general del módulo para la organización autenticada.

### Response 200

```json
{
  "organization_id": 94,
  "viewer_id": 501,
  "items": [
    {
      "league": {
        "id": 2,
        "name": "LIFFAMH",
        "slug": "liffamh",
        "logo_url": "https://...",
        "status": "active",
        "season_label": "2026"
      },
      "teams": [
        {
          "club_link_id": 231,
          "team_name": "PANTERAS NEGRO U14 FEMENIL",
          "team_slug": "panteras-negro-u14-femenil",
          "organization": {
            "id": 94,
            "name": "PANTERAS",
            "slug": "panteras",
            "city": "",
            "logo_url": "https://..."
          },
          "league": {
            "id": 2,
            "name": "LIFFAMH",
            "slug": "liffamh",
            "logo_url": "https://...",
            "status": "active",
            "season_label": "2026"
          }
        }
      ],
      "tournaments": [
        {
          "id": 8,
          "name": "Temporada de Verano 2026",
          "slug": "temporada-de-verano-2026",
          "logo_url": "https://...",
          "status": "active",
          "roster_deadline_at": "2026-05-31T23:59:00-06:00",
          "starts_at": "2026-05-14T00:00:00-06:00",
          "ends_at": null,
          "teams": [
            {
              "team": {
                "club_link_id": 231,
                "team_name": "PANTERAS NEGRO U14 FEMENIL",
                "team_slug": "panteras-negro-u14-femenil"
              },
              "division_entries": [
                {
                  "division": {
                    "id": 32,
                    "name": "Femenil",
                    "slug": "femenil"
                  },
                  "sub_division": {
                    "id": 45,
                    "name": "U14",
                    "slug": "u14"
                  }
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

Uso esperado en front:
- si `items` viene vacío, no mostrar el módulo
- si viene con datos, mostrar ligas, torneos y variantes competitivas de la organización

## 2) GET `/tournaments/{tournamentId}/standings`

Devuelve la tabla general del torneo.

### Query params

- `club_link_id` (optional, int)

Si se manda `club_link_id`, backend marca `is_my_team=true` para ese equipo competitivo específico.

### Response 200

```json
{
  "tournament": {
    "id": 8,
    "league_id": 2,
    "name": "Temporada de Verano 2026",
    "slug": "temporada-de-verano-2026",
    "logo_url": "https://...",
    "status": "active",
    "league": {
      "id": 2,
      "name": "LIFFAMH",
      "slug": "liffamh",
      "logo_url": "https://..."
    }
  },
  "items": [
    {
      "id": 135759,
      "is_my_organization": true,
      "is_my_team": true,
      "team": {
        "club_link_id": 239,
        "name": "PANTERAS NEGRO U14 FEMENIL",
        "team_slug": "panteras-negro-u14-femenil",
        "organization_id": 94,
        "logo_url": "https://..."
      },
      "division": {
        "id": 32,
        "name": "Femenil",
        "slug": "femenil"
      },
      "sub_division": {
        "id": 45,
        "name": "U14",
        "slug": "u14"
      },
      "stats": {
        "played": 2,
        "wins": 2,
        "draws": 0,
        "losses": 0,
        "goals_for": 6,
        "goals_against": 0,
        "goal_difference": 6,
        "points": 6,
        "rank_position": 1
      }
    }
  ]
}
```

## 3) GET `/tournaments/{tournamentId}/fixtures`

Devuelve el calendario/resultados del torneo.

### Query params

- `club_link_id` (optional, int)

### Response 200

```json
{
  "tournament": {
    "id": 8,
    "league_id": 2,
    "name": "Temporada de Verano 2026",
    "slug": "temporada-de-verano-2026",
    "logo_url": "https://...",
    "status": "active",
    "league": {
      "id": 2,
      "name": "LIFFAMH",
      "slug": "liffamh",
      "logo_url": "https://..."
    }
  },
  "items": [
    {
      "id": 700,
      "status": "completed",
      "kickoff_at": "2026-05-16T18:50:00-06:00",
      "venue_name": "Campo 1",
      "venue_address": "",
      "is_my_organization_match": true,
      "is_my_team_match": true,
      "matchday": {
        "id": 29,
        "round_number": 1,
        "name": "Jornada 1",
        "match_date": "2026-05-16"
      },
      "division": {
        "id": 32,
        "name": "Femenil",
        "slug": "femenil"
      },
      "sub_division": {
        "id": 45,
        "name": "U14",
        "slug": "u14"
      },
      "home_team": {
        "club_link_id": 240,
        "name": "PANTERAS BLANCO U14 FEMENIL",
        "organization_id": 94,
        "logo_url": "https://...",
        "is_my_team": false,
        "is_my_organization_team": true
      },
      "away_team": {
        "club_link_id": 239,
        "name": "PANTERAS NEGRO U14 FEMENIL",
        "organization_id": 94,
        "logo_url": "https://...",
        "is_my_team": true,
        "is_my_organization_team": true
      },
      "score": {
        "home": 0,
        "away": 12
      }
    }
  ]
}
```

## 4) GET `/teams/{clubLinkId}`

Devuelve el detalle de un equipo competitivo específico.

### Response 200

```json
{
  "team": {
    "club_link_id": 239,
    "team_name": "PANTERAS NEGRO U14 FEMENIL",
    "team_slug": "panteras-negro-u14-femenil",
    "organization": {
      "id": 94,
      "name": "PANTERAS",
      "slug": "panteras",
      "city": "",
      "logo_url": "https://..."
    },
    "league": {
      "id": 2,
      "name": "LIFFAMH",
      "slug": "liffamh",
      "logo_url": "https://...",
      "status": "active",
      "season_label": "2026"
    }
  },
  "tournaments": [
    {
      "id": 8,
      "name": "Temporada de Verano 2026",
      "slug": "temporada-de-verano-2026",
      "logo_url": "https://...",
      "status": "active",
      "roster_deadline_at": "2026-05-31T23:59:00-06:00",
      "starts_at": "2026-05-14T00:00:00-06:00",
      "ends_at": null,
      "division_entries": [
        {
          "division": {
            "id": 32,
            "name": "Femenil",
            "slug": "femenil"
          },
          "sub_division": {
            "id": 45,
            "name": "U14",
            "slug": "u14"
          }
        }
      ]
    }
  ]
}
```

## 5) GET `/teams/{clubLinkId}/roster-source`

Devuelve el roster base elegible de la organización para armar un roster competitivo.

### Query params

- `category_id` (optional, int)
- `tournament_id` (optional, int)
- `division_id` (optional, int)
- `sub_division_id` (optional, int)

Notas:
- si mandas `category_id`, backend filtra al roster de esa categoría de la organización
- si además mandas `tournament_id` + `division_id` (+ `sub_division_id` si aplica), backend también regresa `current_entry` para saber quién ya fue enviado

### Response 200

```json
{
  "team": {
    "club_link_id": 239,
    "team_name": "PANTERAS NEGRO U14 FEMENIL"
  },
  "category": {
    "id": 15,
    "name": "U14",
    "slug": "u14"
  },
  "items": [
    {
      "player_id": 345,
      "first_name": "Ana",
      "last_name": "Lopez",
      "display_name": "Ana Lopez",
      "email": "ana@example.com",
      "phone": "5512345678",
      "avatar_url": "https://...",
      "position": "QB",
      "position_id": 2,
      "category_jersey_number": 12,
      "latest_league_jersey_number": 7,
      "current_entry": {
        "jersey_number": 7,
        "position": "QB",
        "position_id": 2
      }
    }
  ],
  "catalogs": {
    "positions": [
      { "id": 2, "code": "QB", "name": "Quarterback" }
    ]
  }
}
```

## 6) GET `/tournaments/{tournamentId}/teams/{clubLinkId}/roster-entries`

Devuelve el roster competitivo ya enviado para ese `club_link_id` dentro de un torneo.

### Query params

- `division_id` (optional, int)
- `sub_division_id` (optional, int)

### Response 200

```json
{
  "team": {
    "club_link_id": 239,
    "team_name": "PANTERAS NEGRO U14 FEMENIL"
  },
  "tournament": {
    "id": 8,
    "name": "Temporada de Verano 2026",
    "slug": "temporada-de-verano-2026",
    "logo_url": "https://...",
    "status": "active",
    "roster_deadline_at": "2026-05-31T23:59:00-06:00",
    "league": {
      "id": 2,
      "name": "LIFFAMH",
      "slug": "liffamh",
      "logo_url": "https://..."
    }
  },
  "items": [
    {
      "id": 887,
      "league_id": 2,
      "tournament_id": 8,
      "division": {
        "id": 32,
        "name": "Femenil",
        "slug": "femenil"
      },
      "sub_division": {
        "id": 45,
        "name": "U14",
        "slug": "u14"
      },
      "club_link_id": 239,
      "player": {
        "id": 345,
        "first_name": "Ana",
        "last_name": "Lopez",
        "display_name": "Ana Lopez",
        "email": "ana@example.com",
        "phone": "5512345678",
        "avatar_url": "https://..."
      },
      "jersey_number": 7,
      "position": "QB",
      "position_id": 2,
      "status": "approved",
      "source": "system_club",
      "created_at": "2026-05-23T12:00:00-06:00",
      "updated_at": "2026-05-23T12:00:00-06:00"
    }
  ]
}
```

## 7) PUT `/tournaments/{tournamentId}/teams/{clubLinkId}/roster-entries/sync`

Sincroniza el roster competitivo final para una categoría/subdivisión.

Este endpoint es transaccional y hace diff:
- crea jugadores nuevos
- actualiza `jersey_number`
- actualiza `position`
- elimina jugadores que ya no vengan en la lista enviada

### Body JSON

```json
{
  "category_id": 15,
  "division_id": 32,
  "sub_division_id": 45,
  "players": [
    {
      "player_id": 345,
      "jersey_number": 7,
      "position_id": 2
    },
    {
      "player_id": 346,
      "jersey_number": 22,
      "position": "RB"
    }
  ]
}
```

Notas:
- `category_id` es opcional, pero si se manda backend valida que todos los players pertenezcan a esa categoría
- `position_id` y `position` son opcionales
- si mandas `position_id`, backend usa el catálogo de posiciones de la organización
- la posición también se sincroniza a la ficha general del `Player`
- no puedes repetir `player_id`
- no puedes repetir `jersey_number` dentro del mismo envío

### Response 200

```json
{
  "message": "Roster competitivo sincronizado correctamente.",
  "team": {
    "club_link_id": 239,
    "team_name": "PANTERAS NEGRO U14 FEMENIL"
  },
  "tournament": {
    "id": 8,
    "name": "Temporada de Verano 2026",
    "slug": "temporada-de-verano-2026",
    "logo_url": "https://..."
  },
  "division": {
    "id": 32,
    "name": "Femenil",
    "slug": "femenil"
  },
  "sub_division": {
    "id": 45,
    "name": "U14",
    "slug": "u14"
  },
  "summary": {
    "total": 2,
    "created_count": 1,
    "updated_count": 1,
    "deleted_count": 3
  },
  "items": [
    {
      "id": 887,
      "club_link_id": 239,
      "jersey_number": 7,
      "position": "QB",
      "position_id": 2
    }
  ]
}
```

## 8) PATCH `/tournaments/{tournamentId}/teams/{clubLinkId}/roster-entries/{entryId}`

Actualiza una asignación puntual del roster competitivo.

### Body JSON

```json
{
  "jersey_number": 10,
  "position": "WR"
}
```

### Response 200

```json
{
  "message": "Asignación de roster actualizada correctamente.",
  "item": {
    "id": 887,
    "club_link_id": 239,
    "jersey_number": 10,
    "position": "WR",
    "position_id": null
  }
}
```

## Errores comunes

- `403 AUTH_CONTEXT_INVALID`
- `403 ORGANIZATION_REQUIRED`
- `403 ORG_MEMBERSHIP_REQUIRED`
- `403 ROSTER_FORBIDDEN`
- `404 TEAM_NOT_FOUND`
- `404 TOURNAMENT_NOT_FOUND`
- `404 CATEGORY_NOT_FOUND`
- `404 ROSTER_DIVISION_NOT_FOUND`
- `404 ROSTER_SUB_DIVISION_NOT_FOUND`
- `404 ROSTER_MEMBER_NOT_FOUND`
- `422 ROSTER_DIVISION_NOT_ENROLLED`
- `422 ROSTER_DEADLINE_EXPIRED`
- `422` validación Laravel para duplicados o payload inválido

## Flujo recomendado de front

1. Llamar `GET /overview`.
2. Si hay datos, mostrar módulo de ligas.
3. Al entrar a un torneo:
   - `GET /tournaments/{tournamentId}/standings`
   - `GET /tournaments/{tournamentId}/fixtures`
4. Si el usuario entra a gestión de roster competitivo:
   - `GET /teams/{clubLinkId}`
   - `GET /teams/{clubLinkId}/roster-source?category_id=...&tournament_id=...&division_id=...&sub_division_id=...`
   - `GET /tournaments/{tournamentId}/teams/{clubLinkId}/roster-entries?...`
   - `PUT /tournaments/{tournamentId}/teams/{clubLinkId}/roster-entries/sync`
