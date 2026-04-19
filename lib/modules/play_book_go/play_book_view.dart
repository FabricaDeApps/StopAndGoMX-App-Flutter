import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/play_book_model.dart';
import 'package:stopandgo/core/playbook/playbook_catalog.dart';
import 'play_book_controller.dart';
import 'play_book_painter.dart';

class PlayBookView extends GetView<PlayBookController> {
  const PlayBookView({super.key});

  String _routeTypeLabel(RouteEndType type) {
    switch (type) {
      case RouteEndType.arrow:
        return 'Flecha';
      case RouteEndType.block:
        return 'Bloqueo';
      case RouteEndType.stop:
        return 'Stop';
      case RouteEndType.motion:
        return 'Motion';
      case RouteEndType.pitch:
        return 'Pitch';
      case RouteEndType.adjustment:
        return 'Ajuste';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget metaBar() {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Obx(() {
          final sport = controller.playSport.value ?? PlaySport.flagFootball;
          final side = controller.playSide.value ?? 'offense';
          final sideLabel = side == 'defense' ? 'Defensiva' : 'Ofensiva';
          final count = controller.playersCount.value > 0
              ? controller.playersCount.value
              : controller.players.length;

          final type = controller.playType.value ?? PlayType.run;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _pill(
                  theme,
                  icon: Icons.emoji_events_outlined,
                  label: controller.sportLabel(sport),
                ),
                const SizedBox(width: 8),
                _pill(
                  theme,
                  icon: side == 'defense'
                      ? Icons.shield
                      : Icons.sports_football,
                  label: sideLabel,
                ),
                const SizedBox(width: 8),
                _pill(theme, icon: Icons.group, label: '$count jugadores'),
                const SizedBox(width: 8),
                _pill(
                  theme,
                  icon: Icons.category,
                  label: controller.typeLabel(type),
                ),
              ],
            ),
          );
        }),
      );
    }

    Widget likesCard() {
      return Card(
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Obx(() {
            final likes = controller.playLikes.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Confirmación de vista',
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: controller.isEditingExisting &&
                              !controller.isLikingPlay.value
                          ? controller.togglePlayLike
                          : null,
                      icon: controller.isLikingPlay.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              likes.isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                            ),
                      label: Text(likes.isLiked ? 'Te gusta' : 'Dar like'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  likes.count == 1
                      ? '1 persona ya confirmó esta jugada.'
                      : '${likes.count} personas ya confirmaron esta jugada.',
                  style: theme.textTheme.bodyMedium,
                ),
                if (likes.users.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: likes.users
                        .map(
                          (user) => Chip(
                            avatar: Icon(
                              user.role == 'coach'
                                  ? Icons.sports
                                  : Icons.person,
                              size: 16,
                            ),
                            label: Text(user.name),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            );
          }),
        ),
      );
    }

    Widget bottomBarForRoute() {
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              offset: const Offset(0, -2),
              color: Colors.black.withValues(alpha: 0.08),
            ),
          ],
        ),
        child: Column(
          children: [
            Obx(() {
              final t = controller.routeEndType.value;

              return SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: RouteEndType.values.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final option = RouteEndType.values[index];
                    return ChoiceChip(
                      label: Text(_routeTypeLabel(option)),
                      selected: t == option,
                      onSelected: (_) => controller.routeEndType.value = option,
                    );
                  },
                ),
              );
            }),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.deleteRouteButton,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Borrar ruta'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.stepBackActive,
                    icon: const Icon(Icons.undo),
                    label: const Text('Step back'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: controller.saveActiveRoute,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    Widget bottomBarForPlay() {
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              offset: const Offset(0, -2),
              color: Colors.black.withValues(alpha: 0.08),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Alias
                Expanded(
                  child: TextField(
                    controller: controller.playAliasCtrl,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Alias de la jugada',
                      hintText: 'Ej: Trips Right - Slant',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Tipo (enum PlayType)
                SizedBox(
                  width: 170,
                  child: Obx(() {
                    final safeValue = controller.playType.value ?? PlayType.run;

                    return DropdownButtonFormField<PlayType>(
                      initialValue: safeValue,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de jugada',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: controller.playTypes
                          .map(
                            (t) => DropdownMenuItem<PlayType>(
                              value: t,
                              child: Text(controller.typeLabel(t)),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        controller.playType.value = val;
                      },
                    );
                  }),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Error
            Obx(() {
              final msg = controller.playError.value;
              if (msg == null || msg.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 18,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        msg,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Guardar / Actualizar
            SizedBox(
              width: double.infinity,
              child: Obx(() {
                final saving = controller.isSavingPlay.value;
                final editing = controller.isEditingExisting;

                final label = saving
                    ? (editing ? 'Actualizando...' : 'Guardando...')
                    : (editing ? 'Actualizar jugada' : 'Guardar jugada');

                return FilledButton.icon(
                  onPressed: saving ? null : controller.savePlayToBackend,
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          editing
                              ? Icons.system_update_alt
                              : Icons.save_outlined,
                        ),
                  label: Text(label),
                );
              }),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(
            controller.isEditingExisting ? 'Editar PlayBook' : 'Nuevo PlayBook',
          ),
        ),
        actions: [
          // Eliminar solo en edit mode
          Obx(() {
            if (!controller.isEditingExisting) return const SizedBox.shrink();
            final deleting = controller.isDeletingPlay.value;
            return IconButton(
              tooltip: 'Eliminar jugada',
              onPressed:
                  (deleting ||
                      controller.isSavingPlay.value ||
                      controller.isLoading.value)
                  ? null
                  : controller.deletePlayFromBackend,
              icon: deleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
            );
          }),

          // Reset formación
          Obx(() {
            final disabled =
                controller.isLoading.value ||
                controller.isSavingPlay.value ||
                controller.isDeletingPlay.value;
            return IconButton(
              tooltip: 'Reset formación',
              onPressed: disabled ? null : controller.resetFormation,
              icon: const Icon(Icons.refresh),
            );
          }),
        ],
      ),
      body: Column(
        children: [
          metaBar(),
          if (controller.isEditingExisting) likesCard(),
          const SizedBox(height: 10),

          // SegmentedButton (3 modos)
          Center(
            child: Obx(() {
              final current = controller.mode.value;

              return SegmentedButton<PlayBookMode>(
                showSelectedIcon: false,
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                segments: const [
                  ButtonSegment(
                    value: PlayBookMode.play,
                    label: Text('Jugada'),
                    icon: Icon(Icons.edit),
                  ),
                  ButtonSegment(
                    value: PlayBookMode.move,
                    label: Text('Mover'),
                    icon: Icon(Icons.open_with),
                  ),
                  ButtonSegment(
                    value: PlayBookMode.route,
                    label: Text('Ruta'),
                    icon: Icon(Icons.alt_route),
                  ),
                ],
                selected: {current},
                onSelectionChanged: (set) => controller.setMode(set.first),
              );
            }),
          ),

          const SizedBox(height: 8),

          // Label superior (jugador + estado)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Obx(() {
              final selectedId = controller.selectedPlayerId.value;
              final selected = selectedId == null
                  ? null
                  : controller.players.firstWhereOrNull(
                      (p) => p.id == selectedId,
                    );

              final moving =
                  controller.isDragging.value &&
                  controller.draggingPlayerId.value == selectedId;

              final name = selected?.name ?? '-';
              final hasInfo = selected?.hasInfo == true;
              final txt = moving
                  ? 'Jugador: $name • moviendo...'
                  : 'Jugador: $name';

              return Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: selected == null
                          ? null
                          : () async {
                              final ctrl = TextEditingController(
                                text: selected.name,
                              );
                              final infoCtrl = TextEditingController(
                                text: selected.infoText ?? '',
                              );

                              final result =
                                  await Get.dialog<Map<String, String>>(
                                AlertDialog(
                                  title: const Text('Editar jugador'),
                                  content: SizedBox(
                                    width: 420,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          controller: ctrl,
                                          maxLength: 3,
                                          textCapitalization:
                                              TextCapitalization.characters,
                                          decoration: const InputDecoration(
                                            labelText: 'Nombre corto',
                                            hintText: 'Ej: WR2',
                                            border: OutlineInputBorder(),
                                            isDense: true,
                                            counterText: '',
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        TextField(
                                          controller: infoCtrl,
                                          minLines: 3,
                                          maxLines: 6,
                                          maxLength: 3000,
                                          decoration: const InputDecoration(
                                            labelText: 'Info del jugador',
                                            hintText:
                                                'Ej: Lee primero al safety y si baja ataca seam.',
                                            border: OutlineInputBorder(),
                                            alignLabelWithHint: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Get.back(result: null),
                                      child: const Text('Cancelar'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Get.back(
                                        result: {
                                          'name': ctrl.text,
                                          'infoText': infoCtrl.text,
                                        },
                                      ),
                                      child: const Text('Guardar'),
                                    ),
                                  ],
                                ),
                              );

                              if (result != null) {
                                controller.updateSelectedPlayerDetails(
                                  name: result['name'] ?? '',
                                  infoText: result['infoText'] ?? '',
                                );
                              }
                            },
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              txt,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: moving ? Colors.orange.shade800 : null,
                              ),
                            ),
                          ),
                          if (hasInfo)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.info,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          if (selected != null)
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Icon(Icons.edit, size: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Obx(() {
              final selectedId = controller.selectedPlayerId.value;
              final selected = selectedId == null
                  ? null
                  : controller.players.firstWhereOrNull(
                      (p) => p.id == selectedId,
                    );
              final info = selected?.infoText?.trim();

              if (info == null || info.isEmpty) {
                return Text(
                  'Este jugador no tiene info adicional.',
                  style: theme.textTheme.bodySmall,
                );
              }

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Info de ${selected?.name ?? 'jugador'}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(info),
                  ],
                ),
              );
            }),
          ),

          // Canvas
          Expanded(
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: Colors.black12,
                  child: SizedBox(
                    width: controller.fieldSize.width,
                    height: controller.fieldSize.height,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      dragStartBehavior: DragStartBehavior.down,
                      onPanDown: (d) {
                        if (controller.mode.value == PlayBookMode.move) {
                          controller.onPanDown(d.localPosition);
                        }
                      },
                      onTapDown: (d) {
                        final hit = controller.hitTestPlayer(d.localPosition);
                        if (hit != null) {
                          controller.selectPlayer(hit);
                          return;
                        }
                        if (controller.mode.value == PlayBookMode.route) {
                          controller.addRoutePointFromTap(d.localPosition);
                        }
                      },
                      onPanStart: (d) {
                        if (controller.mode.value == PlayBookMode.move) {
                          controller.onPanStart(d.localPosition);
                        }
                      },
                      onPanUpdate: (d) {
                        if (controller.mode.value == PlayBookMode.move) {
                          controller.onPanUpdate(d.localPosition);
                        }
                      },
                      onPanEnd: (_) => controller.onPanEnd(),
                      onPanCancel: controller.onPanEnd,
                      child: Obx(() {
                        final selected = controller.selectedPlayerId.value;

                        return CustomPaint(
                          painter: PlayBookPainter(
                            fieldSize: controller.fieldSize,
                            players: controller.players.toList(),
                            selectedPlayerId: selected,
                            isDragging: controller.isDragging.value,
                            draggingPlayerId: controller.draggingPlayerId.value,
                            isDrawMode:
                                controller.mode.value == PlayBookMode.route,
                            routesByPlayer: controller.routesByPlayer,
                            activeRoutePoints: controller.activeRoutePoints
                                .toList(),
                            currentRouteType: controller.routeEndType.value,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Barra inferior por modo
          Obx(() {
            return switch (controller.mode.value) {
              PlayBookMode.route => bottomBarForRoute(),
              PlayBookMode.play => bottomBarForPlay(),
              PlayBookMode.move => const SizedBox.shrink(),
            };
          }),
        ],
      ),
    );
  }

  Widget _pill(
    ThemeData theme, {
    required IconData icon,
    required String label,
    _PillTone tone = _PillTone.neutral,
  }) {
    Color bg;
    Color fg;

    switch (tone) {
      case _PillTone.warning:
        bg = Colors.orange.withValues(alpha: 0.15);
        fg = Colors.orange.shade800;
        break;
      case _PillTone.neutral:
        bg = theme.colorScheme.primary.withValues(alpha: 0.10);
        fg = theme.colorScheme.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

enum _PillTone { neutral, warning }
