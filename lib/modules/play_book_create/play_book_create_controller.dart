import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stopandgo/core/models/play_book_model.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/playbook/playbook_catalog.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/routes/app_routes.dart';

enum PlayMode { playbookGo, attachment }

class PlayBookCreateController extends GetxController {
  final _api = Get.find<ApiRepository>();
  final _picker = ImagePicker();

  // Wizard
  final stepIndex = 0.obs;

  // Selections
  final sport = Rxn<PlaySport>();
  final side = Rxn<PlaySide>();
  final type = Rxn<PlayType>();
  final playersCount = 7.obs;
  final mode = Rxn<PlayMode>();
  final availableShareCategories = <PlaybookCategoryRef>[].obs;
  final selectedSharedCategoryIds = <int>[].obs;

  // Attachment fields
  final alias = ''.obs;
  final attachmentPath = RxnString();
  final attachmentLabel = RxnString();

  // UI state
  final isLoadingShareCategories = false.obs;
  final isPicking = false.obs;
  final isSaving = false.obs;

  int? get selectedCategoryId => AppStorage.getSelectedCategoryId();

  // ----- Labels
  String sportLabel(PlaySport s) => playSportLabel(s);

  String sideLabel(PlaySide s) => playSideLabel(s);

  String typeLabel(PlayType t) => playTypeLabel(t);

  String modeLabel(PlayMode m) =>
      m == PlayMode.playbookGo ? 'Playbook GO' : 'Adjuntar archivo';

  // ----- Options by side
  List<PlayType> get typeOptions {
    return playTypeOptions(sport: sport.value, side: side.value);
  }

  List<PlaybookCategoryRef> get shareableCategories {
    final baseCategoryId = selectedCategoryId;
    return availableShareCategories
        .where((e) => baseCategoryId == null || e.id != baseCategoryId)
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadShareCategories();
  }

  // ----- Step validations
  bool get isStep0Valid => sport.value != null;
  bool get isStep1Valid => side.value != null;
  bool get isStep2Valid => type.value != null;
  bool get isStep3Valid => playersCount.value >= 5 && playersCount.value <= 11;

  bool get isStep4Valid {
    if (mode.value == null) return false;

    if (mode.value == PlayMode.attachment) {
      final hasAlias = alias.value.trim().isNotEmpty;
      final hasFile = (attachmentPath.value ?? '').isNotEmpty;
      return hasAlias && hasFile;
    }

    return true; // Playbook GO
  }

  bool get canContinue {
    switch (stepIndex.value) {
      case 0:
        return isStep0Valid;
      case 1:
        return isStep1Valid;
      case 2:
        return isStep2Valid;
      case 3:
        return isStep3Valid;
      case 4:
        return isStep4Valid;
      default:
        return false;
    }
  }

  // ----- Mutations
  void setSport(PlaySport s) {
    final previous = sport.value;
    sport.value = s;

    if (previous != s) {
      type.value = null;

      if (playersCount.value == suggestedPlayersCountForSport(previous)) {
        playersCount.value = suggestedPlayersCountForSport(s);
      }
    }

    if (stepIndex.value > 0) stepIndex.value = 1;
  }

  void setSide(PlaySide s) {
    side.value = s;
    type.value = null;
    if (stepIndex.value > 1) stepIndex.value = 2;
  }

  void setType(PlayType t) => type.value = t;
  void setPlayers(int v) => playersCount.value = v;

  void setMode(PlayMode m) {
    mode.value = m;
    if (m == PlayMode.playbookGo) {
      alias.value = '';
      clearAttachment();
    }
  }

  void setAlias(String v) => alias.value = v;

  void toggleSharedCategory(int categoryId) {
    if (selectedSharedCategoryIds.contains(categoryId)) {
      selectedSharedCategoryIds.remove(categoryId);
    } else {
      selectedSharedCategoryIds.add(categoryId);
    }
    selectedSharedCategoryIds.refresh();
  }

  void clearAttachment() {
    attachmentPath.value = null;
    attachmentLabel.value = null;
  }

  Future<void> loadShareCategories() async {
    try {
      isLoadingShareCategories.value = true;
      final categories = await _api.getPlaybookCategories();
      availableShareCategories.assignAll(categories);
    } catch (_) {
      availableShareCategories.clear();
    } finally {
      isLoadingShareCategories.value = false;
    }
  }

  Future<void> pickAttachment() async {
    final choice = await _pickAttachmentSource();
    if (choice == null) return;

    switch (choice) {
      case _AttachmentSource.galleryImage:
        await _pickImageFromGallery();
        return;
      case _AttachmentSource.galleryVideo:
        await _pickVideoFromGallery();
        return;
      case _AttachmentSource.cameraPhoto:
        await _pickPhotoFromCamera();
        return;
      case _AttachmentSource.cameraVideo:
        await _pickVideoFromCamera();
        return;
      case _AttachmentSource.file:
        await _pickAttachmentFile();
        return;
    }
  }

  Future<_AttachmentSource?> _pickAttachmentSource() async {
    return Get.bottomSheet<_AttachmentSource?>(
      SafeArea(
        child: Material(
          color: Colors.white,
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Elegir foto de galería'),
                onTap: () => Get.back(result: _AttachmentSource.galleryImage),
              ),
              ListTile(
                leading: const Icon(Icons.video_library_outlined),
                title: const Text('Elegir video de galería'),
                onTap: () => Get.back(result: _AttachmentSource.galleryVideo),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar foto'),
                onTap: () => Get.back(result: _AttachmentSource.cameraPhoto),
              ),
              ListTile(
                leading: const Icon(Icons.videocam_outlined),
                title: const Text('Grabar video'),
                onTap: () => Get.back(result: _AttachmentSource.cameraVideo),
              ),
              ListTile(
                leading: const Icon(Icons.attach_file),
                title: const Text('Elegir archivo'),
                onTap: () => Get.back(result: _AttachmentSource.file),
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancelar'),
                onTap: () => Get.back(result: null),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      isPicking.value = true;
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (picked == null) return;
      _setAttachmentFromPath(picked.path, picked.name);
    } catch (e) {
      Get.snackbar(
        'Adjuntar archivo',
        'No se pudo seleccionar la imagen: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isPicking.value = false;
    }
  }

  Future<void> _pickVideoFromGallery() async {
    try {
      isPicking.value = true;
      final picked = await _picker.pickVideo(source: ImageSource.gallery);
      if (picked == null) return;
      _setAttachmentFromPath(picked.path, picked.name);
    } catch (e) {
      Get.snackbar(
        'Adjuntar archivo',
        'No se pudo seleccionar el video: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isPicking.value = false;
    }
  }

  Future<void> _pickPhotoFromCamera() async {
    try {
      isPicking.value = true;
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      if (picked == null) return;
      _setAttachmentFromPath(picked.path, picked.name);
    } catch (e) {
      Get.snackbar(
        'Adjuntar archivo',
        'No se pudo tomar la foto: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isPicking.value = false;
    }
  }

  Future<void> _pickVideoFromCamera() async {
    try {
      isPicking.value = true;
      final picked = await _picker.pickVideo(source: ImageSource.camera);
      if (picked == null) return;
      _setAttachmentFromPath(picked.path, picked.name);
    } catch (e) {
      Get.snackbar(
        'Adjuntar archivo',
        'No se pudo grabar el video: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isPicking.value = false;
    }
  }

  /// Selector real de archivo (PDF / Imagen / Video)
  Future<void> _pickAttachmentFile() async {
    try {
      isPicking.value = true;

      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: false,
        type: FileType.custom,
        allowedExtensions: const [
          'pdf',
          'png',
          'jpg',
          'jpeg',
          'mp4',
          'mov',
          'webm',
          'webp',
        ],
      );

      if (result == null || result.files.isEmpty) return;

      final picked = result.files.first;
      final path = picked.path;

      if (path == null || path.isEmpty) {
        Get.snackbar(
          'Adjuntar archivo',
          'No se pudo obtener la ruta del archivo (path vacío).',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final f = File(path);
      if (!f.existsSync()) {
        Get.snackbar(
          'Adjuntar archivo',
          'El archivo seleccionado no existe o no se pudo acceder.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      _setAttachmentFromPath(path, picked.name);
    } catch (e) {
      Get.snackbar(
        'Adjuntar archivo',
        'No se pudo seleccionar: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isPicking.value = false;
    }
  }

  void _setAttachmentFromPath(String path, String? label) {
    final file = File(path);
    if (!file.existsSync()) {
      Get.snackbar(
        'Adjuntar archivo',
        'El archivo seleccionado no existe o no se pudo acceder.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    attachmentPath.value = path;
    attachmentLabel.value =
        (label?.trim().isNotEmpty == true) ? label!.trim() : file.uri.pathSegments.last;
  }

  // ----- Navigation
  void next() {
    if (!canContinue) {
      Get.snackbar(
        'Falta algo',
        'Completa este paso para continuar',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (stepIndex.value < 4) {
      stepIndex.value++;
      return;
    }

    submit();
  }

  void back() {
    if (stepIndex.value == 0) {
      Get.back();
      return;
    }
    stepIndex.value--;
  }

  Future<void> submit() async {
    if (isSaving.value) return;

    final selectedSport = sport.value?.name;
    final selectedSide = side.value?.name; // 'offense' | 'defense'
    final selectedType = type.value?.name; // 'run' | 'pass' | ...
    final selectedMode = mode.value;

    if (selectedSport == null ||
        selectedSide == null ||
        selectedType == null ||
        selectedMode == null) {
      Get.snackbar(
        'Crear jugada',
        'Completa los campos requeridos',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final categoryId = AppStorage.getSelectedCategoryId();
    if (categoryId == null) {
      Get.snackbar(
        'Crear jugada',
        'No hay categoría seleccionada',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // ✅ GO: abre editor, y si editor guardó, propagamos refresh a la lista
    if (selectedMode == PlayMode.playbookGo) {
      final result = await Get.toNamed(
        Routes.playbook,
        arguments: {
          'sport': selectedSport,
          'side': selectedSide,
          'type': selectedType,
          'players_count': playersCount.value,
          'category_id': categoryId,
          'shared_category_ids': selectedSharedCategoryIds.toList(),
        },
      );

      if (result is Map && result['refresh'] == true) {
        Get.back(result: {'refresh': true});
      }

      return;
    }

    // ✅ ATTACHMENT
    final filePath = attachmentPath.value;
    final playAlias = alias.value.trim();

    if (filePath == null || filePath.isEmpty) {
      Get.snackbar(
        'Adjuntar archivo',
        'Selecciona un archivo',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (playAlias.isEmpty) {
      Get.snackbar(
        'Adjuntar archivo',
        'Escribe un alias para la jugada',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isSaving.value = true;

      final res = await _api.playbookCreatePlayAttachment(
        categoryId: categoryId,
        alias: playAlias,
        type: selectedType,
        side: selectedSide,
        playersCount: playersCount.value,
        filePath: filePath,
        sharedCategoryIds: selectedSharedCategoryIds.toList(),
      );

      Get.snackbar(
        'Crear jugada',
        'Jugada guardada',
        snackPosition: SnackPosition.BOTTOM,
      );

      // ✅ importante: regresamos un result consistente para la lista
      Get.back(result: {'refresh': true, 'play': res});
    } catch (e) {
      Get.snackbar(
        'Crear jugada',
        'No se pudo guardar: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }
  }
}

enum _AttachmentSource {
  galleryImage,
  galleryVideo,
  cameraPhoto,
  cameraVideo,
  file,
}
