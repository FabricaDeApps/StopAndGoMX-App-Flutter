import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/players.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/storage/app_storage.dart';

class AttendanceRow {
  final Player player;

  /// Valores de asistencia: present | absent | late | justified
  final RxString status = 'present'.obs;

  /// Minutos tarde si status = "late"
  final RxInt minutesLate = 0.obs;

  /// Notas
  final TextEditingController notesController = TextEditingController();

  AttendanceRow({required this.player});
}

class TrainingAttendanceController extends GetxController {
  final ApiRepository _api = Get.find<ApiRepository>();

  late final int categoryId;
  late final int trainingId;

  final isLoading = true.obs;
  final isSaving = false.obs;
  final error = RxnString();

  final rows = <AttendanceRow>[].obs;

  @override
  void onInit() {
    super.onInit();

    categoryId = AppStorage.getSelectedCategoryId() ?? 0;
    trainingId = Get.arguments['trainingId'];

    loadPlayers();
  }

  Future<void> loadPlayers() async {
    isLoading.value = true;
    error.value = null;

    try {
      final players = await _api.managerCategoryPlayers(categoryId);

      rows.assignAll(
        players.map((p) => AttendanceRow(player: Player.fromJson(p))),
      );
    } catch (e) {
      error.value = 'Error al cargar jugadores: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveAttendance() async {
    isSaving.value = true;

    try {
      final items = <Map<String, dynamic>>[];

      for (final row in rows) {
        items.add({
          'player_id': row.player.id,
          'game_id': null,
          'training_id': trainingId,
          'status': row.status.value,
          'minutes_late': row.status.value == 'late'
              ? row.minutesLate.value
              : null,
          'notes': row.notesController.text.trim().isNotEmpty
              ? row.notesController.text.trim()
              : null,
        });
      }

      final ok = await _api.managerAttendanceBulk(
        categoryId: categoryId,
        items: items,
      );

      if (ok) {
        Get.back(result: true);
        Get.snackbar('Éxito', 'Asistencia guardada correctamente');
      } else {
        Get.snackbar('Error', 'No se pudo guardar la asistencia');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error al guardar asistencia: $e');
    } finally {
      isSaving.value = false;
    }
  }
}
