// attendance_game_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/modules/attendece_game/attendece_game_controller.dart';

class AttendanceGameView extends GetView<AttendanceGameController> {
  const AttendanceGameView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistencias'),
        actions: [
          Obx(
            () => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  'P:${controller.presentCount}  T:${controller.lateCount}  A:${controller.absentCount}',
                  style: theme.textTheme.labelLarge,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!controller.isSameDay) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Solo puedes capturar asistencia el día del partido.',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (controller.rows.isEmpty) {
          return const Center(child: Text('No hay jugadores'));
        }

        return Column(
          children: [
            // Acciones rápidas
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  FilledButton.tonal(
                    onPressed: () => controller.setAll(AttStatus.present),
                    child: const Text('Todos presentes'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: () => controller.setAll(AttStatus.absent),
                    child: const Text('Todos ausentes'),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: controller.rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final r = controller.rows[i];
                  final status = r.status;

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: theme.colorScheme.primary
                                    .withOpacity(.12),
                                foregroundImage:
                                    (r.player.photoUrl != null &&
                                        r.player.photoUrl!.isNotEmpty)
                                    ? NetworkImage(r.player.photoUrl!)
                                    : null,
                                onForegroundImageError: (_, __) {},
                                child: Text(
                                  r.player.initials,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  r.player.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // 2) Botones de estado
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              ChoiceChip(
                                label: const Text('Presente'),
                                selected: status == AttStatus.present,
                                onSelected: (_) => controller.toggleStatus(
                                  r,
                                  AttStatus.present,
                                ),
                              ),
                              ChoiceChip(
                                label: const Text('Ausente'),
                                selected: status == AttStatus.absent,
                                onSelected: (_) => controller.toggleStatus(
                                  r,
                                  AttStatus.absent,
                                ),
                              ),
                              ChoiceChip(
                                label: const Text('Tarde'),
                                selected: status == AttStatus.late,
                                onSelected: (_) =>
                                    controller.toggleStatus(r, AttStatus.late),
                              ),
                            ],
                          ),

                          // 3) Minutos si 'Tarde'
                          if (status == AttStatus.late) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Text('Minutos tarde:'),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 80,
                                  child: TextFormField(
                                    initialValue: r.minutesLate?.toString(),
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      hintText: 'Ej. 5',
                                    ),
                                    onChanged: (v) => controller.setMinutesLate(
                                      r,
                                      int.tryParse(v),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // 4) Notas (opcional)
                          const SizedBox(height: 10),
                          TextFormField(
                            initialValue: r.notes,
                            decoration: const InputDecoration(
                              labelText: 'Notas (opcional)',
                              hintText: 'Observaciones...',
                            ),
                            maxLines: 2,
                            onChanged: (v) => controller.setNotes(r, v),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
      bottomNavigationBar: Obx(
        () => SafeArea(
          minimum: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: controller.isSaving.value ? null : controller.saveBulk,
            icon: controller.isSaving.value
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(
              controller.isSaving.value ? 'Guardando...' : 'Guardar asistencia',
            ),
          ),
        ),
      ),
    );
  }
}
