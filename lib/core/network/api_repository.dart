import 'dart:io';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stopandgo/core/config/flavor_config.dart';
import 'package:stopandgo/core/constants/api_endpoints.dart';
import 'package:stopandgo/core/auth/social_auth_result.dart';
import 'package:stopandgo/core/models/admin_player.dart';
import 'package:stopandgo/core/models/category.dart';
import 'package:stopandgo/core/models/checkin_model.dart';
import 'package:stopandgo/core/models/checkin_checkout_request.dart';
import 'package:stopandgo/core/models/checkin_model_response.dart';
import 'package:stopandgo/core/models/checkin_response.dart';
import 'package:stopandgo/core/models/checkin_today_status.dart';
import 'package:stopandgo/core/models/combines/combine_event.dart';
import 'package:stopandgo/core/models/combines/combine_event_results_response.dart';
import 'package:stopandgo/core/models/dashboard_models.dart';
import 'package:stopandgo/core/models/documents_compliance.dart';
import 'package:stopandgo/core/models/dto/notice_model.dart';
import 'package:stopandgo/core/models/dto/payment_dto.dart';
import 'package:stopandgo/core/models/dto/payment_provider_intent_dto.dart';
import 'package:stopandgo/core/models/ecommerce/checkout_result_model.dart';
import 'package:stopandgo/core/models/ecommerce/ecommerce_order_detail_model.dart';
import 'package:stopandgo/core/models/ecommerce/ecommerce_order_list_item_model.dart';
import 'package:stopandgo/core/models/games/game_comment.dart';
import 'package:stopandgo/core/models/games/games.dart';
import 'package:stopandgo/core/models/gazzetta/gazzetta_models.dart';
import 'package:stopandgo/core/models/league/club_league_overview.dart';
import 'package:stopandgo/core/models/league/club_league_roster_models.dart';
import 'package:stopandgo/core/models/league/club_league_tournament_data.dart';
import 'package:stopandgo/core/models/news/news_models.dart';
import 'package:stopandgo/core/models/player_document.dart';
import 'package:stopandgo/core/models/player_file.dart';
import 'package:stopandgo/core/models/player_full_profile.dart';
import 'package:stopandgo/core/models/player_documents_checklist.dart';
import 'package:stopandgo/core/models/players.dart';
import 'package:stopandgo/core/models/players/parents_model.dart';
import 'package:stopandgo/core/models/responses/generic_response.dart';
import 'package:stopandgo/core/models/responses/login_response.dart';
import 'package:stopandgo/core/models/responses/organization_response.dart';
import 'package:stopandgo/core/models/streaming/live_event.dart';
import 'package:stopandgo/core/models/training.dart';
import 'package:stopandgo/core/models/trainings/training_player_response.dart';
import 'package:stopandgo/core/models/trainning_attendance.dart';
import 'package:stopandgo/core/network/gazzetta_exceptions.dart';
import 'package:stopandgo/core/network/paginated_response.dart';
import 'package:stopandgo/core/services/app_usage_session_service.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/core/utils/device_info.dart';
import 'package:stopandgo/core/models/play_book_model.dart';
import 'package:stopandgo/modules/combine_event_detail/combine_event_detail_controller.dart';
import 'package:stopandgo/modules/home/tabs/dashboard/models/dashboard_social_post.dart';
import 'api_client.dart';
import 'token_storage.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;
import '../models/ecommerce/product_category_model.dart';
import '../models/ecommerce/product_model.dart';
import '../models/ecommerce/product_detail_model.dart';
import '../models/ecommerce/product_variant_model.dart';
import '../models/ecommerce/cart_model.dart';

class ApiRepository {
  final Dio _dio = ApiClient.dio;
  final TokenStorage _tokenStorage = Get.find<TokenStorage>();

  /// ---- ORGANIZATION ----
  Future<OrganizationResponse> getOrganization() async {
    final orgId = FlavorConfig.I.organizationId;

    final res = await _dio.get('${ApiEndpoints.organization}/$orgId');

    if (res.statusCode == 200) {
      final orgData = OrganizationResponse.fromJson(res.data['data']);
      await AppStorage.setOrganization(orgData);
      return orgData;
    } else {
      throw Exception('Error ${res.statusCode}: ${res.statusMessage}');
    }
  }

  /// Obtener catálogo público de organizaciones
  Future<List<OrganizationResponse>> getPublicOrganizations() async {
    final res = await _dio.get(ApiEndpoints.publicOrganizations);

    if (res.statusCode == 200) {
      final List data = res.data['data'] ?? [];

      final orgs =
          data.map((json) => OrganizationResponse.fromJson(json)).toList();

      return orgs;
    } else {
      throw Exception('Error ${res.statusCode}: ${res.statusMessage}');
    }
  }

  // ApiRepository.dart (fragmentos relevantes)
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final tokenDevice = AppStorage.getTokenDevice();
      final deviceInfo = await DeviceInfoHelper.getDeviceInfo();
      final organizationId = FlavorConfig.I.organizationId!;

      final res = await _dio.post(
        ApiEndpoints.authLogin,
        data: {
          'email': email,
          'password': password,
          'so': deviceInfo['os'],
          'device_token': tokenDevice,
          'device_name': deviceInfo['device_model'],
          'organization_id': organizationId,
        },
        options: Options(headers: {'Accept': 'application/json'}),
      );

      final loginData = LoginResponse.fromJson(res.data);

      // Guarda sesión completa (access + refresh + expiraciones)
      await _tokenStorage.setSession(
        accessToken: loginData.accessToken,
        tokenType:
            (loginData.tokenType.isNotEmpty ? loginData.tokenType : 'Bearer'),
        refreshToken: loginData.refreshToken,
        refreshExpiresAt: loginData.refreshExpiresAt,
        accessExpiresInMinutes: loginData.accessExpiresInMinutes,
      );

      // Persistir usuario y organización
      await AppStorage.setUser(loginData.user);

      return loginData;
    } on DioException catch (e) {
      // Mensaje más claro para UI
      final msg =
          e.response?.data is Map && (e.response?.data['message'] != null)
              ? e.response?.data['message'].toString()
              : e.message ?? 'Error de red';
      throw Exception('Login fallido: $msg');
    } catch (e) {
      throw Exception('Login fallido: $e');
    }
  }

  Future<LoginResponse> loginWithSocial({
    required SocialAuthResult socialAuth,
    String? activeRole,
  }) async {
    try {
      final tokenDevice = AppStorage.getTokenDevice();
      final deviceInfo = await DeviceInfoHelper.getDeviceInfo();
      final organizationId = FlavorConfig.I.organizationId!;

      final res = await _dio.post(
        ApiEndpoints.authLoginSocial,
        data: {
          'organization_id': organizationId,
          'provider': socialAuth.provider.apiValue,
          'id_token': socialAuth.firebaseIdToken,
          'so': deviceInfo['os'],
          'device_token': tokenDevice,
          'device_name': deviceInfo['device_model'],
          if (activeRole != null && activeRole.trim().isNotEmpty)
            'active_role': activeRole.trim(),
        },
        options: Options(headers: {'Accept': 'application/json'}),
      );

      final loginData = LoginResponse.fromJson(_asMap(res.data));
      await _persistLoginSession(loginData);
      return loginData;
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Login social fallido: $e');
    }
  }

  Future<void> logout({String reason = 'logout'}) async {
    final rt = _tokenStorage.refreshToken;
    try {
      if (Get.isRegistered<AppUsageSessionService>()) {
        await Get.find<AppUsageSessionService>().endSession(reason: reason);
      }
      await _dio.post(
        ApiEndpoints.authLogout,
        data: {if (rt != null && rt.isNotEmpty) 'refresh_token': rt},
        options: Options(headers: {'Accept': 'application/json'}),
      );
    } catch (_) {
    } finally {
      await _tokenStorage.clear();
      await AppStorage.clearAll();
    }
  }

  Future<LoginResponse> registerPublicUserWithSocial({
    required int organizationId,
    required SocialAuthResult socialAuth,
    required String role,
    String? name,
    String? phone,
    String? curp,
    String? birthdate,
    String? activeRole,
  }) async {
    try {
      final tokenDevice = AppStorage.getTokenDevice();
      final deviceInfo = await DeviceInfoHelper.getDeviceInfo();

      final res = await _dio.post(
        ApiEndpoints.authRegisterSocial,
        data: {
          'organization_id': organizationId,
          'provider': socialAuth.provider.apiValue,
          'id_token': socialAuth.firebaseIdToken,
          'role': role,
          if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
          if (curp != null && curp.trim().isNotEmpty) 'curp': curp.trim(),
          if (birthdate != null && birthdate.trim().isNotEmpty)
            'birthdate': birthdate.trim(),
          'so': deviceInfo['os'],
          'device_token': tokenDevice,
          'device_name': deviceInfo['device_model'],
          if (activeRole != null && activeRole.trim().isNotEmpty)
            'active_role': activeRole.trim(),
        },
        options: Options(headers: {'Accept': 'application/json'}),
      );

      final loginData = LoginResponse.fromJson(_asMap(res.data));
      await _persistLoginSession(loginData);
      return loginData;
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Registro social fallido: $e');
    }
  }

  // /player/my-games?player_id=...
  Future<List<Game>> playerMyGamesFromParent({
    int? playerId,
    required String from,
    required String to,
    String? status,
    bool allOrganizationGames = false,
  }) async {
    final params = <String, dynamic>{'from': from, 'to': to};

    if (playerId != null) {
      params['player_id'] = playerId;
    }

    if (status != null) {
      params['status'] = status;
    }
    if (allOrganizationGames) {
      params['all_organization_games'] = true;
    }

    final res = await _dio.get(
      '/player/my-games',
      queryParameters: params,
      options: Options(headers: _headers()),
    );

    final data = res.data['data'];
    return gameDtoListFromData(data);
  }

  Future<List<Game>> playerMyGames({
    required String from,
    required String to,
    String? status,
    bool allOrganizationGames = false,
  }) async {
    final params = <String, dynamic>{'from': from, 'to': to};

    if (status != null) {
      params['status'] = status;
    }
    if (allOrganizationGames) {
      params['all_organization_games'] = true;
    }
    final res = await _dio.get(
      '/player/my-games',
      queryParameters: params,
      options: Options(headers: _headers()),
    );

    final data = res.data['data']; // <- AQUÍ VIENE LA LISTA
    return gameDtoListFromData(data);
  }

  // /manager/{categoryId}/games?from=YYYY-MM-DD&to=YYYY-MM-DD
  Future<List<Game>> managerCategoryGames({
    required int categoryId,
    required String from,
    required String to,
    String? status,
    bool allOrganizationGames = false,
  }) async {
    final params = <String, dynamic>{'from': from, 'to': to};
    if (status != null) {
      params['status'] = status;
    }
    if (allOrganizationGames) {
      params['all_organization_games'] = true;
    }

    final res = await _dio.get(
      '/manager/$categoryId/games',
      queryParameters: params,
      options: Options(headers: _headers()),
    );

    final data = res.data['data'];
    return gameDtoListFromData(data);
  }

  Future<List<Map<String, dynamic>>> managerCategoryPlayers(
    int categoryId,
  ) async {
    final res = await _dio.get(
      '/manager/$categoryId/players',
      options: Options(headers: _headers()),
    );

    final data = res.data;

    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    return [];
  }

  Future<AdminPlayersResponse> getAdminPlayers({
    String? q,
    String active = 'all',
    String confirmed = 'all',
    int? categoryId,
    bool includeArchived = false,
    int perPage = 25,
    int page = 1,
  }) async {
    final res = await _dio.get(
      ApiEndpoints.adminPlayers,
      queryParameters: {
        if (q != null && q.isNotEmpty) 'q': q,
        'active': active,
        'confirmed': confirmed,
        if (categoryId != null) 'category_id': categoryId,
        'include_archived': includeArchived,
        'per_page': perPage,
        'page': page,
      },
      options: Options(headers: _headers()),
    );

    return AdminPlayersResponse.fromJson(Map<String, dynamic>.from(res.data));
  }

  Future<AdminPlayer> updateAdminPlayer({
    required int playerId,
    required Map<String, dynamic> data,
  }) async {
    final res = await _dio.patch(
      '${ApiEndpoints.adminPlayers}/$playerId',
      data: data,
      options: Options(headers: _headers()),
    );

    final payload = Map<String, dynamic>.from(res.data as Map);
    return AdminPlayer.fromJson(Map<String, dynamic>.from(payload['data']));
  }

  /// GET /api/manager/categories
  Future<List<Category>> getManagedCategories({
    int page = 1,
    int perPage = 10,
  }) async {
    final res = await _dio.get(
      '/manager/categories',
      queryParameters: {'page': page, 'per_page': perPage},
      options: Options(headers: _headers()),
    );

    final data = (res.data['data'] as List).cast<Map<String, dynamic>>();
    return data.map((e) => Category.fromJson(e)).toList();
  }

  Future<List<Category>> getMyPlayerCategories() async {
    final res = await _dio.get(
      '/player/my-categories',
      options: Options(headers: _headers()),
    );
    final data = (res.data as List).cast<Map<String, dynamic>>();

    return data.map((e) => Category.fromJson(e)).toList();
  }

  Future<List<Category>> getCoachCategories() async {
    final res = await _dio.get(
      '/coach/categories',
      options: Options(headers: _headers()),
    );

    final body = res.data as Map<String, dynamic>;
    final list = (body['data'] as List).cast<Map<String, dynamic>>();

    return list.map((e) => Category.fromJson(e)).toList();
  }

  Future<List<Game>> getCoachCategoryGames({
    required int categoryId,
    required String from,
    required String to,
    String? status,
    bool allOrganizationGames = false,
  }) async {
    final params = <String, dynamic>{'from': from, 'to': to};
    if (status != null) {
      params['status'] = status;
    }
    if (allOrganizationGames) {
      params['all_organization_games'] = true;
    }

    final res = await _dio.get(
      '/coach/categories/$categoryId/games',
      queryParameters: params,
      options: Options(headers: _headers()),
    );

    final data = res.data['data'];
    return gameDtoListFromData(data);
  }

  Future<List<Training>> getCoachCategoryTrainings({
    required int categoryId,
    DateTime? from,
    DateTime? to,
    String? status,
  }) async {
    final res = await _dio.get(
      '/coach/categories/$categoryId/trainings',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (from != null) 'from': _dateOnly(from),
        if (to != null) 'to': _dateOnly(to),
      },
      options: Options(headers: _headers()),
    );

    final data = (res.data['data'] as List?) ?? [];
    return data
        .map((e) => Training.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // player: /player/my-payments?player_id=X  (usa res.data['data'])
  Future<List<PaymentDto>> playerMyPayments({required int playerId}) async {
    final res = await _dio.get(
      '/player/my-payments',
      queryParameters: {'player_id': playerId},
      options: Options(headers: _headers()),
    );
    final data = (res.data['data'] as List?) ?? const [];
    return data
        .map((e) => PaymentDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<PaymentDto>> myPayments() async {
    final res = await _dio.get(
      '/player/my-payments',
      options: Options(headers: _headers()),
    );
    final data = (res.data['data'] as List?) ?? const [];
    return data
        .map((e) => PaymentDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // manager: /manager/{categoryId}/payments (usa res.data['data'])
  Future<List<PaymentDto>> managerCategoryPayments({
    required int categoryId,
  }) async {
    final res = await _dio.get(
      '/manager/$categoryId/payments',
      options: Options(headers: _headers()),
    );
    final data = (res.data['data'] as List?) ?? const [];
    final list = data
        .map((e) => PaymentDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    list.sort((a, b) => b.id.compareTo(a.id));

    return list;
  }

  // PLAYER/PARENT: /player/home  -> tomar last_notice (si existe)
  Future<Map<String, dynamic>?> playerLastNotice() async {
    final res = await _dio.get(
      '/player/home',
      options: Options(headers: _headers()),
    );
    final map = Map<String, dynamic>.from(res.data as Map);
    if (map['last_notice'] == null) return null;
    return Map<String, dynamic>.from(map['last_notice'] as Map);
  }

  // MANAGER: /manager/notices -> usar res.data['data'] (lista)
  Future<List<Notice>> managerNotices() async {
    final res = await _dio.get(
      '/manager/notices',
      options: Options(headers: _headers()),
    );
    final data = (res.data['data'] as List?) ?? const [];

    return data
        .map((e) => Notice.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> createPlayerReceipt({
    required int paymentId,
    required double amount,
    required String method,
    String? reference,
    required String paidAtYmd,
    required String filePath,
  }) async {
    final form = FormData.fromMap({
      'amount': amount,
      'method': method,
      if (reference != null && reference.isNotEmpty) 'reference': reference,
      'paid_at': paidAtYmd,
      'file': await MultipartFile.fromFile(filePath),
    });

    final res = await _dio.post(
      '/player/my-payments/$paymentId/createReceipt',
      data: form,
      options: Options(headers: _headers()),
    );

    if (res.statusCode != 201) {
      throw Exception('Error ${res.statusCode}: ${res.statusMessage}');
    }
  }

  Future<GenericResponse> createGame(
    int categoryId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await managerCreateGameRequest(
        categoryId: categoryId,
        data: data,
      );
      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        return GenericResponse.fromJson(raw);
      }
      if (raw is Map) {
        return GenericResponse.fromJson(Map<String, dynamic>.from(raw));
      }
      return GenericResponse(
        success: true,
        message: 'Juego creado correctamente.',
      );
    } on DioException catch (e) {
      final msg =
          e.response?.data?['message'] ?? e.message ?? 'Error desconocido';
      throw Exception('Error al crear el juego: $msg');
    } catch (e) {
      throw Exception('Error inesperado al crear el juego: $e');
    }
  }

  Future<GenericResponse> completeGame({
    required int categoryId,
    required int gameId,
    required int homeScore,
    required int opponentScore,
    required File evidenceFile,
  }) async {
    final form = FormData.fromMap({
      'game_id': gameId,
      'home_score': homeScore,
      'opponent_score': opponentScore,
      'evidece': await MultipartFile.fromFile(
        evidenceFile.path,
        filename: evidenceFile.uri.pathSegments.last,
      ),
    });

    try {
      final res = await _dio.post(
        '/manager/$categoryId/games/complete',
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (res.data is Map<String, dynamic>) {
        return GenericResponse.fromJson(res.data as Map<String, dynamic>);
      }
      return GenericResponse(
        success: false,
        message: 'Respuesta inesperada del servidor',
      );
    } on DioException catch (e) {
      final payload = e.response?.data;
      if (payload is Map<String, dynamic>) {
        // La API suele devolver {success:false, message:"..."} en errores controlados
        return GenericResponse.fromJson(payload);
      }
      final msg = e.message ?? 'Error al completar juego';
      return GenericResponse(success: false, message: msg);
    } catch (e) {
      return GenericResponse(success: false, message: 'Error inesperado: $e');
    }
  }

  ////////

  String? get _accessToken => _tokenStorage.accessToken;
  String get _tokenType => _tokenStorage.tokenType;

  Map<String, dynamic> get _authHeader => _accessToken == null
      ? {}
      : {'Authorization': '$_tokenType $_accessToken'};

  Map<String, dynamic> get _orgHeader {
    final org = AppStorage.getOrganization();
    return org == null ? {} : {'X-Organization-Id': org.id.toString()};
  }

  Map<String, dynamic> _headers([Map<String, dynamic>? extra]) => {
        ..._authHeader,
        ..._orgHeader,
        'Accept': 'application/json',
        if (extra != null) ...extra,
      };

  /// GET /api/home/dashboard (ejemplo)
  /// Puedes ajustar a tu ruta real: /api/player/home, etc.
  /// Acepta filter_category_id opcional
  Future<Map<String, dynamic>> getHomeDashboard({int? filterCategoryId}) async {
    final res = await _dio.get(
      '/home/dashboard',
      queryParameters: {
        if (filterCategoryId != null) 'filter_category_id': filterCategoryId,
      },
      options: Options(headers: _headers()),
    );
    // Devuelve el json crudo; puedes crear un modelo si quieres tiparlo
    return (res.data as Map<String, dynamic>);
  }

  Future<List<Map<String, dynamic>>> parentMyPlayers() async {
    final res = await _dio.get('/player/my-players');
    final data = (res.data['data'] as List).cast<Map<String, dynamic>>();
    return data;
  }

  /// Parent/Player: dashboard general (no por player específico)
  Future<Map<String, dynamic>> playerHomeDashboard() async {
    final res = await _dio.get('/player/home');
    return (res.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> managerCategoryDashboard(int categoryId) async {
    final res = await _dio.get(
      '/manager/$categoryId/dashboard',
      options: Options(headers: _headers()),
    );
    return (res.data as Map<String, dynamic>);
  }

  /// ---- ACCOUNT / PERFIL ----

  /// GET /account
  Future<Map<String, dynamic>> getAccount() async {
    final res = await _dio.get(
      '/account',
      options: Options(headers: _headers()),
    );

    if (res.data is Map<String, dynamic>) {
      return Map<String, dynamic>.from(res.data as Map);
    }

    throw Exception('Respuesta inesperada al obtener cuenta');
  }

  Future<ClubLeagueOverviewResponse> getClubLeagueOverview() async {
    final res = await _dio.get(
      ApiEndpoints.clubLeagueOverview,
      options: Options(headers: _headers()),
    );

    final payload = res.data;
    if (payload is! Map<String, dynamic>) {
      throw Exception('Respuesta inesperada al obtener torneos');
    }

    final data = payload['data'];
    final rawOverview = data is Map<String, dynamic> ? data : payload;

    return ClubLeagueOverviewResponse.fromJson(rawOverview);
  }

  Future<ClubLeagueTournamentStandingsResponse>
      getClubLeagueTournamentStandings(int tournamentId,
          {int? clubLinkId}) async {
    final res = await _dio.get(
      '${ApiEndpoints.clubLeague}/tournaments/$tournamentId/standings',
      queryParameters: {if (clubLinkId != null) 'club_link_id': clubLinkId},
      options: Options(headers: _headers()),
    );

    final payload = res.data;
    if (payload is! Map<String, dynamic>) {
      throw Exception('Respuesta inesperada al obtener standings');
    }

    final data = payload['data'];
    final rawData = data is Map<String, dynamic> ? data : payload;

    return ClubLeagueTournamentStandingsResponse.fromJson(rawData);
  }

  Future<ClubLeagueTournamentFixturesResponse> getClubLeagueTournamentFixtures(
    int tournamentId, {
    int? clubLinkId,
  }) async {
    final res = await _dio.get(
      '${ApiEndpoints.clubLeague}/tournaments/$tournamentId/fixtures',
      queryParameters: {if (clubLinkId != null) 'club_link_id': clubLinkId},
      options: Options(headers: _headers()),
    );

    final payload = res.data;
    if (payload is! Map<String, dynamic>) {
      throw Exception('Respuesta inesperada al obtener fixtures');
    }

    final data = payload['data'];
    final rawData = data is Map<String, dynamic> ? data : payload;

    return ClubLeagueTournamentFixturesResponse.fromJson(rawData);
  }

  Future<ClubLeagueTeamDetailResponse> getClubLeagueTeamDetail(
    int clubLinkId,
  ) async {
    final res = await _dio.get(
      '${ApiEndpoints.clubLeague}/teams/$clubLinkId',
      options: Options(headers: _headers()),
    );

    final payload = res.data;
    if (payload is! Map<String, dynamic>) {
      throw Exception('Respuesta inesperada al obtener equipo competitivo');
    }

    final data = payload['data'];
    final rawData = data is Map<String, dynamic> ? data : payload;
    return ClubLeagueTeamDetailResponse.fromJson(rawData);
  }

  Future<ClubLeagueRosterSourceResponse> getClubLeagueRosterSource(
    int clubLinkId, {
    int? categoryId,
    int? tournamentId,
    int? divisionId,
    int? subDivisionId,
  }) async {
    final res = await _dio.get(
      '${ApiEndpoints.clubLeague}/teams/$clubLinkId/roster-source',
      queryParameters: {
        if (categoryId != null) 'category_id': categoryId,
        if (tournamentId != null) 'tournament_id': tournamentId,
        if (divisionId != null) 'division_id': divisionId,
        if (subDivisionId != null) 'sub_division_id': subDivisionId,
      },
      options: Options(headers: _headers()),
    );

    final payload = res.data;
    if (payload is! Map<String, dynamic>) {
      throw Exception('Respuesta inesperada al obtener roster elegible');
    }

    final data = payload['data'];
    final rawData = data is Map<String, dynamic> ? data : payload;
    return ClubLeagueRosterSourceResponse.fromJson(rawData);
  }

  Future<ClubLeagueRosterEntriesResponse> getClubLeagueRosterEntries(
    int tournamentId,
    int clubLinkId, {
    int? divisionId,
    int? subDivisionId,
  }) async {
    final res = await _dio.get(
      '${ApiEndpoints.clubLeague}/tournaments/$tournamentId/teams/$clubLinkId/roster-entries',
      queryParameters: {
        if (divisionId != null) 'division_id': divisionId,
        if (subDivisionId != null) 'sub_division_id': subDivisionId,
      },
      options: Options(headers: _headers()),
    );

    final payload = res.data;
    if (payload is! Map<String, dynamic>) {
      throw Exception('Respuesta inesperada al obtener roster enviado');
    }

    final data = payload['data'];
    final rawData = data is Map<String, dynamic> ? data : payload;
    return ClubLeagueRosterEntriesResponse.fromJson(rawData);
  }

  Future<ClubLeagueRosterSyncResponse> syncClubLeagueRosterEntries(
    int tournamentId,
    int clubLinkId, {
    int? categoryId,
    required int divisionId,
    int? subDivisionId,
    required List<Map<String, dynamic>> players,
  }) async {
    try {
      final res = await _dio.put(
        '${ApiEndpoints.clubLeague}/tournaments/$tournamentId/teams/$clubLinkId/roster-entries/sync',
        data: {
          if (categoryId != null) 'category_id': categoryId,
          'division_id': divisionId,
          if (subDivisionId != null) 'sub_division_id': subDivisionId,
          'players': players,
        },
        options: Options(headers: _headers()),
      );

      final payload = res.data;
      if (payload is! Map<String, dynamic>) {
        throw Exception('Respuesta inesperada al enviar roster');
      }

      final data = payload['data'];
      final rawData = data is Map<String, dynamic> ? data : payload;
      return ClubLeagueRosterSyncResponse.fromJson(rawData);
    } on DioException catch (e) {
      final payload = e.response?.data;
      final message = payload is Map && payload['message'] != null
          ? payload['message'].toString()
          : e.message ?? 'No se pudo enviar el roster';
      throw Exception(message);
    }
  }

  /// PUT /account
  Future<Map<String, dynamic>> updateAccount({
    required String name,
    required String email,
    String? role,
    String? phone,
    String? curp,
    String? birthdate,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name.trim(),
        'email': email.trim(),
        if (role != null && role.isNotEmpty) 'role': role,
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (curp != null && curp.trim().isNotEmpty) 'curp': curp.trim(),
        if (birthdate != null && birthdate.trim().isNotEmpty)
          'birthdate': birthdate.trim(),
      };

      final res = await _dio.put(
        '/account',
        data: body,
        options: Options(headers: _headers()),
      );

      if (res.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(res.data as Map);
      }

      throw Exception('Respuesta inesperada al actualizar perfil');
    } on DioException catch (e) {
      final payload = e.response?.data;
      String msg = 'Error al actualizar perfil';

      if (payload is Map && payload['message'] != null) {
        msg = payload['message'].toString();
      } else if (e.message != null) {
        msg = e.message!;
      }

      throw Exception(msg);
    } catch (e) {
      throw Exception('Error inesperado al actualizar perfil: $e');
    }
  }

  /// POST /account/photo
  Future<Map<String, dynamic>> updateAccountPhoto({
    required String filePath,
  }) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        throw Exception('La imagen seleccionada no existe.');
      }

      final filename = file.uri.pathSegments.isNotEmpty
          ? file.uri.pathSegments.last
          : 'profile_photo.jpg';

      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(filePath, filename: filename),
      });

      final res = await _dio.post(
        ApiEndpoints.accountPhoto,
        data: formData,
        options: Options(
          headers: _headers(),
          contentType: 'multipart/form-data',
        ),
      );

      if (res.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(res.data as Map);
      }

      throw Exception('Respuesta inesperada al actualizar foto de perfil');
    } on DioException catch (e) {
      final payload = e.response?.data;
      String msg = 'Error al actualizar foto de perfil';

      if (payload is Map && payload['message'] != null) {
        msg = payload['message'].toString();
      } else if (e.message != null) {
        msg = e.message!;
      }

      throw Exception(msg);
    } catch (e) {
      throw Exception('Error inesperado al actualizar foto de perfil: $e');
    }
  }

  /// PUT /account/password
  Future<void> updateAccountPassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final body = {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': confirmPassword,
      };

      await _dio.put(
        '/account/password',
        data: body,
        options: Options(headers: _headers()),
      );
    } on DioException catch (e) {
      final payload = e.response?.data;
      String msg = 'Error al cambiar contraseña';

      if (payload is Map && payload['message'] != null) {
        msg = payload['message'].toString();
      } else if (e.message != null) {
        msg = e.message!;
      }

      throw Exception(msg);
    } catch (e) {
      throw Exception('Error inesperado al cambiar contraseña: $e');
    }
  }

  /// DELETE /account/delete
  Future<void> deleteAccount() async {
    try {
      await _dio.delete(
        '/account/delete',
        options: Options(headers: _headers()),
      );
    } on DioException catch (e) {
      final payload = e.response?.data;
      String msg = 'Error al eliminar cuenta';

      if (payload is Map && payload['message'] != null) {
        msg = payload['message'].toString();
      } else if (e.message != null) {
        msg = e.message!;
      }

      throw Exception(msg);
    } catch (e) {
      throw Exception('Error inesperado al eliminar cuenta: $e');
    }
  }

  /// ---- PLAYERS ----

  /// Players visibles para MANAGER (por categorías asignadas)
  Future<List<dynamic>> managerPlayers() async {
    final res = await _dio.get('/manager/players');
    return (res.data as List).toList();
  }

  /// Players visibles para PARENT (por father_email / mother_email)
  Future<List<dynamic>> parentPlayers() async {
    final res = await _dio.get('/parent/players');
    return (res.data as List).toList();
  }

  /// ---- PAYMENTS ----

  Future<List<dynamic>> managerPayments() async {
    final res = await _dio.get('/manager/payments');
    return (res.data as List).toList();
  }

  /// Jugadores disponibles para enrolar en una categoría
  /// GET /manager/{categoryId}/playersForEnroll
  Future<List<Player>> managerPlayersForEnroll({
    required int categoryId,
  }) async {
    final res = await _dio.get(
      '/manager/$categoryId/playersForEnroll',
      options: Options(headers: _headers()),
    );

    final data = (res.data['data'] as List?) ?? const [];
    return data
        .map((e) => Player.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Enrolar jugador en una categoría
  /// POST /manager/{categoryId}/enrollPlayer
  ///
  /// body esperado:
  /// {
  ///   "player_id": 1,
  ///   "jersey_number": "12",
  ///   "is_captain": false
  /// }
  Future<GenericResponse> enrollPlayer({
    required int categoryId,
    required Map<String, dynamic> body,
  }) async {
    try {
      final res = await _dio.post(
        '/manager/$categoryId/enrollPlayer',
        data: body,
        options: Options(headers: _headers()),
      );

      if (res.statusCode == 201) {
        return GenericResponse(
          success: true,
          message: 'Jugador enrolado correctamente',
        );
      } else {
        return GenericResponse(
          success: false,
          message: res.statusMessage ?? "",
        );
      }
    } on DioException catch (e) {
      final payload = e.response?.data;
      if (payload is Map<String, dynamic>) {
        return GenericResponse.fromJson(payload);
      }
      final msg = e.message ?? 'Error al enrolar jugador';
      return GenericResponse(success: false, message: msg);
    } catch (e) {
      return GenericResponse(
        success: false,
        message: 'Error inesperado al enrolar jugador: $e',
      );
    }
  }

  Future<List<Training>> managerCategoryTrainings({
    required int categoryId,
    DateTime? from,
    DateTime? to,
    String? status,
  }) async {
    final res = await _dio.get(
      '/manager/$categoryId/trainings',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (from != null) 'from': _dateOnly(from), // yyyy-MM-dd
        if (to != null) 'to': _dateOnly(to), // yyyy-MM-dd
      },
      options: Options(headers: _headers()),
    );

    final data = (res.data['data'] as List?) ?? [];

    return data
        .map((e) => Training.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  String _dateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<Map<String, dynamic>> createTraining({
    required int categoryId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final res = await managerCreateTrainingRequest(
        categoryId: categoryId,
        data: data,
      );

      if (res.statusCode == 201) {
        return {
          'success': true,
          'message': 'Entrenamiento creado correctamente.',
        };
      } else {
        return {'success': false, 'message': 'Error al crear entrenamiento'};
      }
    } on DioException catch (e) {
      final payload = e.response?.data;
      if (payload is Map<String, dynamic>) {
        return Map<String, dynamic>.from(payload);
      }
      return {
        'success': false,
        'message': e.message ?? 'Error al crear entrenamiento',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error inesperado: $e'};
    }
  }

  Future<Response<dynamic>> managerCreateGameRequest({
    required int categoryId,
    required Map<String, dynamic> data,
  }) {
    return _dio.post(
      '/manager/$categoryId/games/create',
      data: data,
      options: Options(headers: _headers()),
    );
  }

  Future<Response<dynamic>> managerUpdateGameRequest({
    required int categoryId,
    required int gameId,
    required Map<String, dynamic> data,
  }) {
    return _dio.put(
      '/manager/$categoryId/games/$gameId',
      data: data,
      options: Options(headers: _headers()),
    );
  }

  Future<Response<dynamic>> managerCreateTrainingRequest({
    required int categoryId,
    required Map<String, dynamic> data,
  }) {
    return _dio.post(
      '/manager/$categoryId/trainings',
      data: data,
      options: Options(headers: _headers()),
    );
  }

  Future<Response<dynamic>> managerUpdateTrainingRequest({
    required int categoryId,
    required int trainingId,
    required Map<String, dynamic> data,
  }) {
    return _dio.put(
      '/manager/$categoryId/trainings/$trainingId',
      data: data,
      options: Options(headers: _headers()),
    );
  }

  Future<Response<dynamic>> coachCreateGameRequest({
    required int categoryId,
    required Map<String, dynamic> data,
  }) {
    return _dio.post(
      '/coach/categories/$categoryId/games',
      data: data,
      options: Options(headers: _headers()),
    );
  }

  Future<Response<dynamic>> coachUpdateGameRequest({
    required int categoryId,
    required int gameId,
    required Map<String, dynamic> data,
  }) {
    return _dio.put(
      '/coach/categories/$categoryId/games/$gameId',
      data: data,
      options: Options(headers: _headers()),
    );
  }

  Future<Response<dynamic>> coachCreateTrainingRequest({
    required int categoryId,
    required Map<String, dynamic> data,
  }) {
    return _dio.post(
      '/coach/categories/$categoryId/trainings',
      data: data,
      options: Options(headers: _headers()),
    );
  }

  Future<Response<dynamic>> coachUpdateTrainingRequest({
    required int categoryId,
    required int trainingId,
    required Map<String, dynamic> data,
  }) {
    return _dio.put(
      '/coach/categories/$categoryId/trainings/$trainingId',
      data: data,
      options: Options(headers: _headers()),
    );
  }

  /// Registrar abono; payload puede ser FormData si subes archivo
  Future<void> markPaymentPaid({
    required int paymentId,
    required Map<String, dynamic> data,
  }) async {
    await _dio.put('/manager/payments/$paymentId/mark-paid', data: data);
  }

  //GAMES

  Future<List<Player>> getGamePlayers({required int categoryId}) async {
    final res = await _dio.get('/manager/$categoryId/players');
    final data = res.data;

    if (data is Map && data['data'] is List) {
      final list = data['data'] as List;
      return list
          .map((e) => Player.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return [];
  }

  Future<PlayerPositionsCatalog> getCategoryPlayerPositions({
    required int categoryId,
  }) async {
    final res = await _dio.get(
      '/categories/$categoryId/player-positions',
      options: Options(headers: _headers()),
    );

    final body = Map<String, dynamic>.from(res.data as Map? ?? const {});
    final rawList =
        (body['data'] ?? body['positions'] ?? body['items']) as List?;
    final allowsCustom = body['allows_custom_position'] == true ||
        body['meta'] is Map &&
            (body['meta'] as Map)['allows_custom_position'] == true;

    final options = (rawList ?? const [])
        .whereType<Map>()
        .map((e) => PlayerPositionOption.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.id > 0 && e.label.trim().isNotEmpty && e.active)
        .toList();

    return PlayerPositionsCatalog(
      options: options,
      allowsCustomPosition: allowsCustom,
    );
  }

  Future<bool> updateCategoryPlayerPosition({
    required int categoryId,
    required int playerId,
    int? positionId,
    String? position,
  }) async {
    final payload = <String, dynamic>{
      'position_id': positionId,
      'position': position,
    };

    final res = await _dio.patch(
      '/categories/$categoryId/players/$playerId/position',
      data: payload,
      options: Options(headers: _headers()),
    );

    return res.statusCode == 200 || res.statusCode == 201;
  }

  // Guardar asistencia BULK (juego o entrenamiento)
  Future<bool> managerAttendanceBulk({
    required int categoryId,
    required List<Map<String, dynamic>> items,
  }) async {
    final res = await _dio.post(
      '/manager/$categoryId/attendances/bulk',
      data: {'items': items},
    );

    return res.statusCode == 200;
  }

  Future<bool> coachAttendanceBulk({
    required int categoryId,
    required List<Map<String, dynamic>> items,
  }) async {
    final res = await _dio.post(
      '/coach/categories/$categoryId/attendances/bulk',
      data: {'items': items},
      options: Options(headers: _headers()),
    );

    return res.statusCode == 200;
  }

  Future<Map<String, dynamic>> registerPublicUser({
    required int organizationId,
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final res = await _dio.post(
        '/public/organization/$organizationId/register',
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
          'role': role,
        },
      );

      final data = res.data;
      return data is Map<String, dynamic> ? data : {'success': true};
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return data; // p.ej. {success:false,message:'...'}
      }
      return {'success': false, 'message': e.message ?? 'Error en registro'};
    } catch (e) {
      return {'success': false, 'message': 'Error inesperado: $e'};
    }
  }

  Future<void> _persistLoginSession(LoginResponse loginData) async {
    await _tokenStorage.setSession(
      accessToken: loginData.accessToken,
      tokenType:
          loginData.tokenType.isNotEmpty ? loginData.tokenType : 'Bearer',
      refreshToken: loginData.refreshToken,
      refreshExpiresAt: loginData.refreshExpiresAt,
      accessExpiresInMinutes: loginData.accessExpiresInMinutes,
    );
    await AppStorage.setUser(loginData.user);
  }

  Future<void> uploadReceipt({
    required int paymentId,
    required String filePath,
    required double amount,
    required String paidAtIso,
    String method = 'transfer',
    String? reference,
  }) async {
    final form = FormData.fromMap({
      'amount': amount,
      'paid_at': paidAtIso,
      'method': method,
      if (reference != null) 'reference': reference,
      'file': await MultipartFile.fromFile(filePath),
    });

    await _dio.put('/manager/payments/$paymentId/mark-paid', data: form);
  }

  Future<void> updatePlayerPhoto({
    required int categoryId,
    required int playerId,
    required String filePath,
  }) async {
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(
        filePath,
        filename: 'player_$playerId.jpg',
      ),
    });

    await _dio.post(
      '/manager/$categoryId/players/$playerId/photo',
      data: formData,
    );
  }

  /// ---- NOTICES ----

  Future<List<dynamic>> notices() async {
    final res = await _dio.get('/notices');
    return (res.data as List).toList();
  }

  /// Ejemplo de creación con adjunto
  Future<Map<String, dynamic>> createNotice({
    required String title,
    String? message,
    bool isPublished = true,
    String? publishedAtIso,
    String? attachmentPath,
    int? categoryId,
  }) async {
    final map = <String, dynamic>{
      'title': title,
      if (message != null) 'message': message,
      'is_published': isPublished ? 1 : 0,
      if (publishedAtIso != null) 'published_at': publishedAtIso,
      if (categoryId != null) 'category_id': categoryId,
    };

    FormData data;
    if (attachmentPath != null) {
      data = FormData.fromMap({
        ...map,
        'attachment': await MultipartFile.fromFile(attachmentPath),
      });
    } else {
      data = FormData.fromMap(map);
    }

    final res = await _dio.post('/manager/notices', data: data);
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Notice> createManagerCategoryNotice({
    required int categoryId,
    required String title,
    required String message,
    String? externalUrl,
    int? seasonId,
    bool isPublished = true,
    bool pinned = false,
    DateTime? publishedAt,
    DateTime? expiresAt,
    String? attachmentPath,
  }) async {
    return _createCategoryNotice(
      endpoint: '/manager/$categoryId/notices',
      title: title,
      message: message,
      externalUrl: externalUrl,
      seasonId: seasonId,
      isPublished: isPublished,
      pinned: pinned,
      publishedAt: publishedAt,
      expiresAt: expiresAt,
      attachmentPath: attachmentPath,
    );
  }

  Future<Notice> createCoachCategoryNotice({
    required int categoryId,
    required String title,
    required String message,
    String? externalUrl,
    int? seasonId,
    bool isPublished = true,
    bool pinned = false,
    DateTime? publishedAt,
    DateTime? expiresAt,
    String? attachmentPath,
  }) async {
    return _createCategoryNotice(
      endpoint: '/coach/categories/$categoryId/notices',
      title: title,
      message: message,
      externalUrl: externalUrl,
      seasonId: seasonId,
      isPublished: isPublished,
      pinned: pinned,
      publishedAt: publishedAt,
      expiresAt: expiresAt,
      attachmentPath: attachmentPath,
    );
  }

  Future<Notice> _createCategoryNotice({
    required String endpoint,
    required String title,
    required String message,
    String? externalUrl,
    int? seasonId,
    required bool isPublished,
    required bool pinned,
    DateTime? publishedAt,
    DateTime? expiresAt,
    String? attachmentPath,
  }) async {
    final payload = <String, dynamic>{
      'title': title.trim(),
      'message': message.trim(),
      if (externalUrl != null && externalUrl.trim().isNotEmpty)
        'external_url': externalUrl.trim(),
      'is_published': isPublished,
      'pinned': pinned,
      if (seasonId != null) 'season_id': seasonId,
      if (publishedAt != null) 'published_at': publishedAt.toIso8601String(),
      if (expiresAt != null) 'expires_at': expiresAt.toIso8601String(),
    };

    final hasAttachment =
        attachmentPath != null && attachmentPath.trim().isNotEmpty;

    final data = hasAttachment
        ? FormData.fromMap({
            ...payload,
            // Laravel boolean en multipart suele aceptar 1/0 (o '1'/'0').
            'is_published': isPublished ? '1' : '0',
            'pinned': pinned ? '1' : '0',
            'attachment': await MultipartFile.fromFile(attachmentPath.trim()),
          })
        : payload;

    Response<dynamic> res;
    try {
      res = await _dio.post(
        endpoint,
        data: data,
        options: Options(headers: _headers()),
      );
    } on DioException catch (e) {
      throw Exception(_extractDioMessage(e));
    }

    final raw = res.data;
    if (raw is Map<String, dynamic>) {
      final nested = raw['data'];
      if (nested is Map) {
        return Notice.fromJson(Map<String, dynamic>.from(nested));
      }
      return Notice.fromJson(raw);
    }
    if (raw is Map) {
      return Notice.fromJson(Map<String, dynamic>.from(raw));
    }
    throw Exception('Respuesta inesperada al crear aviso');
  }

  String _extractDioMessage(DioException e) {
    final data = e.response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }

      final errors = data['errors'];
      if (errors is Map) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            final first = value.first?.toString();
            if (first != null && first.trim().isNotEmpty) {
              return first.trim();
            }
          }
        }
      }
    } else if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final message = map['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    } else if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    final status = e.response?.statusCode;
    if (status == 422) {
      return 'Datos inválidos para crear el aviso. Revisa los campos e intenta de nuevo.';
    }
    return e.message ?? 'No se pudo crear el aviso.';
  }

  Future<void> completeTraining(int trainingId, int categoryId) async {
    try {
      await _dio.post('/manager/$categoryId/trainings/$trainingId/complete');
    } on DioException catch (e) {
      // Error devuelto por el servidor
      if (e.response != null) {
        final msg = e.response?.data['message'] ?? 'Ocurrió un error.';
        throw Exception(msg);
      }

      // Error de red / conexión
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('La solicitud tardó demasiado. Inténtalo de nuevo.');
      }

      throw Exception('No se pudo conectar con el servidor.');
    }
  }

  Future<List<TrainingAttendanceItem>> getTrainningAttendance(
    int trainingId,
    int categoryId,
  ) async {
    try {
      final response = await _dio.get(
        '/manager/$categoryId/trainings/$trainingId/attendance',
      );
      final data = response.data['data'] as List<dynamic>;
      return data.map((json) => TrainingAttendanceItem.fromJson(json)).toList();
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data['message'] ?? 'Ocurrió un error.';
        throw Exception(msg);
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('La solicitud tardó demasiado. Inténtalo de nuevo.');
      }

      throw Exception('No se pudo conectar con el servidor.');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  Future<List<TrainingAttendanceItem>> getCoachTrainningAttendance(
    int trainingId,
    int categoryId,
  ) async {
    try {
      final response = await _dio.get(
        '/coach/categories/$categoryId/trainings/$trainingId/attendance',
        options: Options(headers: _headers()),
      );
      final data = response.data['data'] as List<dynamic>;
      return data.map((json) => TrainingAttendanceItem.fromJson(json)).toList();
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data['message'] ?? 'Ocurrió un error.';
        throw Exception(msg);
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('La solicitud tardó demasiado. Inténtalo de nuevo.');
      }

      throw Exception('No se pudo conectar con el servidor.');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  Future<void> updateTrainingAttendance({
    required int categoryId,
    required int trainingId,
    required int attendanceId,
    required String status,
    required int minutesLate,
    String? notes,
  }) async {
    try {
      await _dio.put(
        '/manager/$categoryId/trainings/$trainingId/attendance/$attendanceId',
        data: {'status': status, 'minutes_late': minutesLate, 'notes': notes},
      );
    } on DioException catch (e) {
      // Error devuelto por el backend
      if (e.response != null) {
        final msg = e.response?.data['message'] ?? 'Ocurrió un error.';
        throw Exception(msg);
      }

      // Timeouts o desconexión
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('La solicitud tardó demasiado. Inténtalo de nuevo.');
      }

      throw Exception('No se pudo conectar con el servidor.');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  Future<void> updateCoachTrainingAttendance({
    required int categoryId,
    required int trainingId,
    required int attendanceId,
    required String status,
    required int minutesLate,
    String? notes,
  }) async {
    try {
      await _dio.put(
        '/coach/categories/$categoryId/trainings/$trainingId/attendance/$attendanceId',
        data: {'status': status, 'minutes_late': minutesLate, 'notes': notes},
        options: Options(headers: _headers()),
      );
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data['message'] ?? 'Ocurrió un error.';
        throw Exception(msg);
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('La solicitud tardó demasiado. Inténtalo de nuevo.');
      }

      throw Exception('No se pudo conectar con el servidor.');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  Future<List<PlayerDocument>> getPlayerDocuments(int playerId) async {
    final activeRole = AppStorage.getActiveRole()?.trim().toLowerCase();
    final response = await _dio.get(
      '/player/$playerId/documents',
      options: Options(
        headers: _headers({
          if (activeRole != null && activeRole.isNotEmpty)
            'X-Active-Role': activeRole,
        }),
      ),
    );

    final data = response.data['data'] as List<dynamic>? ?? [];

    return data
        .whereType<Map>()
        .map((item) => PlayerDocument.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<PlayerDocumentsChecklist> getPlayerDocumentsChecklist(
    int playerId,
  ) async {
    final activeRole = AppStorage.getActiveRole()?.trim().toLowerCase();
    final response = await _dio.get(
      '/player/$playerId/documents/checklist',
      options: Options(
        headers: _headers({
          if (activeRole != null && activeRole.isNotEmpty)
            'X-Active-Role': activeRole,
        }),
      ),
    );

    final map = response.data['data'] is Map
        ? Map<String, dynamic>.from(response.data['data'] as Map)
        : Map<String, dynamic>.from(response.data as Map);

    return PlayerDocumentsChecklist.fromJson(map);
  }

  Future<PlayerDocument> uploadPlayerDocument({
    required int playerId,
    required File file,
    int? requiredDocumentId,
  }) async {
    final activeRole = AppStorage.getActiveRole()?.trim().toLowerCase();
    final fileName = file.path.split('/').last;

    final formData = FormData.fromMap({
      if (requiredDocumentId != null)
        'required_document_id': requiredDocumentId,
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });

    final response = await _dio.post(
      '/player/$playerId/documents',
      data: formData,
      options: Options(
        headers: _headers({
          if (activeRole != null && activeRole.isNotEmpty)
            'X-Active-Role': activeRole,
        }),
        contentType: 'multipart/form-data',
      ),
    );

    final rawDoc = response.data['document'] ?? response.data['data'];
    final docJson =
        rawDoc is Map ? Map<String, dynamic>.from(rawDoc) : <String, dynamic>{};
    return PlayerDocument.fromJson(docJson);
  }

  Future<bool> deletePlayerDocument({
    required int playerId,
    required int documentId,
  }) async {
    final activeRole = AppStorage.getActiveRole()?.trim().toLowerCase();
    final response = await _dio.delete(
      '/player/$playerId/documents/$documentId',
      options: Options(
        headers: _headers({
          if (activeRole != null && activeRole.isNotEmpty)
            'X-Active-Role': activeRole,
        }),
      ),
    );
    if (response.data is Map<String, dynamic>) {
      return response.data['ok'] != false;
    }
    return (response.statusCode ?? 500) >= 200 &&
        (response.statusCode ?? 500) < 300;
  }

  Future<PlayerFileResponse> fetchPlayerFile({
    required int playerId,
    required String tab,
    int page = 1,
    int perPage = 25,
  }) async {
    final response = await _dio.get(
      '/manager/players/$playerId/file',
      queryParameters: {'tab': tab, 'page': page, 'per_page': perPage},
      options: Options(headers: _headers()),
    );

    final map = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : <String, dynamic>{};

    return PlayerFileResponse.fromJson(map, tab: tab);
  }

  Future<OrganizationPlayerFullProfileResponse>
      fetchOrganizationPlayerFullProfile({
    int? playerId,
  }) async {
    final activeRole = (AppStorage.getActiveRole() ?? '').trim().toLowerCase();

    final String path;
    final Map<String, dynamic> extraHeaders = {};

    if (_hasOrganizationPlayerManagerAccess(activeRole)) {
      if (playerId == null || playerId <= 0) {
        throw Exception('Se requiere un jugador para consultar el perfil.');
      }
      path = '/manager/players/$playerId/full-profile';
    } else if (activeRole == 'parent') {
      if (playerId == null || playerId <= 0) {
        throw Exception('Selecciona un jugador para consultar el perfil.');
      }
      path = '/player/my-players/$playerId/full-profile';
      extraHeaders['X-Active-Role'] = activeRole;
    } else if (activeRole == 'player') {
      path = '/player/me/full-profile';
      extraHeaders['X-Active-Role'] = activeRole;
    } else {
      throw Exception('Tu rol actual no tiene acceso a este perfil.');
    }

    final response = await _dio.get(
      path,
      options: Options(headers: _headers(extraHeaders)),
    );

    final map = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : <String, dynamic>{};

    return OrganizationPlayerFullProfileResponse.fromJson(map);
  }

  Future<DocumentsComplianceResponse> fetchDocumentsCompliance({
    required int categoryId,
    String q = '',
    String status = 'all',
    int page = 1,
    int perPage = 15,
  }) async {
    final response = await _dio.get(
      '/manager/$categoryId/documents-compliance',
      queryParameters: {
        'q': q,
        'status': status,
        'page': page,
        'per_page': perPage,
      },
      options: Options(headers: _headers()),
    );

    final map = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : <String, dynamic>{};

    return DocumentsComplianceResponse.fromJson(map);
  }

  bool _hasOrganizationPlayerManagerAccess(String role) {
    return role == 'manager' || role == 'admin' || role == 'superadmin';
  }

  Future<ManagerDashboardResponse> getManagerDashboard() async {
    final res = await _dio.get(
      '/dashboards/manager',
      options: Options(headers: _headers()),
    );

    if (res.data is! Map) {
      throw Exception('Respuesta inesperada en dashboard manager');
    }

    final map = Map<String, dynamic>.from(res.data as Map);
    return ManagerDashboardResponse.fromJson(map);
  }

  /// GET /dashboards/player
  Future<PlayerDashboardResponse> getPlayerDashboard() async {
    final res = await _dio.get(
      '/dashboards/player',
      options: Options(headers: _headers()),
    );

    if (res.data is! Map) {
      throw Exception('Respuesta inesperada en dashboard player');
    }

    final map = Map<String, dynamic>.from(res.data as Map);
    return PlayerDashboardResponse.fromJson(map);
  }

  /// GET /dashboards/parent
  Future<ParentDashboardResponse> getParentDashboard() async {
    final res = await _dio.get(
      '/dashboards/parent',
      options: Options(headers: _headers()),
    );

    if (res.data is! Map) {
      throw Exception('Respuesta inesperada en dashboard parent');
    }

    final map = Map<String, dynamic>.from(res.data as Map);
    return ParentDashboardResponse.fromJson(map);
  }

  /// GET /dashboards/coach
  Future<ParentDashboardResponse> getCoachDashboard() async {
    final res = await _dio.get(
      '/dashboards/coach',
      options: Options(headers: _headers()),
    );

    if (res.data is! Map) {
      throw Exception('Respuesta inesperada en dashboard parent');
    }

    final map = Map<String, dynamic>.from(res.data as Map);
    return ParentDashboardResponse.fromJson(map);
  }

  /// GET /dashboards/staff
  Future<StaffDashboard> getStaffDashboard() async {
    final res = await _dio.get(
      '/dashboards/staff',
      options: Options(headers: _headers()),
    );

    if (res.data is! Map) {
      throw Exception('Respuesta inesperada en dashboard parent');
    }

    final map = Map<String, dynamic>.from(res.data as Map);
    return StaffDashboard.fromJson(map);
  }

  Future<List<Game>> getStaffGames({
    String? status, // opcional: scheduled|finished|canceled|...
    DateTime? from, // opcional
    DateTime? to, // opcional
    int limit = 50, // opcional (backend max 200)
  }) async {
    final query = <String, dynamic>{
      if (status != null && status.isNotEmpty) 'status': status,
      if (from != null) 'from': _toYmd(from),
      if (to != null) 'to': _toYmd(to),
      'limit': limit,
    };

    final res = await _dio.get(
      '/staff/games',
      queryParameters: query,
      options: Options(headers: _headers()),
    );

    if (res.data is! Map) {
      throw Exception('Respuesta inesperada en staff games');
    }

    final map = Map<String, dynamic>.from(res.data as Map);
    final list = (map['games'] as List?) ?? const [];

    return list
        .map((e) => Game.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// GET /staff/notices
  Future<List<Notice>> getStaffNotices({
    bool published = true, // backend default true
    int limit = 20, // backend max 200
  }) async {
    final res = await _dio.get(
      '/staff/notices',
      queryParameters: {'published': published, 'limit': limit},
      options: Options(headers: _headers()),
    );

    if (res.data is! Map) {
      throw Exception('Respuesta inesperada en staff notices');
    }

    final map = Map<String, dynamic>.from(res.data as Map);
    final list = (map['notices'] as List?) ?? const [];

    return list
        .map((e) => Notice.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<Notice>> getMyNotices() async {
    try {
      final res = await _dio.get(
        '/player/my-notices',
        options: Options(headers: _headers()),
      );

      if (res.data is! Map) {
        throw Exception('Respuesta inesperada en staff notices');
      }

      final map = Map<String, dynamic>.from(res.data as Map);
      final list = (map['data'] as List?) ?? const [];

      return list
          .map((e) => Notice.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<GazettaDetail?> getGazettaFeed() async {
    try {
      final res = await _dio.get(
        '/gazetta/feed',
        options: Options(headers: _headers()),
      );
      final map = _asMap(res.data);
      return GazettaFeedResponse.fromJson(map).data;
    } on DioException catch (e) {
      throw _mapGazettaError(e);
    }
  }

  Future<PaginatedResponse<GazettaItem>> getGazettaHistory({
    DateTime? from,
    DateTime? to,
    DateTime? weekStart,
    int perPage = 20,
    int page = 1,
  }) async {
    try {
      final query = <String, dynamic>{
        if (from != null) 'from': _toYmd(from),
        if (to != null) 'to': _toYmd(to),
        if (weekStart != null) 'week_start': _toYmd(weekStart),
        'per_page': perPage,
        'page': page,
      };

      final res = await _dio.get(
        '/gazetta/history',
        queryParameters: query,
        options: Options(headers: _headers()),
      );

      final root = _asMap(res.data);
      final payload = root['data'] is Map ? _asMap(root['data']) : root;
      return PaginatedResponse<GazettaItem>.fromJson(
        payload,
        GazettaItem.fromJson,
      );
    } on DioException catch (e) {
      throw _mapGazettaError(e);
    }
  }

  Future<GazettaDetail> getGazettaDetail(int id) async {
    try {
      final res = await _dio.get(
        '/gazetta/$id',
        options: Options(headers: _headers()),
      );
      final root = _asMap(res.data);
      final payload = root['data'] is Map ? _asMap(root['data']) : root;
      return GazettaDetail.fromJson(payload);
    } on DioException catch (e) {
      throw _mapGazettaError(e);
    }
  }

  Future<GazettaMeta> getGazettaMeta(int id) async {
    try {
      final res = await _dio.get(
        '/gazetta/$id/meta',
        options: Options(headers: _headers()),
      );
      final root = _asMap(res.data);
      final payload = root['data'] is Map ? _asMap(root['data']) : root;
      return GazettaMeta.fromJson(payload);
    } on DioException catch (e) {
      throw _mapGazettaError(e);
    }
  }

  Future<void> markGazettaSeen(int id) async {
    try {
      await _dio.post(
        '/gazetta/$id/seen',
        options: Options(headers: _headers()),
      );
    } on DioException catch (e) {
      throw _mapGazettaError(e);
    }
  }

  Future<NewsPreferences> getNewsPreferences() async {
    try {
      final res = await _dio.get(
        ApiEndpoints.newsPreferences,
        options: Options(headers: _headers()),
      );
      final root = _asMap(res.data);
      return NewsPreferences.fromJson(root);
    } on DioException catch (e) {
      throw _mapNewsError(e);
    }
  }

  Future<NewsFeedResponse> getNewsFeed({
    List<String>? sports,
    int perPage = 15,
    int page = 1,
  }) async {
    try {
      final cleanSports = (sports ?? const <String>[])
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final res = await _dio.get(
        ApiEndpoints.newsFeed,
        queryParameters: {
          if (cleanSports.isNotEmpty) 'sports': cleanSports.join(','),
          'per_page': perPage,
          'page': page,
        },
        options: Options(headers: _headers()),
      );

      final root = _asMap(res.data);
      return NewsFeedResponse.fromJson(root);
    } on DioException catch (e) {
      throw _mapNewsError(e);
    }
  }

  Future<void> markNewsSeen(int id) async {
    try {
      await _dio.post('/news/$id/seen', options: Options(headers: _headers()));
    } on DioException catch (e) {
      throw _mapNewsError(e);
    }
  }

  /// helper: DateTime -> YYYY-MM-DD
  String _toYmd(DateTime d) {
    final dt = DateTime(d.year, d.month, d.day);
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$mm-$dd';
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return const <String, dynamic>{};
  }

  Exception _mapGazettaError(DioException e) {
    final status = e.response?.statusCode;
    if (status == 404) {
      return const GazettaModuleUnavailableException();
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return Exception('Sin conexión o tiempo de espera agotado');
    }

    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString().trim();
      if (message != null && message.isNotEmpty) {
        return Exception(message);
      }
    }

    return Exception(e.message ?? 'No se pudo consultar Gazzetta');
  }

  Exception _mapNewsError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return Exception('Sin conexión o tiempo de espera agotado');
    }

    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString().trim();
      if (message != null && message.isNotEmpty) {
        return Exception(message);
      }
    }

    return Exception(e.message ?? 'No se pudieron consultar las noticias');
  }

  /// GET /dashboards/parent
  Future<List<Venue>> getVenues() async {
    final res = await _dio.get(
      '/venues',
      options: Options(headers: _headers()),
    );

    final data = res.data;

    final list = (data is Map && data['data'] is List)
        ? (data['data'] as List)
        : (data as List);

    return list
        .whereType<Map>()
        .map((e) => Venue.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<PaymentProviderIntentDto> createMercadoPagoIntent({
    required int paymentId,
  }) async {
    final res = await _dio.post(
      '/payments/$paymentId/providers/mercadopago/intent',
      options: Options(headers: _headers()),
    );

    if (res.data is! Map) {
      throw Exception('Respuesta inesperada creando intent de Mercado Pago');
    }

    final map = Map<String, dynamic>.from(res.data as Map);
    return PaymentProviderIntentDto.fromJson(map);
  }

  Future<PaginatedResponse<PlaybookPlay>> getPlaybookPlays({
    required int categoryId,
    int page = 1,
    String? type,
  }) async {
    final res = await _dio.get(
      '/playbook/plays',
      queryParameters: {
        'page': page,
        'category_id': categoryId,
        if (type != null && type.trim().isNotEmpty) 'type': type.trim(),
      },
      options: Options(headers: _headers()),
    );

    if (res.data is! Map) {
      throw Exception('Respuesta inesperada en playbook/plays');
    }

    final map = Map<String, dynamic>.from(res.data as Map);
    return PaginatedResponse<PlaybookPlay>.fromJson(
      map,
      (j) => PlaybookPlay.fromJson(j),
    );
  }

  Future<List<PlaybookCategoryRef>> getPlaybookCategories() async {
    final res = await _dio.get(
      '/playbook/categories',
      options: Options(headers: _headers()),
    );

    final rawData = (res.data is Map)
        ? ((res.data as Map)['data'] as List? ?? const [])
        : const [];

    return rawData
        .whereType<Map>()
        .map((e) => PlaybookCategoryRef.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Map<String, dynamic>> playbookCreatePlayGo({
    required Map<String, dynamic> payload,
  }) async {
    final res = await _dio.post(
      '/playbook/plays/go',
      data: payload,
      options: Options(headers: _headers()),
    );

    if (res.data is! Map) {
      throw Exception('Respuesta inesperada al guardar jugada (GO)');
    }
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// POST /api/playbook/plays/attachment
  ///
  /// Required:
  /// - categoryId, alias, type, side, playersCount, filePath
  /// Optional:
  /// - notes

  Future<Map<String, dynamic>> playbookCreatePlayAttachment({
    required int categoryId,
    required String alias,
    required String type,
    required String side,
    required int playersCount,
    required String filePath,
    List<int> sharedCategoryIds = const [],
    String? notes,
  }) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('El archivo no existe: $filePath');
    }

    final fileName = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : 'attachment';

    final form = FormData.fromMap({
      'category_id': categoryId,
      'alias': alias,
      'type': type,
      'side': side,
      'players_count': playersCount,
      if (sharedCategoryIds.isNotEmpty)
        'shared_category_ids[]': sharedCategoryIds,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final res = await _dio.post(
      '/playbook/plays/attachment',
      data: form,
      options: Options(headers: _headers(), contentType: 'multipart/form-data'),
    );

    if (res.data is! Map) {
      throw Exception('Respuesta inesperada al guardar jugada (Adjunto)');
    }

    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<PlaybookPlay> getPlaybookPlay({required String playId}) async {
    final res = await _dio.get(
      '/playbook/plays/$playId',
      options: Options(headers: _headers()),
    );

    if (res.data is! Map) {
      throw Exception('Respuesta inesperada en playbook/plays/{id}');
    }

    final map = Map<String, dynamic>.from(res.data as Map);
    return PlaybookPlay.fromJson(map);
  }

  Future<Map<String, dynamic>> playbookSharePlay({
    required String playId,
    required List<int> categoryIds,
  }) async {
    final res = await _dio.post(
      '/playbook/plays/$playId/share',
      data: {'category_ids': categoryIds},
      options: Options(headers: _headers()),
    );

    if (res.data is! Map) {
      throw Exception('Respuesta inesperada al compartir jugada');
    }

    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<List<PlaybookFeedback>> getPlaybookFeedback({
    required String playId,
    int limit = 50,
  }) async {
    final res = await _dio.get(
      '/playbook/plays/$playId/feedback',
      queryParameters: {'limit': limit},
      options: Options(headers: _headers()),
    );

    final rawData = (res.data is Map)
        ? ((res.data as Map)['data'] as List? ?? const [])
        : const [];

    return rawData
        .whereType<Map>()
        .map((e) => PlaybookFeedback.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<PlaybookFeedback> playbookCreateFeedback({
    required String playId,
    String? message,
    String? filePath,
  }) async {
    final trimmedMessage = message?.trim();
    final trimmedPath = filePath?.trim();

    final formMap = <String, dynamic>{
      if (trimmedMessage != null && trimmedMessage.isNotEmpty)
        'message': trimmedMessage,
    };

    if (trimmedPath != null && trimmedPath.isNotEmpty) {
      final file = File(trimmedPath);
      if (!file.existsSync()) {
        throw Exception('El archivo de feedback no existe: $trimmedPath');
      }

      final fileName = file.uri.pathSegments.isNotEmpty
          ? file.uri.pathSegments.last
          : 'feedback';
      formMap['file'] = await MultipartFile.fromFile(
        trimmedPath,
        filename: fileName,
      );
    }

    final res = await _dio.post(
      '/playbook/plays/$playId/feedback',
      data: FormData.fromMap(formMap),
      options: Options(headers: _headers(), contentType: 'multipart/form-data'),
    );

    if (res.data is! Map) {
      throw Exception('Respuesta inesperada al crear feedback');
    }

    final map = Map<String, dynamic>.from(res.data as Map);
    if (map['data'] is Map) {
      return PlaybookFeedback.fromJson(
        Map<String, dynamic>.from(map['data'] as Map),
      );
    }
    return PlaybookFeedback.fromJson(map);
  }

  Future<PlaybookLikes> playbookToggleLike({required String playId}) async {
    final res = await _dio.post(
      '/playbook/plays/$playId/like',
      options: Options(headers: _headers()),
    );

    if (res.data is! Map) {
      throw Exception('Respuesta inesperada al dar like a la jugada');
    }

    final map = Map<String, dynamic>.from(res.data as Map);
    final likesRaw = map['likes'];
    if (likesRaw is! Map) {
      throw Exception('La respuesta no incluye el bloque likes');
    }

    return PlaybookLikes.fromJson(Map<String, dynamic>.from(likesRaw));
  }

  Future<bool> playbookDeleteFeedback({
    required String playId,
    required int feedbackId,
  }) async {
    final res = await _dio.delete(
      '/playbook/plays/$playId/feedback/$feedbackId',
      options: Options(headers: _headers()),
    );

    if (res.data is Map) {
      final map = Map<String, dynamic>.from(res.data as Map);
      if (map['ok'] is bool) return map['ok'] as bool;
    }

    return res.statusCode != null &&
        res.statusCode! >= 200 &&
        res.statusCode! < 300;
  }

  // UPDATE  PUT /playbook/plays/{playId}
  Future<Map<String, dynamic>> playbookUpdatePlay({
    required String playId,
    required Map<String, dynamic> payload,
  }) async {
    final res = await _dio.put(
      '/playbook/plays/$playId',
      data: payload,
      options: Options(headers: _headers()),
    );

    if (res.data is! Map) {
      throw Exception('Respuesta inesperada al actualizar jugada');
    }
    return Map<String, dynamic>.from(res.data as Map);
  }

  // DELETE  DELETE /playbook/plays/{playId}
  Future<bool> playbookDeletePlay({required String playId}) async {
    final res = await _dio.delete(
      '/playbook/plays/$playId',
      options: Options(headers: _headers()),
    );

    // si tu backend regresa {ok:true} puedes validar eso aquí
    return res.statusCode != null &&
        res.statusCode! >= 200 &&
        res.statusCode! < 300;
  }

  Future<List<ProductCategoryModel>> ecommerceCategories() async {
    final res = await _dio.get(
      '/ecommerce/categories',
      options: Options(headers: _headers()),
    );

    final data = (res.data['data'] as List?) ?? const [];
    return data
        .map(
          (e) => ProductCategoryModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  Future<List<ProductModel>> ecommerceProducts({
    int? categoryId,
    String? q,
  }) async {
    final query = <String, dynamic>{};
    if (categoryId != null) query['category_id'] = categoryId;
    if (q != null && q.trim().isNotEmpty) query['q'] = q.trim();

    final res = await _dio.get(
      '/ecommerce/products',
      queryParameters: query.isEmpty ? null : query,
      options: Options(headers: _headers()),
    );

    final data = (res.data['data'] as List?) ?? const [];
    return data
        .map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<ProductDetailModel> ecommerceProductDetail({
    required int productId,
  }) async {
    final res = await _dio.get(
      '/ecommerce/products/$productId',
      options: Options(headers: _headers()),
    );

    return ProductDetailModel.fromApiResponse(
      Map<String, dynamic>.from(res.data as Map),
    );
  }

  Future<ProductVariantListModel> ecommerceResolveVariant({
    required int productId,
    required List<int> valueIds,
  }) async {
    final res = await _dio.post(
      '/ecommerce/products/$productId/resolve-variant',
      data: {'value_ids': valueIds},
      options: Options(headers: _headers()),
    );

    final data = Map<String, dynamic>.from(res.data['data'] as Map);
    return ProductVariantListModel.fromJson(data);
  }

  // =========================
  // CARRITO
  // =========================

  Future<CartModel> ecommerceCart() async {
    final res = await _dio.get(
      '/ecommerce/cart',
      options: Options(headers: _headers()),
    );

    final data = Map<String, dynamic>.from(res.data['data'] as Map);
    return CartModel.fromJson(data);
  }

  Future<CartModel> ecommerceCartAddItem({
    int? variantId,
    int? productId,
    List<int>? valueIds,
    required int qty,
  }) async {
    final data = <String, dynamic>{'qty': qty};
    if (variantId != null) {
      data['variant_id'] = variantId;
    } else {
      data['product_id'] = productId;
      data['value_ids'] = valueIds ?? const <int>[];
    }

    await _dio.post(
      '/ecommerce/cart/items',
      data: data,
      options: Options(headers: _headers()),
    );
    return ecommerceCart();
  }

  Future<CartModel> ecommerceCartUpdateItem({
    required int cartItemId,
    required int qty,
  }) async {
    final res = await _dio.patch(
      '/ecommerce/cart/items/$cartItemId',
      data: {'qty': qty},
      options: Options(headers: _headers()),
    );

    final data = Map<String, dynamic>.from(res.data['data'] as Map);
    return CartModel.fromJson(data);
  }

  Future<CartModel> ecommerceCartRemoveItem({required int cartItemId}) async {
    final res = await _dio.delete(
      '/ecommerce/cart/items/$cartItemId',
      options: Options(headers: _headers()),
    );

    final data = Map<String, dynamic>.from(res.data['data'] as Map);
    return CartModel.fromJson(data);
  }

  Future<CartModel> ecommerceCartClear() async {
    final res = await _dio.delete(
      '/ecommerce/cart',
      options: Options(headers: _headers()),
    );

    final data = Map<String, dynamic>.from(res.data['data'] as Map);
    return CartModel.fromJson(data);
  }

  // =========================
  // CHECKOUT + ÓRDENES
  // =========================
  Future<CheckoutResultModel> ecommerceCheckout({
    String fulfillmentType = "pickup",
  }) async {
    final organization = AppStorage.getOrganization();
    final provider =
        organization?.payCardEnabled == true ? 'mercadopago' : 'cash_on_pickup';

    final res = await _dio.post(
      '/ecommerce/checkout',
      data: {'fulfillment_type': fulfillmentType, 'provider': provider},
      options: Options(headers: _headers()),
    );

    return CheckoutResultModel.fromJson(
      Map<String, dynamic>.from(res.data as Map),
    );
  }

  Future<Map<String, dynamic>> createPaymentIntentByUrl(String url) async {
    final res = await _dio.post(url, options: Options(headers: _headers()));

    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<List<EcommerceOrderListItemModel>> ecommerceOrders() async {
    final res = await _dio.get(
      '/ecommerce/orders',
      options: Options(headers: _headers()),
    );
    final root = Map<String, dynamic>.from(res.data as Map);
    dynamic data = root['data'];
    if (data is Map && data['data'] is List) data = data['data'];
    if (data is! List) data = const [];

    return (data)
        .map(
          (e) => EcommerceOrderListItemModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  Future<EcommerceOrderDetailModel> ecommerceOrderShow(int orderId) async {
    final res = await _dio.get(
      '/ecommerce/orders/$orderId',
      options: Options(headers: _headers()),
    );

    return EcommerceOrderDetailModel.fromJson(
      Map<String, dynamic>.from(res.data as Map),
    );
  }

  Future<LiveEventModel> createLiveEvent({
    required int organizationId,
    required int categoryId,
    required int gameId,
    required String title,
  }) async {
    final res = await _dio.post(
      '/live-events',
      data: {
        'organization_id': organizationId,
        'category_id': categoryId,
        'game_id': gameId,
        'title': title,
      },
      options: Options(headers: _headers()),
    );

    return LiveEventModel.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<LiveEventModel> getLiveEvent(int liveEventId) async {
    final res = await _dio.get(
      '/live-events/$liveEventId',
      options: Options(headers: _headers()),
    );

    return LiveEventModel.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<void> startLiveEvent(int liveEventId) async {
    await _dio.post(
      '/live-events/$liveEventId/start',
      options: Options(headers: _headers()),
    );
  }

  Future<void> pauseLiveEvent(int liveEventId) async {
    await _dio.post(
      '/live-events/$liveEventId/pause',
      options: Options(headers: _headers()),
    );
  }

  Future<void> finishLiveEvent(int liveEventId) async {
    await _dio.post(
      '/live-events/$liveEventId/finish',
      options: Options(headers: _headers()),
    );
  }

  Future<LiveEventModel?> getLiveByGame(int gameId) async {
    final res = await _dio.get(
      '/games/$gameId/live',
      options: Options(headers: _headers()),
    );

    if (res.data == null) return null;

    return LiveEventModel.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<TrainingPlayerResponse?> getTrainingPlayerHistory({
    required int playerId,
    DateTime? from,
    DateTime? to,
    int? seasonId,
    int? categoryId,
    bool countJustified = false,
  }) async {
    try {
      final qp = <String, dynamic>{'count_justified': countJustified ? 1 : 0};

      String fmtDate(DateTime d) {
        final y = d.year.toString().padLeft(4, '0');
        final m = d.month.toString().padLeft(2, '0');
        final day = d.day.toString().padLeft(2, '0');
        return '$y-$m-$day';
      }

      if (from != null) qp['from'] = fmtDate(from);
      if (to != null) qp['to'] = fmtDate(to);
      if (seasonId != null) qp['season_id'] = seasonId;
      if (categoryId != null) qp['category_id'] = categoryId;

      final res = await _dio.get(
        '/training/player/$playerId',
        queryParameters: qp,
        options: Options(headers: _headers()),
      );

      final data = res.data;
      if (data == null) return null;

      if (data is Map<String, dynamic>) {
        return TrainingPlayerResponse.fromJson(data);
      }

      if (data is Map) {
        return TrainingPlayerResponse.fromJson(Map<String, dynamic>.from(data));
      }

      return null;
    } on DioException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<CombineEvent>?> getCombineEvents({
    int? categoryId,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final qp = <String, dynamic>{};

      String fmtDate(DateTime d) {
        final y = d.year.toString().padLeft(4, '0');
        final m = d.month.toString().padLeft(2, '0');
        final day = d.day.toString().padLeft(2, '0');
        return '$y-$m-$day';
      }

      if (categoryId != null) qp['category_id'] = categoryId;
      if (from != null) qp['from'] = fmtDate(from);
      if (to != null) qp['to'] = fmtDate(to);

      final res = await _dio.get(
        '/combine/events',
        queryParameters: qp,
        options: Options(headers: _headers()),
      );

      final data = res.data;
      if (data == null) return null;
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        final list = map['data'] ?? map['events'] ?? map['items'];
        if (list is List) {
          return list
              .whereType<Map>()
              .map((e) => CombineEvent.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }

      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => CombineEvent.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      return null;
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<CombineEvent?> createCombineEvent({
    required int categoryId,
    int? seasonId,
    int? venueId,
    required String name,
    required String startsAt, // "YYYY-MM-DD HH:mm:ss"
    String? endsAt, // "YYYY-MM-DD HH:mm:ss"
    String? notes,
  }) async {
    try {
      final body = <String, dynamic>{
        'category_id': categoryId,
        'name': name,
        'starts_at': startsAt,
      };
      if (seasonId != null) body['season_id'] = seasonId;
      if (venueId != null) body['venue_id'] = venueId;
      if (endsAt != null) body['ends_at'] = endsAt;
      if (notes != null) body['notes'] = notes;

      final res = await _dio.post(
        '/combine/events',
        data: body,
        options: Options(headers: _headers()),
      );

      final raw = res.data;
      if (raw == null) return null;

      // Caso 1: Map<String,dynamic>
      if (raw is Map<String, dynamic>) {
        final eventRaw = raw['event']; // 👈 TU PAYLOAD REAL
        if (eventRaw is Map<String, dynamic>) {
          return CombineEvent.fromJson(eventRaw);
        }
        if (eventRaw is Map) {
          return CombineEvent.fromJson(Map<String, dynamic>.from(eventRaw));
        }

        // fallback por si alguna vez regresa directo
        return CombineEvent.fromJson(raw);
      }

      // Caso 2: Map<dynamic,dynamic>
      if (raw is Map) {
        final map = Map<String, dynamic>.from(raw);
        final eventRaw = map['event'];
        if (eventRaw is Map<String, dynamic>) {
          return CombineEvent.fromJson(eventRaw);
        }
        if (eventRaw is Map) {
          return CombineEvent.fromJson(Map<String, dynamic>.from(eventRaw));
        }

        return CombineEvent.fromJson(map);
      }

      return null;
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<CombineEventDetailResponse?> getCombineEventDetail({
    required int eventId,
  }) async {
    try {
      final res = await _dio.get(
        '/combine/events/$eventId',
        options: Options(headers: _headers()),
      );

      final raw = res.data;
      if (raw == null) return null;

      // Caso ideal: Map<String, dynamic>
      if (raw is Map<String, dynamic>) {
        return CombineEventDetailResponse.fromJson(raw);
      }

      // Caso: Map<dynamic, dynamic>
      if (raw is Map) {
        return CombineEventDetailResponse.fromJson(
          Map<String, dynamic>.from(raw),
        );
      }

      return null;
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> createCombineResult({
    required int eventId,
    required int playerId,
    required String measuredAt,
    String? notes,
    double? overallScore,
    required List<Map<String, dynamic>> values,
  }) async {
    try {
      final body = <String, dynamic>{
        'player_id': playerId,
        'measured_at': measuredAt,
        'values': values,
      };
      if (notes != null && notes.trim().isNotEmpty) {
        body['notes'] = notes.trim();
      }
      if (overallScore != null) body['overall_score'] = overallScore;

      final res = await _dio.post(
        '/combine/events/$eventId/results',
        data: body,
        options: Options(headers: _headers()),
      );

      final raw = res.data;
      if (raw == null) return null;

      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) return Map<String, dynamic>.from(raw);

      return null;
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getCombineLeaderboard({
    required int eventId,
    required String metricKey,
    int limit = 10,
  }) async {
    try {
      final res = await _dio.get(
        '/combine/events/$eventId/leaderboard',
        queryParameters: {'metric_key': metricKey, 'limit': limit},
        options: Options(headers: _headers()),
      );

      final raw = res.data;
      if (raw == null) return null;

      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) return Map<String, dynamic>.from(raw);

      return null;
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<CombineEventResultsResponse?> getCombineEventResults({
    required int eventId,
  }) async {
    try {
      final res = await _dio.get(
        '/combine/events/$eventId/results',
        options: Options(headers: _headers()),
      );

      final raw = res.data;
      if (raw == null) return null;

      return CombineEventResultsResponse.fromJson(raw);
    } on DioException {
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> createCombineMetric({
    required String key,
    required String name,
    String? unit,
    String type = 'number',
    String direction = 'lower_is_better',
    int decimals = 2,
    double? min,
    double? max,
    bool isActive = true,
  }) async {
    try {
      final body = <String, dynamic>{
        'key': key,
        'name': name,
        'type': type,
        'direction': direction,
        'decimals': decimals,
        'is_active': isActive,
      };

      if (unit != null && unit.trim().isNotEmpty) {
        body['unit'] = unit.trim();
      }

      if (min != null) body['min'] = min;
      if (max != null) body['max'] = max;

      final res = await _dio.post(
        '/combine/metrics',
        data: body,
        options: Options(headers: _headers()),
      );

      final raw = res.data;
      if (raw == null) return null;

      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) return Map<String, dynamic>.from(raw);

      return null;
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }

  dynamic jsonNormalize(dynamic input) {
    if (input is Map) {
      return input.map((k, v) => MapEntry(k.toString(), jsonNormalize(v)));
    }
    if (input is List) {
      return input.map(jsonNormalize).toList();
    }
    return input;
  }

  Future<List<Map<String, dynamic>>?> getCombineMetrics({
    bool? onlyActive,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (onlyActive != null) {
        query['is_active'] = onlyActive ? 1 : 0;
      }

      final res = await _dio.get(
        '/combine/metrics',
        queryParameters: query.isEmpty ? null : query,
        options: Options(headers: _headers()),
      );

      final raw = res.data;
      if (raw == null) return null;

      // ✅ Contrato real del backend
      if (raw is Map && raw['metrics'] is List) {
        return List<Map<String, dynamic>>.from(raw['metrics'] as List);
      }

      return null;
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<ParentsModel?> getMyParents() async {
    try {
      final res = await _dio.get(
        '/player/my-parents',
        options: Options(headers: _headers()),
      );
      final raw = res.data;
      if (raw == null || raw is! Map<String, dynamic>) return null;

      final data = raw['data'];
      if (data == null || data is! Map<String, dynamic>) return null;

      return ParentsModel.fromJson(data);
    } on DioException {
      return null;
    } catch (e) {
      return null;
    }
  }

  // PUT /player/my-parents
  Future<bool> updateMyParents({required ParentsModel parents}) async {
    try {
      final res = await _dio.put(
        '/player/my-parents',
        data: parents.toJson(),
        options: Options(headers: _headers()),
      );
      return res.statusCode == 200;
    } on DioException {
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<List<CheckinModelResponse>> getCheckinsHistory({
    required String dateFrom,
    required String dateTo,
  }) async {
    try {
      final res = await _dio.get(
        '/checkins/history',
        queryParameters: {'date_from': dateFrom, 'date_to': dateTo},
        options: Options(headers: _headers()),
      );

      final raw = res.data;
      if (raw is! Map<String, dynamic>) return [];

      final paginated = raw['data'];
      if (paginated is! Map<String, dynamic>) return [];

      final list = paginated['data'];
      if (list is! List) return [];

      return list
          .whereType<Map<String, dynamic>>()
          .map(CheckinModelResponse.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<CheckinTodayStatus> getCheckinToday() async {
    final res = await _dio.get(
      '/checkins/today',
      options: Options(
        headers: _headers(),
        validateStatus: (code) => code != null && code >= 200 && code < 500,
      ),
    );

    final raw = res.data;
    if (raw is Map<String, dynamic>) {
      return CheckinTodayStatus.fromJson(raw);
    }
    return CheckinTodayStatus.empty;
  }

  Future<CheckinResponse?> createCheckin({
    required CheckinModel checkin,
  }) async {
    try {
      final res = await _dio.post(
        '/checkins',
        data: checkin.toJson(),
        options: Options(
          headers: _headers(),
          validateStatus: (code) => code != null && code >= 200 && code < 500,
        ),
      );

      final raw = res.data;
      if (raw is Map<String, dynamic>) {
        return CheckinResponse.fromJson(raw);
      }

      return null;
    } on DioException catch (e) {
      final raw = e.response?.data;
      if (raw is Map<String, dynamic>) {
        return CheckinResponse.fromJson(raw);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<CheckinResponse?> checkoutCheckin({
    required CheckinCheckoutRequest checkout,
  }) async {
    try {
      final res = await _dio.post(
        '/checkins/checkout',
        data: checkout.toJson(),
        options: Options(
          headers: _headers(),
          validateStatus: (code) => code != null && code >= 200 && code < 500,
        ),
      );

      final raw = res.data;
      if (raw is Map<String, dynamic>) {
        return CheckinResponse.fromJson(raw);
      }

      return null;
    } on DioException catch (e) {
      final raw = e.response?.data;
      if (raw is Map<String, dynamic>) {
        return CheckinResponse.fromJson(raw);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updatePlayerJerseyNumber({
    required int categoryPlayerId,
    required int jerseyNumber,
  }) async {
    try {
      final res = await _dio.put(
        '/category-players/$categoryPlayerId/jersey',
        data: {'jersey_number': jerseyNumber},
        options: Options(
          headers: _headers(),
          validateStatus: (code) => code != null && code >= 200 && code < 500,
        ),
      );

      if (res.statusCode == 200) {
        return true;
      }
      return false;
    } on DioException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<Game?> getGameDetailById(int gameId) async {
    try {
      final res = await _dio.get(
        '/games/$gameId',
        options: Options(
          headers: _headers(),
          validateStatus: (code) => code != null && code >= 200 && code < 500,
        ),
      );

      if (res.statusCode == 200 && res.data != null) {
        return Game.fromJson(res.data as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> toggleGameLike(int gameId) async {
    try {
      final res = await _dio.post(
        '/games/$gameId/like',
        options: Options(
          headers: _headers(),
          validateStatus: (code) => code != null && code >= 200 && code < 500,
        ),
      );

      if (res.statusCode == 200 && res.data != null) {
        return Map<String, dynamic>.from(res.data as Map);
      }
      return null;
    } on DioException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> uploadGameImage({
    required int gameId,
    required File file,
  }) async {
    try {
      final form = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final res = await _dio.post(
        '/games/$gameId/images',
        data: form,
        options: Options(
          headers: {..._headers(), 'Content-Type': 'multipart/form-data'},
          validateStatus: (code) => code != null && code >= 200 && code < 500,
        ),
      );

      if ((res.statusCode == 200 || res.statusCode == 201) &&
          res.data != null) {
        final data = Map<String, dynamic>.from(res.data as Map);
        return data['url'] as String?;
      }
      return null;
    } on DioException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<GameComment>> getGameComments({
    required int gameId,
    int? afterId,
    int limit = 30,
  }) async {
    try {
      final query = <String, dynamic>{
        'limit': limit,
        if (afterId != null && afterId > 0) 'after_id': afterId,
      };

      final res = await _dio.get(
        '/games/$gameId/comments',
        queryParameters: query,
        options: Options(
          headers: _headers(),
          validateStatus: (code) => code != null && code >= 200 && code < 500,
        ),
      );

      if (res.statusCode == 200 && res.data != null) {
        final map = Map<String, dynamic>.from(res.data as Map);
        final list = (map['data'] as List? ?? const []);
        return list
            .map(
              (e) => GameComment.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
      }

      return [];
    } on DioException catch (_) {
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<GameComment?> createGameComment({
    required int gameId,
    required String message,
  }) async {
    try {
      final res = await _dio.post(
        '/games/$gameId/comments',
        data: {'message': message},
        options: Options(
          headers: _headers(),
          validateStatus: (code) => code != null && code >= 200 && code < 500,
        ),
      );

      if ((res.statusCode == 200 || res.statusCode == 201) &&
          res.data != null) {
        return GameComment.fromJson(Map<String, dynamic>.from(res.data as Map));
      }

      return null;
    } on DioException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> toggleCommentLike({
    required int gameId,
    required int commentId,
  }) async {
    try {
      final res = await _dio.post(
        '/games/$gameId/comments/$commentId/like',
        options: Options(
          headers: _headers(),
          validateStatus: (code) => code != null && code >= 200 && code < 500,
        ),
      );

      if (res.statusCode == 200 && res.data != null) {
        return Map<String, dynamic>.from(res.data as Map);
      }
      return null;
    } on DioException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<DashboardSocialPost>> getSocialFeed({
    int page = 1,
    int perPage = 10,
  }) async {
    final res = await _dio.get(
      '/social/posts',
      queryParameters: {'page': page, 'per_page': perPage},
      options: Options(headers: _headers()),
    );

    final root = Map<String, dynamic>.from(res.data as Map);
    final data = (root['data'] as List?) ?? const [];
    return data
        .map(
          (e) =>
              DashboardSocialPost.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<DashboardSocialPost> createSocialPost({
    required String caption,
    List<int> mentionIds = const [],
  }) async {
    final res = await _dio.post(
      '/social/posts',
      data: {
        'caption': caption,
        if (mentionIds.isNotEmpty) 'mentions': mentionIds,
      },
      options: Options(headers: _headers()),
    );

    final root = Map<String, dynamic>.from(res.data as Map);
    return DashboardSocialPost.fromJson(
      Map<String, dynamic>.from(root['data'] as Map),
    );
  }

  Future<DashboardSocialPost> getSocialPostDetail(int postId) async {
    final res = await _dio.get(
      '/social/posts/$postId',
      options: Options(headers: _headers()),
    );

    final root = Map<String, dynamic>.from(res.data as Map);
    return DashboardSocialPost.fromJson(
      Map<String, dynamic>.from(root['data'] as Map),
    );
  }

  Future<DashboardSocialComment> createSocialComment({
    required int postId,
    required String message,
  }) async {
    final res = await _dio.post(
      '/social/posts/$postId/comments',
      data: {'message': message},
      options: Options(headers: _headers()),
    );

    final root = Map<String, dynamic>.from(res.data as Map);
    return DashboardSocialComment.fromJson(
      Map<String, dynamic>.from(root['data'] as Map),
    );
  }

  Future<Map<String, dynamic>?> toggleSocialPostLike({
    required int postId,
  }) async {
    try {
      final res = await _dio.post(
        '/social/posts/$postId/like',
        options: Options(
          headers: _headers(),
          validateStatus: (code) => code != null && code >= 200 && code < 500,
        ),
      );

      if (res.statusCode == 200 && res.data != null) {
        final root = Map<String, dynamic>.from(res.data as Map);
        return Map<String, dynamic>.from((root['data'] as Map?) ?? const {});
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> toggleSocialCommentLike({
    required int commentId,
  }) async {
    try {
      final res = await _dio.post(
        '/social/comments/$commentId/like',
        options: Options(
          headers: _headers(),
          validateStatus: (code) => code != null && code >= 200 && code < 500,
        ),
      );

      if (res.statusCode == 200 && res.data != null) {
        final root = Map<String, dynamic>.from(res.data as Map);
        return Map<String, dynamic>.from((root['data'] as Map?) ?? const {});
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteSocialPost({required int postId}) async {
    try {
      final res = await _dio.delete(
        '/social/posts/$postId',
        options: Options(
          headers: _headers(),
          validateStatus: (code) => code != null && code >= 200 && code < 500,
        ),
      );

      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<DashboardMentionableUser>> searchMentionableUsers({
    String query = '',
    int limit = 20,
  }) async {
    final res = await _dio.get(
      '/social/mentionable-users',
      queryParameters: {'query': query, 'limit': limit},
      options: Options(headers: _headers()),
    );

    final root = Map<String, dynamic>.from(res.data as Map);
    final data = (root['data'] as List?) ?? const [];
    return data
        .map(
          (e) => DashboardMentionableUser.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  Future<Map<String, dynamic>?> initSocialImageUpload(int postId) async {
    try {
      final res = await _dio.post(
        '/social/posts/$postId/images/init',
        options: Options(
          headers: _headers(),
          validateStatus: (code) => code != null && code >= 200 && code < 500,
        ),
      );

      if ((res.statusCode == 200 || res.statusCode == 201) &&
          res.data != null) {
        return Map<String, dynamic>.from(res.data as Map);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<DashboardSocialMediaItem?> confirmSocialImageUpload({
    required int postId,
    required String imageId,
    required int position,
    int? width,
    int? height,
  }) async {
    try {
      final res = await _dio.post(
        '/social/posts/$postId/images/confirm',
        data: {
          'imageId': imageId,
          'position': position,
          'variant': 'public',
          if (width != null) 'width': width,
          if (height != null) 'height': height,
        },
        options: Options(
          headers: _headers(),
          validateStatus: (code) => code != null && code >= 200 && code < 500,
        ),
      );

      if ((res.statusCode == 200 || res.statusCode == 201) &&
          res.data != null) {
        final root = Map<String, dynamic>.from(res.data as Map);
        return DashboardSocialMediaItem.fromJson(
          Map<String, dynamic>.from((root['data'] as Map?) ?? const {}),
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> initSocialVideoUpload(int postId) async {
    try {
      final res = await _dio.post(
        '/social/posts/$postId/videos/init',
        options: Options(
          headers: _headers(),
          validateStatus: (code) => code != null && code >= 200 && code < 500,
        ),
      );

      if ((res.statusCode == 200 || res.statusCode == 201) &&
          res.data != null) {
        return Map<String, dynamic>.from(res.data as Map);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<DashboardSocialMediaItem?> confirmSocialVideoUpload({
    required int postId,
    required String uid,
    required int position,
    int? width,
    int? height,
    int? durationSeconds,
  }) async {
    try {
      final res = await _dio.post(
        '/social/posts/$postId/videos/confirm',
        data: {
          'uid': uid,
          'position': position,
          if (width != null) 'width': width,
          if (height != null) 'height': height,
          if (durationSeconds != null) 'duration_seconds': durationSeconds,
        },
        options: Options(
          headers: _headers(),
          validateStatus: (code) => code != null && code >= 200 && code < 500,
        ),
      );

      if ((res.statusCode == 200 || res.statusCode == 201) &&
          res.data != null) {
        final root = Map<String, dynamic>.from(res.data as Map);
        return DashboardSocialMediaItem.fromJson(
          Map<String, dynamic>.from((root['data'] as Map?) ?? const {}),
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> uploadFileToCloudflare({
    required String uploadUrl,
    required XFile file,
    ProgressCallback? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: file.name),
      });

      final res = await _dio.post(
        uploadUrl,
        data: formData,
        options: Options(
          headers: {'Accept': 'application/json'},
          validateStatus: (code) => code != null && code >= 200 && code < 500,
        ),
        onSendProgress: onProgress,
      );

      return res.statusCode != null &&
          res.statusCode! >= 200 &&
          res.statusCode! < 300;
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteTraining({
    required int trainingId,
    required int categoryId,
  }) async {
    await _dio.delete(
      '/manager/$categoryId/trainings/$trainingId',
      options: Options(
        headers: _headers(),
        validateStatus: (code) => code != null && code >= 200 && code < 500,
      ),
    );
  }
}
