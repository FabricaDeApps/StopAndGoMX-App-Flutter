import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/players.dart';
import 'package:stopandgo/core/models/trainning_attendance.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/core/utils/role_utils.dart';

class AttendanceRow {
  final Player player;

  /// id de la asistencia (para modo EDIT, puede ser null en NEW)
  int? attendanceId;

  /// Valores de asistencia: present | absent | late | justified
  final RxString status = 'present'.obs;

  /// Minutos tarde si status = "late"
  final RxInt minutesLate = 0.obs;

  /// Notas
  final TextEditingController notesController = TextEditingController();

  /// Indicador de actualización de este row
  final RxBool isUpdating = false.obs;

  AttendanceRow({required this.player, this.attendanceId});
}

class TrainingAttendanceController extends GetxController {
  final ApiRepository _api = Get.find<ApiRepository>();

  late final int categoryId;
  late final int trainingId;
  late final bool isEditMode;

  final isLoading = true.obs;
  final isSaving = false.obs;
  final error = RxnString();

  /// Lista completa (sin filtro)
  final allRows = <AttendanceRow>[].obs;

  /// Lista filtrada para la UI
  final rows = <AttendanceRow>[].obs;

  /// Texto de búsqueda
  final searchQuery = ''.obs;

  final userRole = 'player'.obs;

  bool get canEdit =>
      hasManagerPrivileges(userRole.value) || userRole.value == 'coach';
  bool get isReadOnly => !canEdit;
  bool get isCoachRole => userRole.value == 'coach';

  @override
  void onInit() {
    super.onInit();
    _loadSession();

    categoryId = AppStorage.getSelectedCategoryId() ?? 0;
    trainingId = Get.arguments['trainingId'];
    isEditMode = Get.arguments['isEdit'] ?? false;

    if (isEditMode) {
      loadForEdit();
    } else {
      loadForNew();
    }
  }

  void _loadSession() {
    final user = AppStorage.getUser();
    final role = AppStorage.getActiveRole() ?? user?.role;
    userRole.value = (role ?? 'player').trim().toLowerCase();
  }

  /// 🆕 Modo NUEVO
  Future<void> loadForNew() async {
    isLoading.value = true;
    error.value = null;

    try {
      final playersJson = await _api.managerCategoryPlayers(categoryId);
      final players = playersJson.map((p) => Player.fromJson(p)).toList();

      final newRows = players
          .map((player) => AttendanceRow(player: player))
          .toList();

      // 👉 Ordenar por número de jersey (si tu Player tiene `number`)
      newRows.sort((a, b) {
        final aj = a.player.number ?? 9999;
        final bj = b.player.number ?? 9999;
        return aj.compareTo(bj);
      });

      allRows.assignAll(newRows);
      _applyFilter();
    } catch (e) {
      error.value = 'Error al cargar jugadores: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Helper para construir Player desde TrainingAttendanceItem
  Player _playerFromAttendance(TrainingAttendanceItem att) {
    return Player(
      id: att.playerId,
      organizationId: 0,
      categoryId: null,
      number: att.playerNumber,
      isCaptain: false,
      status: 'active',
      assignedAt: null,
      firstName: att.playerName,
      lastName: '',
      position: '',
      name: att.playerName,
      displayName: att.playerName,
      photoUrl: att.playerPhoto.isNotEmpty ? att.playerPhoto : null,
      createdAt: null,
    );
  }

  /// ✏️ Modo EDIT → SOLO usa getTrainningAttendance
  Future<void> loadForEdit() async {
    isLoading.value = true;
    error.value = null;

    try {
      final List<TrainingAttendanceItem> attendanceItems = isCoachRole
          ? await _api.getCoachTrainningAttendance(trainingId, categoryId)
          : await _api.getTrainningAttendance(trainingId, categoryId);
      attendanceItems.sort(
        (a, b) =>
            a.playerName.toLowerCase().compareTo(b.playerName.toLowerCase()),
      );

      final newRows = attendanceItems.map((att) {
        final player = _playerFromAttendance(att);

        final row = AttendanceRow(player: player, attendanceId: att.id);

        row.status.value = att.status;
        row.minutesLate.value = att.minutesLate;
        row.notesController.text = att.notes ?? '';

        return row;
      }).toList();

      allRows.assignAll(newRows);
      _applyFilter();
    } catch (e) {
      error.value = 'Error al cargar asistencia: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Cambia el texto de búsqueda
  void onSearchChanged(String value) {
    searchQuery.value = value;
    _applyFilter();
  }

  /// Aplica el filtro por nombre sobre allRows
  void _applyFilter() {
    final q = searchQuery.value.trim().toLowerCase();

    if (q.isEmpty) {
      rows.assignAll(allRows);
      return;
    }

    rows.assignAll(
      allRows.where((row) {
        final name = row.player.name.toLowerCase();
        return name.contains(q);
      }),
    );
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

      final ok = isCoachRole
          ? await _api.coachAttendanceBulk(
              categoryId: categoryId,
              items: items,
            )
          : await _api.managerAttendanceBulk(
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

  Future<void> updateSingleAttendance(AttendanceRow row) async {
    if (!isEditMode) return;
    if (row.attendanceId == null) return;

    row.isUpdating.value = true;

    try {
      if (isCoachRole) {
        await _api.updateCoachTrainingAttendance(
          categoryId: categoryId,
          trainingId: trainingId,
          attendanceId: row.attendanceId!,
          status: row.status.value,
          minutesLate: row.status.value == 'late' ? row.minutesLate.value : 0,
          notes: row.notesController.text.trim().isNotEmpty
              ? row.notesController.text.trim()
              : null,
        );
      } else {
        await _api.updateTrainingAttendance(
          categoryId: categoryId,
          trainingId: trainingId,
          attendanceId: row.attendanceId!,
          status: row.status.value,
          minutesLate: row.status.value == 'late' ? row.minutesLate.value : 0,
          notes: row.notesController.text.trim().isNotEmpty
              ? row.notesController.text.trim()
              : null,
        );
      }

      Get.snackbar(
        'Actualizado',
        'Asistencia actualizada para ${row.player.name}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 1),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo actualizar la asistencia de ${row.player.name}: $e',
      );
    } finally {
      row.isUpdating.value = false;
    }
  }
}
