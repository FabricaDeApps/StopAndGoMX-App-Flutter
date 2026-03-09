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

  String _dateLabel(DateTime? dt) {
    if (dt == null) return 'Fecha por definir';
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$day/$month  $hh:$mm';
  }

  String _statusLabel({required String? status, required String? liveStatus}) {
    final live = (liveStatus ?? '').trim().toLowerCase();
    if (live == 'live') return 'EN VIVO';
    if (live == 'replay' || live == 'finished') return 'REPLAY';

    switch ((status ?? '').trim().toLowerCase()) {
      case 'completed':
        return 'JUGADO';
      case 'scheduled':
        return 'POR JUGAR';
      default:
        return 'PROGRAMADO';
    }
  }

  Color _statusColor(
    ThemeData theme, {
    required String? status,
    required String? liveStatus,
  }) {
    final live = (liveStatus ?? '').trim().toLowerCase();
    if (live == 'live') return Colors.red;
    if (live == 'replay' || live == 'finished') return Colors.grey;
    if ((status ?? '').trim().toLowerCase() == 'completed') {
      return theme.colorScheme.primary;
    }
    return Colors.orange.shade700;
  }

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
                final isManagerAllTeamScope =
                    role == 'manager' &&
                    controller.scopeFilter.value ==
                        GamesScopeFilter.organization;
                final hideManagerActions = isManagerAllTeamScope;

                final canComplete = role == 'manager' && isPast;

                final streamingEnabled = controller.streamingEnabled;

                final venueName = g.venueObj?.name ?? g.venue ?? '';
                // LIVE flags
                final liveStatus = (g.liveStatus ?? '').trim().toLowerCase();
                final isLiveNow = liveStatus == 'live';
                final isReplay =
                    liveStatus == 'replay' || liveStatus == 'finished';

                final liveEventId = g.liveEventId;
                final playUrl = (g.livePlayUrl ?? '').trim();
                final hasLive = liveEventId != null && playUrl.isNotEmpty;

                final opponentCategory =
                    (g.opponentCategory ?? g.categoryName ?? '').trim();
                final statusLabel = _statusLabel(
                  status: g.status,
                  liveStatus: g.liveStatus,
                );
                final statusColor = _statusColor(
                  theme,
                  status: g.status,
                  liveStatus: g.liveStatus,
                );

                return Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                g.opponent,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                statusLabel,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: .3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (opponentCategory.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            opponentCategory,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.secondary,
                              letterSpacing: .2,
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 15,
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(.8),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _dateLabel(g.startsAt),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        if (venueName.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.place_outlined,
                                size: 15,
                                color: theme.textTheme.bodySmall?.color
                                    ?.withOpacity(.8),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  venueName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if ((g.notes ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
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
                          const SizedBox(height: 6),
                          Text(
                            'Marcador: ${g.homeScore ?? 0} - ${g.opponentScore ?? 0}',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
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
                        if (streamingEnabled &&
                            (role == 'coach' ||
                                (role == 'manager' && !hideManagerActions)))
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
                              final we =
                                  AppStorage.getOrganization()?.name ?? '';
                              final categ =
                                  AppStorage.getSelectedCategoryName();

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
                          visible:
                              role == 'manager' &&
                              !hideManagerActions &&
                              g.status != "completed",
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
                                  // Usa la categoría real del juego para evitar
                                  // desalineación cuando el manager ve "Toda la organización".
                                  'categoryId': g.categoryId,
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

                        if (((role == 'manager' && !isManagerAllTeamScope) ||
                                role == 'coach') &&
                            g.status != 'completed')
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.edit_outlined, size: 22),
                            tooltip: 'Editar juego',
                            onPressed: () async {
                              final result = await Get.toNamed(
                                Routes.newGame,
                                arguments: {
                                  'categoryId': g.categoryId,
                                  'game': g,
                                },
                              );

                              if (result == true) {
                                await controller.refresh();
                              }
                            },
                          ),

                        // 📋 Asistencia (manager, mismo día)
                        if (role == 'manager' &&
                            !isManagerAllTeamScope &&
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
                  ),
                );
              },
            );

      return Stack(
        children: [
          Column(
            children: [
              _GamesFiltersHeader(controller: controller),
              Expanded(child: listView),
            ],
          ),

          if ((controller.role.value == 'manager' &&
                  controller.scopeFilter.value == GamesScopeFilter.mine) ||
              controller.role.value == 'coach')
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

class _GamesFiltersHeader extends StatelessWidget {
  final GamesTabController controller;
  const _GamesFiltersHeader({required this.controller});

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final range = controller.effectiveRange;
      final selected = controller.selectedRange.value != null;
      final mineLabel =
          (controller.role.value == 'manager' ||
              controller.role.value == 'coach')
          ? 'Mis juegos'
          : 'Mis partidos';

      Widget chip(String label, GamesStatusFilter v) {
        final active = controller.filterStatus.value == v;
        return ChoiceChip(
          label: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          selected: active,
          onSelected: (_) async {
            controller.setFilterStatus(v);
            await controller.refresh(); // ✅ consume endpoint
          },
        );
      }

      return Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            bottom: BorderSide(color: theme.dividerColor.withOpacity(.5)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controller.canFilterByScope) ...[
              SegmentedButton<GamesScopeFilter>(
                showSelectedIcon: false,
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                segments: <ButtonSegment<GamesScopeFilter>>[
                  ButtonSegment<GamesScopeFilter>(
                    value: GamesScopeFilter.mine,
                    label: Text(mineLabel),
                    icon: Icon(Icons.person_outline, size: 18),
                  ),
                  const ButtonSegment<GamesScopeFilter>(
                    value: GamesScopeFilter.organization,
                    label: Text('Todos del equipo'),
                    icon: Icon(Icons.groups_2_outlined, size: 18),
                  ),
                ],
                selected: <GamesScopeFilter>{controller.scopeFilter.value},
                onSelectionChanged: (selection) async {
                  if (selection.isEmpty) return;
                  final selectedScope = selection.first;
                  if (selectedScope == controller.scopeFilter.value) return;
                  controller.setScopeFilter(selectedScope);
                  await controller.refresh();
                },
              ),
              const SizedBox(height: 8),
            ],

            // RANGO FECHAS
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020, 1, 1),
                        lastDate: DateTime(2035, 12, 31),
                        initialDateRange: range,
                      );
                      if (picked != null) {
                        controller.setDateRange(picked);
                        await controller.refresh(); // ✅ consume endpoint
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.dividerColor.withOpacity(.7),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.date_range_rounded, size: 17),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${_fmt(range.start)} — ${_fmt(range.end)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (selected)
                  IconButton(
                    tooltip: 'Quitar rango (mes actual)',
                    visualDensity: VisualDensity.compact,
                    onPressed: () async {
                      controller.clearDateRange();
                      await controller.refresh(); // ✅ consume endpoint
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // STATUS: Todos / Jugados / Por jugar
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                chip('Todos', GamesStatusFilter.all),
                chip('Jugados', GamesStatusFilter.played),
                chip('Por jugar', GamesStatusFilter.upcoming),
              ],
            ),
          ],
        ),
      );
    });
  }
}
