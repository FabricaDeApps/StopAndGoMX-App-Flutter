import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'play_book_list_controller.dart';

class PlayBookListView extends GetView<PlayBookListController> {
  const PlayBookListView({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryName = AppStorage.getSelectedCategoryName() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text('PlayBook - $categoryName')],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.goToCreate,
        icon: const Icon(Icons.add),
        label: const Text('Nueva jugada'),
      ),

      body: Column(
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Obx(() {
              final sel = controller.selectedType.value;

              Widget chip(String label, String? value) {
                final selected = sel == value;
                return ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) => controller.setType(value),
                );
              }

              return Wrap(
                spacing: 10,
                runSpacing: 6,
                children: [
                  chip('Todos', null),
                  chip('Pase', 'Pase'),
                  chip('Carrera', 'Carrera'),
                  chip('Defensa', 'Defensa'),
                ],
              );
            }),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.items.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.error.value != null && controller.items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      controller.error.value!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.refreshList,
                child: ListView.separated(
                  controller: controller.scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                  itemBuilder: (_, i) {
                    if (i == controller.items.length) {
                      // footer loader
                      return Obx(() {
                        if (!controller.isLoadingMore.value) {
                          return const SizedBox(height: 24);
                        }
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      });
                    }
                    final play = controller.items[i];

                    final isGo = play.isGo;
                    final modeLabel = isGo ? 'GO' : 'ARCHIVO';
                    final modeIcon = isGo ? Icons.gesture : Icons.attach_file;

                    final sideLabel = (play.side == 'defense')
                        ? 'Defensa'
                        : 'Ofensiva';

                    return Dismissible(
                      key: ValueKey('play_${play.id}'),
                      direction: controller.userRole.value == "coach"
                          ? DismissDirection.endToStart
                          : DismissDirection.none,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        color: Colors.red,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.delete, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Eliminar',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      confirmDismiss: (_) async {
                        final ok = await Get.dialog<bool>(
                          AlertDialog(
                            title: const Text('Eliminar jugada'),
                            content: Text(
                              '¿Seguro que quieres eliminar "${play.alias}"?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(result: false),
                                child: const Text('Cancelar'),
                              ),
                              ElevatedButton(
                                onPressed: () => Get.back(result: true),
                                child: const Text('Eliminar'),
                              ),
                            ],
                          ),
                        );

                        if (ok != true) return false;

                        final deleted = await controller.deletePlayOnBackend(
                          play.id,
                        );
                        if (!deleted) {
                          Get.snackbar(
                            'Jugada',
                            'No se pudo eliminar',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                          return false;
                        }
                        return true;
                      },
                      onDismissed: (_) {
                        controller.items.removeWhere((e) => e.id == play.id);
                        controller.items.refresh();
                        Get.snackbar(
                          'Jugada',
                          'Eliminada',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                      child: ListTile(
                        onTap: () => controller.goToDetail(play),
                        title: Text(
                          play.alias.isEmpty ? '(Sin alias)' : play.alias,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${play.type.isEmpty ? '-' : play.type} • $sideLabel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              avatar: Icon(modeIcon, size: 16),
                              label: Text(
                                modeLabel,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemCount: controller.items.length + 1,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
