import 'package:get/get.dart';
import 'package:stopandgo/core/models/combines/combine_event.dart';
import 'package:stopandgo/core/models/combines/combine_event_results_response.dart';
import 'package:stopandgo/core/network/api_repository.dart';

class CombineEventResultsController extends GetxController {
  final ApiRepository _api = Get.find<ApiRepository>();

  final isLoading = true.obs;
  final error = RxnString();

  final event = Rxn<CombineEvent>();
  final results = <CombineEventResult>[].obs;

  late final int eventId;

  @override
  void onInit() {
    super.onInit();
    final args = (Get.arguments as Map?) ?? {};
    eventId = (args['eventId'] as int?) ?? 0;

    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;

    final raw = await _api.getCombineEventResults(eventId: eventId);

    if (raw == null) {
      error.value = 'No se pudieron cargar los resultados.';
      isLoading.value = false;
      return;
    }

    try {
      event.value = raw.event;
      results.assignAll(raw.results);
    } catch (e) {
      error.value = 'Respuesta inválida del servidor: $e';
    } finally {
      isLoading.value = false;
    }
  }
}
