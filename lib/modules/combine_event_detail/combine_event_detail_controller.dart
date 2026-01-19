// lib/modules/combine/detail/combine_event_detail_controller.dart
import 'package:get/get.dart';
import 'package:stopandgo/core/models/combines/combine_event.dart';
import 'package:stopandgo/core/models/combines/combine_metric.dart';
import 'package:stopandgo/routes/app_routes.dart';
import '../../../core/network/api_repository.dart';

class CombineEventDetailController extends GetxController {
  final _api = Get.find<ApiRepository>();

  final isLoading = false.obs;
  final error = RxnString();

  final event = Rxn<CombineEvent>();
  final metrics = <CombineMetric>[].obs;
  final resultsCount = 0.obs;

  int get eventId => int.tryParse(Get.parameters['eventId'] ?? '') ?? 0;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    try {
      isLoading.value = true;
      error.value = null;

      if (eventId <= 0) {
        error.value = 'Event inválido';
        return;
      }

      final res = await _api.getCombineEventDetail(eventId: eventId);
      if (res == null) {
        error.value = 'No se pudo cargar el evento.';
        return;
      }

      event.value = res.event;
      metrics.assignAll(res.metrics);
      resultsCount.value = res.resultsCount;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void goCapture() {
    Get.toNamed(
      Routes.combineResultCreate,
      parameters: {'eventId': '${event.value!.id}'},
    );
  }

  void goResults() {
    final e = event.value;
    if (e == null) return;

    Get.toNamed(
      Routes.combineEventResults,
      arguments: {'eventId': e.id, 'eventName': e.name},
    );
  }

  void goLeaderboard(CombineMetric m) {
    Get.toNamed(
      Routes.combineMetricLeaderBoard,
      arguments: {'eventId': eventId, 'metric': m, 'limit': 10},
    );
  }
}

/// DTO simple para la respuesta del endpoint detail
class CombineEventDetailResponse {
  final CombineEvent event;
  final List<CombineMetric> metrics;
  final int resultsCount;

  CombineEventDetailResponse({
    required this.event,
    required this.metrics,
    required this.resultsCount,
  });

  factory CombineEventDetailResponse.fromJson(Map<String, dynamic> json) {
    return CombineEventDetailResponse(
      event: CombineEvent.fromJson(
        Map<String, dynamic>.from(json['event'] ?? {}),
      ),
      metrics: ((json['metrics'] ?? []) as List)
          .whereType<Map>()
          .map((e) => CombineMetric.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      resultsCount: int.tryParse('${json['results_count'] ?? 0}') ?? 0,
    );
  }
}
