import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:stopandgo/core/utils/money.dart';

import 'spei_payment_controller.dart';

class SpeiPaymentView extends GetView<SpeiPaymentController> {
  const SpeiPaymentView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagar por transferencia')),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoadingIntent.value &&
              controller.intent.value == null) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Preparando instrucciones SPEI…'),
                ],
              ),
            );
          }

          final error = controller.error.value;
          if (error != null && controller.intent.value == null) {
            return _ErrorState(
              message: error.message,
              retryLabel: error.isAuthenticationError
                  ? 'Volver a intentar'
                  : 'Generar instrucciones',
              onRetry: controller.createOrReuseIntent,
            );
          }

          if (controller.isPaid) return const _PaidState();

          final intent = controller.intent.value;
          if (intent == null) {
            return _ErrorState(
              message: 'No recibimos instrucciones de Mercado Pago.',
              retryLabel: 'Volver a intentar',
              onRetry: controller.createOrReuseIntent,
            );
          }

          final parsedAmount = double.tryParse(intent.amount);
          final amountLabel = parsedAmount == null
              ? '${intent.amount} ${intent.currency}'
              : '${money(parsedAmount)} ${intent.currency}';
          final reference = intent.speiReference;
          final expiresAt = intent.effectiveExpiresAt;
          final steps = intent.paymentInstructions?.steps ?? const <String>[];

          return RefreshIndicator(
            onRefresh: () => controller.refreshPayment(showFeedback: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                _HeaderCard(
                  amount: amountLabel,
                  status: controller.statusLabel,
                  reused: intent.reused,
                  isPolling: controller.isPolling.value,
                ),
                const SizedBox(height: 12),
                if (reference != null)
                  _ReferenceCard(
                    reference: reference,
                    onCopy: controller.copyReference,
                  ),
                if (reference != null) const SizedBox(height: 12),
                if (expiresAt != null)
                  _InfoRow(
                    icon: Icons.schedule_rounded,
                    text:
                        'Estas instrucciones vencen el ${DateFormat('dd/MM/yyyy, HH:mm').format(expiresAt.toLocal())}.',
                  ),
                if (expiresAt != null) const SizedBox(height: 12),
                if (steps.isNotEmpty) _StepsCard(steps: steps),
                if (steps.isNotEmpty) const SizedBox(height: 16),
                if (!intent.isExpired && intent.instructionsUrl != null)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: controller.isOpeningInstructions.value
                        ? null
                        : controller.openInstructions,
                    icon: controller.isOpeningInstructions.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.qr_code_2_rounded),
                    label: const Text('Ver QR / instrucciones'),
                  ),
                if (intent.canRegenerate || intent.isExpired)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: controller.isLoadingIntent.value
                        ? null
                        : controller.createOrReuseIntent,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Generar nuevas instrucciones'),
                  ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: controller.isRefreshingPayment.value
                      ? null
                      : () => controller.refreshPayment(showFeedback: true),
                  icon: controller.isRefreshingPayment.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: const Text('Actualizar estado'),
                ),
                const SizedBox(height: 14),
                Text(
                  'La confirmación es automática. No necesitas subir un comprobante para este método.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.amount,
    required this.status,
    required this.reused,
    required this.isPolling,
  });

  final String amount;
  final String status;
  final bool reused;
  final bool isPolling;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Transferencia SPEI',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text('Monto a transferir', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              amount,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: isPolling
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.schedule_rounded, size: 18),
                  label: Text(status),
                ),
                if (reused)
                  const Chip(label: Text('Intento vigente reutilizado')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferenceCard extends StatelessWidget {
  const _ReferenceCard({required this.reference, required this.onCopy});

  final String reference;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: const Icon(Icons.tag_rounded),
        title: const Text('Referencia SPEI'),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: SelectableText(
            reference,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: .4,
            ),
          ),
        ),
        trailing: IconButton(
          tooltip: 'Copiar referencia',
          onPressed: onCopy,
          icon: const Icon(Icons.content_copy_rounded),
        ),
      ),
    );
  }
}

class _StepsCard extends StatelessWidget {
  const _StepsCard({required this.steps});

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cómo pagar',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            for (var index = 0; index < steps.length; index++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: index == steps.length - 1 ? 0 : 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(steps[index])),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _PaidState extends StatelessWidget {
  const _PaidState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified_rounded,
              size: 72,
              color: Colors.green.shade600,
            ),
            const SizedBox(height: 16),
            Text(
              'Pago confirmado',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'La transferencia fue aplicada y el pago ya está cubierto.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: Get.back, child: const Text('Listo')),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
