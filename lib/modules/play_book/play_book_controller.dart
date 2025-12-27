import 'dart:ui';
import 'package:get/get.dart';
import 'package:stopandgo/modules/play_book/play_book_model.dart';

class PlayBookController extends GetxController {
  final fieldSize = const Size(900, 520);

  final players = <PlayerToken>[].obs;
  final selectedPlayerId = RxnString();
  final isDrawMode = false.obs; // false = mover (por default)

  String? _draggingPlayerId;
  Offset? _dragOffsetFromCenter; // para que no “salte” al centro

  // ✅ Para UX (label + anim/size)
  final isDragging = false.obs;
  final draggingPlayerId = RxnString();

  @override
  void onReady() {
    super.onReady();
    _seedDemoFormation();
  }

  void _seedDemoFormation() {
    if (players.isNotEmpty) return;

    players.assignAll(const [
      PlayerToken(id: 'qb', name: 'QB', pos: Offset(250, 260)),
      PlayerToken(id: 'rb', name: 'RB', pos: Offset(200, 310)),
      PlayerToken(id: 'wr1', name: 'WR1', pos: Offset(140, 180)),
      PlayerToken(id: 'wr2', name: 'WR2', pos: Offset(140, 340)),
      PlayerToken(id: 'c', name: 'C', pos: Offset(280, 260)),
    ]);

    selectedPlayerId.value = 'qb';
  }

  void resetFormation() {
    players.clear();
    _seedDemoFormation();
  }

  void selectPlayer(String id) {
    selectedPlayerId.value = id;
  }

  String? hitTestPlayer(Offset point, {double radius = 22}) {
    for (final p in players) {
      if ((p.pos - point).distance <= radius) return p.id;
    }
    return null;
  }

  void onPanStart(Offset localPoint) {
    if (isDrawMode.value) return;

    final hit = hitTestPlayer(localPoint);
    if (hit == null) return;

    _draggingPlayerId = hit;
    selectPlayer(hit);

    final p = players.firstWhere((e) => e.id == hit);
    _dragOffsetFromCenter = localPoint - p.pos;

    // ✅ UX flags
    isDragging.value = true;
    draggingPlayerId.value = hit;
  }

  void onPanUpdate(Offset localPoint) {
    if (isDrawMode.value) return;
    if (_draggingPlayerId == null) return;

    final offset = _dragOffsetFromCenter ?? Offset.zero;
    final desiredCenter = localPoint - offset;

    _movePlayerClamped(_draggingPlayerId!, desiredCenter);
  }

  void onPanEnd() {
    _draggingPlayerId = null;
    _dragOffsetFromCenter = null;

    // ✅ UX flags
    isDragging.value = false;
    draggingPlayerId.value = null;
  }

  void _movePlayerClamped(String playerId, Offset pos) {
    const tokenRadius = 18.0;
    final clamped = Offset(
      pos.dx.clamp(tokenRadius, fieldSize.width - tokenRadius),
      pos.dy.clamp(tokenRadius, fieldSize.height - tokenRadius),
    );

    final idx = players.indexWhere((p) => p.id == playerId);
    if (idx == -1) return;

    players[idx] = players[idx].copyWith(pos: clamped);
    players.refresh();
  }

  void onPanDown(Offset localPoint) {
    if (isDrawMode.value) return;

    final hit = hitTestPlayer(localPoint);
    if (hit == null) return;

    // Selección inmediata y label “moviendo…” desde el touch
    selectPlayer(hit);
    isDragging.value = true;
    draggingPlayerId.value = hit;
  }
}
