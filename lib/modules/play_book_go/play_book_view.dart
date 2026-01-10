import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/play_book_model.dart';
import 'package:stopandgo/modules/play_book_create/play_book_create_controller.dart';
import 'play_book_controller.dart';
import 'play_book_painter.dart';

class PlayBookView extends GetView<PlayBookController> {
  const PlayBookView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget _metaBar() {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Obx(() {
          final side = controller.playSide.value ?? 'offense';
          final sideLabel = side == 'defense' ? 'Defensiva' : 'Ofensiva';
          final count = controller.playersCount.value > 0
              ? controller.playersCount.value
              : controller.players.length;

          final type = controller.playType.value ?? PlayType.run;

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _pill(
                theme,
                icon: side == 'defense' ? Icons.shield : Icons.sports_football,
                label: sideLabel,
              ),
              const SizedBox(width: 8),
              _pill(theme, icon: Icons.group, label: '$count jugadores'),
              const SizedBox(width: 8),
              // ✅ ahora label correcto del enum
              _pill(
                theme,
                icon: Icons.category,
                label: controller.typeLabel(type),
              ),
            ],
          );
        }),
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
              color: Colors.black.withOpacity(0.08),
            ),
          ],
        ),
        child: Column(
          children: [
            Obx(() {
              final t = controller.routeEndType.value;

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Flecha'),
                    selected: t == RouteEndType.arrow,
                    onSelected: (_) =>
                        controller.routeEndType.value = RouteEndType.arrow,
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Bloqueo'),
                    selected: t == RouteEndType.block,
                    onSelected: (_) =>
                        controller.routeEndType.value = RouteEndType.block,
                  ),
                ],
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
              color: Colors.black.withOpacity(0.08),
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
                      value: safeValue,
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
          _metaBar(),
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

                              final result = await Get.dialog<String>(
                                AlertDialog(
                                  title: const Text('Renombrar jugador'),
                                  content: TextField(
                                    controller: ctrl,
                                    maxLength: 3,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    decoration: const InputDecoration(
                                      hintText: 'Ej: WR2',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      counterText:
                                          '', // oculta contador si quieres
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Get.back(result: null),
                                      child: const Text('Cancelar'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Get.back(result: ctrl.text),
                                      child: const Text('Guardar'),
                                    ),
                                  ],
                                ),
                              );

                              if (result != null) {
                                controller.renameSelectedPlayer(result);
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
                        // forzar repaint
                        final _ = controller.players.length;
                        final __ = controller.activeRoutePoints.length;
                        final ___ = controller.routesByPlayer.length;

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
        bg = Colors.orange.withOpacity(0.15);
        fg = Colors.orange.shade800;
        break;
      case _PillTone.neutral:
      default:
        bg = theme.colorScheme.primary.withOpacity(0.10);
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
