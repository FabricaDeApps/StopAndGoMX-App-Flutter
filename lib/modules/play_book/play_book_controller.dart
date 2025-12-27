import 'dart:math';
import 'dart:ui';
import 'package:get/get.dart';
import 'package:stopandgo/modules/play_book/play_book_model.dart';

class PlayBookController extends GetxController {
  final fieldSize = const Size(900, 520);

  final players = <PlayerToken>[].obs;
  final selectedPlayerId = RxnString();

  // false = mover (por default), true = dibujar
  final isDrawMode = false.obs;

  // Drag (mover tokens)
  String? _draggingPlayerId;
  Offset? _dragOffsetFromCenter;

  // UX
  final isDragging = false.obs;
  final draggingPlayerId = RxnString();

  // ----------------------------
  // RUTAS (world points para “preview” en vivo)
  // ----------------------------
  final activeRoutePoints = <Offset>[].obs; // puntos absolutos (en canvas)
  final routesByPlayer = <String, List<PlayRoute>>{}.obs; // guardadas

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

    // init routes map
    for (final p in players) {
      routesByPlayer.putIfAbsent(p.id, () => <PlayRoute>[]);
    }
    routesByPlayer.refresh();
  }

  void resetFormation() {
    players.clear();
    routesByPlayer.clear();
    activeRoutePoints.clear();
    _seedDemoFormation();
  }

  void selectPlayer(String id) {
    selectedPlayerId.value = id;

    // si cambias de jugador mientras dibujas, limpia preview activo
    if (isDrawMode.value) {
      clearActiveRoute();
    }
  }

  PlayerToken? get selectedPlayer {
    final id = selectedPlayerId.value;
    if (id == null) return null;
    return players.firstWhereOrNull((p) => p.id == id);
  }

  // ----------------------------
  // HIT TEST
  // ----------------------------
  String? hitTestPlayer(Offset point, {double radius = 22}) {
    for (final p in players) {
      if ((p.pos - point).distance <= radius) return p.id;
    }
    return null;
  }

  // ----------------------------
  // MODO MOVER (drag)
  // ----------------------------
  void onPanDown(Offset localPoint) {
    if (isDrawMode.value) return;

    final hit = hitTestPlayer(localPoint);
    if (hit == null) return;

    selectPlayer(hit);
    isDragging.value = true;
    draggingPlayerId.value = hit;
  }

  void onPanStart(Offset localPoint) {
    if (isDrawMode.value) return;

    final hit = hitTestPlayer(localPoint);
    if (hit == null) return;

    _draggingPlayerId = hit;
    selectPlayer(hit);

    final p = players.firstWhere((e) => e.id == hit);
    _dragOffsetFromCenter = localPoint - p.pos;

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

  // ----------------------------
  // MODO DIBUJAR (tap agrega puntos)
  // ----------------------------
  void addRoutePointFromTap(Offset localPoint) {
    if (!isDrawMode.value) return;

    final sp = selectedPlayer;
    if (sp == null) return;

    // arrancar desde el token seleccionado
    if (activeRoutePoints.isEmpty) {
      activeRoutePoints.add(sp.pos);
    }

    // evita puntos duplicados muy pegados
    if (activeRoutePoints.isNotEmpty &&
        (activeRoutePoints.last - localPoint).distance < 6) {
      return;
    }

    activeRoutePoints.add(localPoint);
  }

  void stepBackActive() {
    if (activeRoutePoints.isEmpty) return;

    // si solo está el punto inicial (token), al hacer stepBack se limpia todo
    if (activeRoutePoints.length <= 1) {
      activeRoutePoints.clear();
      return;
    }

    activeRoutePoints.removeLast();
    activeRoutePoints.refresh();
  }

  void clearActiveRoute() {
    activeRoutePoints.clear();
  }

  void saveActiveRoute() {
    final pid = selectedPlayerId.value;
    final sp = selectedPlayer;
    if (pid == null || sp == null) return;

    // mínimo: inicio + 1 punto
    if (activeRoutePoints.length < 2) {
      activeRoutePoints.clear();
      return;
    }

    final origin = activeRoutePoints.first; // normalmente sp.pos
    // Guardamos puntos RELATIVOS al origen (para que se mueva con el token)
    final relPoints = activeRoutePoints.map((p) => p - origin).toList();

    final route = PlayRoute(
      id: _id(),
      playerId: pid,
      points: relPoints, // 👈 relativos
      originTokenPos: origin, // 👈 ancla (pos token al dibujar)
    );

    final list = routesByPlayer[pid] ?? <PlayRoute>[];
    routesByPlayer[pid] = [...list, route];
    routesByPlayer.refresh();

    activeRoutePoints.clear();
  }

  void deleteLastSavedRoute() {
    final pid = selectedPlayerId.value;
    if (pid == null) return;

    final list = routesByPlayer[pid] ?? <PlayRoute>[];
    if (list.isEmpty) return;

    routesByPlayer[pid] = list.sublist(0, list.length - 1);
    routesByPlayer.refresh();
  }

  /// Botón "Borrar ruta":
  /// - Si hay ruta activa (preview), la borra
  /// - Si no hay activa, borra la última guardada del jugador
  void deleteRouteButton() {
    if (activeRoutePoints.isNotEmpty) {
      activeRoutePoints.clear();
      return;
    }
    deleteLastSavedRoute();
  }

  String _id() =>
      "${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}";
}
