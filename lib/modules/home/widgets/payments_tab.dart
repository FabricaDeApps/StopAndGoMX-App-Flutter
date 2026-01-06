import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/modules/home/home_controller.dart';
import 'package:stopandgo/routes/app_routes.dart';

import '../../../core/config/flavor_config.dart';

class PaymentsTab extends StatelessWidget {
  const PaymentsTab({super.key, required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      if (controller.isLoadingPayments.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final list = controller.payments;
      if (list.isEmpty) {
        return Center(
          child: Text('Sin pagos', style: theme.textTheme.bodyMedium),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          debugPrint('Flavor: ${FlavorConfig.I.flavor}');
          debugPrint('Providers: ${FlavorConfig.I.paymentProvider}');

          final canPayCard = FlavorConfig.I.isPaymentProvider('mercadopago');
          final p = list[i];
          final paid = p.status == 'paid';
          final partial = p.status == 'partial';

          // 💰 Total recibido (suma de recibos)
          final totalRecibido = p.receipts.fold<double>(
            0.0,
            (sum, r) => sum + r.amount,
          );

          // 💳 Monto efectivo después de descuentos
          final effectiveAmount = p.netAmount; // <- ya viene del backend/DTO

          // 🧮 Saldo = neto - pagado
          final balance = (effectiveAmount - totalRecibido).clamp(
            0,
            double.infinity,
          );

          Color chipColor;
          String chipText;
          if (paid) {
            chipColor = Colors.green;
            chipText = 'Pagado';
          } else if (partial) {
            chipColor = Colors.orange;
            chipText = 'Parcial';
          } else {
            chipColor = Colors.red;
            chipText = 'Pendiente';
          }

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withOpacity(.12),
                child: const Icon(Icons.receipt_long),
              ),
              title: Text(
                p.concept,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (p.playerName != null && p.playerName!.isNotEmpty)
                    Text(p.playerName!, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 2),

                  // Línea principal con Monto/Neto/Pagado/Saldo
                  Text(
                    // Monto original + neto si hay descuento
                    p.hasDiscount
                        ? 'Monto: \$${p.amount.toStringAsFixed(2)} '
                              '· Neto: \$${effectiveAmount.toStringAsFixed(2)} '
                              '· Pagado: \$${totalRecibido.toStringAsFixed(2)} '
                              '· Saldo: \$${balance.toStringAsFixed(2)}'
                        : 'Monto: \$${p.amount.toStringAsFixed(2)} '
                              '· Pagado: \$${totalRecibido.toStringAsFixed(2)} '
                              '· Saldo: \$${balance.toStringAsFixed(2)}',
                    style: theme.textTheme.bodySmall,
                  ),

                  // Línea corta con el total descontado
                  if (p.hasDiscount) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Descuento aplicado: -\$${p.discountsSumAmount.toStringAsFixed(2)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  if (p.dueDate != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Vence: ${_fmtDateOnly(p.dueDate!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
              trailing: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Chip(
                    label: Text(
                      chipText,
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: chipColor,
                  ),
                ],
              ),
              children: [
                // 🔹 Detalle de DESCUENTOS (si hay)
                if (p.hasDiscount && p.discounts.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Descuentos aplicados',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...p.discounts.map((d) {
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.local_offer),
                      title: Text('-\$${d.amount.toStringAsFixed(2)}'),
                      subtitle: Text(
                        d.createdAt != null
                            ? 'Fecha: ${_fmtDateOnly(d.createdAt!)}'
                            : 'Sin fecha',
                      ),
                    );
                  }),
                  const Divider(),
                ],

                // 🔹 Detalle de RECIBOS
                if (p.receipts.isEmpty)
                  Text('Sin recibos', style: theme.textTheme.bodySmall),
                if (p.receipts.isNotEmpty)
                  ...p.receipts.map((r) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.attach_money),
                      title: Text(
                        '\$${r.amount.toStringAsFixed(2)} • ${r.method}',
                      ),
                      subtitle: Text(
                        '${_fmtDateTime(r.paidAt)}'
                        '${r.reference != null ? ' · Ref: ${r.reference}' : ''}',
                      ),
                      trailing: r.url != null
                          ? IconButton(
                              icon: const Icon(Icons.open_in_new),
                              tooltip: 'Ver comprobante',
                              onPressed: () => _openReceipt(context, r.url!),
                            )
                          : null,
                    );
                  }),

                if (!paid)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.end,
                        children: [
                          FilledButton.icon(
                            icon: const Icon(Icons.payments_outlined),
                            label: const Text('Pagar'),
                            onPressed: () async {
                              await Get.toNamed(
                                Routes.makePayment,
                                arguments: {'paymentId': p.id},
                              );
                              controller.loadPaymentsTab();
                            },
                          ),

                          if (canPayCard)
                            Obx(
                              () => FilledButton.icon(
                                icon: controller.isPayingWithCard.value
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.credit_card),
                                label: const Text('Pagar con tarjeta'),
                                onPressed: controller.isPayingWithCard.value
                                    ? null
                                    : () => controller.payWithCard(p.id),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    });
  }

  static String _fmtDateOnly(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _fmtDateTime(DateTime? d) {
    if (d == null) return 'Sin fecha';
    return '${_fmtDateOnly(d)} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  void _openReceipt(BuildContext context, String url) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.image, size: 28),
              const SizedBox(height: 8),
              Text(
                'Comprobante',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () {
                  Get.back();
                  Get.toNamed(Routes.imageView, arguments: {'url': url});
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Abrir'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
