import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'ecommerce_orders_controller.dart';

class EcommerceOrdersView extends GetView<EcommerceOrdersController> {
  const EcommerceOrdersView({super.key});

  static final _money = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 2,
  );

  Color _statusColor(String s) {
    final v = s.toLowerCase().trim();
    if (v == 'paid' || v == 'completed') return Colors.green;
    if (v == 'pending_payment' || v == 'pending') return Colors.orange;
    if (v == 'canceled' ||
        v == 'cancelled' ||
        v == 'failed' ||
        v == 'payment_failed')
      return Colors.red;
    return Colors.blueGrey;
  }

  String _statusLabel(String s) {
    final v = s.toLowerCase().trim();
    if (v == 'paid' || v == 'completed') return 'Pagado';
    if (v == 'pending_payment' || v == 'pending') return 'Pendiente';
    if (v == 'canceled' || v == 'cancelled') return 'Cancelado';
    if (v == 'failed' || v == 'payment_failed') return 'Fallido';
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis pedidos'),
        actions: [
          IconButton(
            onPressed: controller.load,
            icon: const Icon(Icons.refresh),
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

          final list = controller.orders;

          return list.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Aún no tienes pedidos.'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: controller.load,
                        child: const Text('Actualizar'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: controller.load,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final o = list[i];
                      final c = _statusColor(o.status);
                      final label = _statusLabel(o.status);

                      return InkWell(
                        onTap: () => controller.openOrder(o),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.black12),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: c.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: c.withOpacity(0.35),
                                  ),
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: c,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      o.folio,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      o.createdAt == null
                                          ? '—'
                                          : DateFormat(
                                              'dd/MM/yyyy  HH:mm',
                                              'es_MX',
                                            ).format(o.createdAt!.toLocal()),
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 12,
                                      ),
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
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _money.format(o.total),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
        }),
      ),
    );
  }
}
