import 'package:get/get.dart';
import 'package:stopandgo/core/models/attendance_dashboard.dart';
import 'package:stopandgo/core/models/dashboard_models.dart';
import 'package:stopandgo/core/models/games.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/modules/home/models/home_notice_item.dart';

class DashboardTabController extends GetxController {
  final api = Get.find<ApiRepository>();

  // Inputs (los setea HomeController)
  final role = ''.obs; // manager/coach/staff/parent/player
  final selectedCategoryId = RxnInt();
  final selectedPlayerId = RxnInt();

  // Outputs (UI)
  final isLoading = false.obs;
  final saldoPendiente = 0.0.obs;
  final pagosRealizados = 0.0.obs;
  final upcomingGames = <Game>[].obs;
  final notices = <NoticeItem>[].obs;
  final playerCategories = <PlayerDashboardCategory>[].obs;
  final attendance = AttendanceDashboard.empty.obs;

  void setContext({required String userRole, int? categoryId, int? playerId}) {
    role.value = userRole;
    selectedCategoryId.value = categoryId;
    selectedPlayerId.value = playerId;
  }

  Future<void> refresh() async {
    switch (role.value) {
      case 'manager':
        return _loadDashboardForManager();
      case 'coach':
        return _loadDashboardForCoach();
      case 'staff':
        return _loadDashboardForStaff();
      case 'parent':
      case 'player':
        return _loadDashboardForPlayerOrParent();
      default:
        return _loadDashboardForPlayerOrParent();
    }
  }

  // ---------------- MANAGER ----------------
  Future<void> _loadDashboardForManager() async {
    try {
      isLoading.value = true;
      final dash = await api.getManagerDashboard();
      _mapManagerDashboard(dash);
    } catch (e) {
      Get.snackbar(
        'Dashboard',
        'No se pudo cargar: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _mapManagerDashboard(ManagerDashboardResponse dash) {
    saldoPendiente.value = 0.0;
    pagosRealizados.value = 0.0;
    upcomingGames.assignAll(_sortedByStart(dash.nextGames));
    _setSingleNotice(dash.lastNotice);
  }

  // ---------------- STAFF ----------------
  Future<void> _loadDashboardForStaff() async {
    try {
      isLoading.value = true;
      final dash = await api.getStaffDashboard();
      _mapStaffDashboard(dash);
    } catch (e) {
      Get.snackbar(
        'Dashboard',
        'No se pudo cargar: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _mapStaffDashboard(StaffDashboard dash) {
    saldoPendiente.value = 0.0;
    pagosRealizados.value = 0.0;

    final sorted = _sortedByStart(List<Game>.from(dash.upcomingGames));
    upcomingGames.assignAll(sorted.take(3).toList());
    _setSingleNotice(dash.lastNotice);
  }

  // ---------------- COACH ----------------
  Future<void> _loadDashboardForCoach() async {
    try {
      isLoading.value = true;

      // Asegura que exista una categoría seleccionada
      final categoryId =
          selectedCategoryId.value ?? AppStorage.getSelectedCategoryId();
      if (categoryId == null) return;

      // Si tu endpoint ya filtra por categoría internamente, ok.
      // Si no, aquí podríamos pasar categoryId si el API lo soporta.
      final dash = await api.getCoachDashboard();
      _mapCoachDashboard(dash);
    } catch (e) {
      Get.snackbar(
        'Dashboard',
        'No se pudo cargar: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _mapCoachDashboard(ParentDashboardResponse dash) {
    saldoPendiente.value = 0.0;
    pagosRealizados.value = 0.0;

    final all = <Game>[];
    for (final child in dash.children) {
      all.addAll(child.upcomingGames);
    }

    final sorted = _sortedByStart(all);
    upcomingGames.assignAll(sorted.take(3).toList());
    _setSingleNotice(dash.lastNotice);
  }

  // ---------------- PLAYER/PARENT ----------------
  Future<void> _loadDashboardForPlayerOrParent() async {
    try {
      isLoading.value = true;

      if (role.value == 'player') {
        final dash = await api.getPlayerDashboard();
        _mapPlayerDashboard(dash);
      } else if (role.value == 'parent') {
        final dash = await api.getParentDashboard();
        _mapParentDashboard(dash);
      } else {
        // fallback viejo
        final json = await api.playerHomeDashboard();
        _mapPlayerHomeJson(json);
      }
    } catch (e) {
      Get.snackbar(
        'Dashboard',
        'No se pudo cargar: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _mapPlayerDashboard(PlayerDashboardResponse dash) {
    saldoPendiente.value = dash.pendingTotal;
    pagosRealizados.value = 0.0;

    final games = dash.categories
        .map((c) => c.nextGame)
        .whereType<Game>()
        .toList();

    final sorted = _sortedByStart(games);
    playerCategories.clear();
    upcomingGames.clear();

    upcomingGames.assignAll(sorted.take(3).toList());
    playerCategories.assignAll(dash.categories);
    attendance.value = dash.attendance;

    _setSingleNotice(dash.lastNotice);
  }

  void _mapParentDashboard(ParentDashboardResponse dash) {
    saldoPendiente.value = dash.pendingTotal;
    pagosRealizados.value = 0.0;

    final all = <Game>[];
    for (final child in dash.children) {
      all.addAll(child.upcomingGames);
    }

    final sorted = _sortedByStart(all);
    upcomingGames.assignAll(sorted.take(3).toList());
    _setSingleNotice(dash.lastNotice);
  }

  // ---------------- Helpers ----------------
  void _setSingleNotice(dynamic n) {
    notices.clear();
    if (n == null) return;

    DateTime date = DateTime.now();
    try {
      final published = n.publishedAt;
      final created = n.createdAt;

      if (published is DateTime) {
        date = published;
      } else if (published is String) {
        date = DateTime.tryParse(published) ?? date;
      } else if (created is DateTime) {
        date = created;
      } else if (created is String) {
        date = DateTime.tryParse(created) ?? date;
      }
    } catch (_) {}

    notices.add(
      NoticeItem(
        id: (n.id as int),
        title: (n.title as String),
        message: n.message?.toString(),
        image: n.image?.toString(),
        attachment: n.attachment?.toString(),
        date: date,
      ),
    );
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

  void _mapPlayerHomeJson(Map<String, dynamic> json) {
    final payments = (json['payments'] ?? {}) as Map<String, dynamic>;
    final items = (payments['items'] as List?) ?? const [];

    double totalPagado = 0.0;
    double totalAdeudo = 0.0;

    for (final raw in items) {
      final m = raw as Map<String, dynamic>;
      final amount = (m['amount'] ?? 0).toDouble();
      final receipts = (m['receipts'] as List?) ?? const [];
      double pagado = 0.0;
      for (final r in receipts) {
        pagado += ((r as Map<String, dynamic>)['amount'] ?? 0).toDouble();
      }
      totalPagado += pagado;
      final balance = (amount - pagado);
      if (balance > 0) totalAdeudo += balance;
    }

    pagosRealizados.value = totalPagado;
    saldoPendiente.value = totalAdeudo;

    final gamesJson =
        ((json['games'] ?? {}) as Map<String, dynamic>)['items'] as List? ??
        const [];
    final games = gamesJson.map((g) => Game.fromJson(g)).toList();
    upcomingGames.assignAll(_sortedByStart(games).take(3).toList());

    notices.clear();
    if (json['last_notice'] != null) {
      final n = json['last_notice'] as Map<String, dynamic>;
      notices.add(
        NoticeItem(
          id: (n['id'] ?? 0) as int,
          title: (n['title'] ?? '') as String,
          message: n['message']?.toString(),
          image: n['image']?.toString(),
          attachment: n['attachment']?.toString(),
          date:
              DateTime.tryParse(
                (n['published_at'] ?? n['created_at'] ?? '').toString(),
              ) ??
              DateTime.now(),
        ),
      );
    }
  }
}
