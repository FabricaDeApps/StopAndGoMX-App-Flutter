import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:stopandgo/modules/trainnings/trainnings_controller.dart';
import 'package:stopandgo/routes/app_routes.dart';

class TrainingsView extends GetView<TrainingsController> {
  const TrainingsView({super.key});

  String _formatDateTime(DateTime dt) {
    final date = DateFormat('dd MMM yyyy', 'es_MX').format(dt);
    final time = DateFormat('HH:mm', 'es_MX').format(dt);
    return '$date · $time';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'scheduled':
        return 'Programado';
      case 'completed':
        return 'Completado';
      case 'canceled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Entrenamientos'), centerTitle: true),

      // 👉 FAB para “Nuevo Entrenamiento”
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nuevo entrenamiento'),
        onPressed: controller.goToCreateTraining,
      ),

      body: Obx(() {
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
                  Text(
                    controller.error.value!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: controller.loadTrainings,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        final trainings = controller.trainings;

        if (trainings.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Aún no hay entrenamientos registrados para esta categoría.',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadTrainings,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: trainings.length,
            itemBuilder: (context, index) {
              final t = trainings[index];
              final isScheduled = t.status == 'scheduled';
              final isCompleted = t.status == 'completed';

              return Slidable(
                key: ValueKey(t.id),
                enabled: isScheduled,
                endActionPane: isScheduled
                    ? ActionPane(
                        motion: const DrawerMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (_) => controller.completeTraining(t),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            icon: Icons.check_circle,
                            label: 'Completar',
                          ),
                        ],
                      )
                    : null,
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // -------------------------
                        // FECHA + STATUS  (TU CÓDIGO)
                        // -------------------------
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                _formatDateTime(t.startsAt),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor(t.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _statusLabel(t.status),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: _statusColor(t.status),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // -------------------------
                        // LUGAR (TU CÓDIGO)
                        // -------------------------
                        if (t.venue != null && t.venue!.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.sports_football, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  t.venue!,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),

                        // -------------------------
                        // DIRECCIÓN / CIUDAD (TU CÓDIGO)
                        // -------------------------
                        if ((t.address != null && t.address!.isNotEmpty) ||
                            (t.city != null && t.city!.isNotEmpty))
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    [
                                      if (t.address != null &&
                                          t.address!.isNotEmpty)
                                        t.address!,
                                      if (t.city != null && t.city!.isNotEmpty)
                                        t.city!,
                                    ].join(', '),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // -------------------------
                        // DURACIÓN (TU CÓDIGO)
                        // -------------------------
                        if (t.durationMinutes != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                '${t.durationMinutes} min',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],

                        // -------------------------
                        // NOTAS (TU CÓDIGO)
                        // -------------------------
                        if (t.notes != null && t.notes!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(t.notes!, style: theme.textTheme.bodySmall),
                        ],

                        const SizedBox(height: 12),

                        // ----------------------------------------------------
                        // AQUI SOLO CAMBIAMOS EL BOTÓN  (LO ÚNICO QUE EDITÉ)
                        // ----------------------------------------------------
                        if (isScheduled || isCompleted)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () async {
                                await Get.toNamed(
                                  Routes.trainingAttendance,
                                  arguments: {
                                    'trainingId': t.id,
                                    'isEdit': isCompleted,
                                  },
                                );
                                controller.loadTrainings();
                              },
                              icon: const Icon(Icons.checklist_rtl),
                              label: Text(
                                isScheduled
                                    ? 'Pasar lista'
                                    : 'Ver / editar lista',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
