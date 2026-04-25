import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/checkin_today_status.dart';
import 'checkins_controller.dart';

String _formatDateTime(DateTime d) {
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

class CheckinsView extends GetView<CheckinsController> {
  const CheckinsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check-ins')),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Obx(() {
        if (controller.hasCheckinToday) {
          return const SizedBox.shrink();
        }
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

              Obx(() {
                final today = controller.today.value;
                return _TodayStatusCard(
                  today: today,
                  isCheckingOut: controller.isCheckingOut.value,
                  onCheckout: controller.canCheckoutToday
                      ? controller.doCheckout
                      : null,
                );
              }),

              const SizedBox(height: 12),

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
                          'Fecha: ${_formatDateTime(item.checkedInAt)}',
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
}

class _TodayStatusCard extends StatelessWidget {
  final CheckinTodayStatus today;
  final bool isCheckingOut;
  final VoidCallback? onCheckout;

  const _TodayStatusCard({
    required this.today,
    required this.isCheckingOut,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final hasCheckin = today.hasCheckin;
    final hasCheckout = today.hasCheckout;
    final theme = Theme.of(context);

    final title = hasCheckout
        ? 'Tu asistencia de hoy ya fue cerrada'
        : hasCheckin
        ? 'Ya tienes check-in hoy'
        : 'Aún no haces check-in hoy';

    final subtitle = hasCheckout
        ? 'Tu checkout quedó registrado correctamente.'
        : hasCheckin
        ? 'Puedes cerrar tu asistencia cuando salgas.'
        : 'Cuando registres tu entrada, aquí aparecerá el resumen del día.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: hasCheckout
            ? Colors.green.shade50
            : hasCheckin
            ? Colors.blue.shade50
            : Colors.grey.shade100,
        border: Border.all(
          color: hasCheckout
              ? Colors.green.shade200
              : hasCheckin
              ? Colors.blue.shade200
              : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasCheckout
                    ? Icons.verified_outlined
                    : hasCheckin
                    ? Icons.login_outlined
                    : Icons.schedule_outlined,
                color: hasCheckout
                    ? Colors.green.shade700
                    : hasCheckin
                    ? Colors.blue.shade700
                    : Colors.black54,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(subtitle),
          if (today.locationLabel != null &&
              today.locationLabel!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Ubicación: ${today.locationLabel}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
          if (today.checkedInAt != null) ...[
            const SizedBox(height: 8),
            Text('Check-in: ${_formatDateTime(today.checkedInAt!.toLocal())}'),
          ],
          if (today.checkedOutAt != null) ...[
            const SizedBox(height: 4),
            Text('Checkout: ${_formatDateTime(today.checkedOutAt!.toLocal())}'),
          ],
          if (today.durationMinutes != null) ...[
            const SizedBox(height: 4),
            Text('Duración: ${today.durationMinutes} min'),
          ],
          if (hasCheckin && !hasCheckout) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isCheckingOut ? null : onCheckout,
                icon: isCheckingOut
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout_outlined),
                label: Text(
                  isCheckingOut ? 'Registrando checkout...' : 'Hacer checkout',
                ),
              ),
            ),
          ],
        ],
      ),
    );
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
