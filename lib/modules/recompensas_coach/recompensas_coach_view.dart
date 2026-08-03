import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/merit/merit_incident.dart';
import 'package:stopandgo/core/models/merit/merit_prospect.dart';
import 'package:stopandgo/core/models/merit/merit_snapshot.dart';
import 'package:stopandgo/core/models/players.dart';
import 'package:stopandgo/core/utils/merit_level.dart';
import 'package:stopandgo/core/utils/month_label.dart';
import 'package:stopandgo/routes/app_routes.dart';

import 'recompensas_coach_controller.dart';

const _incidentTypes = <String, String>{
  'physical': 'Física',
  'verbal': 'Verbal',
  'other': 'Otro',
};

class RecompensasCoachView extends GetView<RecompensasCoachController> {
  const RecompensasCoachView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Recompensas · ${controller.categoryName}'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Captura'),
              Tab(text: 'Ranking'),
              Tab(text: 'Prospectos'),
              Tab(text: 'Incidencias'),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value && controller.players.isEmpty) {
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
              _CaptureTab(controller: controller),
              _RankingTab(controller: controller),
              _ProspectsTab(controller: controller),
              _IncidentsTab(controller: controller),
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

class _CaptureTab extends StatelessWidget {
  const _CaptureTab({required this.controller});

  final RecompensasCoachController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.players.isEmpty) {
        return const Center(child: Text('No hay jugadores en esta categoría.'));
      }
      return RefreshIndicator(
        onRefresh: controller.refreshData,
        child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: controller.players.length,
          itemBuilder: (context, index) {
            final Player p = controller.players[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    p.photoUrl != null ? NetworkImage(p.photoUrl!) : null,
                child: p.photoUrl == null ? const Icon(Icons.person) : null,
              ),
              title: Text(p.displayName.isNotEmpty ? p.displayName : p.name),
              subtitle: p.number != null ? Text('#${p.number}') : null,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Get.toNamed(
                Routes.recompensasCoachScoreEntry,
                arguments: {
                  'playerId': p.id,
                  'playerName': p.displayName.isNotEmpty ? p.displayName : p.name,
                  'categoryId': controller.categoryId,
                },
              ),
            );
          },
        ),
      );
    });
  }
}

class _RankingTab extends StatelessWidget {
  const _RankingTab({required this.controller});

  final RecompensasCoachController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => controller.changeSnapshotMonth(
                    DateTime(
                      controller.selectedSnapshotMonth.value.year,
                      controller.selectedSnapshotMonth.value.month - 1,
                    ),
                  ),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  monthLabel(controller.selectedSnapshotMonth.value),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  onPressed: () => controller.changeSnapshotMonth(
                    DateTime(
                      controller.selectedSnapshotMonth.value.year,
                      controller.selectedSnapshotMonth.value.month + 1,
                    ),
                  ),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoadingSnapshots.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.snapshots.isEmpty) {
              return const Center(
                child: Text('Sin snapshots generados para este mes.'),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: controller.snapshots.length,
              itemBuilder: (context, index) {
                final MeritSnapshot s = controller.snapshots[index];
                final isValidating =
                    controller.validatingSnapshotIds.contains(s.id);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          meritLevelIcon(s.meritLevel),
                          color: meritLevelColor(s.meritLevel),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.player?.fullName ?? 'Jugador #${s.playerId}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${meritLevelLabel(s.meritLevel)} · ${s.totalScore.toStringAsFixed(0)} pts'
                                '${s.isFundEligible ? ' · Elegible' : ''}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (s.isLocked)
                                const Text(
                                  'Bloqueado',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (!s.isLocked)
                          OutlinedButton(
                            onPressed: isValidating
                                ? null
                                : () => controller.validateSnapshot(s.id),
                            child: isValidating
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child:
                                        CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Aprobar'),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}

class _ProspectsTab extends StatefulWidget {
  const _ProspectsTab({required this.controller});

  final RecompensasCoachController controller;

  @override
  State<_ProspectsTab> createState() => _ProspectsTabState();
}

class _ProspectsTabState extends State<_ProspectsTab> {
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
        'Prospectos',
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
                    decoration: const InputDecoration(labelText: 'Nombre completo'),
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
                      onPressed:
                          widget.controller.isCreatingProspect.value ? null : _submit,
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
          Text('Mis prospectos', style: Theme.of(context).textTheme.titleMedium),
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
              children: prospects.map((p) => _ProspectTile(prospect: p)).toList(),
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

class _IncidentsTab extends StatelessWidget {
  const _IncidentsTab({required this.controller});

  final RecompensasCoachController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final incidents = controller.incidents;
      return RefreshIndicator(
        onRefresh: controller.refreshData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FilledButton.icon(
              onPressed: () => Get.bottomSheet(
                _AddIncidentSheet(controller: controller),
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
              ),
              icon: const Icon(Icons.report_outlined),
              label: const Text('Reportar incidencia'),
            ),
            const SizedBox(height: 16),
            Text('Mis incidencias', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (incidents.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Sin incidencias registradas.'),
              )
            else
              ...incidents.map((i) => _IncidentTile(incident: i)),
          ],
        ),
      );
    });
  }
}

class _IncidentTile extends StatelessWidget {
  const _IncidentTile({required this.incident});

  final MeritIncident incident;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          incident.isRepeat ? Icons.warning_amber : Icons.report_gmailerrorred_outlined,
          color: incident.isRepeat ? Colors.red : Colors.orange,
        ),
        title: Text(_incidentTypes[incident.incidentType] ?? incident.incidentType),
        subtitle: Text(incident.description ?? ''),
        trailing: incident.isRepeat ? const Chip(label: Text('Reincidencia')) : null,
      ),
    );
  }
}

class _AddIncidentSheet extends StatefulWidget {
  const _AddIncidentSheet({required this.controller});

  final RecompensasCoachController controller;

  @override
  State<_AddIncidentSheet> createState() => _AddIncidentSheetState();
}

class _AddIncidentSheetState extends State<_AddIncidentSheet> {
  String _type = _incidentTypes.keys.first;
  DateTime _occurredAt = DateTime.now();
  final _descriptionCtrl = TextEditingController();

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _occurredAt = picked);
  }

  Future<void> _submit() async {
    final description = _descriptionCtrl.text.trim();
    if (description.isEmpty) {
      Get.snackbar(
        'Incidencias',
        'Describe lo ocurrido.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final ok = await widget.controller.createIncident(
      incidentType: _type,
      description: description,
      occurredAt: _occurredAt,
    );
    if (ok && mounted) {
      Get.back();
      Get.snackbar(
        'Incidencias',
        'Incidencia registrada correctamente.',
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
              Text('Reportar incidencia', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: _incidentTypes.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _type = value);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionCtrl,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(
                  '${_occurredAt.day}/${_occurredAt.month}/${_occurredAt.year}',
                ),
                trailing: TextButton(
                  onPressed: _pickDate,
                  child: const Text('Cambiar'),
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => FilledButton(
                  onPressed: widget.controller.isCreatingIncident.value ? null : _submit,
                  child: widget.controller.isCreatingIncident.value
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
    );
  }
}
