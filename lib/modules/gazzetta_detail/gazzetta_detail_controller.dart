import 'package:get/get.dart';
import 'package:stopandgo/core/models/gazzetta/gazzetta_models.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/network/gazzetta_exceptions.dart';

class GazzettaDetailController extends GetxController {
  final _api = Get.find<ApiRepository>();

  final isLoading = true.obs;
  final isModuleUnavailable = false.obs;
  final error = RxnString();

  final detail = Rxn<GazettaDetail>();
  final htmlContent = RxnString();

  late final int gazettaId;

  @override
  void onInit() {
    super.onInit();
    gazettaId = _readGazettaId(Get.arguments);
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    isModuleUnavailable.value = false;
    htmlContent.value = null;

    try {
      final result = await _api.getGazettaDetail(gazettaId);
      detail.value = result;
      final html = detail.value?.html?.trim();
      htmlContent.value = (html == null || html.isEmpty) ? null : html;
      _markSeen();
    } on GazettaModuleUnavailableException {
      isModuleUnavailable.value = true;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _markSeen() async {
    try {
      await _api.markGazettaSeen(gazettaId);
    } catch (_) {
      // Tracking no bloqueante.
    }
  }

  int _readGazettaId(dynamic args) {
    if (args is int && args > 0) return args;
    if (args is Map<String, dynamic>) {
      final raw = args['id'] ?? args['gazettaId'];
      final id = _asInt(raw);
      if (id != null && id > 0) return id;
    }
    throw ArgumentError('gazettaId es requerido');
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
