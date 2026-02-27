import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:stopandgo/core/models/games/games.dart';
import 'package:stopandgo/core/network/api_request_exception.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/services/coach_trainings_service.dart';
import 'package:stopandgo/core/services/manager_trainings_service.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/core/models/training.dart';

class CreateTrainningController extends GetxController {
  final ApiRepository _api = Get.find<ApiRepository>();
  final ManagerTrainingsService _managerTrainings =
      Get.find<ManagerTrainingsService>();
  final CoachTrainingsService _coachTrainings =
      Get.find<CoachTrainingsService>();

  late final int categoryId;
  bool isEditing = false;
  int? trainingId;
  Training? _editingTraining;

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

    final args = Get.arguments as Map<String, dynamic>?;
    final editingTraining = args?['training'];
    if (editingTraining is Training) {
      _editingTraining = editingTraining;
      trainingId = editingTraining.id;
      isEditing = true;
    }

    final selectedCategoryId =
        (args?['categoryId'] as int?) ?? AppStorage.getSelectedCategoryId();
    if (selectedCategoryId == null) {
      error.value = 'No hay categoría seleccionada.';
    } else {
      categoryId = selectedCategoryId;
    }

    if (_editingTraining != null) {
      _prefillIfEditing(_editingTraining!);
    } else {
      final now = DateTime.now().add(const Duration(hours: 1));
      _setStartsAt(now);
    }
    loadVenues();
  }

  void _prefillIfEditing(Training training) {
    _setStartsAt(training.startsAt);
    if (training.durationMinutes != null) {
      durationController.text = '${training.durationMinutes}';
    }
    selectedVenueId.value = training.venueId;
    status.value = training.status.trim().isEmpty
        ? 'scheduled'
        : training.status;
    notesController.text = (training.notes ?? '').trim();
  }

  Future<void> loadVenues() async {
    isLoadingVenues.value = true;
    venuesError.value = null;

    try {
      final list = await _api.getVenues();
      venues.assignAll(list);

      // Si la organización tiene una sede por defecto y existe en catálogo,
      // selecciónala automáticamente al abrir el formulario.
      final org = AppStorage.getOrganization();
      final defaultVenueId = org?.idVenueDefault;
      final hasCurrentSelection = selectedVenueId.value != null;
      if (!hasCurrentSelection && defaultVenueId != null) {
        final exists = list.any((v) => v.id == defaultVenueId);
        if (exists) {
          selectedVenueId.value = defaultVenueId;
        }
      }
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
      final activeRole =
          (AppStorage.getActiveRole() ?? AppStorage.getUser()?.role ?? '')
              .trim()
              .toLowerCase();

      final Map<String, dynamic>? patch = (isEditing && trainingId != null)
          ? _buildUpdatePayload(body)
          : null;
      if (patch != null && patch.isEmpty) {
        Get.snackbar(
          'Sin cambios',
          'No hay cambios para actualizar.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final resp = await (activeRole == 'coach'
          ? (isEditing && trainingId != null
                ? _coachTrainings.updateTraining(
                    categoryId: categoryId,
                    trainingId: trainingId!,
                    data: patch!,
                  )
                : _coachTrainings.createTraining(
                    categoryId: categoryId,
                    data: body,
                  ))
          : (isEditing && trainingId != null
                ? _managerTrainings.updateTraining(
                    categoryId: categoryId,
                    trainingId: trainingId!,
                    data: patch!,
                  )
                : _managerTrainings.createTraining(
                    categoryId: categoryId,
                    data: body,
                  )));

      if (resp.success) {
        await _showSuccessDialog(isEditing: isEditing);
        Get.back(result: true);
      } else {
        _showError(resp.message);
      }
    } catch (e) {
      _showError(_mapCreateError(e));
    } finally {
      isSubmitting.value = false;
    }
  }

  Map<String, dynamic> _buildUpdatePayload(Map<String, dynamic> fullBody) {
    final training = _editingTraining;
    if (training == null) return fullBody;

    final patch = <String, dynamic>{};

    final newStartsAt = fullBody['starts_at']?.toString();
    final oldStartsAt = DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(training.startsAt);
    if (newStartsAt != oldStartsAt) {
      patch['starts_at'] = newStartsAt;
    }

    final newDuration = fullBody['duration_minutes'] as int?;
    if (newDuration != training.durationMinutes) {
      patch['duration_minutes'] = newDuration;
    }

    final newVenueId = fullBody['venue_id'] as int?;
    if (newVenueId != training.venueId) {
      patch['venue_id'] = newVenueId;
    }

    final newStatus = (fullBody['status'] ?? '').toString().trim();
    final oldStatus = training.status.trim();
    if (newStatus != oldStatus) {
      patch['status'] = newStatus;
    }

    final newNotesRaw = fullBody['notes'];
    final newNotes = newNotesRaw?.toString().trim();
    final oldNotes = training.notes?.trim();
    if ((newNotes ?? '') != (oldNotes ?? '')) {
      patch['notes'] = (newNotes == null || newNotes.isEmpty) ? null : newNotes;
    }

    return patch;
  }

  Future<void> _showSuccessDialog({required bool isEditing}) async {
    await Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isEditing ? 'Entrenamiento actualizado' : 'Entrenamiento creado',
        ),
        content: Text(
          isEditing
              ? 'El entrenamiento se actualizó correctamente para esta categoría.'
              : 'El entrenamiento se creó correctamente para esta categoría.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade50,
      colorText: Colors.red.shade800,
    );
  }

  String _mapCreateError(Object error) {
    if (error is ApiRequestException) {
      return error.message;
    }
    final text = error.toString();
    if (text.startsWith('Exception: ')) {
      return text.replaceFirst('Exception: ', '');
    }
    return 'No se pudo crear el entrenamiento.';
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
