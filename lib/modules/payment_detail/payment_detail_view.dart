import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/dto/receipt_dto.dart';
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
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.concept,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Chip(
                            backgroundColor: chipColor,
                            label: Text(
                              chipText,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      if ((p.playerName ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            p.playerName!,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      const SizedBox(height: 10),
                      Text('Monto: ${money(p.amount)}'),
                      if (p.hasDiscount) ...[
                        Text('Descuento: -${money(p.discountsSumAmount)}'),
                        Text('Neto: ${money(p.netAmount)}'),
                      ],
                      Text('Pagado: ${money(totalRecibido)}'),
                      Text('Saldo: ${money(balance)}'),
                      if (p.dueDate != null)
                        Text('Vence: ${_fmtDateOnly(p.dueDate!)}'),
                      if (p.paidAt != null)
                        Text('Liquidado: ${_fmtDateTime(p.paidAt)}'),
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
                            leading: const Icon(Icons.local_offer),
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
                    onPressed: () async {
                      await controller.goToMakePayment();
                    },
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Pagar'),
                  ),
                ),
              if (!controller.isPaid && controller.canPayWithCard)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
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
                        : const Icon(Icons.credit_card),
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.attach_money),
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
                  Get.back();
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
