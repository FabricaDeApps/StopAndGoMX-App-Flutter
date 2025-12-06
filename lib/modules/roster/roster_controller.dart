import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stopandgo/core/models/players.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/storage/app_storage.dart';

class RosterController extends GetxController {
  final _api = Get.find<ApiRepository>();

  final isLoading = false.obs;
  final error = RxnString();
  final players = <Player>[].obs;

  late final int categoryId;
  late final String categoryName;

  @override
  void onInit() {
    super.onInit();
    categoryId = AppStorage.getSelectedCategoryId() ?? 0;
    categoryName = AppStorage.getSelectedCategoryName() ?? "";
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    isLoading.value = true;
    error.value = null;

    try {
      final result = await _api.getGamePlayers(categoryId: categoryId);
      players.assignAll(result);
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
    print('Camera status BEFORE request: $status');

    if (status.isGranted) return true;

    // Pedir permiso
    status = await Permission.camera.request();
    print('Camera status AFTER request: $status');

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      // En este punto iOS ya debió haber mostrado el popup alguna vez
      // y el usuario lo bloqueó desde settings
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
