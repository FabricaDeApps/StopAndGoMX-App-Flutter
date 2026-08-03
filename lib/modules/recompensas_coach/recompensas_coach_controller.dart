import 'package:get/get.dart';
import 'package:stopandgo/core/models/merit/merit_incident.dart';
import 'package:stopandgo/core/models/merit/merit_prospect.dart';
import 'package:stopandgo/core/models/merit/merit_snapshot.dart';
import 'package:stopandgo/core/models/players.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/network/merit_exceptions.dart';
import 'package:stopandgo/core/storage/app_storage.dart';

class RecompensasCoachController extends GetxController {
  final _api = Get.find<ApiRepository>();

  late final int categoryId;
  late final String categoryName;

  final isLoading = false.obs;
  final isModuleUnavailable = false.obs;
  final error = RxnString();

  final players = <Player>[].obs;
  final selectedSnapshotMonth =
      DateTime(DateTime.now().year, DateTime.now().month).obs;
  final snapshots = <MeritSnapshot>[].obs;
  final isLoadingSnapshots = false.obs;
  final validatingSnapshotIds = <int>{}.obs;

  final prospects = <MeritProspect>[].obs;
  final isCreatingProspect = false.obs;

  final incidents = <MeritIncident>[].obs;
  final isCreatingIncident = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments is Map
        ? Get.arguments as Map
        : <String, dynamic>{};
    categoryId = args['categoryId'] as int? ??
        AppStorage.getSelectedCategoryId() ??
        0;
    categoryName = args['categoryName'] as String? ??
        AppStorage.getSelectedCategoryName() ??
        'Categoría';
    refreshData();
  }

  Future<void> refreshData() async {
    if (isLoading.value) return;
    isLoading.value = true;
    error.value = null;
    isModuleUnavailable.value = false;

    try {
      final result = await Future.wait<dynamic>([
        _api.getGamePlayers(categoryId: categoryId),
        _api.getCoachMeritSnapshots(periodMonth: selectedSnapshotMonth.value),
        _api.getCoachMeritProspects(),
        _api.getCoachMeritIncidents(),
      ]);

      players.assignAll(result[0] as List<Player>);
      snapshots.assignAll(result[1] as List<MeritSnapshot>);
      prospects.assignAll(result[2] as List<MeritProspect>);
      incidents.assignAll(result[3] as List<MeritIncident>);
    } on MeritModuleUnavailableException {
      isModuleUnavailable.value = true;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> changeSnapshotMonth(DateTime month) async {
    selectedSnapshotMonth.value = DateTime(month.year, month.month);
    isLoadingSnapshots.value = true;
    try {
      final list = await _api.getCoachMeritSnapshots(
        periodMonth: selectedSnapshotMonth.value,
      );
      snapshots.assignAll(list);
    } catch (e) {
      Get.snackbar('Ranking', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoadingSnapshots.value = false;
    }
  }

  Future<void> validateSnapshot(int snapshotId) async {
    if (validatingSnapshotIds.contains(snapshotId)) return;
    validatingSnapshotIds.add(snapshotId);

    try {
      final result = await _api.validateCoachSnapshot(snapshotId: snapshotId);
      if (result.snapshot != null) {
        final idx = snapshots.indexWhere((s) => s.id == snapshotId);
        if (idx >= 0) snapshots[idx] = result.snapshot!;
      }
      Get.snackbar(
        'Validación',
        result.message.isNotEmpty ? result.message : 'Aprobación registrada.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Validación', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      validatingSnapshotIds.remove(snapshotId);
    }
  }

  Future<bool> createProspect({
    required String fullName,
    String? phone,
  }) async {
    if (isCreatingProspect.value) return false;
    isCreatingProspect.value = true;

    try {
      final prospect = await _api.createCoachMeritProspect(
        fullName: fullName,
        contactInfo:
            (phone != null && phone.trim().isNotEmpty) ? {'phone': phone.trim()} : null,
      );
      prospects.insert(0, prospect);
      return true;
    } catch (e) {
      Get.snackbar('Prospectos', e.toString(), snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isCreatingProspect.value = false;
    }
  }

  Future<bool> createIncident({
    int? playerId,
    required String incidentType,
    required String description,
    required DateTime occurredAt,
  }) async {
    if (isCreatingIncident.value) return false;
    final coachId = AppStorage.getUser()?.id;
    if (coachId == null) {
      Get.snackbar(
        'Incidencias',
        'No se pudo identificar al coach autenticado.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    isCreatingIncident.value = true;
    try {
      final incident = await _api.createCoachMeritIncident(
        coachId: coachId,
        playerId: playerId,
        incidentType: incidentType,
        description: description,
        occurredAt: occurredAt,
      );
      incidents.insert(0, incident);
      if (incident.isRepeat) {
        Get.snackbar(
          'Incidencias',
          'Es una reincidencia: corresponde evaluar expulsión del staff.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return true;
    } catch (e) {
      Get.snackbar('Incidencias', e.toString(), snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isCreatingIncident.value = false;
    }
  }
}
