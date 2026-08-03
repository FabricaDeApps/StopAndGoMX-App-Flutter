import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/merit/merit_credit_ledger_entry.dart';
import 'package:stopandgo/core/models/merit/merit_prospect.dart';
import 'package:stopandgo/core/models/merit/merit_responses.dart';
import 'package:stopandgo/core/models/merit/merit_snapshot.dart';
import 'package:stopandgo/core/utils/merit_level.dart';
import 'package:stopandgo/core/utils/money.dart';
import 'package:stopandgo/core/utils/month_label.dart';

import 'recompensas_player_controller.dart';

class RecompensasPlayerView extends GetView<RecompensasPlayerController> {
  const RecompensasPlayerView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Recompensas'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Mis Recompensas'),
              Tab(text: 'Mi saldo'),
              Tab(text: 'Reclutar amigos'),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value && controller.me.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.isModuleUnavailable.value) {
            return _EmptyState(
              icon: Icons.military_tech_outlined,
              title: 'Recompensas no disponible',
              message:
                  'El Programa de Recompensas no está habilitado para tu organización.',
              onRetry: controller.refreshData,
            );
          }

          if (controller.error.value != null) {
            return _EmptyState(
              icon: Icons.error_outline,
              title: 'No se pudo cargar',
              message: controller.error.value!,
              onRetry: controller.refreshData,
            );
          }

          return TabBarView(
            children: [
              _MyRecompensasTab(controller: controller),
              _BalanceTab(controller: controller),
              _RecruitTab(controller: controller),
            ],
          );
        }),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class _MyRecompensasTab extends StatelessWidget {
  const _MyRecompensasTab({required this.controller});

  final RecompensasPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final MeritPlayerMeResponse? me = controller.me.value;
      final current = me?.current;
      final history = me?.history ?? const <MeritHistoryItem>[];

      return RefreshIndicator(
        onRefresh: controller.refreshData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (current == null)
              const _EmptyState(
                icon: Icons.emoji_events_outlined,
                title: 'Aún sin evaluación',
                message: 'Todavía no tienes un puntaje de recompensas este mes.',
                onRetry: _noop,
              )
            else ...[
              _LevelCard(snapshot: current),
              const SizedBox(height: 16),
              Text(
                'Desglose por rubro',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...current.breakdowns.map(
                (b) => _BreakdownTile(breakdown: b),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Evolución mensual',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (history.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Sin historial todavía.'),
              )
            else
              ...history.map((h) => _HistoryTile(item: h)),
          ],
        ),
      );
    });
  }

  static void _noop() {}
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.snapshot});

  final MeritSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final color = meritLevelColor(snapshot.meritLevel);
    return Card(
      color: color.withValues(alpha: .12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(meritLevelIcon(snapshot.meritLevel), color: color, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meritLevelLabel(snapshot.meritLevel),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      if (snapshot.periodMonth != null)
                        Text(monthLabel(snapshot.periodMonth!)),
                    ],
                  ),
                ),
                Text(
                  snapshot.totalScore.toStringAsFixed(0),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (snapshot.totalScore / 100).clamp(0, 1),
              color: color,
              backgroundColor: color.withValues(alpha: .15),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  snapshot.isFundEligible
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
                  size: 16,
                  color: snapshot.isFundEligible ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    snapshot.isFundEligible
                        ? 'Elegible para el Fondo de Recompensas'
                        : 'Aún no elegible para el Fondo de Recompensas',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            if (snapshot.extraPoints > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Puntos extra de reclutamiento: ${snapshot.extraPoints.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BreakdownTile extends StatelessWidget {
  const _BreakdownTile({required this.breakdown});

  final MeritScoreBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(breakdown.rubricItem)),
          Text(
            '${breakdown.pointsEarned.toStringAsFixed(0)}/${breakdown.pointsPossible.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.item});

  final MeritHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final color = meritLevelColor(item.meritLevel);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(meritLevelIcon(item.meritLevel), color: color),
      title: Text(item.periodMonth != null ? monthLabel(item.periodMonth!) : '-'),
      subtitle: Text(meritLevelLabel(item.meritLevel)),
      trailing: Text(
        item.totalScore.toStringAsFixed(0),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _BalanceTab extends StatelessWidget {
  const _BalanceTab({required this.controller});

  final RecompensasPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final balance = controller.creditBalance.value;
      final entries = balance?.entries ?? const <MeritCreditLedgerEntry>[];

      return RefreshIndicator(
        onRefresh: controller.refreshData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Saldo a favor disponible'),
                    const SizedBox(height: 4),
                    Text(
                      money(balance?.currentBalanceMxn ?? 0),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Historial', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Sin movimientos todavía.'),
              )
            else
              ...entries.map((e) => _LedgerTile(entry: e)),
          ],
        ),
      );
    });
  }
}

class _LedgerTile extends StatelessWidget {
  const _LedgerTile({required this.entry});

  final MeritCreditLedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final isCredit = entry.isCredit;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isCredit ? Icons.arrow_upward : Icons.arrow_downward,
        color: isCredit ? Colors.green : Colors.red,
      ),
      title: Text(isCredit ? 'Crédito' : 'Débito'),
      subtitle: Text(
        entry.appliedToType == 'payment'
            ? 'Aplicado a un pago'
            : entry.sourceType,
      ),
      trailing: Text(
        '${isCredit ? '+' : '-'}${money(entry.amountMxn)}',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: isCredit ? Colors.green : Colors.red,
        ),
      ),
    );
  }
}

class _RecruitTab extends StatefulWidget {
  const _RecruitTab({required this.controller});

  final RecompensasPlayerController controller;

  @override
  State<_RecruitTab> createState() => _RecruitTabState();
}

class _RecruitTabState extends State<_RecruitTab> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      Get.snackbar(
        'Reclutar amigos',
        'Escribe el nombre del prospecto.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final ok = await widget.controller.createProspect(
      fullName: name,
      phone: _phoneCtrl.text,
    );
    if (ok) {
      _nameCtrl.clear();
      _phoneCtrl.clear();
      Get.snackbar(
        'Reclutar amigos',
        'Prospecto registrado correctamente.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.controller.refreshData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Registrar prospecto',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => FilledButton(
                      onPressed: widget.controller.isCreatingProspect.value
                          ? null
                          : _submit,
                      child: widget.controller.isCreatingProspect.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Registrar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Mis prospectos',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Obx(() {
            final prospects = widget.controller.prospects;
            if (prospects.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Aún no has registrado prospectos.'),
              );
            }
            return Column(
              children: prospects
                  .map((p) => _ProspectTile(prospect: p))
                  .toList(),
            );
          }),
        ],
      ),
    );
  }
}

class _ProspectTile extends StatelessWidget {
  const _ProspectTile({required this.prospect});

  final MeritProspect prospect;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.person_add_alt_outlined),
      title: Text(prospect.fullName),
      trailing: Chip(label: Text(prospect.status)),
    );
  }
}
