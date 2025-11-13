// lib/modules/home/home_view.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/category.dart';
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
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Notificaciones',
              ),
            ],
          ),

          body: Column(
            children: [
              // ====== DASHBOARD ======
              Obx(() {
                if (controller.currentTab.value == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: role == 'manager'
                        ? _ManagerDashboard(controller: controller)
                        : _PlayerDashboard(controller: controller),
                  );
                } else {
                  return const SizedBox.shrink(); // no mostrar nada en otros tabs
                }
              }),

              // ====== CONTENIDO DE TABS ======
              Expanded(
                child: TabBarView(
                  controller: controller.tabController,
                  children: [
                    //_DashboardTab(controller: controller),
                    Container(),
                    GamesTab(controller: controller),
                    PaymentsTab(controller: controller),
                    NoticesTab(controller: controller),
                  ],
                ),
              ),
            ],
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
                tabs: const [
                  Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
                  Tab(icon: Icon(Icons.sports_football), text: 'Juegos'),
                  Tab(icon: Icon(Icons.payments_outlined), text: 'Pagos'),
                  Tab(icon: Icon(Icons.campaign_outlined), text: 'Avisos'),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // ================= Drawer =================
  Widget _buildDrawer(ThemeData theme) {
    return Drawer(
      child: SafeArea(
        child: Obx(() {
          // Lee el rol desde el controlador
          final role = controller.userRole.value;
          final isManager = role == 'manager';

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

              // Opción siempre visible
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Inicio'),
                onTap: () => Get.back(),
              ),

              // 👇 SOLO PARA MANAGER
              if (isManager) ...[
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Asignar Jugador'),
                  onTap: () {
                    Get.back();
                    Get.toNamed(Routes.assignPlayer);
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

              /*
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Perfil'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Configuración'),
                onTap: () {},
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
    return Obx(() {
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
            // Métricas
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Saldo pendiente',
                    value:
                        '\$${controller.saldoPendiente.value.toStringAsFixed(2)}',
                    onTap: controller.onTapPay,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    icon: Icons.payments_outlined,
                    label: 'Pagos realizados',
                    value:
                        '\$${controller.pagosRealizados.value.toStringAsFixed(2)}',
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

class _PlayerDashboard extends StatelessWidget {
  const _PlayerDashboard({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
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
                    label: 'Saldo pendiente',
                    value:
                        '\$${controller.saldoPendiente.value.toStringAsFixed(2)}',
                    onTap: controller.onTapPay,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    icon: Icons.payments_outlined,
                    label: 'Pagos realizados',
                    value:
                        '\$${controller.pagosRealizados.value.toStringAsFixed(2)}',
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
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

// ================= Tabs =================

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (controller.upcomingGames.isEmpty) {
        return Center(
          child: Text('Sin juegos próximos', style: theme.textTheme.bodyMedium),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: controller.upcomingGames.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final g = controller.upcomingGames[i];
          return ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            tileColor: theme.colorScheme.surface,
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withOpacity(.12),
              child: const Icon(Icons.sports_soccer),
            ),
            title: Text(
              g.opponent,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('${_fmtDate(g.startsAt!)} · ${g.venue}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => controller.onTapGame(g),
          );
        },
      );
    });
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
      focusColor: Colors.transparent,
      items: items
          .map(
            (c) => DropdownMenuItem<int>(
              value: c.id,
              child: Text(c.name, overflow: TextOverflow.ellipsis),
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
      items: items
          .map(
            (p) => DropdownMenuItem<int>(
              value: p.id,
              child: Text(p.name, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
