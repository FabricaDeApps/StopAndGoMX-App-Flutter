import 'dart:io';

import 'package:dio/dio.dart';
import 'package:stopandgo/core/config/flavor_config.dart';
import 'package:stopandgo/core/constants/api_endpoints.dart';
import 'package:stopandgo/core/models/category.dart';
import 'package:stopandgo/core/models/dto/payment_dto.dart';
import 'package:stopandgo/core/models/games.dart';
import 'package:stopandgo/core/models/players.dart';
import 'package:stopandgo/core/models/responses/generic_response.dart';
import 'package:stopandgo/core/models/responses/login_response.dart';
import 'package:stopandgo/core/models/responses/organization_response.dart';
import 'package:stopandgo/core/models/training.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'api_client.dart';
import 'token_storage.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;

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

  // ApiRepository.dart (fragmentos relevantes)
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.authLogin,
        data: {
          'email': email,
          'password': password,
          'so': 'android',
          'device_token': 'fcm_device_token_demo',
          'device_name': 'Pixel 8',
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

  /// Refresh con refresh_token persistido
  Future<void> refreshAccessToken() async {
    final rt = _tokenStorage.refreshToken;
    if (rt == null || rt.isEmpty) throw Exception('No hay refresh_token');

    final res = await _dio.post(
      ApiEndpoints.authRefresh,
      data: {'refresh_token': rt},
      options: Options(headers: {'Accept': 'application/json'}),
    );

    // Respuesta tipo login (solo access token + ttl; algunos backends regresan todo)
    final data = res.data as Map<String, dynamic>;

    final newAccess = data['access_token'] as String;
    final ttl = (data['access_expires_in_minutes'] as num).toInt();

    // Si el backend también devuelve un nuevo refresh_token, puedes actualizarlo aquí.
    // final newRefresh   = data['refresh_token'] as String? ?? _tokenStorage.refreshToken;
    // final refreshExpAt = data['refresh_expires_at'] as String? ?? _tokenStorage.refreshExpAt?.toIso8601String();

    await _tokenStorage.updateAccess(
      accessToken: newAccess,
      accessTtlMinutes: ttl,
    );
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
  Future<List<Game>> playerMyGames({required int playerId}) async {
    final res = await _dio.get(
      '/player/my-games',
      queryParameters: {'player_id': playerId},
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

  // manager: /manager/{categoryId}/payments (usa res.data['data'])
  Future<List<PaymentDto>> managerCategoryPayments({
    required int categoryId,
  }) async {
    final res = await _dio.get(
      '/manager/$categoryId/payments',
      options: Options(headers: _headers()),
    );
    final data = (res.data['data'] as List?) ?? const [];
    return data
        .map((e) => PaymentDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
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
  }) async {
    final res = await _dio.get(
      '/manager/$categoryId/trainings',
      options: Options(headers: _headers()),
    );

    final data = (res.data['data'] as List?) ?? [];

    return data
        .map((e) => Training.fromJson(Map<String, dynamic>.from(e)))
        .toList();
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

  /// Helper para subir comprobante (multipart)
  Future<void> uploadReceipt({
    required int paymentId,
    required String filePath,
    required double amount,
    required String paidAtIso, // 2025-11-06T13:15:00Z
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

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
