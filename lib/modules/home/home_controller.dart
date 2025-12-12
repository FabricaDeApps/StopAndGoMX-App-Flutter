// lib/modules/home/home_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/config/flavor_config.dart';
import 'package:stopandgo/core/models/category.dart';
import 'package:stopandgo/core/models/dashboard_models.dart';
import 'package:stopandgo/core/models/dto/payment_dto.dart';
import 'package:stopandgo/core/models/games.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/network/token_storage.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/routes/app_routes.dart';

class NoticeItem {
  final int id;
  final String title;
  final String? message;
  final String? image;
  final String? attachment;
  final DateTime date;

  NoticeItem({
    required this.id,
    required this.title,
    required this.date,
    this.message,
    this.image,
    this.attachment,
  });
}

class SimplePlayer {
  final int id;
  final String name;
  final String? avatarUrl;
  SimplePlayer({required this.id, required this.name, this.avatarUrl});
}

class HomeController extends GetxController with GetTickerProviderStateMixin {
  final api = Get.find<ApiRepository>();

  // Perfil / sesión
  final userName = 'Usuario'.obs;
  final userEmail = ''.obs;
  final userAvatar = RxnString();
  final userRole = 'player'.obs; // 'manager' | 'parent' | 'player'

  // ========== MANAGER ==========
  final categories = <Category>[].obs;
  final selectedCategoryId = RxnInt();

  // ========== PARENT ==========
  final myPlayers = <SimplePlayer>[].obs;
  final selectedPlayerId = RxnInt();

  // ========== PLAYER ==========
  final myCategories = <Category>[].obs;
  final selectedPlayerCategoryId = RxnInt();

  // ========== Dashboard ==========
  final saldoPendiente = 0.0.obs;
  final pagosRealizados = 0.0.obs;
  final upcomingGames = <Game>[].obs;
  final notices = <NoticeItem>[].obs;

  // Loading del servicio (juegos Tab 1)
  final isLoadingTab1 = false.obs;

  // Tabs
  late final TabController tabController;
  final currentTab = 0.obs;

  // Loading flags generales
  final isLoadingCats = false.obs;
  final isLoadingKids = false.obs;
  final isLoadingDash = false.obs;

  final isLoadingPayments = false.obs;
  final isLoadingNotices = false.obs;

  final payments = <PaymentDto>[].obs;
  final tabs = <String>[].obs;

  // ✅ FIX: evita doble llamada al cambiar tabs
  int _lastLoadedTabIndex = -1;

  @override
  Future<void> onReady() async {
    super.onReady();
    _loadSession();

    tabs.value = FlavorConfig.I.getTabsForRole(userRole.value);
    tabController = TabController(length: tabs.length, vsync: this);

    tabController.addListener(() async {
      // 🔥 evita múltiples triggers durante animación/cambio
      if (tabController.indexIsChanging) return;

      final idx = tabController.index;

      // 🔥 evita pegar 2 veces al mismo tab por listeners
      if (_lastLoadedTabIndex == idx) return;
      _lastLoadedTabIndex = idx;

      currentTab.value = idx;

      if (idx == 1) {
        await loadTabGameContent();
      } else if (idx == 2) {
        await loadPaymentsTab();
      } else if (idx == 3) {
        await loadNoticesTab();
      }
    });

    switch (userRole.value) {
      case 'manager':
        await _bootstrapManager();
        break;
      case 'parent':
        await _bootstrapParent();
        break;
      case 'player':
        await _bootstrapPlayer();
        break;
      default:
        await _loadDashboardForPlayerOrParent();
        break;
    }

    // ✅ opcional: marcar el tab 0 como ya “visitado”
    _lastLoadedTabIndex = 0;
  }

  Future<void> logout() async {
    try {
      final tokenStorage = Get.find<TokenStorage>();
      tokenStorage.clear();
      AppStorage.clearAll();
      await api.logout();
    } catch (_) {
      Get.offAllNamed(Routes.login);
    } finally {
      Get.offAllNamed(Routes.login);
    }
  }

  // ========= Session =========
  void _loadSession() {
    final user = AppStorage.getUser();
    if (user != null) {
      userName.value = user.name;
      userEmail.value = user.email;
      userRole.value = user.role;
    }
    userAvatar.value = null;
  }

  // ========= MANAGER =========
  Future<void> _bootstrapManager() async {
    await _loadCategories();

    if (categories.isEmpty) {
      Get.offAllNamed(Routes.noCategory);
      return;
    }

    if (selectedCategoryId.value == null) {
      selectedCategoryId.value = categories.first.id;
      await AppStorage.setSelectedCategoryId(categories.first.id);
      await AppStorage.setSelectedCategoryName(categories.first.name);
    }

    await _loadDashboardForManager();
  }

  Future<void> _loadCategories() async {
    try {
      isLoadingCats.value = true;
      final cats = await api.getManagedCategories(perPage: 100);
      categories.assignAll(cats);
    } catch (e) {
      Get.snackbar(
        'Categorías',
        'No se pudieron cargar: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingCats.value = false;
    }
  }

  Future<void> _loadDashboardForManager() async {
    try {
      isLoadingDash.value = true;
      final dash = await api.getManagerDashboard();
      _mapManagerDashboard(dash);
    } catch (e) {
      Get.snackbar(
        'Dashboard',
        'No se pudo cargar: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingDash.value = false;
    }
  }

  void _mapManagerDashboard(ManagerDashboardResponse dash) {
    // En el endpoint manager actual no hay totales de pagos
    saldoPendiente.value = 0.0;
    pagosRealizados.value = 0.0;

    // Ya viene "proximos 3"
    upcomingGames.assignAll(_sortedByStart(dash.nextGames));

    _setSingleNotice(dash.lastNotice);
  }

  // ========= PARENT =========
  Future<void> _bootstrapParent() async {
    await _loadMyPlayers();

    if (myPlayers.isNotEmpty && selectedPlayerId.value == null) {
      selectedPlayerId.value = myPlayers.first.id;
      await AppStorage.setSelectedPlayerId(selectedPlayerId.value);
      await AppStorage.setSelectedPlayerName(myPlayers.first.name);
    }

    await _loadDashboardForPlayerOrParent();
  }

  Future<void> _loadMyPlayers() async {
    try {
      isLoadingKids.value = true;
      final list = await api.parentMyPlayers();
      myPlayers.assignAll(
        list.map<SimplePlayer>((m) {
          return SimplePlayer(
            id: (m['id'] ?? 0) as int,
            name: (m['display_name'] ?? m['name'] ?? 'Jugador') as String,
            avatarUrl: m['photo_url']?.toString(),
          );
        }).toList(),
      );
    } catch (e) {
      Get.snackbar(
        'Mis jugadores',
        'No se pudieron cargar: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingKids.value = false;
    }
  }

  // ========= PLAYER =========
  Future<void> _bootstrapPlayer() async {
    final user = AppStorage.getUser();
    if (user != null) {
      await AppStorage.setSelectedPlayerId(user.id);
      await AppStorage.setSelectedPlayerName(user.name);
    }

    await _loadPlayerCategories();

    if (myCategories.isNotEmpty && selectedPlayerCategoryId.value == null) {
      selectedPlayerCategoryId.value = myCategories.first.id;
      await AppStorage.setSelectedCategoryId(myCategories.first.id);
      await AppStorage.setSelectedCategoryName(myCategories.first.name);
    }

    await _loadDashboardForPlayerOrParent();
  }

  Future<void> _loadPlayerCategories() async {
    try {
      isLoadingCats.value = true;
      final list = await api.getMyPlayerCategories();
      myCategories.assignAll(list);
    } catch (e, st) {
      debugPrint(
        '[HomeController] ❌ Error cargando categorías del player: $e\n$st',
      );
      Get.snackbar(
        'Categorías',
        'No se pudieron cargar tus categorías: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingCats.value = false;
    }
  }

  /// Usa dashboards nuevos para PARENT y PLAYER
  Future<void> _loadDashboardForPlayerOrParent() async {
    try {
      isLoadingDash.value = true;

      if (userRole.value == 'player') {
        final dash = await api.getPlayerDashboard();
        _mapPlayerDashboard(dash);
      } else if (userRole.value == 'parent') {
        final dash = await api.getParentDashboard();
        _mapParentDashboard(dash);
      } else {
        // fallback viejo si algún rol raro cae aquí
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
      isLoadingDash.value = false;
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
    upcomingGames.assignAll(sorted.take(3).toList());

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

  /// ✅ No dependemos de NoticeModel: acepta cualquier DTO con esos campos
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

  /// ⚠️ Versión vieja basada en /player/home (fallback)
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

  // ===================== Tabs existentes =====================

  Future<void> loadTabGameContent() async {
    if (isLoadingTab1.value) return;
    isLoadingTab1.value = true;

    try {
      upcomingGames.clear();

      if (userRole.value == 'manager') {
        final categoryId =
            selectedCategoryId.value ?? AppStorage.getSelectedCategoryId();
        if (categoryId == null) return;

        final now = DateTime.now();
        final from = DateTime(now.year, now.month, 1);
        final to = DateTime(now.year, now.month + 1, 0);

        final dtos = await api.managerCategoryGames(
          categoryId: categoryId,
          from: _ymd(from),
          to: _ymd(to),
        );

        upcomingGames.assignAll(_sortedByStart(dtos));
      } else if (userRole.value == 'parent') {
        final playerId =
            selectedPlayerId.value ?? AppStorage.getSelectedPlayerId();
        if (playerId == null) return;

        final dtos = await api.playerMyGamesFromParent(playerId: playerId);
        upcomingGames.assignAll(_sortedByStart(dtos));
      } else {
        final dtos = await api.playerMyGames();
        upcomingGames.assignAll(_sortedByStart(dtos));
      }
    } catch (e, st) {
      debugPrint('[HomeController] ❌ Error cargando Tab1: $e\n$st');
      Get.snackbar(
        'Juegos',
        'No se pudieron cargar los juegos: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingTab1.value = false;
    }
  }

  Future<void> loadPaymentsTab() async {
    if (isLoadingPayments.value) return;
    isLoadingPayments.value = true;

    try {
      payments.clear();

      List<PaymentDto> list;
      if (userRole.value == 'manager') {
        final categoryId =
            selectedCategoryId.value ?? AppStorage.getSelectedCategoryId();
        if (categoryId == null) return;
        list = await api.managerCategoryPayments(categoryId: categoryId);
      } else if (userRole.value == 'parent') {
        final playerId =
            selectedPlayerId.value ?? AppStorage.getSelectedPlayerId();
        if (playerId == null) return;
        list = await api.playerMyPayments(playerId: playerId);
      } else {
        list = await api.myPayments();
      }

      payments.assignAll(list);

      double totalPagado = 0.0;
      double totalAdeudo = 0.0;

      for (final p in list) {
        final totalRecibido = p.receipts.fold<double>(
          0.0,
          (sum, r) => sum + r.amount,
        );
        final effectiveAmount = p.netAmount;
        totalPagado += totalRecibido;
        final balance = (effectiveAmount - totalRecibido);
        if (balance > 0) totalAdeudo += balance;
      }

      pagosRealizados.value = totalPagado;
      saldoPendiente.value = totalAdeudo;
    } catch (e, st) {
      debugPrint('[HomeController] ❌ Error cargando pagos: $e\n$st');
      Get.snackbar(
        'Pagos',
        'No se pudieron cargar los pagos: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingPayments.value = false;
    }
  }

  Future<void> loadNoticesTab() async {
    if (isLoadingNotices.value) return;
    isLoadingNotices.value = true;

    try {
      notices.clear();

      if (userRole.value == 'manager') {
        final list = await api.managerNotices();
        final mapped = list.map((m) {
          return NoticeItem(
            id: (m['id'] ?? 0) as int,
            title: (m['title'] ?? '') as String,
            message: m['message']?.toString(),
            image: m['image']?.toString(),
            attachment: m['attachment']?.toString(),
            date:
                DateTime.tryParse(
                  (m['published_at'] ?? m['created_at'] ?? '').toString(),
                ) ??
                DateTime.now(),
          );
        }).toList();
        notices.assignAll(mapped);
      } else {
        // Player/Parent: usamos last_notice del dashboard nuevo
        if (notices.isEmpty) {
          await _loadDashboardForPlayerOrParent();
        }
      }
    } catch (e, st) {
      debugPrint('[HomeController] ❌ Error cargando avisos: $e\n$st');
      Get.snackbar(
        'Avisos',
        'No se pudieron cargar los avisos: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingNotices.value = false;
    }
  }

  // ========= Callbacks UI =========
  Future<void> onChangeCategory(int? id) async {
    if (id == null) return;
    if (userRole.value != 'manager') return;

    selectedCategoryId.value = id;
    await AppStorage.setSelectedCategoryId(id);

    final cat = categories.firstWhereOrNull((c) => c.id == id);
    if (cat != null) {
      await AppStorage.setSelectedCategoryName(cat.name);
    }

    await _loadDashboardForManager();

    if (tabController.index == 1) {
      await loadTabGameContent();
    } else if (tabController.index == 2) {
      await loadPaymentsTab();
    } else if (tabController.index == 3) {
      await loadNoticesTab();
    }
  }

  Future<void> onChangePlayer(int? id) async {
    if (id == null) return;
    if (userRole.value != 'parent' && userRole.value != 'player') return;

    selectedPlayerId.value = id;
    await AppStorage.setSelectedPlayerId(id);

    final player = myPlayers.firstWhereOrNull((p) => p.id == id);
    if (player != null) {
      await AppStorage.setSelectedPlayerName(player.name);
    }

    await _loadDashboardForPlayerOrParent();

    if (tabController.index == 1) {
      await loadTabGameContent();
    } else if (tabController.index == 2) {
      await loadPaymentsTab();
    } else if (tabController.index == 3) {
      await loadNoticesTab();
    }
  }

  Future<void> onChangePlayerCategory(int? id) async {
    if (id == null) return;
    if (userRole.value != 'player') return;

    selectedPlayerCategoryId.value = id;

    final cat = myCategories.firstWhereOrNull((c) => c.id == id);
    if (cat != null) {
      await AppStorage.setSelectedCategoryId(cat.id);
      await AppStorage.setSelectedCategoryName(cat.name);
    }

    await _loadDashboardForPlayerOrParent();
  }

  void onTapGame(Game g) {}
  void onTapPay() {
    tabController.index = 2;
  }

  void onTapNotice(NoticeItem n) {}

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
