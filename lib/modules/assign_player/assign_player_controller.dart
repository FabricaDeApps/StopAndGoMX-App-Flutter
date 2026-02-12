import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/players.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/storage/app_storage.dart';

class AssignPlayerController extends GetxController {
  final ApiRepository _api = Get.find<ApiRepository>();

  /// Categoría seleccionada en el AppBar (guardada en AppStorage)
  late final int categoryId;
  late final String categoryName;

  // Estado de carga
  final isLoading = true.obs;
  final isSubmitting = false.obs;
  final error = RxnString();

  // Listas
  final categoryPlayers = <Player>[].obs;
  final players = <Player>[].obs;
  final filteredPlayers = <Player>[].obs;
  final selectedPlayer = Rxn<Player>();

  // Campos de formulario
  final searchController = TextEditingController();
  final jerseyController = TextEditingController();
  final isCaptain = false.obs;

  @override
  void onInit() {
    super.onInit();

    final selectedCategoryId = AppStorage.getSelectedCategoryId();
    if (selectedCategoryId == null) {
      error.value = 'No hay categoría seleccionada.';
      isLoading.value = false;
      return;
    }

    categoryId = selectedCategoryId;
    categoryName = AppStorage.getSelectedCategoryName() ?? '';

    loadInitialData();

    searchController.addListener(() {
      _filterPlayers(searchController.text);
    });
  }

  Future<void> loadInitialData() async {
    isLoading.value = true;
    error.value = null;

    try {
      final enrolledInCategory = await _api.getGamePlayers(
        categoryId: categoryId,
      );
      final playersForEnroll = await _api.managerPlayersForEnroll(
        categoryId: categoryId,
      );

      categoryPlayers.assignAll(enrolledInCategory);

      final enrolledIds = enrolledInCategory.map((p) => p.id).toSet();
      final availablePlayers = playersForEnroll
          .where((p) => !enrolledIds.contains(p.id))
          .toList();

      final loadedPlayers = availablePlayers
          .map((e) => Player.fromJson(e.toJson()))
          .toList();

      players.assignAll(loadedPlayers);
      filteredPlayers.assignAll(loadedPlayers);

      debugPrint(
        '[AssignPlayerController] categoryId=$categoryId '
        'enrolled=${categoryPlayers.length} '
        'available=${players.length}',
      );
    } catch (e) {
      error.value = 'Ocurrió un error al cargar datos: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void _filterPlayers(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      filteredPlayers.assignAll(players);
      return;
    }

    filteredPlayers.assignAll(
      players.where((p) => p.name.toLowerCase().contains(q)),
    );
  }

  void onSelectPlayer(Player player) {
    selectedPlayer.value = player;
    searchController.text = player.name;

    // Reduce autocomplete a solo este jugador
    _filterPlayers(player.name);
  }

  Future<void> submitAssign() async {
    final player = selectedPlayer.value;
    final jersey = jerseyController.text.trim();

    if (player == null) {
      Get.snackbar(
        'Selecciona jugador',
        'Debes seleccionar un jugador para asignar.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (jersey.isEmpty) {
      Get.snackbar(
        'Número de jersey',
        'Ingresa un número de jersey.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isSubmitting.value = true;

    try {
      final resp = await _api.enrollPlayer(
        categoryId: categoryId,
        body: {
          'player_id': player.id,
          'jersey_number': jersey,
          'is_captain': isCaptain.value,
        },
      );

      if (resp.success) {
        // ÉXITO — Mostramos un diálogo
        await Get.dialog(
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              '¡Jugador asignado!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text('${player.name} fue asignado correctamente.'),
            actions: [
              TextButton(onPressed: () => Get.back(), child: const Text('OK')),
            ],
          ),
          barrierDismissible: false,
        );

        /// Recargar jugadores disponibles (el asignado ya no aparecerá)
        await loadInitialData();

        /// Limpiar formulario para asignar otro jugador
        selectedPlayer.value = null;
        searchController.clear();
        jerseyController.clear();
        isCaptain.value = false;
      } else {
        Get.snackbar(
          'Error',
          resp.message ?? 'No se pudo asignar el jugador.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade800,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo asignar el jugador: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    jerseyController.dispose();
    super.onClose();
  }
}
