import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/network/api_repository.dart';

class NewGameController extends GetxController {
  final _api = Get.find<ApiRepository>();

  // Argumento requerido: categoryId
  late final int categoryId;

  // Form
  final formKey = GlobalKey<FormState>();
  final opponentCtrl = TextEditingController();
  final venueCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  // Estado
  final isHome = true.obs;
  final isSubmitting = false.obs;
  final scheduledAt = Rxn<DateTime>(); // fecha+hora

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;

    categoryId =
        (args?['categoryId'] as int?) ??
        (throw ArgumentError('categoryId es requerido en arguments'));
  }

  @override
  void onClose() {
    opponentCtrl.dispose();
    venueCtrl.dispose();
    notesCtrl.dispose();
    super.onClose();
  }

  Future<void> pickDateTime(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = scheduledAt.value ?? now;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (time == null) return;

    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    scheduledAt.value = dt;
  }

  String _formatForApi(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}:00';
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (scheduledAt.value == null) {
      Get.snackbar(
        'Falta fecha/hora',
        'Selecciona la fecha y hora del partido',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isSubmitting.value = true;
    try {
      final body = {
        "opponent_name": opponentCtrl.text.trim(),
        "scheduled_at": _formatForApi(scheduledAt.value!),
        "venue": venueCtrl.text.trim(),
        "is_home": isHome.value,
        "status": "scheduled", // default fijo
        "notes": notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
      };

      await _api.createGame(categoryId, body);

      Get.back(result: true);
      Get.snackbar(
        'Éxito',
        'Juego creado correctamente',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo crear el juego: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isSubmitting.value = false;
    }
  }
}
