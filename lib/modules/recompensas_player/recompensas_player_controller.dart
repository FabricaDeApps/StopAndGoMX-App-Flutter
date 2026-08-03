import 'package:get/get.dart';
import 'package:stopandgo/core/models/merit/merit_config.dart';
import 'package:stopandgo/core/models/merit/merit_prospect.dart';
import 'package:stopandgo/core/models/merit/merit_responses.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/network/merit_exceptions.dart';

class RecompensasPlayerController extends GetxController {
  final _api = Get.find<ApiRepository>();

  final isLoading = false.obs;
  final isModuleUnavailable = false.obs;
  final error = RxnString();

  final config = Rxn<MeritConfig>();
  final me = Rxn<MeritPlayerMeResponse>();
  final creditBalance = Rxn<MeritCreditBalanceResponse>();
  final prospects = <MeritProspect>[].obs;

  final isCreatingProspect = false.obs;

  @override
  void onInit() {
    super.onInit();
    refreshData();
  }

  Future<void> refreshData() async {
    if (isLoading.value) return;
    isLoading.value = true;
    error.value = null;
    isModuleUnavailable.value = false;

    try {
      final result = await Future.wait<dynamic>([
        _api.getPlayerMeritConfig(),
        _api.getPlayerMeritMe(),
        _api.getPlayerMeritCreditBalance(),
        _api.getPlayerMeritProspects(),
      ]);

      config.value = result[0] as MeritConfig;
      me.value = result[1] as MeritPlayerMeResponse;
      creditBalance.value = result[2] as MeritCreditBalanceResponse;
      prospects.assignAll(result[3] as List<MeritProspect>);
    } on MeritModuleUnavailableException {
      isModuleUnavailable.value = true;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createProspect({
    required String fullName,
    String? phone,
  }) async {
    if (isCreatingProspect.value) return false;
    isCreatingProspect.value = true;

    try {
      final prospect = await _api.createPlayerMeritProspect(
        fullName: fullName,
        contactInfo: (phone != null && phone.trim().isNotEmpty)
            ? {'phone': phone.trim()}
            : null,
      );
      prospects.insert(0, prospect);
      return true;
    } catch (e) {
      Get.snackbar(
        'Reclutar amigos',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isCreatingProspect.value = false;
    }
  }
}
