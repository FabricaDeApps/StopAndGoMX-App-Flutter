// complete_game_controller.dart
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:stopandgo/core/network/api_request_exception.dart';
import 'package:stopandgo/core/services/manager_games_service.dart';
import 'package:stopandgo/core/utils/app_navigator.dart';

class CompleteGameController extends GetxController {
  static const int maxEvidenceBytes = 4 * 1024 * 1024;
  static const Set<String> allowedEvidenceExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.pdf',
  };

  final _managerGames = Get.find<ManagerGamesService>();

  late final int categoryId;
  late final int gameId; // id del juego

  final formKey = GlobalKey<FormState>();
  final homeScoreCtrl = TextEditingController();
  final oppScoreCtrl = TextEditingController();

  final isSubmitting = false.obs;
  final evidenceFile = Rxn<File>();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    categoryId =
        parseInt(args?['categoryId']) ??
        (throw ArgumentError('categoryId es requerido'));
    gameId =
        parseInt(args?['gameId']) ??
        (throw ArgumentError('gameId es requerido'));
  }

  @override
  void onClose() {
    homeScoreCtrl.dispose();
    oppScoreCtrl.dispose();
    super.onClose();
  }

  Future<void> pickEvidence(ImageSource source) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: source, imageQuality: 85);
    if (x != null) {
      await _setEvidence(File(x.path));
    }
  }

  Future<void> pickEvidenceFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
    );
    final selectedPath = result?.files.single.path;
    if (selectedPath != null) {
      await _setEvidence(File(selectedPath));
    }
  }

  Future<void> _setEvidence(File file) async {
    final error = await validateEvidence(file);
    if (error != null) {
      Get.snackbar(
        'Evidencia inválida',
        error,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    evidenceFile.value = file;
  }

  Future<String?> validateEvidence(File file) async {
    final extension = path.extension(file.path).toLowerCase();
    if (!allowedEvidenceExtensions.contains(extension)) {
      return 'Usa un archivo JPG, JPEG, PNG, WEBP o PDF.';
    }
    if (await file.length() > maxEvidenceBytes) {
      return 'La evidencia no puede superar 4 MB.';
    }
    return null;
  }

  void removeEvidence() => evidenceFile.value = null;

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    final home = int.tryParse(homeScoreCtrl.text.trim());
    final opp = int.tryParse(oppScoreCtrl.text.trim());
    if (home == null || opp == null) {
      Get.snackbar(
        'Marcador inválido',
        'Ingresa números válidos',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isSubmitting.value = true;
    try {
      final evidence = evidenceFile.value;
      if (evidence != null) {
        final error = await validateEvidence(evidence);
        if (error != null) {
          Get.snackbar(
            'Evidencia inválida',
            error,
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
      }

      final result = await _managerGames.completeGame(
        categoryId: categoryId,
        gameId: gameId,
        homeScore: home,
        opponentScore: opp,
        evidenceFile: evidence,
      );

      if (!result.success) {
        Get.snackbar(
          'Error',
          result.message,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      AppNavigator.pop(result: true);
      Get.snackbar(
        'Éxito',
        result.message.isEmpty ? 'Juego completado' : result.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      final message = e is ApiRequestException
          ? e.message
          : 'No se pudo completar el juego.';
      Get.snackbar('Error', message, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSubmitting.value = false;
    }
  }
}
