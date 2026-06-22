import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/player_full_profile.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/storage/app_storage.dart';

class PlayerFileController extends GetxController {
  final ApiRepository _api = Get.find<ApiRepository>();

  final isLoading = false.obs;
  final error = RxnString();
  final profile = Rxn<OrganizationPlayerFullProfileResponse>();

  late final int? playerId;
  late final String fallbackPlayerName;
  late final String activeRole;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments is Map
        ? Map<String, dynamic>.from(Get.arguments as Map)
        : <String, dynamic>{};
    final idFromPath = int.tryParse((Get.parameters['playerId'] ?? '').trim());
    final idFromArgs = _asInt(args['playerId']);

    activeRole = (AppStorage.getActiveRole() ?? '').trim().toLowerCase();
    playerId = idFromPath ?? idFromArgs ?? AppStorage.getSelectedPlayerId();
    fallbackPlayerName = args['playerName']?.toString() ??
        AppStorage.getSelectedPlayerName() ??
        'Jugador';

    loadProfile();
  }

  Future<void> loadProfile() async {
    if (isLoading.value) return;

    isLoading.value = true;
    error.value = null;

    try {
      profile.value = await _api.fetchOrganizationPlayerFullProfile(
        playerId: playerId,
      );
    } catch (e) {
      error.value = _mapError(e);
    } finally {
      isLoading.value = false;
    }
  }

  OrganizationPlayerFullProfileData? get data => profile.value?.data;
  OrganizationPlayerFullProfileMeta? get meta => profile.value?.meta;

  String get playerDisplayName {
    final loaded = data?.player.fullName.trim() ?? '';
    if (loaded.isNotEmpty) return loaded;
    return fallbackPlayerName.trim().isEmpty ? 'Jugador' : fallbackPlayerName;
  }

  String get viewerRoleLabel {
    final role =
        (meta?.viewerRole.isNotEmpty == true) ? meta!.viewerRole : activeRole;

    switch (role) {
      case 'parent':
        return 'Padre/Madre';
      case 'player':
        return 'Jugador';
      case 'manager':
        return 'Manager';
      case 'admin':
        return 'Administrador';
      case 'superadmin':
        return 'Superadmin';
      default:
        return role.isEmpty ? '-' : role;
    }
  }

  String _mapError(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      final message = _extractApiMessage(error.response?.data);

      if (status == 403) {
        return message ?? 'No tienes permisos para ver este perfil.';
      }
      if (status == 404) {
        return message ?? 'No se encontró el jugador solicitado.';
      }
      if (status == 401) {
        return message ?? 'Tu sesión expiró. Vuelve a iniciar sesión.';
      }
      return message ?? 'No se pudo cargar el perfil del jugador.';
    }

    final text = error.toString();
    if (text.startsWith('Exception: ')) {
      return text.substring('Exception: '.length);
    }
    return text;
  }

  String? _extractApiMessage(dynamic data) {
    if (data is Map && data['message'] != null) {
      return data['message']?.toString();
    }
    return null;
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
