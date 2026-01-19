import 'package:get/get.dart';
import 'package:stopandgo/core/models/trainings/training_player_response.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import '../../../core/network/api_repository.dart';

class PlayerTrainingsController extends GetxController {
  final _api = Get.find<ApiRepository>();

  final isLoading = false.obs;
  final error = RxnString();

  final data = Rxn<TrainingPlayerResponse>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    try {
      isLoading.value = true;
      error.value = null;

      final playerId = AppStorage.getSelectedPlayerId();
      final res = await _api.getTrainingPlayerHistory(playerId: playerId!);
      if (res == null) {
        error.value = 'No se pudo cargar el historial';
        return;
      }

      data.value = res;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
