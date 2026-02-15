// lib/modules/home/tabs/payments/payments_tab_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/utils/money.dart';
import 'package:stopandgo/modules/home/tabs/payments/payments_controller.dart';
import 'package:stopandgo/routes/app_routes.dart';
import 'package:stopandgo/core/config/flavor_config.dart';

class PaymentsTabView extends GetView<PaymentsTabController> {
  const PaymentsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.error.value != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(controller.error.value!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: controller.loadPayments,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        );
      }

      final list = controller.filteredPayments;

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  onChanged: controller.setQuery,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Buscar por jugador o concepto…',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    suffixIcon: Obx(() {
                      final hasText = controller.query.value.trim().isNotEmpty;
                      if (!hasText) return const SizedBox.shrink();
                      return IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => controller.setQuery(''),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Obx(() {
                    final selected = controller.statusFilter.value;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: PaymentStatusFilter.values.map((f) {
                        final isSel = f == selected;
                        return ChoiceChip(
                          label: Text(f.label),
                          selected: isSel,
                          onSelected: (_) => controller.setStatusFilter(f),
                        );
                      }).toList(),
                    );
                  }),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: Obx(() {
                        final selected = controller.dueFilter.value;
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: PaymentDueFilter.values.map((f) {
                            final isSel = f == selected;
                            return ChoiceChip(
                              label: Text(f.label),
                              selected: isSel,
                              onSelected: (_) => controller.setDueFilter(f),
                            );
                          }).toList(),
                        );
                      }),
                    ),
                    TextButton.icon(
                      onPressed: controller.clearFilters,
                      icon: const Icon(Icons.filter_alt_off),
                      label: const Text('Limpiar'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1),

          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Text(
                      'Sin pagos con esos filtros',
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final canPayCard = FlavorConfig.I.isPaymentProvider(
                        'mercadopago',
                      );

                      final p = list[i];
                      final paid = p.status == 'paid';
                      final partial = p.status == 'partial';

                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);

                      final isOverdue =
                          !paid &&
                          p.dueDate != null &&
                          p.dueDate!.isBefore(today);

                      final overdueColor = Colors.amber.withOpacity(0.12);

                      final totalRecibido = p.receipts.fold<double>(
                        0.0,
                        (sum, r) => sum + r.amount,
                      );

                      final effectiveAmount = p.netAmount;
                      final double balance = (effectiveAmount - totalRecibido)
                          .clamp(0, double.infinity);

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
                        color: isOverdue ? overdueColor : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ExpansionTile(
                          onExpansionChanged: (expanded) =>
                              controller.setExpanded(p.id, expanded),
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            12,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary
                                .withOpacity(.12),
                            child: const Icon(Icons.receipt_long),
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: chipColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: chipColor.withOpacity(0.45),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: chipColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      chipText,
                                      style: TextStyle(
                                        color: chipColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                p.concept,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (p.playerName != null &&
                                  p.playerName!.isNotEmpty)
                                Text(
                                  p.playerName!,
                                  style: theme.textTheme.bodySmall,
                                ),
                              const SizedBox(height: 2),

                              Text(
                                p.hasDiscount
                                    ? 'Monto: \$${p.amount.toStringAsFixed(2)}\n'
                                          'Con Descuento: ${money(effectiveAmount)} \n'
                                          'Pagado: ${money(totalRecibido)} \n'
                                          'Saldo: ${money(balance)}'
                                    : 'Monto: ${money(p.amount)} \n'
                                          'Pagado: ${money(totalRecibido)} \n'
                                          'Saldo: ${money(balance)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

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
                              const SizedBox(height: 8),
                              Obx(
                                () => Center(
                                  child: AnimatedRotation(
                                    turns:
                                        controller.isExpanded(p.id) ? 0.5 : 0.0,
                                    duration: const Duration(milliseconds: 180),
                                    child: Icon(
                                      Icons.expand_more,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            tooltip: 'Ver detalle',
                            icon: const Icon(Icons.chevron_right, size: 24),
                            onPressed: () async {
                              await Get.toNamed(
                                Routes.paymentDetail,
                                arguments: {
                                  'paymentId': p.id,
                                  'payment': p,
                                },
                              );
                              await controller.loadPayments();
                            },
                          ),
                          children: [
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
                                  title: Text(
                                    '-\$${d.amount.toStringAsFixed(2)}',
                                  ),
                                  subtitle: Text(
                                    d.createdAt != null
                                        ? 'Fecha: ${_fmtDateOnly(d.createdAt!)}'
                                        : 'Sin fecha',
                                  ),
                                );
                              }),
                              const Divider(),
                            ],

                            if (p.receipts.isEmpty)
                              Text(
                                'Sin recibos',
                                style: theme.textTheme.bodySmall,
                              ),

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
                                          onPressed: () =>
                                              _openReceipt(context, r.url!),
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
                                        icon: const Icon(
                                          Icons.payments_outlined,
                                        ),
                                        label: const Text('Pagar'),
                                        onPressed: () async {
                                          await Get.toNamed(
                                            Routes.makePayment,
                                            arguments: {'paymentId': p.id},
                                          );
                                          await controller.loadPayments();
                                        },
                                      ),
                                      if (canPayCard)
                                        Obx(
                                          () => FilledButton.icon(
                                            icon:
                                                controller
                                                    .isPayingWithCard
                                                    .value
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                : const Icon(Icons.credit_card),
                                            label: const Text(
                                              'Pagar con tarjeta',
                                            ),
                                            onPressed:
                                                controller
                                                    .isPayingWithCard
                                                    .value
                                                ? null
                                                : () => controller.payWithCard(
                                                    p.id,
                                                  ),
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
                  ),
          ),
        ],
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
