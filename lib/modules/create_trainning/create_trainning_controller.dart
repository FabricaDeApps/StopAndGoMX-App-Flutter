import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:stopandgo/core/models/games.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/storage/app_storage.dart';

class CreateTrainningController extends GetxController {
  final ApiRepository _api = Get.find<ApiRepository>();

  late final int categoryId;

  final formKey = GlobalKey<FormState>();

  // Campos
  final startsAtController = TextEditingController();
  final durationController = TextEditingController();
  final venueController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final notesController = TextEditingController();

  final isLoadingVenues = false.obs;
  final venues = <Venue>[].obs;
  final venuesError = RxnString();
  final selectedVenueId = RxnInt();

  final status = 'scheduled'.obs; // scheduled | completed | canceled
  DateTime? _startsAt;

  final isSubmitting = false.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();

    final selectedCategoryId = AppStorage.getSelectedCategoryId();
    if (selectedCategoryId == null) {
      error.value = 'No hay categoría seleccionada.';
    } else {
      categoryId = selectedCategoryId;
    }

    // valor por defecto: ahora + 1h
    final now = DateTime.now().add(const Duration(hours: 1));
    _setStartsAt(now);
    loadVenues();
  }

  Future<void> loadVenues() async {
    isLoadingVenues.value = true;
    venuesError.value = null;

    try {
      final list = await _api.getVenues();
      venues.assignAll(list);
    } catch (e) {
      venuesError.value = 'Error al cargar sedes: $e';
    } finally {
      isLoadingVenues.value = false;
    }
  }

  void _setStartsAt(DateTime dt) {
    _startsAt = dt;
    final display = DateFormat('dd/MM/yyyy HH:mm', 'es_MX').format(dt);
    startsAtController.text = display;
  }

  Future<void> pickStartsAt(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = _startsAt ?? now;
    final firstDate = now.subtract(const Duration(days: 365));
    final lastDate = now.add(const Duration(days: 365));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      // ❌ quita esta línea
      // locale: const Locale('es', 'MX'),
    );

    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startsAt ?? now),
    );

    if (pickedTime == null) return;

    final dt = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    _setStartsAt(dt);
  }

  Future<void> submit() async {
    if (error.value != null) {
      Get.snackbar('Error', error.value!, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    if (formKey.currentState?.validate() != true) {
      return;
    }

    if (_startsAt == null) {
      Get.snackbar(
        'Fecha y hora',
        'Selecciona la fecha y hora del entrenamiento.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final durationStr = durationController.text.trim();
    int? durationMinutes;
    if (durationStr.isNotEmpty) {
      durationMinutes = int.tryParse(durationStr);
      if (durationMinutes == null || durationMinutes <= 0) {
        Get.snackbar(
          'Duración inválida',
          'Ingresa una duración válida en minutos.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    }

    final body = <String, dynamic>{
      'starts_at': DateFormat('yyyy-MM-dd HH:mm:ss').format(_startsAt!),
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      'venue_id': selectedVenueId.value,
      'status': status.value,
      'notes': notesController.text.trim().isNotEmpty
          ? notesController.text.trim()
          : null,
    };

    isSubmitting.value = true;

    try {
      final resp = await _api.createTraining(
        categoryId: categoryId,
        data: body,
      );

      if (resp['success'] == true) {
        await Get.dialog(
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Entrenamiento creado'),
            content: const Text(
              'El entrenamiento se creó correctamente para esta categoría.',
            ),
            actions: [
              TextButton(onPressed: () => Get.back(), child: const Text('OK')),
            ],
          ),
        );

        // Volvemos con "true" para que la lista refresque
        Get.back(result: true);
      } else {
        final msg =
            resp['message']?.toString() ?? 'No se pudo crear el entrenamiento.';
        Get.snackbar(
          'Error',
          msg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade800,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo crear el entrenamiento: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    startsAtController.dispose();
    durationController.dispose();
    venueController.dispose();
    addressController.dispose();
    cityController.dispose();
    notesController.dispose();
    super.onClose();
  }
}
