import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/routes/app_routes.dart';

enum PlaySide { offense, defense }

enum PlayType { run, pass, rpo, playAction, screen, trick, blitz, coverage }

enum PlayMode { playbookGo, attachment }

class PlayBookCreateController extends GetxController {
  final _api = Get.find<ApiRepository>();

  // Wizard
  final stepIndex = 0.obs;

  // Selections
  final side = Rxn<PlaySide>();
  final type = Rxn<PlayType>();
  final playersCount = 7.obs;
  final mode = Rxn<PlayMode>();

  // Attachment fields
  final alias = ''.obs;
  final attachmentPath = RxnString();
  final attachmentLabel = RxnString();

  // UI state
  final isPicking = false.obs;
  final isSaving = false.obs;

  // ----- Labels
  String sideLabel(PlaySide s) =>
      s == PlaySide.offense ? 'Ofensiva' : 'Defensiva';

  String typeLabel(PlayType t) {
    switch (t) {
      case PlayType.run:
        return 'Carrera';
      case PlayType.pass:
        return 'Pase';
      case PlayType.rpo:
        return 'RPO';
      case PlayType.playAction:
        return 'Play Action';
      case PlayType.screen:
        return 'Screen';
      case PlayType.trick:
        return 'Trick / Engaño';
      case PlayType.blitz:
        return 'Blitz';
      case PlayType.coverage:
        return 'Cobertura';
    }
  }

  String modeLabel(PlayMode m) =>
      m == PlayMode.playbookGo ? 'Playbook GO' : 'Adjuntar archivo';

  // ----- Options by side
  List<PlayType> get typeOptions {
    final s = side.value;
    if (s == PlaySide.offense) {
      return [
        PlayType.run,
        PlayType.pass,
        PlayType.rpo,
        PlayType.playAction,
        PlayType.screen,
        PlayType.trick,
      ];
    }
    if (s == PlaySide.defense) {
      return [PlayType.blitz, PlayType.coverage];
    }
    return PlayType.values;
  }

  // ----- Step validations
  bool get isStep0Valid => side.value != null;
  bool get isStep1Valid => type.value != null;
  bool get isStep2Valid => playersCount.value >= 5 && playersCount.value <= 11;

  bool get isStep3Valid {
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
      default:
        return false;
    }
  }

  // ----- Mutations
  void setSide(PlaySide s) {
    side.value = s;
    type.value = null;
    if (stepIndex.value > 0) stepIndex.value = 1;
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

  void clearAttachment() {
    attachmentPath.value = null;
    attachmentLabel.value = null;
  }

  /// ✅ Selector real de archivo (PDF / Imagen / Video / Documento)
  Future<void> pickAttachment() async {
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
          'heic',
          'mp4',
          'mov',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'ppt',
          'pptx',
          'txt',
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

      attachmentPath.value = path;
      attachmentLabel.value = picked.name;
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

    if (stepIndex.value < 3) {
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

    final selectedSide = side.value?.name; // 'offense' | 'defense'
    final selectedType = type.value?.name; // 'run' | 'pass' | ...
    final selectedMode = mode.value;

    if (selectedSide == null || selectedType == null || selectedMode == null) {
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
          'side': selectedSide,
          'type': selectedType,
          'players_count': playersCount.value,
          'category_id': categoryId,
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
