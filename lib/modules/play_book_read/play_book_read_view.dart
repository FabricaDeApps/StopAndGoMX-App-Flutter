import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/modules/play_book_go/play_book_painter.dart';
import 'play_book_read_controller.dart';

class PlayBookReadView extends GetView<PlayBookReadController> {
  const PlayBookReadView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final alias = controller.playAlias.value.trim();
          final type = controller.playType.value.trim();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                alias.isEmpty ? 'PlayBook' : alias,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        }),
        actions: [
          IconButton(
            tooltip: 'Reset zoom',
            onPressed: controller.resetView,
            icon: const Icon(Icons.center_focus_strong),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value != null) {
          return Center(
            child: Text(
              controller.error.value!,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        return Column(
          children: [
            // Meta arriba
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Obx(() {
                      final type = controller.playType.value.trim();
                      return Text(
                        type.isEmpty ? '' : 'Tipo: $type',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      );
                    }),
                  ),
                  Obx(() {
                    final selId = controller.selectedPlayerId.value;
                    return Text(
                      selId == null ? '' : 'Jugador: $selId',
                      style: TextStyle(color: theme.hintColor),
                    );
                  }),
                ],
              ),
            ),

            // Canvas (pan + zoom)
            Expanded(
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    color: Colors.black12,
                    child: InteractiveViewer(
                      transformationController: controller.transformation,
                      minScale: 0.6,
                      maxScale: 3.5,
                      boundaryMargin: const EdgeInsets.all(200),

                      // OJO: en ReadOnly no hay drag tokens, entonces InteractiveViewer
                      // puede usar pan/zoom sin conflictos.
                      child: SizedBox(
                        width: controller.fieldSize.width,
                        height: controller.fieldSize.height,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (d) {
                            // Tap para seleccionar token (en coords del "mundo")
                            final world = controller.transformation.toScene(
                              d.localPosition,
                            );
                            final hit = controller.hitTestPlayer(world);
                            if (hit != null) controller.selectPlayer(hit);
                          },
                          child: Obx(() {
                            final selected = controller.selectedPlayerId.value;

                            return CustomPaint(
                              painter: PlayBookPainter(
                                fieldSize: controller.fieldSize,
                                players: controller.players.toList(),
                                selectedPlayerId: selected,

                                // read-only: no drag, no preview activo
                                isDragging: false,
                                draggingPlayerId: null,
                                isDrawMode: false,

                                routesByPlayer: controller.routesByPlayer,
                                activeRoutePoints: const [],
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),
          ],
        );
      }),
    );
  }
}
