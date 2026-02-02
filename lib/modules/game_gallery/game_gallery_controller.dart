import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stopandgo/core/models/games/game_media_models.dart';
import 'package:stopandgo/core/network/game_gallery_repository.dart';
import 'package:stopandgo/core/widgets/snack_bar.dart';

class GameGalleryController extends GetxController {
  final GameGalleryRepository _repo = Get.find<GameGalleryRepository>();
  final ImagePicker _picker = ImagePicker();

  // Params
  late final int gameId;

  // State
  final isLoading = false.obs;
  final isUploading = false.obs;

  final error = RxnString();
  final items = <GameMediaItem>[].obs;

  // Upload progress (para UI)
  final uploadingIndex = (-1).obs; // índice del archivo actual (multi)
  final uploadProgress = 0.0.obs; // 0..1

  @override
  void onInit() {
    super.onInit();

    final arg = Get.arguments;
    gameId = (arg is int) ? arg : int.tryParse(arg?.toString() ?? '') ?? 0;

    load();
  }

  Future<void> load() async {
    try {
      isLoading.value = true;
      error.value = null;

      if (gameId <= 0) {
        error.value = 'gameId inválido';
        return;
      }

      final data = await _repo.fetchGallery(gameId);
      items.assignAll(data);
    } catch (e) {
      error.value = e.toString();
      UiSnackbar.error('Error', 'No se pudo cargar la galería');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshGallery() async {
    try {
      final data = await _repo.fetchGallery(gameId);
      items.assignAll(data);
    } catch (_) {
      // silencioso: es refresh
    }
  }

  // =========================
  // Upload Images (camera OR multi gallery)
  // =========================
  Future<void> pickAndUploadImages() async {
    try {
      error.value = null;

      final src = await _pickSourceSheet(title: 'Agregar fotos');
      if (src == null) return;

      List<XFile> files = [];

      if (src == ImageSource.camera) {
        final one = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );
        if (one == null) return;
        files = [one];
      } else {
        // galería: multi
        final picked = await _picker.pickMultiImage(imageQuality: 85);
        if (picked.isEmpty) return;
        files = picked;
      }

      isUploading.value = true;
      uploadingIndex.value = -1;
      uploadProgress.value = 0;

      final confirmed = await _repo.uploadMultipleImages(
        gameId: gameId,
        files: files,
        onProgress: (index, sent, total) {
          uploadingIndex.value = index;
          uploadProgress.value = total <= 0 ? 0 : sent / total;
        },
      );

      await refreshGallery();

      if (confirmed.isNotEmpty) {
        UiSnackbar.success('Listo', 'Se subieron ${confirmed.length} foto(s)');
      } else {
        UiSnackbar.error('Aviso', 'No se pudo subir ninguna foto');
      }
    } catch (e) {
      error.value = e.toString();
      UiSnackbar.error('Error', 'No se pudo subir fotos');
    } finally {
      isUploading.value = false;
      uploadingIndex.value = -1;
      uploadProgress.value = 0;
    }
  }

  // =========================
  // Upload Video (single)
  // =========================
  Future<void> pickAndUploadVideo() async {
    try {
      error.value = null;

      final src = await _pickSourceSheet(title: 'Agregar video');
      if (src == null) return;

      final file = await _picker.pickVideo(source: src);
      if (file == null) return;

      isUploading.value = true;
      uploadingIndex.value = 0;
      uploadProgress.value = 0;

      final item = await _repo.uploadSingleVideo(
        gameId: gameId,
        file: file,
        onProgress: (sent, total) {
          uploadProgress.value = total <= 0 ? 0 : sent / total;
        },
      );

      await refreshGallery();

      if (item != null) {
        UiSnackbar.success('Listo', 'Video subido');
      } else {
        UiSnackbar.error('Aviso', 'No se pudo subir el video');
      }
    } catch (e) {
      error.value = e.toString();
      UiSnackbar.error('Error', 'No se pudo subir el video');
    } finally {
      isUploading.value = false;
      uploadingIndex.value = -1;
      uploadProgress.value = 0;
    }
  }

  // =========================
  // Source Picker Sheet
  // =========================
  Future<ImageSource?> _pickSourceSheet({
    required String title,
    bool allowCamera = true,
    bool allowGallery = true,
  }) async {
    return await Get.bottomSheet<ImageSource?>(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Get.theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              if (allowCamera)
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Cámara'),
                  onTap: () => Get.back(result: ImageSource.camera),
                ),
              if (allowGallery)
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Galería'),
                  onTap: () => Get.back(result: ImageSource.gallery),
                ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Get.back(result: null),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: false,
    );
  }
}
