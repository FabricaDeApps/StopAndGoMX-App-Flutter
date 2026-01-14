import 'dart:io';

import 'package:dio/dio.dart';
import 'package:stopandgo/core/config/flavor_config.dart';
import 'package:stopandgo/core/constants/api_endpoints.dart';
import 'package:stopandgo/core/models/category.dart';
import 'package:stopandgo/core/models/dashboard_models.dart';
import 'package:stopandgo/core/models/dto/notice_model.dart';
import 'package:stopandgo/core/models/dto/payment_dto.dart';
import 'package:stopandgo/core/models/dto/payment_provider_intent_dto.dart';
import 'package:stopandgo/core/models/ecommerce/checkout_result_model.dart';
import 'package:stopandgo/core/models/ecommerce/ecommerce_order_detail_model.dart';
import 'package:stopandgo/core/models/ecommerce/ecommerce_order_list_item_model.dart';
import 'package:stopandgo/core/models/games.dart';
import 'package:stopandgo/core/models/player_document.dart';
import 'package:stopandgo/core/models/players.dart';
import 'package:stopandgo/core/models/responses/generic_response.dart';
import 'package:stopandgo/core/models/responses/login_response.dart';
import 'package:stopandgo/core/models/responses/organization_response.dart';
import 'package:stopandgo/core/models/training.dart';
import 'package:stopandgo/core/models/trainning_attendance.dart';
import 'package:stopandgo/core/network/paginated_response.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/core/utils/device_info.dart';
import 'package:stopandgo/core/models/play_book_model.dart';
import 'api_client.dart';
import 'token_storage.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import '../models/ecommerce/product_category_model.dart';
import '../models/ecommerce/product_model.dart';
import '../models/ecommerce/product_detail_model.dart';
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

      final orgs = data
          .map((json) => OrganizationResponse.fromJson(json))
          .toList();

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
        tokenType: (loginData.tokenType.isNotEmpty
            ? loginData.tokenType
            : 'Bearer'),
        refreshToken: loginData.refreshToken,
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

  Future<void> logout() async {
    final rt = _tokenStorage.refreshToken;
    try {
      await _dio.post(
        ApiEndpoints.authLogout,
        data: {if (rt != null && rt.isNotEmpty) 'refresh_token': rt},
        options: Options(headers: {'Accept': 'application/json'}),
      );
    } catch (_) {
    } finally {
      _tokenStorage.clear();
      await AppStorage.clearAll();
    }
  }

  // /player/my-games?player_id=...
  Future<List<Game>> playerMyGamesFromParent({required int playerId}) async {
    final res = await _dio.get(
      '/player/my-games',
      queryParameters: {'player_id': playerId},
      options: Options(headers: _headers()),
    );

    final data = res.data['data']; // <- AQUÍ VIENE LA LISTA
    return gameDtoListFromData(data);
  }

  Future<List<Game>> playerMyGames() async {
    final res = await _dio.get(
      '/player/my-games',
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
  }) async {
    final res = await _dio.get(
      '/manager/$categoryId/games',
      queryParameters: {'from': from, 'to': to},
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
  }) async {
    final res = await _dio.get(
      '/coach/categories/$categoryId/games',
      queryParameters: {'from': from, 'to': to},
      options: Options(headers: _headers()),
    );

    final data = res.data['data'];
    return gameDtoListFromData(data);
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
  Future<List<Map<String, dynamic>>> managerNotices() async {
    final res = await _dio.get(
      '/manager/notices',
      options: Options(headers: _headers()),
    );
    final data = (res.data['data'] as List?) ?? const [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
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
      final response = await _dio.post(
        '/manager/$categoryId/games/create',
        data: data,
      );
      return GenericResponse.fromJson(response.data);
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
  String get _tokenType => _tokenStorage.tokenType!;

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

  /// PUT /account
  Future<Map<String, dynamic>> updateAccount({
    required String name,
    required String email,
    String? role, // parent | player | manager
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name.trim(),
        'email': email.trim(),
        if (role != null && role.isNotEmpty) 'role': role,
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
      final res = await _dio.post(
        '/manager/$categoryId/trainings',
        data: data,
        options: Options(headers: _headers()),
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

  Future<GenericResponse> saveAttendancesBulk({
    required int gameId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final res = await _dio.post(
        '/manager/$gameId/attendances/bulk',
        data: {"items": items},
      );
      return GenericResponse.fromJson(Map<String, dynamic>.from(res.data));
    } on DioException catch (e) {
      final payload = e.response?.data;
      if (payload is Map<String, dynamic>) {
        return GenericResponse.fromJson(payload);
      }
      return GenericResponse(
        success: false,
        message: e.message ?? 'Error al guardar asistencias',
      );
    } catch (e) {
      return GenericResponse(success: false, message: 'Error inesperado: $e');
    }
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
      if (data is Map<String, dynamic>)
        return data; // p.ej. {success:false,message:'...'}
      return {'success': false, 'message': e.message ?? 'Error en registro'};
    } catch (e) {
      return {'success': false, 'message': 'Error inesperado: $e'};
    }
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

  Future<List<PlayerDocument>> getPlayerDocuments(int playerId) async {
    final response = await _dio.get('/player/$playerId/documents');

    final data = response.data['data'] as List<dynamic>? ?? [];

    return data
        .map((item) => PlayerDocument.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<PlayerDocument> uploadPlayerDocument({
    required int playerId,
    required File file,
  }) async {
    final fileName = file.path.split('/').last;

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });

    final response = await _dio.post(
      '/player/$playerId/documents',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final docJson = response.data['document'] as Map<String, dynamic>;
    return PlayerDocument.fromJson(docJson);
  }

  Future<bool> deletePlayerDocument({
    required int playerId,
    required int documentId,
  }) async {
    final response = await _dio.delete(
      '/player/$playerId/documents/$documentId',
    );
    return response.data['ok'] == true;
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

  /// helper: DateTime -> YYYY-MM-DD
  String _toYmd(DateTime d) {
    final dt = DateTime(d.year, d.month, d.day);
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$mm-$dd';
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

    final data = Map<String, dynamic>.from(res.data['data'] as Map);
    return ProductDetailModel.fromJson(data);
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
    required int variantId,
    required int qty,
  }) async {
    await _dio.post(
      '/ecommerce/cart/items',
      data: {'variant_id': variantId, 'qty': qty},
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
    final res = await _dio.post(
      '/ecommerce/checkout',
      data: {
        'fulfillment_type': fulfillmentType,
        'provider': FlavorConfig.I.paymentProvider ?? 'mercadopago',
      },
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
}
