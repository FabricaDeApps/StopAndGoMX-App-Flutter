import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stopandgo/core/models/players.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/core/utils/role_utils.dart';
import 'package:stopandgo/routes/app_routes.dart';

class RosterController extends GetxController {
  final _api = Get.find<ApiRepository>();

  final isLoading =
      false.obs; // carga/refresh roster + subir foto + guardar numero
  final isSaving = false.obs; // guardar numero (opcional separado)
  final error = RxnString();

  /// Lista original desde API
  final players = <Player>[].obs;

  /// Texto del buscador
  final searchText = ''.obs;

  /// Lista filtrada para UI
  final filteredPlayers = <Player>[].obs;

  late final int categoryId;
  late final String categoryName;

  final userRole = 'player'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSession();

    categoryId = AppStorage.getSelectedCategoryId() ?? 0;
    categoryName = AppStorage.getSelectedCategoryName() ?? "";

    // Recalcular filtro cuando cambie lista o texto
    ever<List<Player>>(players, (_) => _applyFilter());
    ever<String>(searchText, (_) => _applyFilter());

    _loadPlayers();
  }

  void _loadSession() {
    final user = AppStorage.getUser();
    final role = user == null
        ? 'player'
        : (user.activeRole.isNotEmpty ? user.activeRole : user.role);
    userRole.value = normalizeRole(role);
  }

  Future<void> _loadPlayers() async {
    isLoading.value = true;
    error.value = null;

    try {
      final result = await _api.getGamePlayers(categoryId: categoryId);

      // ✅ Orden por jersey (asc). Si no hay número, al final. Tie-breaker por nombre.
      result.sort((a, b) {
        final an = _toInt(a.number);
        final bn = _toInt(b.number);

        final aHas = (an ?? 0) > 0;
        final bHas = (bn ?? 0) > 0;

        if (aHas && bHas) {
          final c = (an!).compareTo(bn!);
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

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  Future<void> refreshPlayers() => _loadPlayers();

  void openDocumentsCompliance() {
    Get.toNamed(
      Routes.documentsCompliance,
      arguments: {'categoryId': categoryId, 'categoryName': categoryName},
    );
  }

  void openPlayerFile(Player player) {
    Get.toNamed(
      Routes.managerPlayerFile.replaceFirst(':playerId', '${player.id}'),
      arguments: {'playerId': player.id, 'playerName': player.name},
    );
  }

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

  // ---------------------------
  // FOTO
  // ---------------------------
  Future<void> updatePlayerPhoto(Player player) async {
    try {
      final source = await _pickPhotoSource();
      if (source == null) return;

      final allowed = source == ImageSource.camera
          ? await _ensureCameraPermission()
          : await _ensureGalleryPermission();

      if (!allowed) {
        Get.snackbar(
          'Permiso requerido',
          source == ImageSource.camera
              ? 'No se puede usar la cámara sin permiso.'
              : 'No se puede acceder a la galería sin permiso.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
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

  Future<ImageSource?> _pickPhotoSource() async {
    return Get.bottomSheet<ImageSource>(
      SafeArea(
        child: Material(
          color: Colors.white,
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar foto'),
                onTap: () => Get.back(result: ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Elegir de galería'),
                onTap: () => Get.back(result: ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancelar'),
                onTap: () => Get.back(),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: false,
    );
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

  Future<bool> _ensureGalleryPermission() async {
    var photosStatus = await Permission.photos.status;
    if (photosStatus.isGranted || photosStatus.isLimited) return true;

    photosStatus = await Permission.photos.request();
    if (photosStatus.isGranted || photosStatus.isLimited) return true;

    if (Platform.isAndroid) {
      var storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted) return true;
      storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted) return true;
      if (storageStatus.isPermanentlyDenied) {
        await _showGalleryPermissionDialog();
      }
      return false;
    }

    if (photosStatus.isPermanentlyDenied) {
      await _showGalleryPermissionDialog();
    }

    return false;
  }

  Future<void> _showGalleryPermissionDialog() async {
    await Get.dialog(
      AlertDialog(
        title: const Text('Permiso de galería bloqueado'),
        content: const Text(
          'El acceso a la galería está bloqueado. '
          'Ve a Configuración y habilita acceso a Fotos para esta app.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cerrar')),
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

  // ---------------------------
  // JERSEY NUMBER
  // Requiere que Player traiga categoryPlayerId (pivot id).
  // ---------------------------
  Future<void> editJerseyNumber(Player player) async {
    final formKey = GlobalKey<FormState>();
    String value = (player.number == null) ? '' : player.number.toString();

    await Get.dialog(
      AlertDialog(
        title: Text('Número de ${player.name}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            initialValue: value,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Número de jersey',
              hintText: 'Ej. 12',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => value = v,
            validator: (v) {
              final s = (v ?? '').trim();
              if (s.isEmpty) return 'Ingresa un número';
              final n = int.tryParse(s);
              if (n == null) return 'Número inválido';
              if (n < 0 || n > 999) return 'Rango inválido';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;

              final newNumber = int.parse(value.trim());
              Get.back(); // cierra dialog
              await _saveJerseyNumber(player: player, number: newNumber);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  Future<void> _saveJerseyNumber({
    required Player player,
    required int number,
  }) async {
    try {
      isSaving.value = true;
      error.value = null;

      final pivotId =
          player.categoryPlayerId; // <-- debe existir en tu modelo Player
      if (pivotId == null) {
        _showErrorDialog(
          title: 'Falta dato',
          message: 'No se encontró el id de asignación (category_player_id).',
        );
        return;
      }

      final ok = await _api.updatePlayerJerseyNumber(
        categoryPlayerId: pivotId,
        jerseyNumber: number,
      );

      if (!ok) {
        _showErrorDialog(
          title: 'Error',
          message: 'No se pudo actualizar el número.',
        );
        return;
      }

      _showSuccessDialog('Número actualizado.');
      _loadPlayers();
    } catch (e) {
      _showErrorDialog(
        title: 'Error',
        message: 'No se pudo actualizar el número: $e',
      );
    } finally {
      isSaving.value = false;
    }
  }

  void _showErrorDialog({required String title, required String message}) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('OK')),
        ],
      ),
      barrierDismissible: true,
    );
  }

  void _showSuccessDialog(String message) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 72,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              const Text(
                'Listo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Get.back(),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }
}
