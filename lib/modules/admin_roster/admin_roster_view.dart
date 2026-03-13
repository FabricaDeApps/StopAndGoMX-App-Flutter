import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/admin_player.dart';
import 'package:stopandgo/modules/admin_roster/admin_roster_controller.dart';

class AdminRosterView extends GetView<AdminRosterController> {
  const AdminRosterView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Roster General'),
        centerTitle: true,
      ),
      body: Obx(() {
        return Column(
          children: [
            _FiltersCard(controller: controller),
            Expanded(
              child: Builder(
                builder: (_) {
                  if (controller.isLoading.value && controller.players.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (controller.error.value != null &&
                      controller.players.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              controller.error.value!,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: controller.loadPlayers,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (controller.players.isEmpty) {
                    return const Center(
                      child: Text('No se encontraron jugadores.'),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: controller.applyFilters,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: controller.players.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        if (index == controller.players.length) {
                          return _PaginationFooter(controller: controller);
                        }

                        final player = controller.players[index];
                        return _PlayerCard(
                          player: player,
                          onEdit: () => controller.goToEdit(player),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _FiltersCard extends StatelessWidget {
  const _FiltersCard({required this.controller});

  final AdminRosterController controller;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          children: [
            TextField(
              controller: controller.queryCtrl,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => controller.applyFilters(),
              decoration: const InputDecoration(
                labelText: 'Buscar jugador',
                hintText: 'Nombre, alias, email, teléfono o CURP',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Obx(
                    () => DropdownButtonFormField<String>(
                      initialValue: controller.activeFilter.value,
                      decoration: const InputDecoration(
                        labelText: 'Activo',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Todos')),
                        DropdownMenuItem(
                          value: 'active',
                          child: Text('Activos'),
                        ),
                        DropdownMenuItem(
                          value: 'inactive',
                          child: Text('Inactivos'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) controller.activeFilter.value = value;
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(
                    () => DropdownButtonFormField<int>(
                      initialValue: controller.perPage.value,
                      decoration: const InputDecoration(
                        labelText: 'Por página',
                        border: OutlineInputBorder(),
                      ),
                      items: const [10, 25, 50, 100]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text('$value'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) controller.perPage.value = value;
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: controller.clearFilters,
                    child: const Text('Limpiar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: controller.applyFilters,
                    child: const Text('Aplicar filtros'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({required this.player, required this.onEdit});

  final AdminPlayer player;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = player.categories.map((e) => e.name).join(', ');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: player.photoUrl != null
                      ? NetworkImage(player.photoUrl!)
                      : null,
                  child: player.photoUrl == null
                      ? Text(_initials(player.displayName))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if ((player.alias ?? '').isNotEmpty)
                        Text(
                          'Alias: ${player.alias}',
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar jugador',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(
                  label: player.isActive ? 'Activo' : 'Inactivo',
                  color: player.isActive ? Colors.green : Colors.grey,
                ),
                _StatusChip(
                  label: player.confirmed ? 'Confirmado' : 'No confirmado',
                  color: player.confirmed ? Colors.blue : Colors.orange,
                ),
                if (player.archived)
                  const _StatusChip(label: 'Archivado', color: Colors.red),
              ],
            ),
            const SizedBox(height: 10),
            if (categories.isNotEmpty)
              _InfoRow(
                icon: Icons.groups_outlined,
                text: categories,
              ),
            if ((player.email ?? '').isNotEmpty)
              _InfoRow(
                icon: Icons.alternate_email,
                text: player.email!,
              ),
            if ((player.phone ?? '').isNotEmpty)
              _InfoRow(
                icon: Icons.phone_outlined,
                text: player.phone!,
              ),
            if ((player.position ?? '').isNotEmpty)
              _InfoRow(
                icon: Icons.sports_football,
                text: player.position!,
              ),
            if ((player.updatedAt ?? '').isNotEmpty)
              _InfoRow(
                icon: Icons.update,
                text: 'Actualizado: ${player.updatedAt}',
              ),
          ],
        ),
      ),
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((e) => e.isEmpty ? '' : e[0]).join();
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({required this.controller});

  final AdminRosterController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 12),
        child: Column(
          children: [
            Text(
              'Página ${controller.currentPage.value} de ${controller.lastPage.value} · ${controller.total.value} jugadores',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.hasPrevPage
                        ? () => controller.loadPlayers(
                              page: controller.currentPage.value - 1,
                            )
                        : null,
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('Anterior'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: controller.hasNextPage
                        ? () => controller.loadPlayers(
                              page: controller.currentPage.value + 1,
                            )
                        : null,
                    icon: const Icon(Icons.chevron_right),
                    label: const Text('Siguiente'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
