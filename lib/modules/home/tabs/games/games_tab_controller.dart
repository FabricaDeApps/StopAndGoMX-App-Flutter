// lib/modules/home/tabs/games/games_tab_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/games.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/storage/app_storage.dart';

class GamesTabController extends GetxController {
  final api = Get.find<ApiRepository>();

  // Contexto (lo setea HomeController al cambiar categoría/jugador/rol)
  final role = ''.obs; // manager/coach/staff/parent/player
  final selectedCategoryId = RxnInt();
  final selectedPlayerId = RxnInt();

  // Estado UI
  final isLoading = false.obs;
  final games = <Game>[].obs;

  // Org (para streamingEnabled y orgId)
  bool get streamingEnabled =>
      AppStorage.getOrganization()?.streamingEnabled ?? false;
  int? get organizationId => AppStorage.getOrganization()?.id;

  void setContext({required String userRole, int? categoryId, int? playerId}) {
    role.value = userRole;
    selectedCategoryId.value = categoryId;
    selectedPlayerId.value = playerId;
  }

  bool canStartLive() {
    final r = role.value;
    return r == 'manager' || r == 'coach';
  }

  Future<void> refresh() async {
    if (isLoading.value) return;
    isLoading.value = true;

    try {
      games.clear();

      // Rango del mes (para manager/coach/staff que filtran por fecha)
      final now = DateTime.now();
      final from = DateTime(now.year, now.month, 1);
      final to = DateTime(now.year, now.month + 1, 0);

      final r = role.value;

      if (r == 'staff') {
        final dtos = await api.getStaffGames(from: from, to: to, limit: 200);
        games.assignAll(_sortedByStart(dtos));
        return;
      }

      if (r == 'manager') {
        final categoryId =
            selectedCategoryId.value ?? AppStorage.getSelectedCategoryId();
        if (categoryId == null) return;

        final dtos = await api.managerCategoryGames(
          categoryId: categoryId,
          from: _ymd(from),
          to: _ymd(to),
        );
        games.assignAll(_sortedByStart(dtos));
        return;
      }

      if (r == 'parent') {
        final playerId =
            selectedPlayerId.value ?? AppStorage.getSelectedPlayerId();
        if (playerId == null) return;

        final dtos = await api.playerMyGamesFromParent(playerId: playerId);
        games.assignAll(_sortedByStart(dtos));
        return;
      }

      if (r == 'coach') {
        final categoryId =
            selectedCategoryId.value ?? AppStorage.getSelectedCategoryId();
        if (categoryId == null) return;

        final dtos = await api.getCoachCategoryGames(
          categoryId: categoryId,
          from: _ymd(from),
          to: _ymd(to),
        );
        games.assignAll(_sortedByStart(dtos));
        return;
      }

      // player (default)
      final dtos = await api.playerMyGames();
      games.assignAll(_sortedByStart(dtos));
    } catch (e, st) {
      debugPrint('[GamesTabController] ❌ Error cargando juegos: $e\n$st');
      Get.snackbar(
        'Juegos',
        'No se pudieron cargar los juegos: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  List<Game> _sortedByStart(List<Game> list) {
    final copy = [...list];
    copy.sort((a, b) {
      final da = a.startsAt ?? DateTime(2100);
      final db = b.startsAt ?? DateTime(2100);
      return da.compareTo(db);
    });
    return copy;
  }

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
