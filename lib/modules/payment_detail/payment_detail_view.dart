import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/dto/receipt_dto.dart';
import 'package:stopandgo/core/utils/app_navigator.dart';
import 'package:stopandgo/core/utils/money.dart';
import 'package:stopandgo/routes/app_routes.dart';
import 'payment_detail_controller.dart';

class PaymentDetailView extends GetView<PaymentDetailController> {
  const PaymentDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      if (controller.isLoading.value) {
        return Scaffold(
          appBar: AppBar(title: const Text('Detalle de pago')),
          body: const Center(child: CircularProgressIndicator()),
        );
      }

      if (controller.error.value != null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Detalle de pago')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(controller.error.value!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () async {
                      await controller.loadPayment();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      final p = controller.payment.value;
      if (p == null) {
        return Scaffold(
          appBar: AppBar(title: Text('Detalle de pago')),
          body: Center(child: Text('No hay información del pago.')),
        );
      }

      final totalRecibido = p.totalReceipts;
      final balance = p.remainingAfterDiscountsAndReceipts;
      final paid = p.status == 'paid';
      final partial = p.status == 'partial';

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

      return Scaffold(
        appBar: AppBar(title: const Text('Detalle de pago')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _StatusPill(
                            label: chipText,
                            color: chipColor,
                            icon: paid
                                ? Icons.verified_rounded
                                : partial
                                ? Icons.pie_chart_rounded
                                : Icons.receipt_long_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        p.concept,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Monto: ${money(p.netAmount)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: chipColor,
                        ),
                      ),
                      if ((p.playerName ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            p.playerName!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricTile(
                              label: p.hasDiscount ? 'Monto final' : 'Monto',
                              value: money(p.netAmount),
                              tint: chipColor,
                              emphasis: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricTile(
                              label: 'Pagado',
                              value: money(totalRecibido),
                              tint: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _MetricTile(
                        label: 'Saldo pendiente',
                        value: money(balance),
                        tint: paid ? Colors.green : chipColor,
                        emphasis: true,
                        fullWidth: true,
                      ),
                      if (p.hasDiscount) ...[
                        const SizedBox(height: 12),
                        _MetaBadge(
                          icon: Icons.local_offer_outlined,
                          text: 'Descuento: -${money(p.discountsSumAmount)}',
                        ),
                      ],
                      if (p.dueDate != null) ...[
                        const SizedBox(height: 12),
                        _MetaBadge(
                          icon: Icons.event_outlined,
                          text: 'Vence: ${_fmtDateOnly(p.dueDate!)}',
                        ),
                      ],
                      if (p.paidAt != null) ...[
                        const SizedBox(height: 12),
                        _MetaBadge(
                          icon: Icons.check_circle_outline_rounded,
                          text: 'Liquidado: ${_fmtDateTime(p.paidAt)}',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (p.discounts.isNotEmpty)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Descuentos aplicados',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...p.discounts.map(
                          (d) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: theme.colorScheme.primary.withValues(
                                  alpha: .10,
                                ),
                              ),
                              child: Icon(
                                Icons.local_offer,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            title: Text('-${money(d.amount)}'),
                            subtitle: Text(
                              d.createdAt != null
                                  ? 'Fecha: ${_fmtDateOnly(d.createdAt!)}'
                                  : 'Sin fecha',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                        'Historial de recibos',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (p.receipts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text('Sin recibos'),
                        ),
                      ...p.receipts.map((r) => _receiptTile(context, r)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!controller.isPaid)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      await controller.goToMakePayment();
                    },
                    icon: const Icon(Icons.payments_outlined),
                    label: Text(
                      balance > 0
                          ? 'Pagar ${money(balance)}'
                          : 'Registrar pago',
                    ),
                  ),
                ),
              if (!controller.isPaid && controller.canPayWithCard)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: controller.isPayingWithCard.value
                        ? null
                        : () async {
                            await controller.payWithCard();
                          },
                    icon: controller.isPayingWithCard.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.credit_card_rounded),
                    label: const Text('Pagar con tarjeta'),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _receiptTile(BuildContext context, ReceiptDto r) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: theme.colorScheme.primary.withValues(alpha: .10),
        ),
        child: Icon(
          Icons.attach_money,
          color: theme.colorScheme.primary,
        ),
      ),
      title: Text('${money(r.amount)} • ${r.method}'),
      subtitle: Text(
        '${_fmtDateTime(r.paidAt)}${r.reference != null ? ' · Ref: ${r.reference}' : ''}',
      ),
      trailing: r.url != null
          ? IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Ver comprobante',
              onPressed: () => _openReceipt(context, r.url!),
            )
          : null,
    );
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
                  AppNavigator.pop(context: context);
                  Get.toNamed(Routes.imageView, arguments: {'url': url});
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Abrir'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.tint,
    this.emphasis = false,
    this.fullWidth = false,
  });

  final String label;
  final String value;
  final Color tint;
  final bool emphasis;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tint.withValues(alpha: .12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: emphasis ? FontWeight.w900 : FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .42),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
