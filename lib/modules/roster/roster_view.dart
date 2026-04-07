import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/players.dart';
import 'package:stopandgo/core/utils/role_utils.dart';
import 'roster_controller.dart';

class RosterView extends GetView<RosterController> {
  const RosterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.categoryName),
        actions: [
          Obx(() {
            if (!hasManagerPrivileges(controller.userRole.value)) {
              return const SizedBox.shrink();
            }
            return IconButton(
              tooltip: 'Cumplimiento de documentos',
              icon: const Icon(Icons.fact_check_outlined),
              onPressed: controller.openDocumentsCompliance,
            );
          }),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          final list = controller.filteredPlayers;

          if (controller.isLoading.value && controller.players.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.error.value != null && controller.players.isEmpty) {
            return Center(
              child: Text(
                controller.error.value!,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          return Column(
            children: [
              TextField(
                onChanged: controller.setSearch,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o # jersey...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: controller.searchText.value.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: controller.clearSearch,
                        ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: (controller.players.isEmpty)
                    ? RefreshIndicator(
                        onRefresh: controller.refreshPlayers,
                        child: ListView(
                          children: const [
                            SizedBox(height: 40),
                            Center(
                              child: Text(
                                'No hay jugadores en esta categoría.',
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: controller.refreshPlayers,
                        child: ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final player = list[index];

                            return _RosterPlayerCard(
                              index: index,
                              player: player,
                              userRole: controller.userRole.value,
                              onOpen: () => controller.openPlayerFile(player),
                              onEditPosition: () =>
                                  controller.editPlayerPosition(player),
                              onEditNumber: () =>
                                  controller.editJerseyNumber(player),
                              onUpdatePhoto: () =>
                                  controller.updatePlayerPhoto(player),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _RosterPlayerCard extends StatelessWidget {
  const _RosterPlayerCard({
    required this.index,
    required this.player,
    required this.userRole,
    required this.onOpen,
    required this.onEditPosition,
    required this.onEditNumber,
    required this.onUpdatePhoto,
  });

  final int index;
  final Player player;
  final String userRole;
  final VoidCallback onOpen;
  final VoidCallback onEditPosition;
  final VoidCallback onEditNumber;
  final VoidCallback onUpdatePhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canEditPosition = canEditRosterPosition(userRole);
    final canManage = hasManagerPrivileges(userRole);
    final numberLabel = player.number != null ? '#${player.number}' : 'Sin #';
    final positionLabel = player.position.trim().isEmpty
        ? 'Posicion pendiente'
        : player.position.trim();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${index + 1}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    radius: 24,
                    backgroundImage:
                        (player.photoUrl != null && player.photoUrl!.isNotEmpty)
                        ? NetworkImage(player.photoUrl!)
                        : null,
                    child: (player.photoUrl == null || player.photoUrl!.isEmpty)
                        ? Text(player.initials)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoChip(label: numberLabel),
                            _InfoChip(
                              icon: Icons.sports_football_outlined,
                              label: positionLabel,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (canEditPosition || canManage) ...[
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (canEditPosition)
                      OutlinedButton.icon(
                        onPressed: onEditPosition,
                        icon: const Icon(Icons.sports_football_outlined),
                        label: const Text('Posición'),
                      ),
                    if (canManage)
                      OutlinedButton.icon(
                        onPressed: onEditNumber,
                        icon: const Icon(Icons.numbers),
                        label: const Text('Número'),
                      ),
                    if (canManage)
                      OutlinedButton.icon(
                        onPressed: onUpdatePhoto,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Foto'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({this.icon, required this.label});

  final IconData? icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
