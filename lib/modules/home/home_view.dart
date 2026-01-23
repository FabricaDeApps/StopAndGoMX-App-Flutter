// lib/modules/home/home_view.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/category.dart';
import 'package:stopandgo/core/services/ecommerce_cart_service.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/core/widgets/cards.dart';
import 'package:stopandgo/modules/home/widgets/games_tab.dart';
import 'package:stopandgo/modules/home/widgets/notices_tab.dart';
import 'package:stopandgo/modules/home/widgets/payments_tab.dart';
import 'package:stopandgo/routes/app_routes.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final role = controller.userRole.value;
      final isManager = role == 'manager';
      final isParent = role == 'parent';
      final isPlayer = role == 'player';
      final isCoach = role == 'coach';

      return DefaultTabController(
        length: 3,
        child: Scaffold(
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

          body: Column(
            children: [
              Expanded(
                child: Obx(() {
                  return TabBarView(
                    controller: controller.tabController,
                    children: controller.tabs.map((t) {
                      switch (t) {
                        case "dashboard":
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: () {
                              switch (role) {
                                case 'manager':
                                  return _ManagerDashboard(
                                    controller: controller,
                                  );

                                case 'coach':
                                  return _CoachDashboard(
                                    controller: controller,
                                  );
                                case 'staff':
                                  return _CoachDashboard(
                                    controller: controller,
                                  );

                                case 'parent':
                                case 'player':
                                  return _PlayerDashboard(
                                    controller: controller,
                                  );

                                default:
                                  return const SizedBox.shrink();
                              }
                            }(),
                          );
                        case "games":
                          return GamesTab(controller: controller);
                        case "payments":
                          return PaymentsTab();
                        case "notices":
                          return NoticesTab(controller: controller);
                        default:
                          return const SizedBox();
                      }
                    }).toList(),
                  );
                }),
              ),
            ],
          ),

          // ====== TABBAR INFERIOR ======
          bottomNavigationBar: Material(
            elevation: 10,
            color: theme.colorScheme.surface,
            child: SafeArea(
              top: false,
              child: Obx(() {
                return TabBar(
                  controller: controller.tabController,
                  labelPadding: const EdgeInsets.symmetric(vertical: 8),
                  indicatorColor: theme.colorScheme.primary,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(
                    0.6,
                  ),
                  tabs: controller.tabs.map((t) => _buildTab(t)).toList(),
                );
              }),
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
          // Lee el rol desde el controlador
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
              /*
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Configuración'),
                onTap: () {},
              ),
              
              ListTile(
                leading: const Icon(Icons.list),
                title: const Text('Mis Pedidos'),
                onTap: () {
                  Get.back();
                  Get.toNamed(Routes.ecommerceOrders);
                },
              ),
              */
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

// ================= Dashboards =================

class _ManagerDashboard extends StatelessWidget {
  const _ManagerDashboard({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(.10),
            theme.colorScheme.secondary.withOpacity(.10),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(.4),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // Aquí podríamos poner métricas de categorías en un futuro
          _GamesAndNotices(controller: controller),
        ],
      ),
    );
  }
}

class _CoachDashboard extends StatelessWidget {
  const _CoachDashboard({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(.10),
            theme.colorScheme.secondary.withOpacity(.10),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(.4),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // Aquí podríamos poner métricas de categorías en un futuro
          _GamesAndNotices(controller: controller),
        ],
      ),
    );
  }
}

class _PlayerDashboard extends StatelessWidget {
  const _PlayerDashboard({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final role = controller.userRole.value;
      final isParent = role == 'parent';

      final saldoLabel = isParent ? 'Saldo pendiente' : 'Saldo pendiente';

      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(.10),
              theme.colorScheme.secondary.withOpacity(.10),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(.4),
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    icon: Icons.account_balance_wallet_outlined,
                    label: "Pagos pendientes:",
                    value:
                        '\$${controller.saldoPendiente.value.toStringAsFixed(2)}',
                    onTap: controller.onTapPay,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _GamesAndNotices(controller: controller),
          ],
        ),
      );
    });
  }
}

class _GamesAndNotices extends StatelessWidget {
  const _GamesAndNotices({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // -------- Próximos juegos --------
        GestureDetector(
          onTap: () {
            controller.tabController.index = 1;
          },
          child: MiniCard(
            title: 'Próximos juegos',
            child: Obx(() {
              final list = controller.upcomingGames.take(3).toList();
              if (list.isEmpty) {
                return Text(
                  'Sin juegos próximos',
                  style: theme.textTheme.bodySmall,
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: list.map((g) {
                  final fecha = g.startsAt != null
                      ? _fmtDate(g.startsAt!)
                      : 'Fecha por definir';

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Icons.sports_football, size: 20),
                    title: Text(
                      g.opponent,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '$fecha · ${g.venue ?? 'Por definir'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => controller.onTapGame(g),
                  );
                }).toList(),
              );
            }),
          ),
        ),

        const SizedBox(height: 12),

        // -------- Avisos --------
        GestureDetector(
          onTap: () {
            controller.tabController.index = 3;
          },
          child: MiniCard(
            title: 'Avisos',
            child: Obx(() {
              final list = controller.notices.take(2).toList();
              if (list.isEmpty) {
                return Text('Sin avisos', style: theme.textTheme.bodySmall);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: list.map((n) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Icons.campaign, size: 20),
                    title: Text(
                      n.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(_fmtDate(n.date)),
                    onTap: () => controller.onTapNotice(n),
                  );
                }).toList(),
              );
            }),
          ),
        ),
      ],
    );
  }
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} '
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

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
                style: TextStyle(color: Colors.white),
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
                style: TextStyle(color: Colors.white),
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
