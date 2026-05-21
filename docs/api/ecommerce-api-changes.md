# Ecommerce Variants Front Contract

Fecha: 2026-05-21

Este documento resume dos cambios para frontend/app:

1. Admin de variantes ahora permite marcar varios valores dentro de un mismo atributo.
2. La API de ecommerce resuelve variantes a partir de una seleccion de un valor por atributo y ahora expone precio MXN/USD con fallback de visualizacion.

## 1. Cambio en admin

En `admin/ecommerce/variants/create` y `admin/ecommerce/variants/{id}/edit`:

- cada `option set` ahora usa `checkbox` por valor;
- una variante puede guardar varios valores dentro del mismo atributo;
- ejemplo valido:
  - `Color`: `Rojo`, `Negra`
  - `Talla`: `M`, `L`

Eso significa que una sola variante puede representar varias combinaciones permitidas para el mismo producto.

## 2. Regla de precio para frontend

Cada variante puede tener:

- `price_cents` en MXN
- `price_usd` en USD

Regla de visualizacion:

- si la variante tiene MXN, ese es el precio default a mostrar;
- si no tiene MXN pero si tiene USD, mostrar USD.

La API ahora expone un bloque `pricing` por variante:

```json
{
  "currency": "MXN",
  "amount": 399.0,
  "price_cents_mxn": 39900,
  "price_usd": 24.99
}
```

Notas:

- `currency` es la moneda default para mostrar esa variante.
- `amount` es el monto ya listo para UI en moneda mayor.
- `price_cents_mxn` puede venir `null`.
- `price_usd` puede venir `null`.

## 3. Flujo que debe usar la app

Para cada producto:

1. cargar detalle del producto;
2. renderizar `attribute_groups`;
3. permitir al usuario elegir solo un valor por atributo;
4. enviar esa seleccion al endpoint `resolve-variant`;
5. con la variante resuelta, mostrar precio/stock y agregar al carrito.

Importante:

- aunque una variante en admin pueda tener varios valores por atributo, la app debe mandar solo un valor elegido por cada atributo;
- el backend hara el matching contra las variantes activas que contengan esos valores seleccionados.

## 4. Endpoints actualizados

### `GET /api/ecommerce/products/{product}`

Sigue devolviendo:

- `data`
- `attribute_groups`
- `variant_matrix`

Ejemplo:

```json
{
  "data": {
    "id": 15,
    "name": "Playera manga corta"
  },
  "attribute_groups": [
    {
      "id": 1,
      "name": "Color",
      "values": [
        { "id": 10, "value": "red", "label": "Rojo" },
        { "id": 11, "value": "black", "label": "Negra" }
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
      "title": "Playera manga corta",
      "price_cents": 39900,
      "price_usd": 24.99,
      "pricing": {
        "currency": "MXN",
        "amount": 399.0,
        "price_cents_mxn": 39900,
        "price_usd": 24.99
      },
      "stock": 8,
      "is_active": true,
      "value_ids": [10, 11, 20, 21],
      "option_set_ids": [1, 2]
    }
  ]
}
```

Interpretacion del ejemplo:

- la variante `100` acepta `Rojo` o `Negra`;
- y acepta `M` o `L`.

## 5. Resolve variant

### `POST /api/ecommerce/products/{product}/resolve-variant`

#### Request

La app manda solo un valor por atributo:

```json
{
  "value_ids": [10, 20]
}
```

Ejemplo:

- `10` = `Color: Rojo`
- `20` = `Talla: M`

#### Regla de matching en backend

Una variante hace match cuando:

- contiene todos los `value_ids` seleccionados;
- y cubre exactamente los mismos atributos seleccionados por el usuario.

Si varias variantes hacen match, backend prioriza la mas especifica.

#### Response

```json
{
  "data": {
    "variant_id": 100,
    "title": "Playera manga corta",
    "price_cents": 39900,
    "price_usd": 24.99,
    "pricing": {
      "currency": "MXN",
      "amount": 399.0,
      "price_cents_mxn": 39900,
      "price_usd": 24.99
    },
    "stock": 8,
    "is_active": true,
    "value_ids": [10, 20]
  }
}
```

#### Error de validacion esperado

Si la app manda dos valores del mismo atributo:

```json
{
  "message": "Debes enviar solo un valor por atributo."
}
```

## 6. Carrito

### `POST /api/ecommerce/cart/items`

Sigue soportando dos modos.

#### Modo legado

```json
{
  "variant_id": 100,
  "qty": 1
}
```

#### Modo por seleccion

```json
{
  "product_id": 15,
  "value_ids": [10, 20],
  "qty": 1
}
```

En este segundo modo:

- la app manda un valor por atributo;
- backend resuelve la variante y la agrega al carrito.

## 7. Compatibilidad

Backward compatible:

- sigue funcionando agregar al carrito con `variant_id`;
- los pedidos historicos no cambian;
- los snapshots historicos siguen validos.

## 8. Consideraciones de moneda

Backend usa esta prioridad por variante:

1. `price_cents` MXN si existe
2. `price_usd` si MXN viene vacio

Para checkout:

- no se permite mezclar variantes MXN y USD en el mismo carrito;
- si eso pasa, backend responde error.

## 9. Archivos backend relevantes

- `app/Http/Controllers/Admin/Ecommerce/EcommerceVariantController.php`
- `resources/views/admin/ecommerce/variants/create.blade.php`
- `resources/views/admin/ecommerce/variants/edit.blade.php`
- `app/Http/Controllers/Api/Ecommerce/CatalogController.php`
- `app/Http/Controllers/Api/Ecommerce/CartController.php`
- `app/Http/Controllers/Api/Ecommerce/CheckoutController.php`
- `app/Models/EcommerceVariant.php`
