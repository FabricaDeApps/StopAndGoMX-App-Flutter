import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'play_book_list_controller.dart';

class PlayBookListView extends GetView<PlayBookListController> {
  const PlayBookListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PlayBook')),

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
                  chip('Corrida', 'Corrida'),
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

                    return ListTile(
                      onTap: () => controller.goToDetail(play),
                      title: Text(
                        play.alias.isEmpty ? '(Sin alias)' : play.alias,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        play.type.isEmpty ? '-' : play.type,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
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
