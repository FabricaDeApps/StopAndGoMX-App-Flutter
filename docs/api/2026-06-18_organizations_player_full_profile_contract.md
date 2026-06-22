# 2026-06-18 Organizations Player Full Profile Contract

## Resumen

Se agregan 3 endpoints para consultar el `fullProfile` de un jugador en el contexto de `organizations`, con el mismo contrato de respuesta y distinta autorizacion segun el viewer:

1. `manager` consulta por `player_id`
2. `parent` consulta por `player_id` de uno de sus hijos vinculados
3. `player` consulta su propio perfil vinculado

Todos los endpoints requieren:

- `Authorization: Bearer <token>`
- `X-Organization-Id: <org_id>`

Para `parent` y `player`, si el usuario tiene multiples roles, se recomienda mandar tambien:

- `X-Active-Role: parent`
- `X-Active-Role: player`

## Endpoints

### 1. Manager full profile

`GET /api/manager/players/{player}/full-profile`

#### Acceso

- `manager`
- `admin`
- `superadmin`

#### Reglas de acceso

- El jugador debe pertenecer a la organizacion del header `X-Organization-Id`
- Si el viewer es `manager`, debe gestionar al menos una categoria del jugador

### 2. Parent full profile

`GET /api/player/my-players/{player}/full-profile`

#### Acceso

- `parent` como rol activo

#### Reglas de acceso

- El jugador debe pertenecer a la organizacion del header `X-Organization-Id`
- El email del usuario debe coincidir con `father_email` o `mother_email` del jugador

### 3. Player own full profile

`GET /api/player/me/full-profile`

#### Acceso

- `player` como rol activo

#### Reglas de acceso

- El sistema resuelve el jugador por email del usuario dentro de la organizacion indicada en `X-Organization-Id`

---

## Response 200

Todos responden el mismo shape:

```json
{
  "data": {
    "player": {
      "id": 123,
      "organization_id": 44,
      "organization": {
        "id": 44,
        "name": "Borregos Academy",
        "slug": "borregos-academy",
        "logo_url": "https://example.com/storage/orgs/logo.png"
      },
      "first_name": "Juan",
      "last_name": "Perez",
      "full_name": "Juan Perez",
      "alias": "Juani",
      "photo_url": "https://example.com/storage/players/44/photo.jpg",
      "is_active": true,
      "confirmed": true,
      "created_at": "2026-06-18T16:22:31Z"
    },
    "personal": {
      "email": "juan@example.com",
      "phone": "4421234567",
      "birthdate": "2012-04-10",
      "birth_place": "Queretaro",
      "curp": "XXXX000000HXXXXXX",
      "address": "Calle 1",
      "cp": "76000",
      "city": "Queretaro",
      "state": "Queretaro"
    },
    "sport": {
      "position": "QB",
      "position_id": 5,
      "position_catalog_name": "Quarterback",
      "size_shirt": "M",
      "size_pants": "30",
      "talla": "M",
      "peso": 54.5,
      "blood_type": "O+"
    },
    "health": {
      "allergies": "Ninguna",
      "have_insurance": true,
      "insurance_name": "AXA",
      "has_played_in_fademac": false,
      "fademac_team_name": "",
      "interest_area": "Defensa"
    },
    "family": {
      "father": {
        "name": "Pedro Perez",
        "email": "padre@example.com",
        "phone": "4420001111"
      },
      "mother": {
        "name": "Maria Lopez",
        "email": "madre@example.com",
        "phone": "4420002222"
      }
    },
    "categories": [
      {
        "id": 7,
        "name": "U14",
        "slug": "u14",
        "jersey_number": 12,
        "is_captain": false,
        "status": "active",
        "assigned_at": "2026-01-10T12:00:00Z"
      }
    ],
    "documents": {
      "summary": {
        "required_total": 4,
        "required_completed": 3,
        "required_pending": 1,
        "completion_ratio": 0.75,
        "uploaded_total": 5
      },
      "requirements": [
        {
          "id": 11,
          "name": "Acta de nacimiento",
          "slug": "acta-nacimiento",
          "description": "Documento oficial",
          "is_required": true,
          "is_active": true,
          "sort_order": 1,
          "expires_in_days": null,
          "is_uploaded": true,
          "document": {
            "id": 501,
            "required_document_id": 11,
            "required_document_name": "Acta de nacimiento",
            "required_document_slug": "acta-nacimiento",
            "original_name": "acta.pdf",
            "mime_type": "application/pdf",
            "size": 284331,
            "url": "https://example.com/storage/player-documents/acta.pdf",
            "uploaded_at": "2026-06-10T13:04:00Z"
          }
        }
      ],
      "extra_documents": [
        {
          "id": 601,
          "required_document_id": null,
          "required_document_name": "",
          "required_document_slug": "",
          "original_name": "extra.jpg",
          "mime_type": "image/jpeg",
          "size": 182771,
          "url": "https://example.com/storage/player-documents/extra.jpg",
          "uploaded_at": "2026-06-11T11:44:00Z"
        }
      ]
    },
    "payments": {
      "summary": {
        "total_count": 6,
        "pending_count": 2,
        "partial_count": 1,
        "paid_count": 3,
        "total_due": 5400,
        "total_paid": 3900,
        "total_balance": 1500
      },
      "recent": [
        {
          "id": 9001,
          "concept": "Mensualidad junio",
          "status": "pending",
          "due_date": "2026-06-20",
          "paid_at": null,
          "category": {
            "id": 7,
            "name": "U14",
            "slug": "u14"
          },
          "amount": 1800,
          "total_due": 1800,
          "amount_paid": 0,
          "balance": 1800
        }
      ]
    }
  },
  "meta": {
    "viewer_role": "manager",
    "organization_id": 44,
    "player_id": 123
  }
}
```

---

## Campo por campo

### `data.player`

- Identidad base del jugador
- Incluye organizacion y `photo_url`

### `data.personal`

- Datos personales y de contacto

### `data.sport`

- Posicion y datos fisicos/deportivos

### `data.health`

- Alergias, seguro y antecedentes Fademac

### `data.family`

- Contactos de padre y madre

### `data.categories`

- Categorias del jugador dentro de la organizacion
- Incluye `jersey_number`, `is_captain`, `status` y fecha de asignacion

### `data.documents.summary`

- Resumen de cumplimiento documental

### `data.documents.requirements`

- Requisitos documentales activos de la organizacion
- Si el jugador ya subio documento para ese requirement, viene en `document`

### `data.documents.extra_documents`

- Documentos subidos sin requirement asociado

### `data.payments.summary`

- Resumen agregado de cobranza del jugador

### `data.payments.recent`

- Ultimos 5 pagos del jugador ordenados por `due_date desc, id desc`

---

## Errores esperados

### `403 Forbidden`

```json
{
  "message": "No autorizado (rol)"
}
```

O segun el caso:

```json
{
  "message": "No autorizado (manager sin acceso al jugador)"
}
```

```json
{
  "message": "No autorizado (no coincide email)"
}
```

```json
{
  "message": "No autorizado (rol activo player requerido)"
}
```

### `404 Not Found`

```json
{
  "message": "Jugador vinculado al usuario no encontrado en la organizacion"
}
```

---

## Recomendaciones front

### Manager

- Usar `GET /api/manager/players/{player}/full-profile`
- Ideal para una pantalla de ficha completa del roster

### Parent

- Primero listar hijos con `GET /api/player/my-players`
- Luego abrir `GET /api/player/my-players/{player}/full-profile`

### Player

- Consumir directamente `GET /api/player/me/full-profile`
- No requiere mandar `player_id`

---

## Compatibilidad

Esto no reemplaza endpoints existentes como:

- `GET /api/manager/players/{player}/file`
- `GET /api/player/my-players/{player}`

La idea es que `full-profile` sea el endpoint nuevo y estable para vistas completas de perfil.
