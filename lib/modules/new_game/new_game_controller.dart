import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/games/games.dart';
import 'package:stopandgo/core/network/api_repository.dart';

class NewGameController extends GetxController {
  final _api = Get.find<ApiRepository>();

  // Argumento requerido: categoryId
  late final int categoryId;

  // Form
  final formKey = GlobalKey<FormState>();
  final opponentCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  // Venues
  final isLoadingVenues = false.obs;
  final venues = <Venue>[].obs;
  final selectedVenue = Rxn<Venue>();
  final venueSearchCtrl = TextEditingController(); // opcional (filtrar)
  List<Venue> get filteredVenues {
    final q = venueSearchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return venues;
    return venues.where((v) => v.name.toLowerCase().contains(q)).toList();
  }

  // Estado
  final isHome = true.obs;
  final isSubmitting = false.obs;
  final scheduledAt = Rxn<DateTime>(); // fecha+hora

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;

    categoryId =
        (args?['categoryId'] as int?) ??
        (throw ArgumentError('categoryId es requerido en arguments'));

    fetchVenues();
    venueSearchCtrl.addListener(() {
      // fuerza rebuild del dropdown cuando se filtra
      venues.refresh();
    });
  }

  @override
  void onClose() {
    opponentCtrl.dispose();
    notesCtrl.dispose();
    venueSearchCtrl.dispose();
    super.onClose();
  }

  Future<void> fetchVenues() async {
    isLoadingVenues.value = true;
    try {
      final list = await _api.getVenues();
      venues.assignAll(list);
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudieron cargar las sedes: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isLoadingVenues.value = false;
    }
  }

  Future<void> pickDateTime(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = scheduledAt.value ?? now;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (time == null) return;

    scheduledAt.value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  String _formatForApi(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}:00';
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    final venue = selectedVenue.value;
    if (venue == null || venue.id <= 0) {
      Get.snackbar(
        'Falta sede',
        'Selecciona la sede/campo',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (scheduledAt.value == null) {
      Get.snackbar(
        'Falta fecha/hora',
        'Selecciona la fecha y hora del partido',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isSubmitting.value = true;
    try {
      final body = {
        "opponent_name": opponentCtrl.text.trim(),
        "scheduled_at": _formatForApi(scheduledAt.value!),

        // ✅ Enviar ID de venue
        "venue_id": venue.id,

        // (opcional) por compatibilidad o display
        "venue_name": venue.name,

        "is_home": isHome.value,
        "status": "scheduled",
        "notes": notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
      };

      await _api.createGame(categoryId, body);

      Get.back(result: true);
      Get.snackbar(
        'Éxito',
        'Juego creado correctamente',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo crear el juego: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isSubmitting.value = false;
    }
  }
}
