// lib/modules/home/home_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/category.dart';
import 'package:stopandgo/core/models/dto/payment_dto.dart';
import 'package:stopandgo/core/models/games.dart';
import 'package:stopandgo/core/network/api_repository.dart';
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

class HomeController extends GetxController
    with GetSingleTickerProviderStateMixin {
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

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 4, vsync: this);
    tabController.addListener(() async {
      currentTab.value = tabController.index;
      if (tabController.index == 1) {
        await loadTabGameContent();
      } else if (tabController.index == 2) {
        await loadPaymentsTab();
      } else if (currentTab.value == 3) {
        await loadNoticesTab();
      }
    });
  }

  @override
  Future<void> onReady() async {
    super.onReady();
    _loadSession();

    switch (userRole.value) {
      case 'manager':
        await _bootstrapManager();
        break;
      case 'parent':
        await _bootstrapParent();
        break;
      default: // 'player'
        await _loadDashboardForPlayerOrParent();
        break;
    }
  }

  Future<void> logout() async {
    try {
      await api.logout();
    } catch (_) {
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

  // ========= Manager =========
  Future<void> _bootstrapManager() async {
    await _loadCategories();

    if (categories.isEmpty) {
      Get.offAllNamed(Routes.noCategory);
      return;
    }
    if (categories.isNotEmpty && selectedCategoryId.value == null) {
      selectedCategoryId.value = categories.first.id;
      await AppStorage.setSelectedCategoryId(categories.first.id);
      await AppStorage.setSelectedCategoryName(categories.first.name);
    }
    if (selectedCategoryId.value != null) {
      await _loadDashboardForManager(categoryId: selectedCategoryId.value!);
    }
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

  Future<void> _loadDashboardForManager({required int categoryId}) async {
    try {
      isLoadingDash.value = true;
      final json = await api.managerCategoryDashboard(categoryId);
      _mapManagerDashboardJson(json);
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

  void _mapManagerDashboardJson(Map<String, dynamic> json) {
    final data = (json['data'] ?? {}) as Map<String, dynamic>;
    final totals = (data['totals'] ?? {}) as Map<String, dynamic>;
    final gamesJson = (data['games'] as List?) ?? const [];
    final noticesJson = (data['notices'] as List?) ?? const [];

    saldoPendiente.value = (totals['saldo_por_pagar'] ?? 0).toDouble();
    pagosRealizados.value = (totals['pagos_realizados'] ?? 0).toDouble();

    final games = gamesJson.map((g) {
      return Game.fromJson(g);
    }).toList();
    upcomingGames.assignAll(games);

    final ns = noticesJson.map((n) {
      final m = n as Map<String, dynamic>;
      return NoticeItem(
        id: (m['id'] ?? 0) as int,
        title: (m['title'] ?? '') as String,
        message: m['message']?.toString(),
        image: m['image']?.toString(),
        attachment: m['attachment']?.toString(),
        date: DateTime.tryParse(m['date']?.toString() ?? '') ?? DateTime.now(),
      );
    }).toList();
    notices.assignAll(ns);
  }

  // ========= Parent =========
  Future<void> _bootstrapParent() async {
    await _loadMyPlayers();
    if (myPlayers.isNotEmpty && selectedPlayerId.value == null) {
      selectedPlayerId.value = myPlayers.first.id;
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

  /// Usa /player/home para PARENT y PLAYER (dashboard general)
  Future<void> _loadDashboardForPlayerOrParent() async {
    try {
      isLoadingDash.value = true;
      final json = await api.playerHomeDashboard();
      _mapPlayerHomeJson(json);
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
    final games = gamesJson.map((g) {
      return Game.fromJson(g);
    }).toList();
    upcomingGames.assignAll(games);
    upcomingGames.assignAll(games);

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

  Future<void> loadTabGameContent() async {
    if (isLoadingTab1.value) return;
    isLoadingTab1.value = true;

    try {
      upcomingGames.clear();

      if (userRole.value == 'manager') {
        final categoryId =
            selectedCategoryId.value ?? AppStorage.getSelectedCategoryId();
        if (categoryId == null) {
          debugPrint('[HomeController] ⚠️ No hay categoría seleccionada.');
          return;
        }

        final now = DateTime.now();
        final from = DateTime(now.year, now.month, 1);
        final to = DateTime(now.year, now.month + 1, 0);

        final dtos = await api.managerCategoryGames(
          categoryId: categoryId,
          from: _ymd(from),
          to: _ymd(to),
        );

        dtos.sort((a, b) {
          final aDate = a.startsAt ?? DateTime(2100);
          final bDate = b.startsAt ?? DateTime(2100);
          return aDate.compareTo(bDate);
        });

        upcomingGames.assignAll(dtos);
      } else {
        final playerId =
            selectedPlayerId.value ?? AppStorage.getSelectedPlayerId();
        if (playerId == null) {
          debugPrint('[HomeController] ⚠️ No hay jugador seleccionado.');
          return;
        }

        final dtos = await api.playerMyGames(playerId: playerId);
        dtos.sort((a, b) {
          final aDate = a.startsAt ?? DateTime(2100);
          final bDate = b.startsAt ?? DateTime(2100);
          return aDate.compareTo(bDate);
        });

        upcomingGames.assignAll(dtos);
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

      if (userRole.value == 'manager') {
        final categoryId =
            selectedCategoryId.value ?? AppStorage.getSelectedCategoryId();
        if (categoryId == null) {
          debugPrint(
            '[HomeController] ⚠️ No hay categoría seleccionada para pagos.',
          );
          return;
        }
        final list = await api.managerCategoryPayments(categoryId: categoryId);
        payments.assignAll(list);
      } else {
        // parent / player
        final playerId =
            selectedPlayerId.value ?? AppStorage.getSelectedPlayerId();
        if (playerId == null) {
          debugPrint(
            '[HomeController] ⚠️ No hay jugador seleccionado para pagos.',
          );
          return;
        }
        final list = await api.playerMyPayments(playerId: playerId);
        payments.assignAll(list);
      }
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
        // player / parent: tomar last_notice de /player/home
        final n = await api.playerLastNotice();
        if (n != null) {
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

    Category? cat;
    for (final c in categories) {
      if (c.id == id) {
        cat = c;
        break;
      }
    }

    if (cat != null) {
      await AppStorage.setSelectedCategoryName(cat.name);
    }

    await _loadDashboardForManager(categoryId: id);

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

    await _loadDashboardForPlayerOrParent();

    if (tabController.index == 1) {
      await loadTabGameContent();
    } else if (tabController.index == 2) {
      await loadPaymentsTab();
    } else if (tabController.index == 3) {
      await loadNoticesTab();
    }
  }

  void onTapGame(Game g) {}
  void onTapPay() {}
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
