// lib/modules/home/tabs/games/games_tab_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/modules/home/widgets/live_breathing_badge.dart';
import 'package:stopandgo/routes/app_routes.dart';
import 'package:url_launcher/url_launcher.dart';

import 'games_tab_controller.dart';

class GamesTabView extends GetView<GamesTabController> {
  const GamesTabView({super.key});

  Future<void> _openInGoogleMaps({
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

    // Si quieres auto-load en primera vez:
    // (Si HomeController ya llama refresh al cambiar tab, no necesitas esto)
    // WidgetsBinding.instance.addPostFrameCallback((_) => controller.refresh());

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final list = controller.games;

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

                final role = controller.role.value;

                final canComplete = role == 'manager' && isPast;
                final canStartLive = controller.canStartLive();

                final streamingEnabled = controller.streamingEnabled;

                final venueName = g.venueObj?.name ?? g.venue ?? '';
                final labelForMaps =
                    '${g.opponent}${venueName.isNotEmpty ? ' · $venueName' : ''}';

                // LIVE flags
                final liveStatus = (g.liveStatus ?? '').trim().toLowerCase();
                final isLiveNow = liveStatus == 'live';
                final isReplay =
                    liveStatus == 'replay' || liveStatus == 'finished';

                final liveEventId = g.liveEventId;
                final playUrl = (g.livePlayUrl ?? '').trim();
                final hasLive = liveEventId != null && playUrl.isNotEmpty;

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
                  trailing: Wrap(
                    spacing: 2,
                    runSpacing: 2,
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // ===== LIVE / REPLAY =====
                      if (streamingEnabled && hasLive) ...[
                        if (isLiveNow)
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            visualDensity: VisualDensity.compact,
                            icon: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.live_tv_rounded,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(height: 2),
                                const LiveBreathingBadge(
                                  label: 'LIVE',
                                  color: Colors.red,
                                ),
                              ],
                            ),
                            tooltip: 'Ver en vivo',
                            onPressed: () async {
                              if (playUrl.isEmpty) {
                                return;
                              }

                              final we =
                                  AppStorage.getOrganization()?.name ?? '';
                              final categ =
                                  AppStorage.getSelectedCategoryName();

                              await Get.toNamed(
                                Routes.watchLive,
                                arguments: {
                                  'liveEventId': liveEventId,
                                  'playUrl': playUrl,
                                  'title': "${g.opponent} vs $we - $categ",
                                },
                              );

                              await controller.refresh();
                            },
                          ),

                        if (isReplay)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_circle_fill_rounded,
                                color: Colors.grey.shade400,
                                size: 20,
                              ),
                              const SizedBox(height: 2),
                              const LiveBreathingBadge(
                                label: 'Finalizado',
                                color: Colors.grey,
                                animate: false,
                              ),
                            ],
                          ),
                      ],

                      // 🎥 Iniciar Live (solo manager/coach y streaming habilitado)
                      if (streamingEnabled && canStartLive)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.videocam_outlined, size: 22),
                          tooltip: 'Iniciar Live',
                          onPressed: () async {
                            final orgId =
                                controller.organizationId ?? g.organizationId;
                            final we = AppStorage.getOrganization()?.name ?? '';
                            final categ = AppStorage.getSelectedCategoryName();

                            await Get.toNamed(
                              Routes.initLive,
                              arguments: {
                                'organizationId': orgId,
                                'categoryId': g.categoryId,
                                'gameId': g.id,
                                'title': "${g.opponent} vs $we - $categ",
                              },
                            );

                            await controller.refresh();
                          },
                        ),

                      // 🗺️ Google Maps
                      Visibility(
                        visible: role == 'manager' && g.status != "completed",
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.fact_check, size: 22),
                          onPressed: () async {
                            if (!canComplete) {
                              if (!isPast) {
                                Get.snackbar(
                                  'No permitido',
                                  'Solo puedes completar juegos que ya pasaron',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              } else {}
                              return;
                            }

                            final result = await Get.toNamed(
                              Routes.completeGame,
                              arguments: {
                                'categoryId':
                                    controller.selectedCategoryId.value ??
                                    AppStorage.getSelectedCategoryId(),
                                'gameId': g.id,
                                'gameDate': g.startsAt,
                              },
                            );

                            if (result == true) {
                              await controller.refresh();
                            }
                          },
                        ),
                      ),

                      // 📋 Asistencia (manager, mismo día)
                      if (role == 'manager' &&
                          g.startsAt != null &&
                          DateTime.now().year == g.startsAt!.year &&
                          DateTime.now().month == g.startsAt!.month &&
                          DateTime.now().day == g.startsAt!.day)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(
                            Icons.playlist_add_check_rounded,
                            size: 22,
                          ),
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
                              await controller.refresh();
                            }
                          },
                        ),
                    ],
                  ),
                  onTap: () async {
                    Get.toNamed(Routes.gameDetail, arguments: {'id': g.id});
                    return;
                  },
                );
              },
            );

      return Stack(
        children: [
          Positioned.fill(child: listView),

          // ✅ Solo manager crea juegos
          if (controller.role.value == 'manager')
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.extended(
                onPressed: () async {
                  final result = await Get.toNamed(
                    Routes.newGame,
                    arguments: {
                      'categoryId':
                          controller.selectedCategoryId.value ??
                          AppStorage.getSelectedCategoryId(),
                    },
                  );

                  if (result == true) {
                    await controller.refresh();
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
