import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/modules/home/home_controller.dart';
import 'package:stopandgo/routes/app_routes.dart';
import 'package:url_launcher/url_launcher.dart';

class GamesTab extends StatelessWidget {
  const GamesTab({super.key, required this.controller});
  final HomeController controller;

  Future<void> _openInGoogleMaps({
    required BuildContext context,
    required double? lat,
    required double? lng,
    required String label,
  }) async {
    if (lat == null || lng == null) {
      Get.snackbar(
        'Sin ubicación',
        'Este juego no tiene coordenadas (lat/lng).',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final encodedLabel = Uri.encodeComponent(label);
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=$encodedLabel',
    );

    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!ok) {
      Get.snackbar(
        'Error',
        'No se pudo abrir Google Maps.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      if (controller.isLoadingTab1.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final list = controller.upcomingGames;
      final listView = (list.isEmpty)
          ? Center(child: Text('Sin juegos', style: theme.textTheme.bodyMedium))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final g = list[i];
                final now = DateTime.now();
                final isPast = g.startsAt != null && g.startsAt!.isBefore(now);
                final canComplete =
                    controller.userRole.value == 'manager' && isPast;

                final venueName = g.venueObj?.name ?? g.venue ?? '';
                final labelForMaps =
                    '${g.opponent}${venueName.isNotEmpty ? ' · $venueName' : ''}';

                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  tileColor: theme.colorScheme.surface,
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withOpacity(.12),
                    child: const Icon(Icons.sports_soccer),
                  ),
                  title: Text(
                    g.opponent,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${g.startsAt?.day.toString().padLeft(2, '0')}/${g.startsAt?.month.toString().padLeft(2, '0')} '
                        '${g.startsAt?.hour.toString().padLeft(2, '0')}:${g.startsAt?.minute.toString().padLeft(2, '0')}'
                        '${venueName.isNotEmpty ? ' · $venueName' : ''}',
                      ),
                      if ((g.notes ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          g.notes!.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(.85),
                          ),
                        ),
                      ],

                      if (g.status == 'completed') ...[
                        const SizedBox(height: 2),
                        Text(
                          'Marcador: ${g.homeScore ?? 0} - ${g.opponentScore ?? 0}',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 🗺️ Google Maps
                      IconButton(
                        icon: const Icon(Icons.map_outlined),
                        tooltip: 'Abrir en Google Maps',
                        onPressed: () => _openInGoogleMaps(
                          context: context,
                          lat: g.lat,
                          lng: g.lng,
                          label: labelForMaps,
                        ),
                      ),

                      // 🔹 Icono de asistencia (solo manager y mismo día)
                      if (controller.userRole.value == 'manager' &&
                          g.startsAt != null &&
                          DateTime.now().year == g.startsAt!.year &&
                          DateTime.now().month == g.startsAt!.month &&
                          DateTime.now().day == g.startsAt!.day)
                        IconButton(
                          icon: const Icon(Icons.playlist_add_check_rounded),
                          tooltip: 'Lista de asistencia',
                          onPressed: () async {
                            final result = await Get.toNamed(
                              Routes.attendanceGame,
                              arguments: {
                                'categoryId': g.categoryId,
                                'gameId': g.id,
                                'gameDate': g.startsAt!,
                              },
                            );
                            if (result == true) {
                              controller.loadTabGameContent();
                            }
                          },
                        ),

                      // 🔹 Ícono de completar solo si no está finalizado
                      if (g.status != 'completed' && canComplete)
                        const Icon(Icons.edit),
                    ],
                  ),
                  onTap: () async {
                    if (g.status == 'completed') {
                      Get.snackbar(
                        'Completado',
                        'Este juego ya fue completado: ${g.homeScore ?? 0} - ${g.opponentScore ?? 0}',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                      return;
                    }

                    if (!canComplete) {
                      if (!isPast) {
                        Get.snackbar(
                          'No permitido',
                          'Solo puedes completar juegos que ya pasaron',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      } else {
                        controller.onTapGame(g);
                      }
                      return;
                    }

                    final result = await Get.toNamed(
                      Routes.completeGame,
                      arguments: {
                        'categoryId': controller.selectedCategoryId.value,
                        'gameId': g.id,
                        'gameDate': g.startsAt,
                      },
                    );

                    if (result == true) {
                      controller.loadTabGameContent();
                    }
                  },
                );
              },
            );

      return Stack(
        children: [
          Positioned.fill(child: listView),
          if (controller.userRole.value == 'manager')
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.extended(
                onPressed: () async {
                  final result = await Get.toNamed(
                    Routes.newGame,
                    arguments: {
                      'categoryId': controller.selectedCategoryId.value,
                    },
                  );

                  if (result == true) {
                    controller.loadTabGameContent();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Nuevo juego'),
              ),
            ),
        ],
      );
    });
  }
}
