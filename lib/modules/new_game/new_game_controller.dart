import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/games/games.dart';
import 'package:stopandgo/core/network/api_request_exception.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/services/coach_games_service.dart';
import 'package:stopandgo/core/services/manager_games_service.dart';
import 'package:stopandgo/core/storage/app_storage.dart';

class NewGameController extends GetxController {
  final _api = Get.find<ApiRepository>();
  final _managerGames = Get.find<ManagerGamesService>();
  final _coachGames = Get.find<CoachGamesService>();

  // Argumento requerido: categoryId
  late final int categoryId;
  bool isEditing = false;
  int? gameId;
  Game? _editingGame;

  // Form
  final formKey = GlobalKey<FormState>();
  final opponentCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  // Venues
  final isLoadingVenues = false.obs;
  final venues = <Venue>[].obs;
  final selectedVenue = Rxn<Venue>();

  // Estado
  final isHome = true.obs;
  final isHomeTouched = false.obs;
  final isSubmitting = false.obs;
  final scheduledAt = Rxn<DateTime>(); // fecha+hora

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    final editingGame = args?['game'];
    if (editingGame is Game) {
      _editingGame = editingGame;
      gameId = editingGame.id;
      isEditing = true;
    }

    categoryId =
        (args?['categoryId'] as int?) ??
        _editingGame?.categoryId ??
        (throw ArgumentError('categoryId es requerido en arguments'));

    _prefillIfEditing();
    fetchVenues();
  }

  @override
  void onClose() {
    opponentCtrl.dispose();
    notesCtrl.dispose();
    super.onClose();
  }

  void _prefillIfEditing() {
    final game = _editingGame;
    if (game == null) return;

    opponentCtrl.text = game.opponent;
    notesCtrl.text = (game.notes ?? '').trim();
    scheduledAt.value = game.startsAt;
  }

  void setIsHome(bool value) {
    isHomeTouched.value = true;
    isHome.value = value;
  }

  Future<void> fetchVenues() async {
    isLoadingVenues.value = true;
    try {
      final list = await _api.getVenues();
      venues.assignAll(list);

      final defaultVenueId = AppStorage.getOrganization()?.idVenueDefault;
      if (defaultVenueId != null && selectedVenue.value == null) {
        for (final venue in list) {
          if (venue.id == defaultVenueId) {
            selectedVenue.value = venue;
            break;
          }
        }
      }

      final editingVenueId = _editingGame?.venueId;
      if (editingVenueId != null) {
        for (final venue in list) {
          if (venue.id == editingVenueId) {
            selectedVenue.value = venue;
            break;
          }
        }
      }
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
      final activeRole =
          (AppStorage.getActiveRole() ?? AppStorage.getUser()?.role ?? '')
              .trim()
              .toLowerCase();

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

      if (isEditing && gameId != null) {
        final patch = _buildUpdatePayload(body);
        if (patch.isEmpty) {
          Get.snackbar(
            'Sin cambios',
            'No hay cambios para actualizar.',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
        if (activeRole == 'coach') {
          await _coachGames.updateGame(
            categoryId: categoryId,
            gameId: gameId!,
            data: patch,
          );
        } else {
          await _managerGames.updateGame(
            categoryId: categoryId,
            gameId: gameId!,
            data: patch,
          );
        }
      } else {
        if (activeRole == 'coach') {
          await _coachGames.createGame(categoryId: categoryId, data: body);
        } else {
          await _managerGames.createGame(categoryId: categoryId, data: body);
        }
      }

      Get.back(result: true);
      Get.snackbar(
        'Éxito',
        isEditing
            ? 'Juego actualizado correctamente'
            : 'Juego creado correctamente',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      final message = _mapCreateError(e);
      Get.snackbar(
        'Error',
        message,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  Map<String, dynamic> _buildUpdatePayload(Map<String, dynamic> fullBody) {
    final game = _editingGame;
    if (game == null) return fullBody;

    final patch = <String, dynamic>{};
    final newOpponent = (fullBody['opponent_name'] ?? '').toString().trim();
    if (newOpponent != game.opponent.trim()) {
      patch['opponent_name'] = newOpponent;
    }

    final newScheduledAt = fullBody['scheduled_at']?.toString();
    final originalScheduledAt = game.startsAt == null
        ? null
        : _formatForApi(game.startsAt!);
    if (newScheduledAt != originalScheduledAt) {
      patch['scheduled_at'] = newScheduledAt;
    }

    final newVenueId = fullBody['venue_id'] as int?;
    if (newVenueId != game.venueId) {
      patch['venue_id'] = newVenueId;
    }

    final newNotesRaw = fullBody['notes'];
    final newNotes = newNotesRaw?.toString().trim();
    final oldNotes = game.notes?.trim();
    if ((newNotes ?? '') != (oldNotes ?? '')) {
      patch['notes'] = (newNotes == null || newNotes.isEmpty) ? null : newNotes;
    }

    if (isHomeTouched.value) {
      patch['is_home'] = isHome.value;
    }

    return patch;
  }

  String _mapCreateError(Object error) {
    if (error is ApiRequestException) {
      return error.message;
    }

    final text = error.toString();
    if (text.startsWith('Exception: ')) {
      return text.replaceFirst('Exception: ', '');
    }
    return 'No se pudo crear el juego.';
  }
}
