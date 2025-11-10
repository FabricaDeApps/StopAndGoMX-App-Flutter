// attendance_game_controller.dart
import 'package:get/get.dart';
import 'package:stopandgo/core/models/players.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/storage/app_storage.dart';

enum AttStatus { present, absent, late }

class AttendanceRow {
  final Player player;
  AttStatus status;
  int? minutesLate;
  String? notes;

  AttendanceRow({
    required this.player,
    this.status = AttStatus.absent,
    this.minutesLate,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    "player_id": player.id,
    "status": switch (status) {
      AttStatus.present => "present",
      AttStatus.absent => "absent",
      AttStatus.late => "late",
    },
    "minutes_late": status == AttStatus.late ? (minutesLate ?? 1) : null,
    "notes": (notes?.trim().isEmpty ?? true) ? null : notes!.trim(),
  };
}

class AttendanceGameController extends GetxController {
  final _api = Get.find<ApiRepository>();

  late final int gameId;
  late final DateTime gameDate;
  late final int categoryId;

  final isLoading = true.obs;
  final isSaving = false.obs;
  final rows = <AttendanceRow>[].obs;

  // Resumen
  int get total => rows.length;
  int get presentCount =>
      rows.where((r) => r.status == AttStatus.present).length;
  int get lateCount => rows.where((r) => r.status == AttStatus.late).length;
  int get absentCount => rows.where((r) => r.status == AttStatus.absent).length;

  bool get isSameDay {
    final now = DateTime.now();
    return now.year == gameDate.year &&
        now.month == gameDate.month &&
        now.day == gameDate.day;
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    categoryId =
        args?['categoryId'] as int? ??
        (throw ArgumentError('categoryId requerido'));

    gameId =
        args?['gameId'] as int? ?? (throw ArgumentError('gameId es requerido'));
    gameDate =
        args?['gameDate'] as DateTime? ??
        (throw ArgumentError('gameDate es requerido'));
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    isLoading.value = true;
    try {
      final players = await _api.getGamePlayers(categoryId: categoryId);
      rows.assignAll(players.map((p) => AttendanceRow(player: p)).toList());
    } catch (e) {
      Get.snackbar(
        'Asistencias',
        'No se pudieron cargar jugadores: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void setAll(AttStatus status) {
    for (final r in rows) {
      r.status = status;
      if (status != AttStatus.late) r.minutesLate = null;
    }
    rows.refresh();
  }

  void toggleStatus(AttendanceRow r, AttStatus status) {
    r.status = status;
    if (status != AttStatus.late) r.minutesLate = null;
    rows.refresh();
  }

  void setMinutesLate(AttendanceRow r, int? minutes) {
    r.minutesLate = minutes;
    rows.refresh();
  }

  void setNotes(AttendanceRow r, String? text) {
    r.notes = text;
    // no es necesario refresh inmediato; si quieres feedback visual, activa:
    // rows.refresh();
  }

  Future<void> saveBulk() async {
    if (!isSameDay) {
      Get.snackbar(
        'No permitido',
        'Solo puedes capturar asistencia el día del partido',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Validación: si hay "late" sin minutos >=1, pedir corrección
    final invalidLate = rows.where(
      (r) =>
          r.status == AttStatus.late &&
          (r.minutesLate == null || r.minutesLate! < 1),
    );
    if (invalidLate.isNotEmpty) {
      Get.snackbar(
        'Faltan minutos',
        'Hay jugadores marcados como "Tarde" sin minutos válidos',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isSaving.value = true;
    try {
      final items = rows.map((r) => r.toJson()).toList();
      final res = await _api.saveAttendancesBulk(gameId: gameId, items: items);

      if (!res.success) {
        Get.snackbar(
          'Asistencias',
          res.message,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      Get.back(result: true);
      Get.snackbar(
        'Asistencias',
        res.message.isEmpty ? 'Guardado correctamente' : res.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Asistencias',
        'Error al guardar: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }
  }
}
