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

  late final int categoryId;

  @override
  void onInit() {
    super.onInit();
    categoryId = AppStorage.getSelectedCategoryId() ?? 0;

    loadTrainings();
  }

  Future<void> loadTrainings() async {
    isLoading.value = true;
    error.value = null;

    try {
      final list = await _api.managerCategoryTrainings(categoryId: categoryId);
      trainings.assignAll(list);
    } catch (e) {
      error.value = 'Error al cargar entrenamientos: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// 👉 Navega a CreateTraining, espera resultado y recarga si fue success.
  Future<void> goToCreateTraining() async {
    final result = await Get.toNamed(Routes.createTrainnig);

    if (result == true) {
      await loadTrainings();
    }
  }

  Future<void> completeTraining(Training t) async {
    try {
      await _api.completeTraining(t.id, categoryId);

      // refrescar lista
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
}
