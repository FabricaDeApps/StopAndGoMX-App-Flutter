import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stopandgo/core/config/flavor_config.dart';
import 'package:stopandgo/core/models/category.dart';
import 'package:stopandgo/core/models/dto/notice_model.dart';
import 'package:stopandgo/core/models/games/games.dart';
import 'package:stopandgo/core/models/responses/organization_response.dart';
import 'package:stopandgo/core/network/token_storage.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/services/clarity_service.dart';
import 'package:stopandgo/core/services/notification_service.dart';
import 'package:stopandgo/modules/home/models/simple_player.dart';
import 'package:stopandgo/modules/home/tabs/games/games_tab_controller.dart';
import 'package:stopandgo/modules/home/tabs/notices/notices_tab_controller.dart';
import 'package:stopandgo/modules/home/tabs/payments/payments_controller.dart';
import 'package:stopandgo/routes/app_routes.dart';

import 'tabs/dashboard/dashboard_tab_controller.dart';

class HomeController extends GetxController with GetTickerProviderStateMixin {
  final api = Get.find<ApiRepository>();
  final _picker = ImagePicker();

  // sesión
  final userName = 'Usuario'.obs;
  final userEmail = ''.obs;
  final userAvatar = RxnString();
  final userRole = 'player'.obs;
  final isUploadingAvatar = false.obs;
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
    await refreshAccount();
    final user = AppStorage.getUser();
    if (user != null) {
      ClarityService.setUserContext(
        userId: user.id,
        role: user.activeRole.isNotEmpty ? user.activeRole : user.role,
        organizationId: FlavorConfig.I.organizationId,
      );
    }
    final hasValidAccess = await _bootstrapSelectorsByRole();
    if (!hasValidAccess) return;
    await _syncTabContext();
    await dashboardCtrl.refresh();
    NotificationService.consumePendingNavigationIfAny();
  }

  void _loadSession() {
    final user = AppStorage.getUser();
    if (user != null) {
      userName.value = user.name;
      userEmail.value = user.email;
      userAvatar.value = user.photoUrl;
      userRole.value = _normalizeRole(
        user.activeRole.isNotEmpty ? user.activeRole : user.role,
      );
    }
  }

  Future<void> refreshAccount() async {
    try {
      final account = await api.getAccount();

      final name = account['name']?.toString().trim();
      if (name != null && name.isNotEmpty) {
        userName.value = name;
      }

      final email = account['email']?.toString().trim();
      if (email != null && email.isNotEmpty) {
        userEmail.value = email;
      }

      final profilePhotoUrl = account['profile_photo_url']?.toString().trim();
      userAvatar.value = (profilePhotoUrl != null && profilePhotoUrl.isNotEmpty)
          ? profilePhotoUrl
          : null;

      final sessionUser = AppStorage.getUser();
      if (sessionUser != null) {
        await AppStorage.setUser(
          sessionUser.copyWith(
            name: userName.value,
            email: userEmail.value,
            photoUrl: userAvatar.value,
          ),
        );
      }
    } catch (_) {
      // No bloqueamos Home si este request falla.
    }
  }

  Future<void> onTapEditAvatar() async {
    final source = await Get.bottomSheet<ImageSource>(
      SafeArea(
        child: Material(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar foto'),
                onTap: () => Get.back(result: ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Elegir de galería'),
                onTap: () => Get.back(result: ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;
    await _pickAndUploadAvatar(source);
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    if (isUploadingAvatar.value) return;

    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (picked == null) return;

      isUploadingAvatar.value = true;

      await api.updateAccountPhoto(filePath: picked.path);
      await refreshAccount();

      final sessionUser = AppStorage.getUser();
      if (sessionUser != null) {
        await AppStorage.setUser(
          sessionUser.copyWith(photoUrl: userAvatar.value),
        );
      }

      Get.snackbar(
        'Foto de perfil',
        'Tu foto se actualizó correctamente.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Foto de perfil',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isUploadingAvatar.value = false;
    }
  }

  String _normalizeRole(String role) => role.trim().toLowerCase();

  List<String> get availableRoles {
    final raw = AppStorage.getAvailableRoles();
    final supported = raw
        .map(_normalizeRole)
        .where((r) => FlavorConfig.I.getTabsForRole(r).isNotEmpty)
        .toSet()
        .toList();
    if (supported.isEmpty) return <String>[userRole.value];
    if (!supported.contains(userRole.value)) {
      supported.insert(0, userRole.value);
    }
    return supported;
  }

  Future<void> changeRole(String newRole) async {
    final nextRole = _normalizeRole(newRole);
    if (nextRole.isEmpty || nextRole == userRole.value) return;

    if (FlavorConfig.I.getTabsForRole(nextRole).isEmpty) {
      Get.snackbar(
        'Rol',
        'El rol "$nextRole" no está habilitado en esta app.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await AppStorage.setActiveRole(nextRole);
    ClarityService.setUserContext(
      userId: AppStorage.getUser()?.id ?? 0,
      role: nextRole,
      organizationId: FlavorConfig.I.organizationId,
    );
    ClarityService.trackEvent('role_changed');
    await AppStorage.setSelectedCategoryId(null);
    await AppStorage.setSelectedCategoryName(null);
    await AppStorage.setSelectedPlayerId(null);
    await AppStorage.setSelectedPlayerName(null);
    _deletePersistentTabControllers();
    Get.offAllNamed(Routes.changeRole, arguments: {'role': nextRole});
  }

  void _deletePersistentTabControllers() {
    if (Get.isRegistered<DashboardTabController>()) {
      Get.delete<DashboardTabController>(force: true);
    }
    if (Get.isRegistered<GamesTabController>()) {
      Get.delete<GamesTabController>(force: true);
    }
    if (Get.isRegistered<PaymentsTabController>()) {
      Get.delete<PaymentsTabController>(force: true);
    }
    if (Get.isRegistered<NoticesTabController>()) {
      Get.delete<NoticesTabController>(force: true);
    }
  }

  Future<bool> _bootstrapSelectorsByRole() async {
    final role = userRole.value;

    if (role == 'manager') {
      await _loadManagerCategories();
      if (categories.isEmpty) {
        Get.offAllNamed(Routes.noCategory);
        return false;
      }

      selectedCategoryId.value ??=
          AppStorage.getSelectedCategoryId() ?? categories.first.id;
      await AppStorage.setSelectedCategoryId(selectedCategoryId.value!);
      return true;
    } else if (role == 'coach') {
      await _loadCoachCategories();
      if (categories.isEmpty) {
        Get.offAllNamed(Routes.noCategory);
        return false;
      }

      selectedCategoryId.value ??=
          AppStorage.getSelectedCategoryId() ?? categories.first.id;
      await AppStorage.setSelectedCategoryId(selectedCategoryId.value!);
      return true;
    } else if (role == 'parent') {
      await _loadMyPlayers();
      if (myPlayers.isEmpty) {
        Get.offAllNamed(Routes.noPlayer);
        return false;
      }

      selectedPlayerId.value ??=
          AppStorage.getSelectedPlayerId() ?? myPlayers.first.id;
      await AppStorage.setSelectedPlayerId(selectedPlayerId.value!);
      return true;
    } else if (role == 'player') {
      // setea el playerId del user en storage si aplica
      final user = AppStorage.getUser();
      if (user != null) {
        await AppStorage.setSelectedPlayerId(user.id);
      }

      await _loadPlayerCategories();
      if (myCategories.isEmpty) {
        Get.offAllNamed(Routes.noCategory);
        return false;
      }

      selectedPlayerCategoryId.value ??=
          AppStorage.getSelectedCategoryId() ?? myCategories.first.id;
      await AppStorage.setSelectedCategoryId(selectedPlayerCategoryId.value!);
      return true;
    } else if (role == 'staff') {
      // staff no necesita selectors
      return true;
    }

    return true;
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

    String name = '';
    for (final p in categories) {
      if (p.id == id) {
        name = p.name;
        break;
      }
    }

    await AppStorage.setSelectedCategoryName(name);
    ClarityService.setSelectedCategory(id);
    ClarityService.trackEvent('category_changed');

    await _loadCurrentTab();
  }

  Future<void> onChangePlayer(int? id) async {
    if (id == null) return;
    selectedPlayerId.value = id;
    selectedPlayerId.value = id;
    await AppStorage.setSelectedPlayerId(id);

    String name = '';
    for (final p in myPlayers) {
      if (p.id == id) {
        name = p.name;
        break;
      }
    }

    await AppStorage.setSelectedPlayerName(name);
    ClarityService.setSelectedPlayer(id);
    ClarityService.trackEvent('player_changed');

    await _loadCurrentTab();
  }

  Future<void> onChangePlayerCategory(int? id) async {
    if (id == null) return;
    selectedPlayerCategoryId.value = id;
    await AppStorage.setSelectedCategoryId(id);

    String name = '';
    for (final p in myCategories) {
      if (p.id == id) {
        name = p.name;
        break;
      }
    }

    await AppStorage.setSelectedPlayerName(name);
    ClarityService.setSelectedCategory(id);
    ClarityService.trackEvent('player_category_changed');

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

  void onTapNotice(Notice n) {
    Get.toNamed(Routes.noticeDetail, arguments: {'notice': n});
  }

  Future<void> logout() async {
    try {
      final tokenStorage = Get.find<TokenStorage>();
      await tokenStorage.clear();
      await AppStorage.clearAll();
      ClarityService.clearUserContext();
      ClarityService.trackEvent('logout');
      await api.logout();
    } catch (_) {
      Get.offAllNamed(Routes.splash);
    } finally {
      Get.offAllNamed(Routes.splash);
    }
  }

  bool get canShowEcommerce {
    final o = org.value;
    if (o == null) return false;

    return o.isActive && o.isEcommerceAvailable && o.ecommerce.enabled;
  }
}
