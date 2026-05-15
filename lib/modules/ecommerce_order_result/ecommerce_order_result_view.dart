import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:stopandgo/core/utils/app_navigator.dart';
import 'ecommerce_order_result_controller.dart';

class EcommerceOrderResultView extends GetView<EcommerceOrderResultController> {
  const EcommerceOrderResultView({super.key});

  static final _money = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 2,
  );

  String? _imageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return 'https://stopandgomx.app/storage/$path';
  }

  _ResultKind _kindFromStatus(String status) {
    final s = status.toLowerCase().trim();

    if (s == 'paid' ||
        s == 'paid_ok' ||
        s == 'completed' ||
        s == 'payment_approved') {
      return _ResultKind.success;
    }

    if (s == 'pending' || s == 'pending_payment' || s == 'in_process') {
      return _ResultKind.pending;
    }

    if (s == 'canceled' ||
        s == 'cancelled' ||
        s == 'failed' ||
        s == 'rejected' ||
        s == 'payment_failed') {
      return _ResultKind.error;
    }

    return _ResultKind.pending;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado del pedido'),
        actions: [
          IconButton(
            onPressed: controller.load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar estado',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final err = controller.error.value;
          if (err != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    err,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: controller.load,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final order = controller.order.value;
          if (order == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No se pudo cargar el pedido.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: controller.load,
                    child: const Text('Actualizar'),
                  ),
                ],
              ),
            );
          }

          final kind = _kindFromStatus(order.status);

          final header = switch (kind) {
            _ResultKind.success => (
              'Pago aprobado',
              'Tu pedido fue confirmado',
              Icons.check_circle_outline,
            ),
            _ResultKind.pending => (
              'Pago pendiente',
              'Estamos esperando confirmación del pago',
              Icons.hourglass_bottom,
            ),
            _ResultKind.error => (
              'Pago no completado',
              'El pago fue rechazado o cancelado',
              Icons.error_outline,
            ),
          };

          return ListView(
            children: [
              _ResultHeader(
                title: header.$1,
                subtitle: header.$2,
                icon: header.$3,
                kind: kind,
                folio: order.folio,
                total: _money.format(order.total),
              ),
              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black12),
                  color: Colors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detalles',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _KV(label: 'Pedido', value: order.folio),
                    _KV(label: 'Estado', value: order.status),
                    _KV(
                      label: 'Entrega',
                      value: order.fulfillmentType == 'delivery'
                          ? 'Envío'
                          : 'Recoger',
                    ),
                    _KV(label: 'Total', value: _money.format(order.total)),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                'Artículos',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),

              ...order.items.map((it) {
                final img = _imageUrl(it.imagePathSnapshot);

                final name = it.productName.isNotEmpty
                    ? it.productName
                    : 'Producto';
                final variant = it.variantTitle.isNotEmpty
                    ? it.variantTitle
                    : '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black12),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 64,
                          width: 64,
                          child: img == null
                              ? Container(
                                  color: Colors.white,
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.image_not_supported_outlined,
                                  ),
                                )
                              : Container(
                                  color: Colors.white,
                                  alignment: Alignment.center,
                                  child: Image.network(
                                    img,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.broken_image_outlined),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (variant.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                variant,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              'Cantidad: ${it.qty}',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _money.format(it.lineTotal),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 6),

              _Actions(kind: kind, controller: controller),

              const SizedBox(height: 10),
            ],
          );
        }),
      ),
    );
  }
}

enum _ResultKind { success, pending, error }

class _ResultHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final _ResultKind kind;
  final String folio;
  final String total;

  const _ResultHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.kind,
    required this.folio,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (kind) {
      _ResultKind.success => Colors.green,
      _ResultKind.pending => Colors.orange,
      _ResultKind.error => Colors.red,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Icon(icon, size: 38, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 8),
                Text(
                  'Pedido: $folio',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 2),
              Text(total, style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }
}

class _KV extends StatelessWidget {
  final String label;
  final String value;
  const _KV({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final _ResultKind kind;
  final EcommerceOrderResultController controller;

  const _Actions({required this.kind, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (kind == _ResultKind.success) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: controller.goOrders,
              child: const Text('Ver mis pedidos'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: controller.goHomeShop,
              child: const Text('Volver a la tienda'),
            ),
          ),
        ],
      );
    }

    if (kind == _ResultKind.pending) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: controller.load,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar estado'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: controller.goOrderDetail,
              child: const Text('Ir al inicio'),
            ),
          ),
        ],
      );
    }

    // error
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: controller.retryPayment,
            child: const Text('Reintentar pago'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton(
            onPressed: () => AppNavigator.maybePop(context),
            child: const Text('Volver'),
          ),
        ),
      ],
    );
  }
}
