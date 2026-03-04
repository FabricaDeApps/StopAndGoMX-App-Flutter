// lib/modules/home/tabs/games/games_tab_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/games/games.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/storage/app_storage.dart';

enum GamesStatusFilter { all, played, upcoming }

enum GamesScopeFilter { mine, organization }

class GamesTabController extends GetxController {
  final api = Get.find<ApiRepository>();

  // Contexto (lo setea HomeController al cambiar categoría/jugador/rol)
  final role = ''.obs; // manager/coach/staff/parent/player
  final selectedCategoryId = RxnInt();
  final selectedPlayerId = RxnInt();

  final filterStatus = GamesStatusFilter.all.obs;
  final scopeFilter = GamesScopeFilter.mine.obs;
  final selectedRange = Rxn<DateTimeRange>();

  // Estado UI
  final isLoading = false.obs;
  final games = <Game>[].obs;

  DateTimeRange get effectiveRange {
    final r = selectedRange.value;
    if (r != null) return r;

    final now = DateTime.now();
    final from = DateTime(now.year, now.month, 1);
    final to = DateTime(now.year, now.month + 1, 0);
    return DateTimeRange(start: from, end: to);
  }

  void setFilterStatus(GamesStatusFilter s) => filterStatus.value = s;
  void setScopeFilter(GamesScopeFilter s) => scopeFilter.value = s;
  void setDateRange(DateTimeRange? r) => selectedRange.value = r;
  bool get canFilterByScope =>
      role.value == 'player' ||
      role.value == 'parent' ||
      role.value == 'manager' ||
      role.value == 'coach';

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

  String? _statusParam(GamesStatusFilter f) {
    switch (f) {
      case GamesStatusFilter.played:
        return 'completed'; // o 'completed' según tu backend
      case GamesStatusFilter.upcoming:
        return 'scheduled';
      case GamesStatusFilter.all:
      default:
        return null;
    }
  }

  Future<void> refresh() async {
    if (isLoading.value) return;
    isLoading.value = true;

    try {
      games.clear();

      final r = role.value;
      final range = effectiveRange;
      final from = range.start;
      final to = range.end;

      final status = _statusParam(filterStatus.value);

      if (r == 'staff') {
        final dtos = await api.getStaffGames(
          from: from,
          to: to,
          status: status,
          limit: 200,
        );
        games.assignAll(_sortedByStart(dtos));
        return;
      }

      if (r == 'manager') {
        final categoryId =
            selectedCategoryId.value ?? AppStorage.getSelectedCategoryId();
        if (categoryId == null) return;
        final allOrganizationGames =
            scopeFilter.value == GamesScopeFilter.organization;

        final dtos = await api.managerCategoryGames(
          categoryId: categoryId,
          from: _ymd(from),
          to: _ymd(to),
          status: status,
          allOrganizationGames: allOrganizationGames,
        );
        games.assignAll(_sortedByStart(dtos));
        return;
      }

      if (r == 'coach') {
        final categoryId =
            selectedCategoryId.value ?? AppStorage.getSelectedCategoryId();
        if (categoryId == null) return;
        final allOrganizationGames =
            scopeFilter.value == GamesScopeFilter.organization;

        final dtos = await api.getCoachCategoryGames(
          categoryId: categoryId,
          from: _ymd(from),
          to: _ymd(to),
          status: status,
          allOrganizationGames: allOrganizationGames,
        );
        games.assignAll(_sortedByStart(dtos));
        return;
      }

      if (r == 'parent') {
        final playerId =
            selectedPlayerId.value ?? AppStorage.getSelectedPlayerId();
        if (playerId == null) return;
        final allOrganizationGames =
            scopeFilter.value == GamesScopeFilter.organization;

        final dtos = await api.playerMyGamesFromParent(
          playerId: playerId,
          from: _ymd(from),
          to: _ymd(to),
          status: status,
          allOrganizationGames: allOrganizationGames,
        );
        games.assignAll(_sortedByStart(dtos));
        return;
      }

      // player
      final allOrganizationGames =
          scopeFilter.value == GamesScopeFilter.organization;
      final dtos = await api.playerMyGames(
        from: _ymd(from),
        to: _ymd(to),
        status: status,
        allOrganizationGames: allOrganizationGames,
      );
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
      if (a.startsAt == null && b.startsAt == null) return 0;
      if (a.startsAt == null) return 1; // a al final
      if (b.startsAt == null) return -1; // b al final

      return b.startsAt!.compareTo(a.startsAt!);
    });
    return copy;
  }

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  void clearDateRange() {
    selectedRange.value = null;
  }
}
