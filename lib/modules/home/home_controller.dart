import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:stopandgo/core/config/flavor_config.dart';
import 'package:stopandgo/core/models/category.dart';
import 'package:stopandgo/core/models/games.dart';
import 'package:stopandgo/core/models/responses/organization_response.dart';
import 'package:stopandgo/core/network/token_storage.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/modules/home/models/home_notice_item.dart';
import 'package:stopandgo/modules/home/models/simple_player.dart';
import 'package:stopandgo/modules/home/tabs/games/games_tab_controller.dart';
import 'package:stopandgo/modules/home/tabs/notices/notices_tab_controller.dart';
import 'package:stopandgo/modules/home/tabs/payments/payments_controller.dart';
import 'package:stopandgo/routes/app_routes.dart';

import 'tabs/dashboard/dashboard_tab_controller.dart';

class HomeController extends GetxController with GetTickerProviderStateMixin {
  final api = Get.find<ApiRepository>();

  // sesión
  final userName = 'Usuario'.obs;
  final userEmail = ''.obs;
  final userAvatar = RxnString();
  final userRole = 'player'.obs;
  final org = Rxn<OrganizationResponse>();

  // selects
  final categories = <Category>[].obs;
  final selectedCategoryId = RxnInt();

  final myPlayers = <SimplePlayer>[].obs;
  final selectedPlayerId = RxnInt();

  final myCategories = <Category>[].obs;
  final selectedPlayerCategoryId = RxnInt();

  // tabs
  late final TabController tabController;
  final tabs = <String>[].obs;
  int _lastLoadedTabIndex = -1;

  // tab controllers
  late final DashboardTabController dashboardCtrl;
  late final GamesTabController gamesCtrl;
  late final PaymentsTabController paymentsCtrl;
  late final NoticesTabController noticesCtrl;

  @override
  void onInit() {
    super.onInit();
    org.value = AppStorage.getOrganization();
    _loadSession();

    tabs.value = FlavorConfig.I.getTabsForRole(userRole.value);
    tabController = TabController(length: tabs.length, vsync: this);

    dashboardCtrl = Get.put(DashboardTabController(), permanent: true);
    gamesCtrl = Get.put(GamesTabController(), permanent: true);
    paymentsCtrl = Get.put(PaymentsTabController(), permanent: true);
    noticesCtrl = Get.put(NoticesTabController(), permanent: true);

    tabController.addListener(() async {
      if (tabController.indexIsChanging) return;
      final idx = tabController.index;
      if (_lastLoadedTabIndex == idx) return;
      _lastLoadedTabIndex = idx;

      await _loadCurrentTab();
    });

    _lastLoadedTabIndex = 0;
  }

  @override
  Future<void> onReady() async {
    super.onReady();
    await _bootstrapSelectorsByRole();
    await _syncTabContext();
    await dashboardCtrl.refresh();
  }

  void _loadSession() {
    final user = AppStorage.getUser();
    if (user != null) {
      userName.value = user.name;
      userEmail.value = user.email;
      userRole.value = user.role;
    }
  }

  Future<void> _bootstrapSelectorsByRole() async {
    final role = userRole.value;

    if (role == 'manager') {
      await _loadManagerCategories();
      if (categories.isEmpty) return;

      selectedCategoryId.value ??=
          AppStorage.getSelectedCategoryId() ?? categories.first.id;
      await AppStorage.setSelectedCategoryId(selectedCategoryId.value!);
    } else if (role == 'coach') {
      await _loadCoachCategories();
      if (categories.isEmpty) return;

      selectedCategoryId.value ??=
          AppStorage.getSelectedCategoryId() ?? categories.first.id;
      await AppStorage.setSelectedCategoryId(selectedCategoryId.value!);
    } else if (role == 'parent') {
      await _loadMyPlayers();
      if (myPlayers.isEmpty) return;

      selectedPlayerId.value ??=
          AppStorage.getSelectedPlayerId() ?? myPlayers.first.id;
      await AppStorage.setSelectedPlayerId(selectedPlayerId.value!);
    } else if (role == 'player') {
      // setea el playerId del user en storage si aplica
      final user = AppStorage.getUser();
      if (user != null) {
        await AppStorage.setSelectedPlayerId(user.id);
      }

      await _loadPlayerCategories();
      if (myCategories.isEmpty) return;

      selectedPlayerCategoryId.value ??=
          AppStorage.getSelectedCategoryId() ?? myCategories.first.id;
      await AppStorage.setSelectedCategoryId(selectedPlayerCategoryId.value!);
    } else if (role == 'staff') {
      // staff no necesita selectors
      return;
    }
  }

  Future<void> _loadManagerCategories() async {
    try {
      final cats = await api.getManagedCategories(perPage: 100);
      categories.assignAll(cats);
    } catch (e) {
      Get.snackbar(
        'Categorías',
        'No se pudieron cargar: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _loadCoachCategories() async {
    try {
      final cats = await api.getCoachCategories();
      categories.assignAll(cats);
    } catch (e) {
      Get.snackbar(
        'Categorías',
        'No se pudieron cargar: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _loadPlayerCategories() async {
    try {
      final list = await api.getMyPlayerCategories();
      myCategories.assignAll(list);
    } catch (e) {
      Get.snackbar(
        'Categorías',
        'No se pudieron cargar tus categorías: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _loadMyPlayers() async {
    try {
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
    }
  }

  Future<void> _syncTabContext() async {
    final role = userRole.value;

    dashboardCtrl.setContext(
      userRole: role,
      categoryId:
          selectedCategoryId.value ?? AppStorage.getSelectedCategoryId(),
      playerId: selectedPlayerId.value ?? AppStorage.getSelectedPlayerId(),
    );

    gamesCtrl.setContext(
      userRole: role,
      categoryId:
          selectedCategoryId.value ?? AppStorage.getSelectedCategoryId(),
      playerId: selectedPlayerId.value ?? AppStorage.getSelectedPlayerId(),
    );

    paymentsCtrl.setContext(
      userRole: role,
      categoryId:
          selectedCategoryId.value ?? AppStorage.getSelectedCategoryId(),
      playerId: selectedPlayerId.value ?? AppStorage.getSelectedPlayerId(),
    );

    noticesCtrl.setContext(
      userRole: role,
      categoryId:
          selectedCategoryId.value ?? AppStorage.getSelectedCategoryId(),
      playerId: selectedPlayerId.value ?? AppStorage.getSelectedPlayerId(),
    );
  }

  Future<void> _loadCurrentTab() async {
    await _syncTabContext();

    final tabKey = tabs[tabController.index];
    switch (tabKey) {
      case 'dashboard':
        await dashboardCtrl.refresh();
        break;
      case 'games':
        await gamesCtrl.refresh();
        break;
      case 'payments':
        await paymentsCtrl.refreshData();
        break;
      case 'notices':
        await noticesCtrl.refresh();
        break;
    }
  }

  // Callbacks selectors (solo cambian selects + refrescan tab actual)
  Future<void> onChangeCategory(int? id) async {
    if (id == null) return;
    selectedCategoryId.value = id;
    await AppStorage.setSelectedCategoryId(id);

    await _loadCurrentTab();
  }

  Future<void> onChangePlayer(int? id) async {
    if (id == null) return;
    selectedPlayerId.value = id;
    await AppStorage.setSelectedPlayerId(id);

    await _loadCurrentTab();
  }

  Future<void> onChangePlayerCategory(int? id) async {
    if (id == null) return;
    selectedPlayerCategoryId.value = id;
    await AppStorage.setSelectedCategoryId(id);

    await _loadCurrentTab();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  void onTapGame(Game g) {
    final idx = tabs.indexOf('games');
    if (idx < 0) return;
    tabController.index = idx;
    if (Get.isRegistered<GamesTabController>()) {
      Get.find<GamesTabController>().refresh();
    }
  }

  void onTapNotice(NoticeItem n) {
    final idx = tabs.indexOf('notices');
    if (idx < 0) return;
    tabController.index = idx;
    if (Get.isRegistered<NoticesTabController>()) {
      Get.find<NoticesTabController>().refresh();
    }
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

  bool get canShowEcommerce {
    final o = org.value;
    if (o == null) return false;

    return o.isActive && o.isEcommerceAvailable && o.ecommerce.enabled;
  }
}
