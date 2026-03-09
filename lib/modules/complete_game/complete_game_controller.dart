// complete_game_controller.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:flutter/services.dart';

class CompleteGameController extends GetxController {
  final _api = Get.find<ApiRepository>();

  late final int categoryId;
  late final int gameId; // id del juego
  late final DateTime gameDate; // fecha del juego (para validar pasado)

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

    DateTime? parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    categoryId =
        parseInt(args?['categoryId']) ??
        (throw ArgumentError('categoryId es requerido'));
    gameId =
        parseInt(args?['gameId']) ??
        (throw ArgumentError('gameId es requerido'));
    gameDate =
        parseDate(args?['gameDate']) ??
        (throw ArgumentError('gameDate es requerido'));
  }

  @override
  void onClose() {
    homeScoreCtrl.dispose();
    oppScoreCtrl.dispose();
    super.onClose();
  }

  bool get isPastGame => DateTime.now().isAfter(gameDate);

  Future<void> pickEvidence(ImageSource source) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: source, imageQuality: 85);
    if (x != null) {
      evidenceFile.value = File(x.path);
    }
  }

  Future<void> submit() async {
    if (!isPastGame) {
      Get.snackbar(
        'No permitido',
        'Solo puedes completar juegos que ya pasaron',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (!(formKey.currentState?.validate() ?? false)) return;

    if (evidenceFile.value == null) {
      Get.snackbar(
        'Falta evidencia',
        'Adjunta una foto/imagen como evidencia',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

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
      final result = await _api.completeGame(
        categoryId: categoryId,
        gameId: gameId,
        homeScore: home,
        opponentScore: opp,
        evidenceFile: evidenceFile.value!,
      );

      if (!result.success) {
        Get.snackbar(
          'Error',
          result.message,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      Get.back(result: true);
      Get.snackbar(
        'Éxito',
        result.message.isEmpty ? 'Juego completado' : result.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSubmitting.value = false;
    }
  }
}
