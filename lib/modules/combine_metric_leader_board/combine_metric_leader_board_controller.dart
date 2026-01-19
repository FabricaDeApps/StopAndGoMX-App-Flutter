import 'package:get/get.dart';
import 'package:stopandgo/core/models/combines/combine_metric.dart';
import 'package:stopandgo/core/models/combines/combine_metric_leaderboard_response.dart';
import 'package:stopandgo/core/network/api_repository.dart';

class CombineMetricLeaderBoardController extends GetxController {
  final ApiRepository _api = Get.find<ApiRepository>();

  late final int eventId;
  late final CombineMetric metric;
  late final int limit;

  final isLoading = true.obs;
  final error = RxnString();
  final data = Rxn<CombineMetricLeaderboardResponse>();

  @override
  void onInit() {
    super.onInit();

    final args = (Get.arguments as Map?) ?? {};

    eventId = (args['eventId'] as int?) ?? 0;
    metric = args['metric'] as CombineMetric;
    limit = (args['limit'] as int?) ?? 10;

    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;

    final raw = await _api.getCombineLeaderboard(
      eventId: eventId,
      metricKey: metric.key,
      limit: limit,
    );

    if (raw == null) {
      error.value = 'No se pudo cargar el leaderboard.';
      isLoading.value = false;
      return;
    }

    try {
      data.value = CombineMetricLeaderboardResponse.fromJson(raw);
    } catch (e) {
      error.value = 'Respuesta inválida del servidor: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refresh() => load();
}
