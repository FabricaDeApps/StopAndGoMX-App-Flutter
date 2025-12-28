import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/modules/play_book/play_book_model.dart';

enum PlayBookMode { play, move, route }

class PlayBookController extends GetxController {
  final _api = Get.find<ApiRepository>();

  final fieldSize = const Size(900, 520);

  // ---------------- VIEW STATE ----------------
  final isLoading = false.obs;
  final error = RxnString();

  // Si viene playId -> estamos viendo/EDITANDO detalle
  final playId = RxnString();
  bool get isEditingExisting =>
      (playId.value != null && playId.value!.isNotEmpty);

  // Texto del botón principal
  String get primaryCtaLabel => isEditingExisting ? 'Actualizar' : 'Guardar';

  // ---------------- PLAYERS ----------------
  final players = <PlayerToken>[].obs;
  final selectedPlayerId = RxnString();

  // ---------------- MODE ----------------
  final mode = PlayBookMode.play.obs;

  bool get isMoveMode => mode.value == PlayBookMode.move;
  bool get isDrawMode => mode.value == PlayBookMode.route;
  bool get isPlayMode => mode.value == PlayBookMode.play;

  void setMode(PlayBookMode m) {
    if (mode.value == m) return;
    mode.value = m;

    onPanEnd();
    if (!isDrawMode) {
      clearActiveRoute();
    }
  }

  // ---------------- DRAG ----------------
  String? _draggingPlayerId;
  Offset? _dragOffsetFromCenter;

  final isDragging = false.obs;
  final draggingPlayerId = RxnString();

  // ---------------- ROUTES ----------------
  final activeRoutePoints = <Offset>[].obs;
  final routesByPlayer = <String, List<PlayRoute>>{}.obs;

  // ---------------- PLAY META ----------------
  final playAliasCtrl = TextEditingController();
  final playTypes = <String>['Pase', 'Corrida', 'Defensa'];
  final playType = RxnString();

  final isSavingPlay = false.obs;
  final isDeletingPlay = false.obs;
  final playError = RxnString();

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments as Map<String, dynamic>?;
    final argPlayId = args?['playId']?.toString();

    if (argPlayId != null && argPlayId.isNotEmpty) {
      playId.value = argPlayId;
    }

    playType.value = playTypes.first;
  }

  @override
  void onReady() {
    super.onReady();

    if (isEditingExisting) {
      loadPlayFromBackend(playId.value!);
    } else {
      _seedDemoFormation();
    }
  }

  @override
  void onClose() {
    playAliasCtrl.dispose();
    super.onClose();
  }

  // ---------------- LOAD PLAY ----------------
  Future<void> loadPlayFromBackend(String id) async {
    isLoading.value = true;
    error.value = null;

    try {
      final PlaybookPlay play = await _api.getPlaybookPlay(playId: id);

      // Limpia todo antes de setear
      players.clear();
      routesByPlayer.clear();
      activeRoutePoints.clear();

      // Meta
      playAliasCtrl.text = play.alias;
      playType.value = (playTypes.contains(play.type))
          ? play.type
          : playTypes.first;

      // Players
      players.assignAll(play.players);

      // Routes
      routesByPlayer.assignAll(play.routesByPlayer);

      // Selección por default: primero
      selectedPlayerId.value = players.isNotEmpty ? players.first.id : null;

      // Modo inicial
      mode.value = PlayBookMode.play;
    } catch (e) {
      error.value = 'Error al cargar jugada: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------- INIT DEMO ----------------
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

    for (final p in players) {
      routesByPlayer.putIfAbsent(p.id, () => <PlayRoute>[]);
    }
  }

  void resetFormation() {
    players.clear();
    routesByPlayer.clear();
    activeRoutePoints.clear();
    _seedDemoFormation();
  }

  // ---------------- SELECTION ----------------
  void selectPlayer(String id) {
    selectedPlayerId.value = id;
  }

  PlayerToken? get selectedPlayer {
    final id = selectedPlayerId.value;
    if (id == null) return null;
    return players.firstWhereOrNull((p) => p.id == id);
  }

  String? hitTestPlayer(Offset point, {double radius = 22}) {
    for (final p in players) {
      if ((p.pos - point).distance <= radius) return p.id;
    }
    return null;
  }

  // ---------------- MOVE (DRAG) ----------------
  void onPanDown(Offset localPoint) {
    if (!isMoveMode) return;

    final hit = hitTestPlayer(localPoint);
    if (hit == null) return;

    selectPlayer(hit);
    isDragging.value = true;
    draggingPlayerId.value = hit;
  }

  void onPanStart(Offset localPoint) {
    if (!isMoveMode) return;

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
    if (!isMoveMode) return;
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

  // ---------------- DRAW (RUTAS) ----------------
  void clearActiveRoute() => activeRoutePoints.clear();

  void addRoutePointFromTap(Offset localPoint) {
    if (!isDrawMode) return;

    final sp = selectedPlayer;
    if (sp == null) return;

    if (activeRoutePoints.isEmpty) {
      activeRoutePoints.add(sp.pos);
    }

    activeRoutePoints.add(localPoint);
    activeRoutePoints.refresh();
  }

  void stepBackActive() {
    if (activeRoutePoints.isEmpty) return;
    activeRoutePoints.removeLast();
    activeRoutePoints.refresh();
  }

  void saveActiveRoute() {
    final pid = selectedPlayerId.value;
    final sp = selectedPlayer;
    if (pid == null || sp == null) return;

    if (activeRoutePoints.length < 2) {
      activeRoutePoints.clear();
      return;
    }

    final origin = sp.pos;
    final rel = activeRoutePoints.map((p) => p - origin).toList();

    final route = PlayRoute(
      id: _id(),
      playerId: pid,
      points: rel,
      origin: origin,
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

  void deleteRouteButton() {
    if (activeRoutePoints.isNotEmpty) {
      activeRoutePoints.clear();
      return;
    }
    deleteLastSavedRoute();
  }

  String _id() => DateTime.now().microsecondsSinceEpoch.toString();

  // ---------------- PAYLOAD (CREATE / UPDATE) ----------------
  Map<String, dynamic> _toPayload() {
    final alias = playAliasCtrl.text.trim();
    final type = playType.value ?? playTypes.first;

    final playersJson = players
        .map(
          (p) => {
            "id": p.id,
            "name": p.name,
            "x": p.pos.dx,
            "y": p.pos.dy,
            "isOffense": p.isOffense,
          },
        )
        .toList();

    final routesJson = <String, dynamic>{};
    routesByPlayer.forEach((playerId, list) {
      routesJson[playerId] = list
          .map(
            (r) => {
              "playerId": r.playerId,
              "origin": {"x": r.origin.dx, "y": r.origin.dy},
              "points": r.points.map((pt) => {"x": pt.dx, "y": pt.dy}).toList(),
            },
          )
          .toList();
    });

    final categoryId = AppStorage.getSelectedCategoryId();

    return {
      "category_id": categoryId,
      "alias": alias,
      "type": type,
      "notes": null,
      "players": playersJson,
      "routesByPlayer": routesJson,
    };
  }

  // ---------------- SAVE (CREATE OR UPDATE) ----------------
  Future<void> savePlayToBackend() async {
    playError.value = null;

    final alias = playAliasCtrl.text.trim();
    if (alias.isEmpty) {
      playError.value = 'Escribe un alias para la jugada.';
      return;
    }
    if (playType.value == null) {
      playError.value = 'Selecciona un tipo de jugada.';
      return;
    }

    isSavingPlay.value = true;
    try {
      final payload = _toPayload();

      if (isEditingExisting) {
        // ✅ UPDATE
        final updated = await _api.playbookUpdatePlay(
          playId: playId.value!,
          payload: payload,
        );

        // Si quieres quedarte en pantalla y refrescar con backend:
        // (si updated es el play completo)
        // final play = PlaybookPlay.fromJson(updated);
        // players.assignAll(play.players);
        // routesByPlayer.assignAll(play.routesByPlayer);

        Get.back(result: updated);
      } else {
        // ✅ CREATE
        final created = await _api.playbookCreatePlay(payload: payload);
        Get.back(result: created);
      }
    } catch (e) {
      playError.value = e.toString();
    } finally {
      isSavingPlay.value = false;
    }
  }

  // ---------------- DELETE (OPCIONAL) ----------------
  Future<void> deletePlayFromBackend() async {
    if (!isEditingExisting) return;

    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Eliminar jugada'),
        content: const Text(
          '¿Seguro que quieres eliminar esta jugada? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    isDeletingPlay.value = true;
    playError.value = null;

    try {
      final deleted = await _api.playbookDeletePlay(playId: playId.value!);
      if (!deleted) {
        throw Exception('No se pudo eliminar (ok != true)');
      }
      Get.back(result: {'deleted': true, 'playId': playId.value});
    } catch (e) {
      playError.value = e.toString();
    } finally {
      isDeletingPlay.value = false;
    }
  }
}
