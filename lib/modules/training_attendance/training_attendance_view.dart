import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'training_attendance_controller.dart';

class TrainingAttendanceView extends GetView<TrainingAttendanceController> {
  const TrainingAttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistencia a Entrenamiento'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.value != null) {
          return Center(
            child: Text(
              controller.error.value!,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.rows.length,
                itemBuilder: (_, index) {
                  final row = controller.rows[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Player name
                          Text(
                            row.player.name,
                            style: theme.textTheme.titleMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Status selector
                          Obx(() {
                            return Wrap(
                              spacing: 10,
                              children: [
                                _buildChip(
                                  row,
                                  'present',
                                  'Presente',
                                  Colors.green,
                                ),
                                _buildChip(
                                  row,
                                  'absent',
                                  'Ausente',
                                  Colors.red,
                                ),
                                _buildChip(row, 'late', 'Tarde', Colors.orange),
                                _buildChip(
                                  row,
                                  'justified',
                                  'Justificado',
                                  Colors.blueGrey,
                                ),
                              ],
                            );
                          }),

                          // Minutes late
                          Obx(() {
                            if (row.status.value != 'late')
                              return const SizedBox.shrink();

                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  const Text('Minutos tarde:'),
                                  const SizedBox(width: 10),
                                  DropdownButton<int>(
                                    value: row.minutesLate.value,
                                    items: List.generate(
                                      31,
                                      (i) => DropdownMenuItem(
                                        value: i,
                                        child: Text('$i'),
                                      ),
                                    ),
                                    onChanged: (v) =>
                                        row.minutesLate.value = v ?? 0,
                                  ),
                                ],
                              ),
                            );
                          }),

                          // Notes
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: TextField(
                              controller: row.notesController,
                              decoration: const InputDecoration(
                                labelText: 'Notas (opcional)',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Save button
            Obx(() {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: controller.isSaving.value
                      ? null
                      : controller.saveAttendance,
                  icon: controller.isSaving.value
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.save),
                  label: const Text('Guardar asistencia'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              );
            }),
          ],
        );
      }),
    );
  }

  Widget _buildChip(
    AttendanceRow row,
    String value,
    String label,
    Color color,
  ) {
    final isSelected = row.status.value == value;

    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      selectedColor: color.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) {
        row.status.value = value;
      },
    );
  }
}
