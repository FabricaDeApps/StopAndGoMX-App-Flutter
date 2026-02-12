import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'assign_player_controller.dart';

class AssignPlayerView extends GetView<AssignPlayerController> {
  const AssignPlayerView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = controller.categoryName.trim();
    final title = category.isEmpty
        ? 'Asignar jugador'
        : 'Asignar jugador a $category';

    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.value != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.error.value!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: controller.loadInitialData,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AUTOCOMPLETE DE JUGADOR
                  Text('Jugador', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller.searchController,
                    decoration: InputDecoration(
                      hintText: 'Busca por nombre del jugador',
                      prefixIcon: const Icon(Icons.search),
                      // 👇 Aquí cambiamos Obx por ValueListenableBuilder
                      suffixIcon: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: controller.searchController,
                        builder: (_, value, __) {
                          if (value.text.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              controller.searchController.clear();
                              controller.selectedPlayer.value = null;
                            },
                          );
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Lista de jugadores con altura flexible
                  Expanded(
                    child: Obx(() {
                      final players = controller.filteredPlayers;
                      if (players.isEmpty) {
                        return Center(
                          child: Text(
                            'No se encontraron jugadores con ese nombre.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: players.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, index) {
                          final p = players[index];
                          final isSelected =
                              controller.selectedPlayer.value?.id == p.id;

                          return ListTile(
                            onTap: () => controller.onSelectPlayer(p),
                            leading: CircleAvatar(
                              backgroundImage:
                                  (p.photoUrl != null && p.photoUrl!.isNotEmpty)
                                      ? NetworkImage(p.photoUrl!)
                                      : null,
                              child: (p.photoUrl == null || p.photoUrl!.isEmpty)
                                  ? Text(
                                      p.name.isNotEmpty
                                          ? p.name[0].toUpperCase()
                                          : '?',
                                    )
                                  : null,
                            ),
                            title: Text(p.name),
                            subtitle: p.position != null
                                ? Text(p.position!)
                                : null,
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : const SizedBox.shrink(),
                          );
                        },
                      );
                    }),
                  ),

                  const SizedBox(height: 16),

                  // NÚMERO DE JERSEY
                  Text('Número de jersey', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller.jerseyController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Ej. 12',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // CAPITÁN (oculto por negocio actual)
                  const SizedBox.shrink(),

                  // BOTÓN ASIGNAR (usa Rx => OK)
                  Obx(() {
                    final isSubmitting = controller.isSubmitting.value;
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: Text(
                          isSubmitting ? 'Asignando...' : 'Asignar jugador',
                        ),
                        onPressed: isSubmitting
                            ? null
                            : controller.submitAssign,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
