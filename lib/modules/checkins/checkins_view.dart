import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/checkin_model_response.dart';
import 'checkins_controller.dart';

class CheckinsView extends GetView<CheckinsController> {
  const CheckinsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check-ins')),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Obx(() {
        return SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FloatingActionButton.extended(
              onPressed: controller.isSaving.value
                  ? null
                  : controller.doCheckin,
              label: controller.isSaving.value
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Text(
                      'HACER CHECKIN',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
              icon: controller.isSaving.value
                  ? null
                  : const Icon(Icons.check_circle),
            ),
          ),
        );
      }),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (controller.error.value != null) ...[
                _ErrorBox(
                  message: controller.error.value!,
                  onOpenSettings: controller.openAppSettings,
                  onOpenLocation: controller.openLocationSettings,
                ),
                const SizedBox(height: 12),
              ],

              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'Desde',
                      value: controller.dateFrom.value,
                      onPick: () async {
                        final picked = await _pickDate(
                          context,
                          controller.dateFrom.value,
                        );
                        if (picked != null) controller.dateFrom.value = picked;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateField(
                      label: 'Hasta',
                      value: controller.dateTo.value,
                      onPick: () async {
                        final picked = await _pickDate(
                          context,
                          controller.dateTo.value,
                        );
                        if (picked != null) controller.dateTo.value = picked;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: controller.loadHistory,
                  icon: const Icon(Icons.filter_alt),
                  label: const Text('Filtrar historial'),
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: Obx(() {
                  if (controller.history.isEmpty) {
                    return const Center(
                      child: Text('Sin check-ins en este rango.'),
                    );
                  }

                  return ListView.separated(
                    itemCount: controller.history.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final item = controller.history[i];

                      return ListTile(
                        leading: const Icon(Icons.place),
                        title: Text('Lat: ${item.lat}, Lng: ${item.lng}'),
                        subtitle: Text(
                          'Fecha: ${formatDateTime(item.checkedInAt)}',
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          );
        }),
      ),
    );
  }

  Future<String?> _pickDate(BuildContext context, String initial) async {
    DateTime init;
    try {
      init = DateTime.parse(initial);
    } catch (_) {
      init = DateTime.now();
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );

    if (picked == null) return null;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${picked.year}-${two(picked.month)}-${two(picked.day)}';
  }

  String formatDateTime(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');

    final day = two(d.day);
    final month = two(d.month);
    final year = d.year;

    int hour = d.hour;
    final minute = two(d.minute);
    final ampm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;

    return '$day/$month/$year • $hour:$minute $ampm';
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onPick;

  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_month),
        ),
        child: Text(value),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenLocation;

  const _ErrorBox({
    required this.message,
    required this.onOpenSettings,
    required this.onOpenLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
        color: Colors.red.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: onOpenLocation,
                child: const Text('Abrir GPS'),
              ),
              OutlinedButton(
                onPressed: onOpenSettings,
                child: const Text('Abrir configuración'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
