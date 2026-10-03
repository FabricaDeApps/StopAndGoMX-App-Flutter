# Visibilidad de transferencia SPEI de Mercado Pago

En editar organización, sección **Proveedor de pago**, la opción
**Mostrar transferencia SPEI de Mercado Pago en la app** guarda
`organization_payment_providers.spei_transfer_enabled` (booleano, por defecto `false`).

La respuesta de `GET /api/public/organization/{orgId}` incluye:

```json
{
  "data": {
    "pay_card_enabled": true,
    "pay_spei_transfer_enabled": true
  }
}
```

La app debe mostrar la opción de transferencia de Mercado Pago únicamente cuando
`data.pay_spei_transfer_enabled === true`; si el campo falta, debe tratarlo como
`false`. Esta bandera requiere el proveedor `mercadopago` habilitado y la nueva
opción marcada. La bandera de tarjeta conserva su comportamiento actual.

Es una opción de visibilidad: no modifica la autorización del endpoint de intentos.
Al seleccionar transferencia, la app sigue enviando `payment_method: "spei_transfer"`
al endpoint de intentos de Mercado Pago. El backend mantiene su validación de
proveedor habilitado y credenciales para procesar el pago.

## Despliegue

Ejecutar `php artisan migrate --force` antes de servir el código nuevo. Las
organizaciones existentes comienzan con la opción apagada; activarla por organización.
Guardar la edición invalida la caché de información pública. Una respuesta almacenada
antes del despliegue puede omitir el campo hasta que expire su caché de 10 minutos
o se guarde la organización.

La aplicación móvil debe consumir la bandera; este repositorio contiene el backend.
