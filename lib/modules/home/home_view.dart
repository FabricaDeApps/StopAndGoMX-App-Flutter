// lib/modules/home/home_view.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/category.dart';
import 'package:stopandgo/core/services/ecommerce_cart_service.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/core/utils/app_navigator.dart';
import 'package:stopandgo/core/utils/role_utils.dart';
import 'package:stopandgo/core/widgets/category_picker_sheet.dart';
import 'package:stopandgo/core/widgets/player_picker_sheet.dart';
import 'package:stopandgo/modules/webview/webview_page.dart';
import 'package:stopandgo/routes/app_routes.dart';

import 'home_controller.dart';
import 'models/simple_player.dart';

import 'tabs/dashboard/dashboard_tab_view.dart';
import 'tabs/games/games_tab_view.dart';
import 'tabs/gazzetta/gazzetta_tab_view.dart';
import 'tabs/payments/payments_tab_view.dart';
import 'tabs/notices/notices_tab_view.dart';
import 'tabs/tournaments/tournaments_tab_view.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  int _tabIndexOf(String key, List<String> tabs) {
    final idx = tabs.indexOf(key);
    return idx >= 0 ? idx : 0;
  }

  static String _roleLabel(String role) {
    switch (role) {
      case 'parent':
        return 'Padre/Madre';
      case 'player':
        return 'Jugador';
      case 'coach':
        return 'Coach';
      case 'manager':
        return 'Manager';
      case 'staff':
        return 'Staff';
      case 'admin':
        return 'Administrador';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final role = controller.userRole.value;

      final isManager = hasManagerPrivileges(role);
      final isParent = role == 'parent';
      final isPlayer = role == 'player';
      final isCoach = role == 'coach';
      final managerLabel = isAdminRole(role) ? 'Administrador: ' : 'Manager: ';

      final tabs = controller.tabs.toList();

      return Scaffold(
        drawer: _buildDrawer(context, theme),
        appBar: AppBar(
          title: Row(
            children: [
              if (isManager) ...[
                Text(
                  managerLabel,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CategoryDropdown(
                    items: controller.categories,
                    value: controller.selectedCategoryId.value,
                    onChanged: controller.onChangeCategory,
                  ),
                ),
              ] else if (isParent) ...[
                const Text(
                  'Jugador: ',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PlayerDropdown(
                    items: controller.myPlayers,
                    value: controller.selectedPlayerId.value,
                    onChanged: controller.onChangePlayer,
                  ),
                ),
              ] else if (isPlayer) ...[
                const Text(
                  'Categoría: ',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PlayerCategoryDropdown(
                    items: controller.myCategories,
                    value: controller.selectedPlayerCategoryId.value,
                    onChanged: controller.onChangePlayerCategory,
                  ),
                ),
              ] else if (isCoach) ...[
                const Text(
                  'Categoría: ',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PlayerCategoryDropdown(
                    items: controller.categories,
                    value: controller.selectedCategoryId.value,
                    onChanged: controller.onChangeCategory,
                  ),
                ),
              ] else ...[
                Expanded(
                  child: Text(
                    controller.userName.value,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            Obx(() {
              if (!controller.canShowEcommerce) {
                return const SizedBox.shrink();
              }
              return IconButton(
                onPressed: () {
                  final cartService = Get.find<EcommerceCartService>();
                  cartService.refreshCart();
                  Get.toNamed(Routes.ecommerceHome);
                },
                icon: const Icon(Icons.shopping_cart),
                tooltip: 'Carrito',
              );
            }),
          ],
        ),

        // ====== BODY: TABBARVIEW ======
        body: TabBarView(
          controller: controller.tabController,
          children: tabs.map((t) {
            switch (t) {
              case 'dashboard':
                return Obx(() {
                  final d = controller.dashboardCtrl;
                  d.upcomingGames.length;
                  d.notices.length;
                  d.saldoPendiente.value; // si aplica

                  return DashboardTabView(
                    onTapPay: () => controller.tabController.index =
                        _tabIndexOf('payments', tabs),
                    onGoGamesTab: () => controller.tabController.index =
                        _tabIndexOf('games', tabs),
                    onGoNoticesTab: () => controller.tabController.index =
                        _tabIndexOf('notices', tabs),
                  );
                });

              case 'games':
                return const GamesTabView();

              case 'payments':
                return const PaymentsTabView();

              case 'notices':
                return const NoticesTabView();
              case 'tournaments':
                return const TournamentsTabView();
              case 'gazzetta':
                return const GazzettaTabView();

              default:
                return const SizedBox.shrink();
            }
          }).toList(),
        ),

        // ====== TABBAR INFERIOR ======
        bottomNavigationBar: Material(
          elevation: 10,
          color: theme.colorScheme.surface,
          child: SafeArea(
            top: false,
            child: TabBar(
              controller: controller.tabController,
              labelPadding: const EdgeInsets.symmetric(vertical: 8),
              indicatorColor: theme.colorScheme.primary,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurface.withValues(
                alpha: 0.6,
              ),
              tabs: tabs.map((t) => _buildTab(t)).toList(),
            ),
          ),
        ),
      );
    });
  }

  Tab _buildTab(String key) {
    switch (key) {
      case "dashboard":
        return _tab(icon: Icons.dashboard, label: "Dashboard");
      case "games":
        return _tab(icon: Icons.sports_football, label: "Juegos");
      case "payments":
        return _tab(icon: Icons.payments_outlined, label: "Pagos");
      case "tournaments":
        return _tab(icon: Icons.emoji_events_outlined, label: "Torneos");
      case "notices":
        return _tab(icon: Icons.campaign_outlined, label: "Avisos");
      case "gazzetta":
        return _tab(icon: Icons.menu_book_outlined, label: "Gazzetta");
      default:
        return _tab(icon: Icons.circle_outlined, label: "N/A");
    }
  }

  Tab _tab({required IconData icon, required String label}) {
    return Tab(
      icon: Icon(icon),
      child: Text(
        label,
        maxLines: 2,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, height: 1.05),
      ),
    );
  }

  // ================= Drawer =================
  Widget _buildDrawer(BuildContext context, ThemeData theme) {
    return Drawer(
      child: SafeArea(
        child: Obx(() {
          final role = controller.userRole.value;

          final isManager = hasManagerPrivileges(role);
          final isParent = role == 'parent';
          final isPlayer = role == 'player';
          final isCoach = role == 'coach';
          final isStaff = role == 'staff';
          final orgSlug = (controller.org.value?.slug ?? '').trim();
          final availableRoles = controller.availableRoles;
          final selectedRole = availableRoles.contains(role)
              ? role
              : availableRoles.first;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: .85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: controller.onDrawerAvatarTap,
                          child: CircleAvatar(
                            radius: 70,
                            backgroundColor: theme.colorScheme.secondary
                                .withValues(alpha: .1),
                            child: controller.userAvatar.value != null
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: controller.userAvatar.value!,
                                      width: 150,
                                      height: 150,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => const SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                      errorWidget: (_, __, ___) =>
                                          const Icon(Icons.person, size: 56),
                                    ),
                                  )
                                : const Icon(Icons.person, size: 56),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Material(
                            color: Colors.white,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: controller.isUploadingAvatar.value
                                  ? null
                                  : controller.onTapEditAvatar,
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: controller.isUploadingAvatar.value
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: theme.colorScheme.primary,
                                        ),
                                      )
                                    : Icon(
                                        Icons.edit,
                                        size: 18,
                                        color: theme.colorScheme.primary,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      controller.userName.value,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      controller.userEmail.value,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: .9),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: const Text(
                        'Rol',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: selectedRole,
                              borderRadius: BorderRadius.circular(10),
                              icon: const Icon(Icons.keyboard_arrow_down),
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 14,
                              ),
                              items: availableRoles
                                  .map(
                                    (r) => DropdownMenuItem<String>(
                                      value: r,
                                      child: Text(_roleLabel(r)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) async {
                                if (value == null || value == role) return;
                                await controller.changeRole(value);
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Inicio'),
                onTap: () => AppNavigator.pop(context: context),
              ),
              ListTile(
                leading: const Icon(Icons.emoji_events_outlined),
                title: const Text('Torneos'),
                onTap: () async {
                  AppNavigator.pop(context: context);
                  await controller.openTournamentsTab();
                },
              ),
              if (controller.showNewsMenu.value)
                ListTile(
                  leading: const Icon(Icons.newspaper_outlined),
                  title: const Text('Noticias'),
                  onTap: () {
                    AppNavigator.pop(context: context);
                    Get.toNamed(Routes.news);
                  },
                ),
              if (isManager || isCoach) ...[
                ListTile(
                  leading: const Icon(Icons.group_add),
                  title: const Text('Asignar Jugador a Categoria'),
                  onTap: () async {
                    AppNavigator.pop(context: context);

                    if (isManager || isCoach) {
                      final picked = await _pickCategoryFromSheet();
                      if (picked == null) return;
                    }

                    Get.toNamed(Routes.assignPlayer);
                  },
                ),
              ],
              if (isManager || isCoach) ...[
                ListTile(
                  leading: const Icon(Icons.supervised_user_circle),
                  title: const Text('Roster'),
                  onTap: () async {
                    AppNavigator.pop(context: context);

                    if (isManager || isCoach) {
                      final picked = await _pickCategoryFromSheet();
                      if (picked == null) return;
                    }

                    Get.toNamed(Routes.roster);
                  },
                ),
                if (isAdminRole(role))
                  ListTile(
                    leading: const Icon(Icons.groups_2_outlined),
                    title: const Text('Roster General'),
                    onTap: () {
                      AppNavigator.pop(context: context);
                      Get.toNamed(Routes.adminRoster);
                    },
                  ),
                if (isManager)
                  ListTile(
                    leading: const Icon(Icons.fact_check_outlined),
                    title: const Text('Cumplimiento de documentos'),
                    onTap: () async {
                      AppNavigator.pop(context: context);

                      final picked = await _pickCategoryFromSheet();
                      if (picked == null) return;

                      final categoryId =
                          AppStorage.getSelectedCategoryId() ?? 0;
                      final categoryName =
                          AppStorage.getSelectedCategoryName() ?? 'Categoría';

                      Get.toNamed(
                        Routes.documentsCompliance,
                        arguments: {
                          'categoryId': categoryId,
                          'categoryName': categoryName,
                        },
                      );
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.list_alt_outlined),
                  title: const Text('Entrenamientos'),
                  onTap: () async {
                    AppNavigator.pop(context: context);

                    if (isManager || isCoach) {
                      final picked = await _pickCategoryFromSheet();
                      if (picked == null) return;
                    }

                    Get.toNamed(Routes.trainnings);
                  },
                ),
              ],
              if (isPlayer || isParent || isCoach) ...[
                ListTile(
                  leading: const Icon(Icons.fitness_center),
                  title: const Text('Evaluación (Combine)'),
                  onTap: () {
                    AppNavigator.pop(context: context);

                    if (isCoach) {
                      if (controller.categories.isEmpty) {
                        Get.snackbar(
                          'Categorías',
                          'No hay categorías asignadas para mostrar.',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                        return;
                      }

                      Get.bottomSheet<Map<String, dynamic>?>(
                        CategoryPickerSheet(categories: controller.categories),
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                      ).then((picked) async {
                        if (picked == null) return;

                        final cid = picked['id'] as int;
                        final cname = picked['name'] as String;

                        controller.selectedCategoryId.value = cid;
                        await AppStorage.setSelectedCategoryId(cid);
                        await AppStorage.setSelectedCategoryName(cname);

                        Get.toNamed(
                          Routes.combineEvents,
                          arguments: {'categoryId': cid, 'categoryName': cname},
                        );
                      });
                      return;
                    }

                    Get.toNamed(Routes.combineEvents);
                  },
                ),
              ],
              if (isPlayer || isParent) ...[
                ListTile(
                  leading: const Icon(Icons.list_alt_outlined),
                  title: const Text('Entrenamientos'),
                  onTap: () {
                    AppNavigator.pop(context: context);
                    Get.toNamed(Routes.playerTrainnings);
                  },
                ),
              ],
              if (isCoach || isPlayer) ...[
                Stack(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.route),
                      title: const Text('Playbook'),
                      onTap: () {
                        AppNavigator.pop(context: context);
                        Get.toNamed(Routes.playbookList);
                      },
                    ),
                    Positioned(
                      right: 12,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'NUEVO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (isParent || isPlayer) ...[
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Perfil Jugador'),
                  onTap: () =>
                      _openPlayerFullProfile(context: context, role: role),
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Documentos'),
                  onTap: () async {
                    AppNavigator.pop(context: context);

                    final user = AppStorage.getUser();
                    final role =
                        user?.role; // 'player' | 'parent' | 'coach' | etc.

                    final idPlayer = AppStorage.getSelectedPlayerId();
                    final name = AppStorage.getSelectedPlayerName();

                    // 👤 PLAYER → siempre directo
                    if (role == 'player' && idPlayer != null) {
                      Get.toNamed(
                        Routes.documents,
                        arguments: {'playerId': idPlayer, 'playerName': name},
                      );
                      return;
                    }

                    // 👨‍👩‍👧‍👦 PARENT → abrir selector
                    if (role == 'parent') {
                      final picked =
                          await Get.bottomSheet<Map<String, dynamic>?>(
                            const PlayerPickerSheet(),
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                          );

                      if (picked == null) return;

                      final pid = picked['id'] as int;
                      final pname = picked['name'] as String;

                      AppStorage.setSelectedPlayerId(pid);
                      AppStorage.setSelectedPlayerName(pname);

                      Get.toNamed(
                        Routes.documents,
                        arguments: {'playerId': pid, 'playerName': pname},
                      );
                      return;
                    }
                  },
                ),
              ],
              if (isPlayer) ...[
                ListTile(
                  leading: const Icon(Icons.family_restroom),
                  title: const Text('Datos de padres'),
                  onTap: () => Get.toNamed(Routes.parentsInfo),
                ),
              ],
              if (isPlayer || isCoach || isManager || isStaff) ...[
                ListTile(
                  leading: const Icon(Icons.how_to_reg),
                  title: const Text('Check-ins'),
                  onTap: () => Get.toNamed(Routes.checkins),
                ),
              ],
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Perfil'),
                onTap: () {
                  AppNavigator.pop(context: context);
                  Get.toNamed(Routes.myProfile);
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Ver políticas de privacidad'),
                onTap: () {
                  if (orgSlug.isEmpty) {
                    Get.snackbar(
                      'Privacidad',
                      'No se pudo obtener la organización actual.',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                    return;
                  }

                  final url = 'https://$orgSlug.stopandgomx.app/privacy-policy';

                  AppNavigator.pop(context: context);
                  Get.to(
                    () => AppWebViewPage(
                      title: 'Políticas de privacidad',
                      url: url,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Cerrar sesión'),
                onTap: () async {
                  final ok = await showDialog<bool>(
                    context: Get.context!,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Cerrar sesión'),
                      content: const Text(
                        '¿Seguro que deseas salir de tu cuenta?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Salir'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await controller.logout();
                  }
                },
              ),
            ],
          );
        }),
      ),
    );
  }

  Future<Map<String, dynamic>?> _pickCategoryFromSheet() async {
    if (controller.categories.isEmpty) {
      Get.snackbar(
        'Categorías',
        'No hay categorías asignadas para mostrar.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }

    final picked = await Get.bottomSheet<Map<String, dynamic>?>(
      CategoryPickerSheet(categories: controller.categories),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );

    if (picked == null) return null;

    final cid = picked['id'] as int;
    final cname = picked['name'] as String;

    controller.selectedCategoryId.value = cid;
    await AppStorage.setSelectedCategoryId(cid);
    await AppStorage.setSelectedCategoryName(cname);

    return picked;
  }

  Future<void> _openPlayerFullProfile({
    required BuildContext context,
    required String role,
  }) async {
    AppNavigator.pop(context: context);

    final selectedPlayerId = AppStorage.getSelectedPlayerId();
    final selectedPlayerName = AppStorage.getSelectedPlayerName();

    if (role == 'player') {
      Get.toNamed(
        Routes.playerFullProfile,
        arguments: {
          if (selectedPlayerId != null) 'playerId': selectedPlayerId,
          if (selectedPlayerName != null) 'playerName': selectedPlayerName,
        },
      );
      return;
    }

    if (role == 'parent' && selectedPlayerId != null) {
      Get.toNamed(
        Routes.playerFullProfile,
        arguments: {
          'playerId': selectedPlayerId,
          if (selectedPlayerName != null) 'playerName': selectedPlayerName,
        },
      );
      return;
    }

    if (role == 'parent') {
      final picked = await Get.bottomSheet<Map<String, dynamic>?>(
        const PlayerPickerSheet(),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );

      if (picked == null) return;

      final pid = picked['id'] as int;
      final pname = picked['name'] as String;

      await AppStorage.setSelectedPlayerId(pid);
      await AppStorage.setSelectedPlayerName(pname);

      Get.toNamed(
        Routes.playerFullProfile,
        arguments: {'playerId': pid, 'playerName': pname},
      );
    }
  }
}

// ============== Selectores AppBar ==============

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.items,
    required this.value,
    required this.onChanged,
  });

  final List<Category> items;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (items.isEmpty) {
      return Text('Sin categorías', style: theme.textTheme.bodyMedium);
    }
    return DropdownButton<int>(
      isExpanded: true,
      value: value ?? items.first.id,
      underline: const SizedBox.shrink(),
      icon: const Icon(Icons.keyboard_arrow_down),
      focusColor: const Color.fromARGB(0, 255, 255, 255),
      dropdownColor: Colors.grey,
      style: const TextStyle(color: Colors.black),
      items: items
          .map(
            (c) => DropdownMenuItem<int>(
              value: c.id,
              child: Text(
                c.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _PlayerDropdown extends StatelessWidget {
  const _PlayerDropdown({
    required this.items,
    required this.value,
    required this.onChanged,
  });

  final List<SimplePlayer> items;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (items.isEmpty) {
      return Text('Sin jugadores', style: theme.textTheme.bodyMedium);
    }
    return DropdownButton<int>(
      isExpanded: true,
      value: value ?? items.first.id,
      underline: const SizedBox.shrink(),
      icon: const Icon(Icons.keyboard_arrow_down),
      focusColor: Colors.transparent,
      dropdownColor: Colors.grey,
      style: const TextStyle(color: Colors.black),
      items: items
          .map(
            (p) => DropdownMenuItem<int>(
              value: p.id,
              child: Text(
                p.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _PlayerCategoryDropdown extends StatelessWidget {
  const _PlayerCategoryDropdown({
    required this.items,
    required this.value,
    required this.onChanged,
  });

  final List<Category> items;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (items.isEmpty) {
      return Text('Sin categorías', style: theme.textTheme.bodyMedium);
    }
    final selected = value ?? items.first.id;

    return DropdownButton<int>(
      isExpanded: true,
      value: selected,
      underline: const SizedBox.shrink(),
      icon: const Icon(Icons.keyboard_arrow_down),
      focusColor: Colors.transparent,
      dropdownColor: Colors.grey,
      style: const TextStyle(color: Colors.black),
      items: items
          .map(
            (c) => DropdownMenuItem<int>(
              value: c.id,
              child: Text(
                c.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
