import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'roster_controller.dart';

class RosterView extends GetView<RosterController> {
  const RosterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(controller.categoryName)),
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

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage:
                                      (player.photoUrl != null &&
                                          player.photoUrl!.isNotEmpty)
                                      ? NetworkImage(player.photoUrl!)
                                      : null,
                                  child:
                                      (player.photoUrl == null ||
                                          player.photoUrl!.isEmpty)
                                      ? Text(
                                          (player.name)
                                              .trim()
                                              .split(' ')
                                              .map(
                                                (p) => p.isNotEmpty ? p[0] : '',
                                              )
                                              .take(2)
                                              .join(),
                                        )
                                      : null,
                                ),
                                title: Text(player.name),
                                subtitle: Text(
                                  "#${player.number.toString()} - ${player.position} ",
                                ),
                                trailing: controller.userRole.value == "manager"
                                    ? IconButton(
                                        icon: const Icon(Icons.camera_alt),
                                        onPressed: () => controller
                                            .updatePlayerPhoto(player),
                                      )
                                    : SizedBox(),
                              ),
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
