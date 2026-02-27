import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/training.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/routes/app_routes.dart';

class TrainingsController extends GetxController {
  final ApiRepository _api = Get.find<ApiRepository>();

  final isLoading = true.obs;
  final trainings = <Training>[].obs;
  final error = RxnString();

  // ✅ filtros
  final selectedStatus = RxnString(); // null = todos
  final fromDate = Rxn<DateTime>();
  final toDate = Rxn<DateTime>();

  late final int categoryId;

  final userRole = 'player'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSession();

    categoryId = AppStorage.getSelectedCategoryId() ?? 0;

    final now = DateTime.now();
    fromDate.value = DateTime(now.year, now.month, 1);
    toDate.value = DateTime(now.year, now.month, now.day);

    loadTrainings();
  }

  void _loadSession() {
    final role = AppStorage.getActiveRole() ?? AppStorage.getUser()?.role;
    userRole.value = (role ?? 'player').trim().toLowerCase();
  }

  Future<void> loadTrainings() async {
    isLoading.value = true;
    error.value = null;

    try {
      final list = userRole.value == 'coach'
          ? await _api.getCoachCategoryTrainings(
              categoryId: categoryId,
              status: selectedStatus.value,
              from: fromDate.value,
              to: toDate.value,
            )
          : await _api.managerCategoryTrainings(
              categoryId: categoryId,
              status: selectedStatus.value,
              from: fromDate.value,
              to: toDate.value,
            );
      trainings.assignAll(list);
    } catch (e) {
      error.value = 'Error al cargar entrenamientos: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> setStatus(String? status) async {
    if (selectedStatus.value == status) return;
    selectedStatus.value = status;
    await loadTrainings();
  }

  // ✅ pickers
  Future<void> pickFromDate(BuildContext context) async {
    final initial = fromDate.value ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'MX'),
    );
    if (picked == null) return;

    fromDate.value = picked;

    // si from > to, ajusta to
    final to = toDate.value;
    if (to != null && picked.isAfter(to)) {
      toDate.value = picked;
    }

    await loadTrainings();
  }

  Future<void> pickToDate(BuildContext context) async {
    final initial = toDate.value ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'MX'),
    );
    if (picked == null) return;

    toDate.value = picked;

    // si to < from, ajusta from
    final from = fromDate.value;
    if (from != null && picked.isBefore(from)) {
      fromDate.value = picked;
    }

    await loadTrainings();
  }

  Future<void> clearDates() async {
    fromDate.value = null;
    toDate.value = null;
    await loadTrainings();
  }

  /// 👉 Navega a CreateTraining, espera resultado y recarga si fue success.
  Future<void> goToCreateTraining() async {
    final result = await Get.toNamed(Routes.createTrainnig);
    if (result == true) {
      await loadTrainings();
    }
  }

  Future<void> goToEditTraining(Training training) async {
    final result = await Get.toNamed(
      Routes.createTrainnig,
      arguments: {'categoryId': categoryId, 'training': training},
    );
    if (result == true) {
      await loadTrainings();
    }
  }

  Future<void> completeTraining(Training t) async {
    try {
      await _api.completeTraining(t.id, categoryId);

      await loadTrainings();
      Get.snackbar(
        'Entrenamiento completado',
        'El entrenamiento ha sido marcado como completado.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo completar el entrenamiento.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> confirmDeleteTraining(Training t) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Eliminar entrenamiento'),
        content: Text(
          '¿Seguro que quieres eliminar este entrenamiento?\n\n'
          '${_formatTrainingSummary(t)}\n\n'
          'Esta acción lo ocultará de la app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Get.back(result: true),
            icon: const Icon(Icons.delete),
            label: const Text('Eliminar'),
          ),
        ],
      ),
      barrierDismissible: true,
    );

    if (ok == true) {
      await deleteTraining(t);
    }
  }

  Future<void> deleteTraining(Training t) async {
    try {
      // Optimista: quítalo de la lista al instante
      final prev = List<Training>.from(trainings);
      trainings.removeWhere((x) => x.id == t.id);

      await _api.deleteTraining(trainingId: t.id, categoryId: categoryId);

      Get.snackbar(
        'Entrenamiento eliminado',
        'Se eliminó correctamente.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      // rollback: vuelve a cargar por si falló
      await loadTrainings();
      Get.snackbar(
        'Error',
        'No se pudo eliminar el entrenamiento.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  String _formatTrainingSummary(Training t) {
    final date = t.startsAt != null ? t.startsAt!.toLocal().toString() : '';
    final venue = (t.venue ?? '').trim();
    if (venue.isNotEmpty) return '$date\n$venue';
    return date;
  }
}
