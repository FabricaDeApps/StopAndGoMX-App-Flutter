import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'play_book_controller.dart';
import 'play_book_painter.dart';

class PlayBookView extends GetView<PlayBookController> {
  const PlayBookView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        child: Row(
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

                // Tipo
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String>(
                    value: controller.playType.value,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de jugada',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: controller.playTypes
                        .map(
                          (type) => DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      controller.playType.value = value;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Guardar
            SizedBox(
              width: double.infinity,
              child: Obx(() {
                final saving = controller.isSavingPlay.value;
                return FilledButton.icon(
                  onPressed: saving ? null : controller.savePlayToBackend,
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(saving ? 'Guardando...' : 'Guardar jugada'),
                );
              }),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('PlayBook'),
        actions: [
          IconButton(
            tooltip: 'Reset formación',
            onPressed: controller.resetFormation,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          // ✅ SegmentedButton (3 modos)
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
                onSelectionChanged: (set) {
                  controller.setMode(set.first);
                },
              );
            }),
          ),

          const SizedBox(height: 8),

          // ✅ Label superior (jugador + estado)
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

              final modeTxt = switch (controller.mode.value) {
                PlayBookMode.move => 'Mover',
                PlayBookMode.route => 'Ruta',
                PlayBookMode.play => 'Jugada',
              };

              return Row(
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
                  const SizedBox(width: 8),
                  Text('Modo: $modeTxt', style: const TextStyle(fontSize: 12)),
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

          // ✅ Barra inferior por modo
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
}
