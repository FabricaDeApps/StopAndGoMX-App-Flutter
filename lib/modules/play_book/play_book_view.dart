import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'play_book_controller.dart';
import 'play_book_painter.dart';

class PlayBookView extends GetView<PlayBookController> {
  const PlayBookView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PlayBook (Mover tokens)'),
        actions: [
          Obx(() {
            final draw = controller.isDrawMode.value;
            return IconButton(
              tooltip: draw ? 'Modo: Dibujar' : 'Modo: Mover',
              onPressed: () => controller.isDrawMode.toggle(),
              icon: Icon(draw ? Icons.edit : Icons.open_with),
            );
          }),
          IconButton(
            tooltip: 'Reset formación',
            onPressed: controller.resetFormation,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ Label superior
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                  Obx(() {
                    final mode = controller.isDrawMode.value
                        ? 'DIBUJAR'
                        : 'MOVER';
                    return Text(
                      'Modo: $mode',
                      style: const TextStyle(fontSize: 12),
                    );
                  }),
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
                      onPanDown: (d) => controller.onPanDown(d.localPosition),
                      onTapDown: (d) {
                        final hit = controller.hitTestPlayer(d.localPosition);
                        if (hit != null) controller.selectPlayer(hit);
                      },

                      onPanStart: (d) => controller.onPanStart(d.localPosition),
                      onPanUpdate: (d) =>
                          controller.onPanUpdate(d.localPosition),
                      onPanEnd: (_) => controller.onPanEnd(),
                      onPanCancel: controller.onPanEnd,
                      child: Obx(() {
                        final _ = controller.players.length;
                        final selected = controller.selectedPlayerId.value;
                        final isDragging = controller.isDragging.value;
                        final draggingId = controller.draggingPlayerId.value;

                        return CustomPaint(
                          painter: PlayBookPainter(
                            fieldSize: controller.fieldSize,
                            players: controller.players.toList(),
                            selectedPlayerId: selected,
                            isDragging: isDragging,
                            draggingPlayerId: draggingId,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
