import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/merit/merit_score_entry.dart';
import 'package:stopandgo/core/utils/month_label.dart';

import 'recompensas_coach_score_entry_controller.dart';

class RecompensasCoachScoreEntryView
    extends GetView<RecompensasCoachScoreEntryController> {
  const RecompensasCoachScoreEntryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.playerName)),
      ),
      floatingActionButton: Obx(
        () => controller.isLocked
            ? const SizedBox.shrink()
            : FloatingActionButton.extended(
                onPressed: () => _openAddEntrySheet(context),
                icon: const Icon(Icons.add),
                label: const Text('Agregar puntos'),
              ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value != null) {
          return Center(child: Text(controller.error.value!));
        }

        return RefreshIndicator(
          onRefresh: controller.loadData,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _MonthSelector(controller: controller),
              if (controller.isLocked)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_outline, color: Color(0xFF7C4A03)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Periodo bloqueado: el comité de mérito ya validó este mes.',
                          style: TextStyle(color: Color(0xFF7C4A03)),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              _AttendanceInfoTile(controller: controller),
              const SizedBox(height: 8),
              if (controller.entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Sin entradas de puntos capturadas este mes.'),
                )
              else
                ...controller.entries.map((e) => _ScoreEntryTile(entry: e)),
            ],
          ),
        );
      }),
    );
  }

  void _openAddEntrySheet(BuildContext context) {
    Get.bottomSheet(
      _AddEntrySheet(controller: controller),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({required this.controller});

  final RecompensasCoachScoreEntryController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () => controller.changeMonth(
              DateTime(
                controller.selectedMonth.value.year,
                controller.selectedMonth.value.month - 1,
              ),
            ),
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            monthLabel(controller.selectedMonth.value),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          IconButton(
            onPressed: () => controller.changeMonth(
              DateTime(
                controller.selectedMonth.value.year,
                controller.selectedMonth.value.month + 1,
              ),
            ),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _AttendanceInfoTile extends StatelessWidget {
  const _AttendanceInfoTile({required this.controller});

  final RecompensasCoachScoreEntryController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final breakdowns = controller.currentSnapshot.value?.breakdowns ?? [];
      final attendance = breakdowns.where((b) => b.rubricItem == 'asistencia');
      final earned = attendance.isNotEmpty ? attendance.first.pointsEarned : null;
      final possible =
          attendance.isNotEmpty ? attendance.first.pointsPossible : null;

      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.fact_check_outlined),
        title: const Text('Asistencia (automático)'),
        subtitle: const Text('Calculado desde check-ins del jugador'),
        trailing: Text(
          earned != null
              ? '${earned.toStringAsFixed(0)}/${possible!.toStringAsFixed(0)}'
              : '—',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
    });
  }
}

class _ScoreEntryTile extends StatelessWidget {
  const _ScoreEntryTile({required this.entry});

  final MeritScoreEntry entry;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.stars_outlined),
      title: Text(entry.rubricItem),
      subtitle: Text(
        [
          if (entry.reason != null && entry.reason!.isNotEmpty) entry.reason!,
          if (entry.enteredBy != null) 'Capturado por ${entry.enteredBy!.name}',
        ].join(' · '),
      ),
      trailing: Text(
        entry.points.toStringAsFixed(0),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _AddEntrySheet extends StatefulWidget {
  const _AddEntrySheet({required this.controller});

  final RecompensasCoachScoreEntryController controller;

  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
  String _rubricItem = meritCapturableRubricItems.first;
  final _pointsCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _evidenceCtrl = TextEditingController();

  @override
  void dispose() {
    _pointsCtrl.dispose();
    _reasonCtrl.dispose();
    _evidenceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final points = double.tryParse(_pointsCtrl.text.trim());
    if (points == null) {
      Get.snackbar(
        'Captura de puntos',
        'Ingresa un puntaje válido.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final ok = await widget.controller.addEntry(
      rubricItem: _rubricItem,
      points: points,
      reason: _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
      evidencePath:
          _evidenceCtrl.text.trim().isEmpty ? null : _evidenceCtrl.text.trim(),
    );

    if (ok && mounted) {
      Get.back();
      Get.snackbar(
        'Captura de puntos',
        'Entrada registrada correctamente.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Agregar puntos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _rubricItem,
                decoration: const InputDecoration(labelText: 'Rubro'),
                items: meritCapturableRubricItems
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _rubricItem = value);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _pointsCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Puntos'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonCtrl,
                decoration: const InputDecoration(labelText: 'Motivo'),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _evidenceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Evidencia (opcional)',
                  hintText: 'Nota o referencia',
                ),
              ),
              const SizedBox(height: 16),
              Obx(
                () => FilledButton(
                  onPressed: widget.controller.isSaving.value ? null : _submit,
                  child: widget.controller.isSaving.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
