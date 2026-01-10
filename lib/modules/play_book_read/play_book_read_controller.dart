import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/models/play_book_model.dart';

class PlayBookReadController extends GetxController {
  final _api = Get.find<ApiRepository>();

  final fieldSize = const Size(900, 520);

  // Pan/zoom (solo lectura)
  final transformation = TransformationController();

  // View state
  final isLoading = false.obs;
  final error = RxnString();

  // Args
  final playId = RxnString();

  // Data
  final playAlias = ''.obs;
  final playType = ''.obs;

  final players = <PlayerToken>[].obs;
  final routesByPlayer = <String, List<PlayRoute>>{}.obs;

  // UI
  final selectedPlayerId = RxnString();

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments as Map<String, dynamic>?;
    final argPlayId = args?['playId']?.toString();

    if (argPlayId != null && argPlayId.isNotEmpty) {
      playId.value = argPlayId;
    }
  }

  @override
  void onReady() {
    super.onReady();
    if (playId.value != null) {
      loadPlayFromBackend(playId.value!);
    } else {
      // Opcional: demo si abres sin args
      _seedDemo();
    }
  }

  @override
  void onClose() {
    transformation.dispose();
    super.onClose();
  }

  Future<void> loadPlayFromBackend(String id) async {
    isLoading.value = true;
    error.value = null;

    try {
      final PlaybookPlay play = await _api.getPlaybookPlay(playId: id);

      // Meta
      playAlias.value = play.alias;
      playType.value = play.type;

      // Data
      players.assignAll(play.players);
      routesByPlayer.assignAll(play.routesByPlayer);

      // Default selection
      selectedPlayerId.value = players.isNotEmpty ? players.first.id : null;

      // Reset zoom al cargar
      resetView();
    } catch (e) {
      error.value = 'Error al cargar jugada: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void resetView() {
    transformation.value = Matrix4.identity();
  }

  String? hitTestPlayer(Offset point, {double radius = 22}) {
    for (final p in players) {
      if ((p.pos - point).distance <= radius) return p.id;
    }
    return null;
  }

  void selectPlayer(String id) {
    selectedPlayerId.value = id;
  }

  // Demo opcional
  void _seedDemo() {
    players.assignAll(const [
      PlayerToken(id: 'qb', name: 'QB', pos: Offset(250, 260)),
      PlayerToken(id: 'wr1', name: 'WR1', pos: Offset(140, 180)),
    ]);
    routesByPlayer.assignAll({
      'wr1': [
        PlayRoute(
          id: 'r1',
          playerId: 'wr1',
          origin: Offset(140, 180), // si tu model usa originTokenPos
          points: [Offset.zero, Offset(120, 10), Offset(200, -40)],
        ),
      ],
    });
    playAlias.value = 'DEMO';
    playType.value = 'Pase';
    selectedPlayerId.value = 'qb';
  }
}
