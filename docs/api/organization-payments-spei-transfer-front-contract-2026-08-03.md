# Organization Payments SPEI Transfer Front Contract

Fecha: 2026-08-03

## Objetivo

Permitir que la app de padres genere instrucciones de pago por SPEI con Mercado Pago para un `payment` pendiente al que el usuario autenticado tenga acceso.

## Endpoint

`POST /api/payments/{payment}/providers/mercadopago/intent`

Requiere `auth:sanctum`.

## Autorizacion y proteccion contra enumeracion

El backend valida las dos condiciones siguientes antes de crear o reutilizar un intent:

1. El pago pertenece a la organizacion activa.
2. Si el rol activo es `parent` o `player`, el usuario esta vinculado al jugador del pago:
   - `parent`: su email coincide con `father_email` o `mother_email`.
   - `player`: su usuario o email coincide con el jugador.

Los roles administrativos autorizados (`superadmin`, `admin`, `admin_viewer`, `manager` y `staff`) pueden operar pagos de su organizacion. Otros roles no pueden iniciar intents.

Un pago inexistente, de otra organizacion o de un jugador no accesible devuelve el mismo `404 PAYMENT_NOT_FOUND`. No se usa `403` para no revelar la existencia de otros pagos.

## Request

```json
{
  "payment_method": "spei_transfer"
}
```

`payment_method` es obligatorio para el flujo SPEI. El endpoint conserva `card` como valor predeterminado por compatibilidad con clientes anteriores.

## Creacion y reutilizacion

- `201 Created`: se creo un intent nuevo. `reused` es `false`.
- `200 OK`: se reutilizo un intent vigente para el mismo pago, metodo y saldo pendiente. `reused` es `true`.
- Si cambio el saldo o el metodo, el intent anterior se marca como `superseded` y se crea uno nuevo.
- Si el intent anterior ya expiro, se marca como `expired` y se crea uno nuevo.
- Los intents `rejected`, `cancelled`, `failed` o `expired` nunca se reutilizan.

## Response 200/201

Todos los campos mostrados se incluyen. Los marcados como anulables se envian como `null`; no se omiten.

```json
{
  "payment_id": 456,
  "provider": "mercadopago",
  "payment_method": "spei_transfer",
  "amount": "850.00",
  "currency": "MXN",
  "intent_id": 123,
  "provider_intent_id": "ORD01ABC123",
  "init_url": "https://www.mercadopago.com.mx/payments/.../ticket?...",
  "status": "action_required",
  "status_detail": "waiting_transfer",
  "reference": "646010349353743569",
  "ticket_url": "https://www.mercadopago.com.mx/payments/.../ticket?...",
  "expires_at": "2026-08-06T10:00:00.000-06:00",
  "payment_instructions": {
    "type": "spei_transfer",
    "provider": "mercadopago",
    "status": "action_required",
    "status_detail": "waiting_transfer",
    "reference": "646010349353743569",
    "ticket_url": "https://www.mercadopago.com.mx/payments/.../ticket?...",
    "instructions_url": "https://www.mercadopago.com.mx/payments/.../ticket?...",
    "instructions_url_content_type": "text/html",
    "qr_url": "https://www.mercadopago.com.mx/payments/.../ticket?...",
    "qr_display_mode": "webview_or_external_browser",
    "expires_at": "2026-08-06T10:00:00.000-06:00",
    "steps": [
      "Abre la liga de pago para ver las instrucciones o el QR de Mercado Pago.",
      "Copia la referencia SPEI si tu banco no puede abrir la liga directamente.",
      "Completa la transferencia desde tu app bancaria.",
      "Vuelve a la app y espera la confirmacion automatica del pago."
    ]
  },
  "reused": false
}
```

### Tipos y nulabilidad

- `payment_id`, `intent_id`: integer.
- `amount`: string decimal con dos posiciones; nunca `double`.
- `currency`: codigo ISO 4217; actualmente `MXN`.
- `provider_intent_id`, `init_url`, `status_detail`, `reference`, `ticket_url`, `expires_at`: string o `null`.
- `payment_instructions`: object para `spei_transfer`; `null` para tarjeta.
- Dentro de `payment_instructions`, `status_detail`, `reference`, `ticket_url`, `instructions_url`, `instructions_url_content_type`, `qr_url` y `expires_at` son string o `null`.

`instructions_url` es la denominacion preferida. Es una pagina HTML que debe abrirse en WebView o navegador externo. `qr_url` se conserva temporalmente por compatibilidad, apunta a la misma pagina HTML y **no** debe pasarse a `Image.network`.

## Estados

Estados que el frontend debe tolerar en un intent:

- `created`: creado, aun sin estado mas especifico del proveedor.
- `action_required`: el usuario debe completar la transferencia.
- `pending`: transferencia en espera de confirmacion.
- `approved`: Mercado Pago confirmo el pago.
- `rejected`: Mercado Pago rechazo el pago; ofrecer crear un intent nuevo.
- `cancelled`: cancelado; ofrecer crear un intent nuevo.
- `expired`: vencido; volver a llamar este endpoint para obtener uno nuevo.
- `failed`: fallo definitivo; permitir reintento explicito.
- `superseded`: sustituido por otro intent; no volver a usar sus instrucciones.

El `payment.status`/saldo del endpoint de detalle del pago es la fuente de verdad para decidir si la deuda esta cubierta. El estado del intent solo gobierna la UX de las instrucciones y no debe marcar el pago como liquidado por si solo.

## Errores

Los errores propios de este endpoint usan un codigo estable:

```json
{
  "code": "PAYMENT_ALREADY_COVERED",
  "message": "Este pago ya esta cubierto."
}
```

| HTTP | `code` | Significado / accion |
|---:|---|---|
| 401 | `UNAUTHENTICATED` | Token ausente o invalido; iniciar sesion de nuevo. |
| 404 | `PAYMENT_NOT_FOUND` | Pago inexistente o no accesible. |
| 404 | `PROVIDER_NOT_SUPPORTED` | Proveedor no soportado. |
| 422 | `INVALID_REQUEST` | Request invalido; revisar `errors`. |
| 422 | `PAYMENT_ALREADY_COVERED` | El saldo ya es cero; refrescar el pago. |
| 422 | `PROVIDER_NOT_CONFIGURED` | La organizacion no configuro Mercado Pago. |
| 422 | `PROVIDER_REQUEST_REJECTED` | Mercado Pago rechazo los datos; no reintentar automaticamente. |
| 503 | `PROVIDER_TEMPORARILY_UNAVAILABLE` | Mercado Pago respondio con limite o error temporal. |
| 503 | `PROVIDER_COMMUNICATION_ERROR` | No se pudo comunicar con Mercado Pago. |
| 503 | `PROVIDER_CONFIGURATION_ERROR` | Configuracion interna invalida; informar indisponibilidad. |

Para `503`, frontend puede ofrecer reintento manual. No debe hacer una rafaga automatica de creacion de intents.

La respuesta `401` de este endpoint incluye siempre `code = UNAUTHENTICATED`. Frontend debe decidir por `code` y HTTP status, nunca por el texto traducible de `message`.

## Refresco y polling

1. Refrescar el detalle del `payment` inmediatamente al volver del navegador/WebView.
2. Mostrar siempre una accion manual `Actualizar estado`.
3. Si se implementa polling, consultar el detalle del pago cada 5 segundos durante un maximo de 2 minutos.
4. Detenerlo cuando:
   - el pago quede cubierto (`payment.status = paid` o saldo cero);
   - la app pase a background;
   - se alcance el maximo de 2 minutos;
   - ocurra un error no transitorio (`4xx`, excepto `401`, que requiere reautenticacion).
5. Al volver a foreground, hacer un solo refresco inmediato; no reiniciar polling indefinido sin accion del usuario.

No generar intents en background. La creacion o sustitucion de un intent requiere una accion explicita del usuario.
