// lib/modules/home/home_view.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/category.dart';
import 'package:stopandgo/core/services/ecommerce_cart_service.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/routes/app_routes.dart';

import 'home_controller.dart';
import 'models/simple_player.dart';

import 'tabs/dashboard/dashboard_tab_view.dart';
import 'tabs/games/games_tab_view.dart';
import 'tabs/payments/payments_tab_view.dart';
import 'tabs/notices/notices_tab_view.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  int _tabIndexOf(String key, List<String> tabs) {
    final idx = tabs.indexOf(key);
    return idx >= 0 ? idx : 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final role = controller.userRole.value;

      final isManager = role == 'manager';
      final isParent = role == 'parent';
      final isPlayer = role == 'player';
      final isCoach = role == 'coach';

      final tabs = controller.tabs.toList();

      return Scaffold(
        drawer: _buildDrawer(theme),
        appBar: AppBar(
          title: Row(
            children: [
              if (isManager) ...[
                const Text(
                  'Manager: ',
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
                  final _ = d.upcomingGames.length;
                  final __ = d.notices.length;
                  final ___ = d.saldoPendiente.value; // si aplica

                  return DashboardTabView(
                    onTapPay: () => controller.tabController.index =
                        _tabIndexOf('payments', tabs),
                    onGoGamesTab: () => controller.tabController.index =
                        _tabIndexOf('games', tabs),
                    onGoNoticesTab: () => controller.tabController.index =
                        _tabIndexOf('notices', tabs),
                    onTapGame: controller.onTapGame,
                    onTapNotice: controller.onTapNotice,
                  );
                });

              case 'games':
                return const GamesTabView();

              case 'payments':
                return const PaymentsTabView();

              case 'notices':
                return const NoticesTabView();

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
              unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(
                0.6,
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
        return const Tab(icon: Icon(Icons.dashboard), text: "Dashboard");
      case "games":
        return const Tab(icon: Icon(Icons.sports_football), text: "Juegos");
      case "payments":
        return const Tab(icon: Icon(Icons.payments_outlined), text: "Pagos");
      case "notices":
        return const Tab(icon: Icon(Icons.campaign_outlined), text: "Avisos");
      default:
        return const Tab(text: "N/A");
    }
  }

  // ================= Drawer =================
  Widget _buildDrawer(ThemeData theme) {
    return Drawer(
      child: SafeArea(
        child: Obx(() {
          final role = controller.userRole.value;

          final isManager = role == 'manager';
          final isParent = role == 'parent';
          final isPlayer = role == 'player';
          final isCoach = role == 'coach';

          return Column(
            children: [
              UserAccountsDrawerHeader(
                currentAccountPicture: CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.secondary.withOpacity(.1),
                  child: controller.userAvatar.value != null
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: controller.userAvatar.value!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.person, size: 36),
                ),
                accountName: Text(controller.userName.value),
                accountEmail: Text(controller.userEmail.value),
              ),

              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Inicio'),
                onTap: () => Get.back(),
              ),

              if (isManager || isCoach) ...[
                ListTile(
                  leading: const Icon(Icons.supervised_user_circle),
                  title: const Text('Roster'),
                  onTap: () {
                    Get.back();
                    Get.toNamed(Routes.roster);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.list_alt_outlined),
                  title: const Text('Entrenamientos'),
                  onTap: () {
                    Get.back();
                    Get.toNamed(Routes.trainnings);
                  },
                ),
              ],

              if (isPlayer || isParent || isCoach) ...[
                ListTile(
                  leading: const Icon(Icons.fitness_center),
                  title: const Text('Evaluación (Combine)'),
                  onTap: () {
                    Get.back();
                    Get.toNamed(Routes.combineEvents);
                  },
                ),
              ],

              if (isPlayer || isParent) ...[
                ListTile(
                  leading: const Icon(Icons.list_alt_outlined),
                  title: const Text('Entrenamientos'),
                  onTap: () {
                    Get.back();
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
                        Get.back();
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
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'BETA',
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

              if (isParent) ...[
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Documentos'),
                  onTap: () {
                    Get.back();
                    final idPlayer = AppStorage.getSelectedPlayerId();
                    final name = AppStorage.getSelectedPlayerName();
                    Get.toNamed(
                      Routes.documents,
                      arguments: {'playerId': idPlayer, 'playerName': name},
                    );
                  },
                ),
              ],

              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Perfil'),
                onTap: () {
                  Get.back();
                  Get.toNamed(Routes.myProfile);
                },
              ),

              const Spacer(),

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
