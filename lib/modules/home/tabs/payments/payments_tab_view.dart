// lib/modules/home/tabs/payments/payments_tab_view.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:get/get.dart';
import 'package:stopandgo/core/utils/app_navigator.dart';
import 'package:stopandgo/core/utils/money.dart';
import 'package:stopandgo/modules/home/tabs/payments/payments_controller.dart';
import 'package:stopandgo/routes/app_routes.dart';

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
          _PaymentsFiltersHeader(controller: controller),

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
                      final p = list[i];
                      final paid = p.status == 'paid';
                      final partial = p.status == 'partial';

                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);

                      final isOverdue =
                          !paid &&
                          p.dueDate != null &&
                          p.dueDate!.isBefore(today);

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

                      return _StaggeredEntrance(
                        index: i,
                        child: Card(
                          elevation: 0,
                          margin: EdgeInsets.zero,
                          color: isOverdue
                              ? Colors.amber.withValues(alpha: .08)
                              : theme.colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Theme(
                            data: theme.copyWith(
                              dividerColor: Colors.transparent,
                            ),
                            child: ExpansionTile(
                              onExpansionChanged: (expanded) =>
                                  controller.setExpanded(p.id, expanded),
                              tilePadding: const EdgeInsets.fromLTRB(
                                18,
                                18,
                                18,
                                16,
                              ),
                              childrenPadding: const EdgeInsets.fromLTRB(
                                18,
                                0,
                                18,
                                18,
                              ),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _PaymentStatusPill(
                                        label: chipText,
                                        color: chipColor,
                                        icon: paid
                                            ? Icons.verified_rounded
                                            : partial
                                            ? Icons.pie_chart_rounded
                                            : Icons.receipt_long_rounded,
                                      ),
                                      if (isOverdue)
                                        const _PaymentStatusPill(
                                          label: 'Vencido',
                                          color: Colors.deepOrange,
                                          icon: Icons.warning_amber_rounded,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    p.concept,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Monto: ${money(effectiveAmount)}',
                                    textAlign: TextAlign.left,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: chipColor,
                                    ),
                                  ),
                                  if (p.playerName != null &&
                                      p.playerName!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      p.playerName!,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                  if (!paid) ...[
                                    const SizedBox(height: 14),
                                    SizedBox(
                                      width: double.infinity,
                                      child: controller.canPayWithCard
                                          ? FilledButton.icon(
                                              style: FilledButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 12,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                ),
                                              ),
                                              icon: const Icon(
                                                Icons.payments_rounded,
                                                size: 18,
                                              ),
                                              label: Text(
                                                balance > 0
                                                    ? 'Pagar ${money(balance)}'
                                                    : 'Registrar pago',
                                              ),
                                              onPressed: () async {
                                                await Get.toNamed(
                                                  Routes.makePayment,
                                                  arguments: {
                                                    'paymentId': p.id,
                                                    'payment': p,
                                                  },
                                                );
                                                await controller.loadPayments();
                                              },
                                            )
                                          : Center(
                                              child: FilledButton.icon(
                                                style: FilledButton.styleFrom(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 12,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          14,
                                                        ),
                                                  ),
                                                ),
                                                icon: const Icon(
                                                  Icons.payments_rounded,
                                                  size: 18,
                                                ),
                                                label: Text(
                                                  balance > 0
                                                      ? 'Pagar ${money(balance)}'
                                                      : 'Registrar pago',
                                                ),
                                                onPressed: () async {
                                                  await Get.toNamed(
                                                    Routes.makePayment,
                                                    arguments: {
                                                      'paymentId': p.id,
                                                      'payment': p,
                                                    },
                                                  );
                                                  await controller
                                                      .loadPayments();
                                                },
                                              ),
                                            ),
                                    ),
                                    if (controller.canPayWithSpei) ...[
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        width: double.infinity,
                                        child: FilledButton.tonalIcon(
                                          style: FilledButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                          icon: const Icon(
                                            Icons.account_balance_rounded,
                                            size: 18,
                                          ),
                                          label: const Text(
                                            'Pagar por transferencia SPEI',
                                          ),
                                          onPressed: () =>
                                              controller.goToSpeiPayment(p),
                                        ),
                                      ),
                                    ],
                                    if (controller.canPayWithCard) ...[
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        width: double.infinity,
                                        child: Obx(
                                          () => OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                            ),
                                            icon:
                                                controller
                                                    .isPayingWithCard
                                                    .value
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                : const Icon(
                                                    Icons.credit_card_rounded,
                                                    size: 18,
                                                  ),
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
                                      ),
                                    ],
                                  ],
                                  const SizedBox(height: 10),
                                  Obx(
                                    () => Align(
                                      alignment: Alignment.centerLeft,
                                      child: AnimatedRotation(
                                        turns: controller.isExpanded(p.id)
                                            ? 0.5
                                            : 0.0,
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        child: Icon(
                                          Icons.expand_more_rounded,
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                tooltip: 'Ver detalle',
                                icon: const Icon(Icons.chevron_right_rounded),
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
                                Row(
                                  children: [
                                    Expanded(
                                      child: _PaymentMetricBox(
                                        label: p.hasDiscount
                                            ? 'Monto final'
                                            : 'Monto',
                                        value: money(effectiveAmount),
                                        tint: chipColor,
                                        emphasis: true,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _PaymentMetricBox(
                                        label: 'Pagado',
                                        value: money(totalRecibido),
                                        tint: Colors.teal,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _PaymentMetricBox(
                                  label: 'Saldo pendiente',
                                  value: money(balance),
                                  tint: paid ? Colors.green : chipColor,
                                  emphasis: true,
                                  fullWidth: true,
                                ),
                                if (p.dueDate != null) ...[
                                  const SizedBox(height: 12),
                                  _PaymentMetaBadge(
                                    icon: Icons.event_outlined,
                                    text: 'Vence ${_fmtDateOnly(p.dueDate!)}',
                                  ),
                                ],
                                if (p.hasDiscount) ...[
                                  const SizedBox(height: 12),
                                  _PaymentMetaBadge(
                                    icon: Icons.local_offer_outlined,
                                    text:
                                        'Descuento -\$${p.discountsSumAmount.toStringAsFixed(2)}',
                                  ),
                                ],
                                if (p.hasDiscount &&
                                    p.discounts.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      'Descuentos aplicados',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
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
                                              icon: const Icon(
                                                Icons.open_in_new,
                                              ),
                                              tooltip: 'Ver comprobante',
                                              onPressed: () =>
                                                  _openReceipt(context, r.url!),
                                            )
                                          : null,
                                    );
                                  }),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    });
  }

  static void _openFiltersSheet(
    BuildContext context,
    PaymentsTabController controller,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Obx(
            () => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtrar pagos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Text('Estado', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Row(
                  children: PaymentStatusFilter.values.map((f) {
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: f == PaymentStatusFilter.partial ? 0 : 6,
                        ),
                        child: ChoiceChip(
                          label: SizedBox(
                            width: double.infinity,
                            child: Text(
                              f.label,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          selected: controller.statusFilter.value == f,
                          onSelected: (_) => controller.setStatusFilter(f),
                          visualDensity: const VisualDensity(
                            horizontal: -3,
                            vertical: -3,
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: controller.hasActiveFilters
                            ? controller.clearFilters
                            : null,
                        icon: const Icon(Icons.filter_alt_off),
                        label: const Text('Limpiar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => AppNavigator.pop(context: context),
                        child: const Text('Listo'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => AppNavigator.pop(context: context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentsFiltersHeader extends StatelessWidget {
  const _PaymentsFiltersHeader({required this.controller});

  final PaymentsTabController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Obx(
        () => Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.searchCtrl,
                    onChanged: controller.setQuery,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Buscar por jugador o concepto',
                      isDense: true,
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: .45),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: controller.query.value.trim().isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => controller.setQuery(''),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.tonalIcon(
                  onPressed: () =>
                      PaymentsTabView._openFiltersSheet(context, controller),
                  icon: const Icon(Icons.tune),
                  label: Text(
                    controller.activeFiltersCount > 0
                        ? 'Filtros (${controller.activeFiltersCount})'
                        : 'Filtros',
                  ),
                ),
              ],
            ),
            if (controller.hasActiveFilters) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (controller.statusFilter.value !=
                            PaymentStatusFilter.all)
                          _ActiveFilterChip(
                            label: controller.statusFilter.value.label,
                            onDeleted: () => controller.setStatusFilter(
                              PaymentStatusFilter.all,
                            ),
                          ),
                        if (controller.query.value.trim().isNotEmpty)
                          _ActiveFilterChip(
                            label: 'Busqueda activa',
                            onDeleted: () => controller.setQuery(''),
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: controller.clearFilters,
                    child: const Text('Limpiar'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.label, required this.onDeleted});

  final String label;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(label),
      onDeleted: onDeleted,
      deleteIcon: const Icon(Icons.close, size: 18),
    );
  }
}

class _PaymentStatusPill extends StatelessWidget {
  const _PaymentStatusPill({
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
            const SizedBox(width: 5),
          ],
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
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

class _PaymentMetricBox extends StatelessWidget {
  const _PaymentMetricBox({
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: fullWidth ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: emphasis ? FontWeight.w900 : FontWeight.w800,
              letterSpacing: -.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMetaBadge extends StatelessWidget {
  const _PaymentMetaBadge({required this.icon, required this.text});

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
          Text(
            text,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StaggeredEntrance extends StatefulWidget {
  const _StaggeredEntrance({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<_StaggeredEntrance> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    final delayMs = 40 * widget.index;
    Future.delayed(Duration(milliseconds: delayMs.clamp(0, 280)), () {
      if (!mounted) return;
      setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEven = widget.index.isEven;
    final hiddenOffset = Offset(isEven ? -0.12 : 0.12, 0.18);
    final hiddenRotation = (isEven ? -1 : 1) * 0.045;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      offset: _visible ? Offset.zero : hiddenOffset,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: _visible ? 1 : 0, end: _visible ? 1 : 0),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          final rotation = hiddenRotation * (1 - value);
          final scale = 0.96 + (0.04 * value);
          return Transform.rotate(
            angle: rotation * math.pi,
            child: Transform.scale(scale: scale, child: child),
          );
        },
        child: widget.child,
      ),
    );
  }
}
