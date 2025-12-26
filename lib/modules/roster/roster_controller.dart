import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stopandgo/core/models/players.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/storage/app_storage.dart';

class RosterController extends GetxController {
  final _api = Get.find<ApiRepository>();

  final isLoading = false.obs;
  final error = RxnString();

  /// Lista original desde API
  final players = <Player>[].obs;

  /// Texto del buscador
  final searchText = ''.obs;

  /// Lista filtrada para UI
  final filteredPlayers = <Player>[].obs;

  late final int categoryId;
  late final String categoryName;

  @override
  void onInit() {
    super.onInit();
    categoryId = AppStorage.getSelectedCategoryId() ?? 0;
    categoryName = AppStorage.getSelectedCategoryName() ?? "";

    // Recalcular filtro cuando cambie lista o texto
    ever<List<Player>>(players, (_) => _applyFilter());
    ever<String>(searchText, (_) => _applyFilter());

    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    isLoading.value = true;
    error.value = null;

    try {
      final result = await _api.getGamePlayers(categoryId: categoryId);

      // ✅ Orden por jersey (asc). Si no hay número, al final. Tie-breaker por nombre.
      result.sort((a, b) {
        final an = (a.number is int)
            ? (a.number as int)
            : int.tryParse('${a.number}') ?? 0;
        final bn = (b.number is int)
            ? (b.number as int)
            : int.tryParse('${b.number}') ?? 0;

        final aHas = an > 0;
        final bHas = bn > 0;

        if (aHas && bHas) {
          final c = an.compareTo(bn);
          if (c != 0) return c;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        }

        if (aHas && !bHas) return -1;
        if (!aHas && bHas) return 1;

        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      players.assignAll(result);
      // filteredPlayers se actualiza por el ever()
    } catch (e) {
      error.value = 'No se pudieron cargar los jugadores.';
      Get.snackbar(
        'Roster',
        'No se pudieron cargar jugadores: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshPlayers() => _loadPlayers();

  void setSearch(String value) => searchText.value = value;

  void clearSearch() => searchText.value = '';

  void _applyFilter() {
    final q = searchText.value.trim().toLowerCase();

    if (q.isEmpty) {
      filteredPlayers.assignAll(players);
      return;
    }

    filteredPlayers.assignAll(
      players.where((p) {
        final name = p.name.toLowerCase();
        final numStr = '${p.number}'.toLowerCase();
        return name.contains(q) || numStr.contains(q);
      }).toList(),
    );
  }

  Future<void> updatePlayerPhoto(Player player) async {
    try {
      final allowed = await _ensureCameraPermission();
      if (!allowed) {
        Get.snackbar(
          'Permiso requerido',
          'No se puede usar la cámara sin permiso.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (image == null) return;

      isLoading.value = true;

      await _api.updatePlayerPhoto(
        categoryId: categoryId,
        playerId: player.id,
        filePath: image.path,
      );

      await _loadPlayers();

      Get.snackbar(
        'Foto actualizada',
        'La foto de ${player.name} se actualizó correctamente.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo actualizar la foto: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> _ensureCameraPermission() async {
    var status = await Permission.camera.status;

    if (status.isGranted) return true;

    status = await Permission.camera.request();

    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      await Get.dialog(
        AlertDialog(
          title: const Text('Permiso de cámara bloqueado'),
          content: const Text(
            'El acceso a la cámara está bloqueado. '
            'Ve a Configuración > Privacidad > Cámara y habilita el acceso para esta app.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cerrar'),
            ),
            TextButton(
              onPressed: () {
                openAppSettings();
                Get.back();
              },
              child: const Text('Abrir Configuración'),
            ),
          ],
        ),
      );
    }

    return false;
  }
}
