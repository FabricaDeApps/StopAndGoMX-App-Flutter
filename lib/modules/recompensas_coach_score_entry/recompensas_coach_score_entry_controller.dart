import 'package:get/get.dart';
import 'package:stopandgo/core/models/merit/merit_score_entry.dart';
import 'package:stopandgo/core/models/merit/merit_snapshot.dart';
import 'package:stopandgo/core/network/api_repository.dart';

const meritCapturableRubricItems = <String>[
  'puntualidad',
  'instalaciones',
  'fisico',
  'tecnico',
  'sistema',
  'trabajo_equipo',
  'servicio_apoyo',
  'representacion',
  'reclutamiento_extra',
  'asignaciones',
  'esfuerzo',
  'produccion',
  'rol',
];

class RecompensasCoachScoreEntryController extends GetxController {
  final _api = Get.find<ApiRepository>();

  late final int playerId;
  late final String playerName;
  late final int categoryId;

  final isLoading = false.obs;
  final error = RxnString();
  final isSaving = false.obs;

  final selectedMonth = DateTime(DateTime.now().year, DateTime.now().month).obs;
  final entries = <MeritScoreEntry>[].obs;
  final currentSnapshot = Rxn<MeritSnapshot>();

  bool get isLocked => currentSnapshot.value?.isLocked == true;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments is Map
        ? Get.arguments as Map
        : <String, dynamic>{};
    playerId = args['playerId'] as int? ?? 0;
    playerName = args['playerName'] as String? ?? 'Jugador';
    categoryId = args['categoryId'] as int? ?? 0;
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    error.value = null;

    try {
      final result = await Future.wait<dynamic>([
        _api.getCoachPlayerScores(
          playerId: playerId,
          periodMonth: selectedMonth.value,
        ),
        _api.getCoachMeritSnapshots(periodMonth: selectedMonth.value),
      ]);

      entries.assignAll(result[0] as List<MeritScoreEntry>);
      final snapshots = result[1] as List<MeritSnapshot>;
      MeritSnapshot? matched;
      for (final s in snapshots) {
        if (s.playerId == playerId) {
          matched = s;
          break;
        }
      }
      currentSnapshot.value = matched;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> changeMonth(DateTime month) async {
    selectedMonth.value = DateTime(month.year, month.month);
    await loadData();
  }

  Future<bool> addEntry({
    required String rubricItem,
    required double points,
    String? reason,
    String? evidencePath,
  }) async {
    if (isSaving.value) return false;
    isSaving.value = true;

    try {
      final entry = await _api.createCoachScoreEntry(
        playerId: playerId,
        categoryId: categoryId,
        rubricItem: rubricItem,
        points: points,
        isExtraPoint: rubricItem == 'reclutamiento_extra',
        periodMonth: selectedMonth.value,
        reason: reason,
        evidencePath: evidencePath,
      );
      entries.insert(0, entry);
      return true;
    } catch (e) {
      Get.snackbar(
        'Captura de puntos',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
