import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/streaming/live_event.dart';
import '../../../core/network/api_repository.dart';

class InitLiveController extends GetxController {
  final _api = Get.find<ApiRepository>();

  final isLoading = false.obs;
  final error = RxnString();

  // Input (desde arguments)
  late final int organizationId;
  late final int categoryId;
  late final int gameId;
  late final String title;

  // Result (si quieres mantenerlos sueltos para la view)
  final liveEvent = Rxn<LiveEventModel>();

  int? get liveEventId => liveEvent.value?.id;
  String get status => liveEvent.value?.status ?? 'scheduled';
  String? get webrtcPublishUrl => liveEvent.value?.webrtcPublishUrl;
  String? get webrtcPlayUrl => liveEvent.value?.webrtcPlayUrl;
  String? get rtmpsUrl => liveEvent.value?.rtmpsUrl;
  String? get rtmpsStreamKey => liveEvent.value?.rtmpsStreamKey;

  @override
  void onInit() {
    super.onInit();

    final args = (Get.arguments ?? {}) as Map;

    organizationId = (args['organizationId'] ?? 0) as int;
    categoryId = (args['categoryId'] ?? 0) as int;
    gameId = (args['gameId'] ?? 0) as int;
    title = (args['title'] ?? 'Live') as String;

    // Validación mínima
    if (organizationId <= 0 || categoryId <= 0 || gameId <= 0) {
      error.value =
          'Faltan parámetros para iniciar el live (organizationId/categoryId/gameId).';
      return;
    }

    load();
  }

  Future<void> load() async {
    try {
      isLoading.value = true;
      error.value = null;

      final created = await _api.createLiveEvent(
        organizationId: organizationId,
        categoryId: categoryId,
        gameId: gameId,
        title: title,
      );

      liveEvent.value = created;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshStatus() async {
    final id = liveEvent.value?.id;
    if (id == null) return;

    try {
      isLoading.value = true;
      error.value = null;

      final updated = await _api.getLiveEvent(id);
      liveEvent.value = updated;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Copiado',
      'Se copió al portapapeles',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void goLive() {
    Get.snackbar(
      'Transmisiones deshabilitadas',
      'La funcionalidad de live está desactivada temporalmente.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
