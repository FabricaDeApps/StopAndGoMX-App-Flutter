# Ecommerce API Changes

Fecha: 2026-05-05

Este documento resume los cambios realizados en la API de ecommerce para soportar seleccion de atributos por producto sin romper integraciones existentes ni pedidos historicos.

## Objetivo

Antes, la app debia conocer directamente la `variant_id` para agregar un producto al carrito.

Ahora la API tambien soporta este flujo:

1. Obtener producto con atributos disponibles.
2. Seleccionar valores de atributos, por ejemplo `Color=Rojo` y `Talla=M`.
3. Resolver la variante correcta.
4. Agregar al carrito usando la combinacion seleccionada.

## Compatibilidad hacia atras

Los cambios son backward compatible.

- Sigue funcionando `POST /api/ecommerce/cart/items` enviando `variant_id`.
- Los pedidos existentes no cambian.
- Los snapshots historicos de `ecommerce_order_items` no se modifican.

## Endpoints actualizados

### 1. `GET /api/ecommerce/products/{product}`

Sigue devolviendo el producto, pero ahora incluye dos bloques nuevos:

- `attribute_groups`
- `variant_matrix`

#### Nuevo payload adicional

```json
{
  "data": {
    "id": 15,
    "name": "Jersey Local",
    "active_variants": []
  },
  "attribute_groups": [
    {
      "id": 1,
      "name": "Color",
      "values": [
        { "id": 10, "value": "red", "label": "Rojo" },
        { "id": 11, "value": "blue", "label": "Azul" }
      ]
    },
    {
      "id": 2,
      "name": "Talla",
      "values": [
        { "id": 20, "value": "m", "label": "M" },
        { "id": 21, "value": "l", "label": "L" }
      ]
    }
  ],
  "variant_matrix": [
    {
      "id": 100,
      "title": "Jersey Local - Rojo - M",
      "price_cents": 39900,
      "stock": 8,
      "is_active": true,
      "value_ids": [10, 20]
    },
    {
      "id": 101,
      "title": "Jersey Local - Rojo - L",
      "price_cents": 39900,
      "stock": 4,
      "is_active": true,
      "value_ids": [10, 21]
    }
  ]
}
```

### 2. Nuevo endpoint: `POST /api/ecommerce/products/{product}/resolve-variant`

Este endpoint permite resolver una variante activa a partir de los valores seleccionados.

#### Request

```json
{
  "value_ids": [10, 20]
}
```

#### Response

```json
{
  "data": {
    "variant_id": 100,
    "title": "Jersey Local - Rojo - M",
    "price_cents": 39900,
    "stock": 8,
    "is_active": true,
    "value_ids": [10, 20]
  }
}
```

#### Uso recomendado en app

1. Cargar detalle del producto.
2. Mostrar `attribute_groups`.
3. Cuando el usuario termine de elegir atributos, llamar `resolve-variant`.
4. Con la `variant_id` resuelta, mostrar precio/stock y permitir agregar al carrito.

### 3. `POST /api/ecommerce/cart/items`

Este endpoint ahora soporta dos modos.

#### Modo anterior

```json
{
  "variant_id": 100,
  "qty": 1
}
```

#### Nuevo modo

```json
{
  "product_id": 15,
  "value_ids": [10, 20],
  "qty": 1
}
```

En el nuevo modo, el backend resuelve internamente la variante activa que coincide exactamente con esa combinacion.

#### Respuesta

La respuesta sigue devolviendo el carrito con items, variante, producto y values asociados.

## Reglas nuevas de negocio

Se reforzo la consistencia de variantes en admin y backend:

- Una variante solo puede tener un valor por `option_set`.
- No se permiten combinaciones duplicadas dentro del mismo producto.
- Si no existe una variante activa para la combinacion seleccionada, la API responde error.

## Impacto para la app

Si la app actual ya usa `variant_id`:

- no necesita cambiar para seguir operando;
- pero no aprovechara la nueva seleccion por atributos hasta implementar el nuevo flujo.

Si la app quiere soportar atributos:

1. usar `GET /api/ecommerce/products/{product}`;
2. renderizar `attribute_groups`;
3. resolver variante con `POST /api/ecommerce/products/{product}/resolve-variant`;
4. agregar al carrito con `variant_id` o con `product_id + value_ids`.

## Archivos backend tocados

- `app/Http/Controllers/Api/Ecommerce/CatalogController.php`
- `app/Http/Controllers/Api/Ecommerce/CartController.php`
- `routes/api.php`

## Nota sobre pedidos existentes

Los pedidos historicos siguen siendo validos porque el checkout mantiene snapshots en `ecommerce_order_items`, incluyendo:

- `product_name_snapshot`
- `variant_title_snapshot`
- `variant_values_snapshot`
- `unit_price_cents_snapshot`

No se rehizo ni se reinterpretó informacion historica.
