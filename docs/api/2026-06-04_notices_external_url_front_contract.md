# Avisos Organization - Front Contract

Fecha: 2026-06-04

## Alcance

Se agrega soporte para `external_url` en avisos de organización.

Este campo:

- es opcional
- puede convivir con `attachment`
- permite que front abra un enlace externo relacionado al aviso

No reemplaza el adjunto actual.

## Regla de negocio

- Un aviso puede no tener adjunto ni URL.
- Un aviso puede tener solo `attachment`.
- Un aviso puede tener solo `external_url`.
- Un aviso puede tener ambos: `attachment` y `external_url`.

## Shape actualizado de aviso

Los endpoints que regresan avisos deben considerar este shape:

```json
{
  "id": 123,
  "organization_id": 45,
  "category_id": 8,
  "category_ids": [8, 9],
  "category_name": "U12",
  "categories": [
    {
      "id": 8,
      "name": "U12"
    }
  ],
  "title": "Cambio de horario",
  "message": "El entrenamiento de hoy cambia a las 7:00 pm.",
  "image": null,
  "attachment": "https://stopandgomx.app/storage/notices/attachments/45/archivo.pdf",
  "external_url": "https://zoom.us/j/123456789",
  "is_published": true,
  "published_at": "2026-06-04 10:30:00",
  "expires_at": null,
  "author": {
    "id": 77,
    "name": "Admin Club"
  }
}
```

## Campo nuevo

- `external_url`: `string|null`
  - URL absoluta
  - ejemplo: `https://...`
  - si no existe, vendrá `null`

## Compatibilidad

- `attachment` se mantiene sin cambios
- `external_url` se agrega sin romper contratos previos
- front puede seguir usando `attachment` como hoy
- si `external_url` viene con valor, front puede pintar CTA adicional como:
  - `Abrir enlace`
  - `Ir al link`
  - `Ver más`

## Endpoints impactados

### 1. Player / Parent

`GET /api/player/my-notices`

Ahora cada item puede incluir:

```json
{
  "external_url": "https://example.com"
}
```

### 2. Manager

`GET /api/manager/notices`

Ahora cada item puede incluir:

```json
{
  "external_url": "https://example.com"
}
```

### 3. Dashboard / respuestas embebidas de notices

Hay respuestas del backend que construyen avisos manualmente en payloads de dashboard y también incluyen:

```json
{
  "external_url": "https://example.com"
}
```

### 4. Crear aviso desde app

Aplica a:

- `POST /api/manager/{category}/notices`
- `POST /api/coach/categories/{category}/notices`

## Request actualizado para creación desde app

Además de los campos existentes, backend acepta:

```json
{
  "title": "Junta informativa",
  "message": "Nos vemos hoy a las 8 pm.",
  "external_url": "https://meet.google.com/abc-defg-hij"
}
```

## Validación backend

- `external_url`
  - opcional
  - tipo `url`
  - máximo `2048` caracteres

## Notas para front

- No asumir que `attachment` y `external_url` son mutuamente excluyentes.
- Si ambos existen, conviene mostrar dos acciones separadas.
- Si `external_url` es `null`, no mostrar CTA de enlace.
- Si `attachment` es `null`, no mostrar CTA de archivo.

## Resumen

Cambio compatible hacia atrás:

- se conserva `attachment`
- se agrega `external_url`
- el nuevo campo es opcional
