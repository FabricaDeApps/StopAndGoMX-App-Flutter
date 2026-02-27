import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/responses/generic_response.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/network/api_request_exception.dart';

class CoachGamesService extends GetxService {
  final ApiRepository _api = Get.find<ApiRepository>();

  Future<GenericResponse> createGame({
    required int categoryId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final res = await _api.coachCreateGameRequest(
        categoryId: categoryId,
        data: data,
      );
      return _toGenericResponse(res.data, successMessage: 'Juego creado.');
    } on DioException catch (e) {
      throw ApiRequestException.fromDio(
        e,
        fallbackMessage: 'No se pudo crear el juego.',
      );
    }
  }

  Future<GenericResponse> updateGame({
    required int categoryId,
    required int gameId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final res = await _api.coachUpdateGameRequest(
        categoryId: categoryId,
        gameId: gameId,
        data: data,
      );
      return _toGenericResponse(res.data, successMessage: 'Juego actualizado.');
    } on DioException catch (e) {
      throw ApiRequestException.fromDio(
        e,
        fallbackMessage: 'No se pudo actualizar el juego.',
      );
    }
  }

  GenericResponse _toGenericResponse(
    dynamic raw, {
    required String successMessage,
  }) {
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw as Map);
      map['success'] = map['success'] ?? true;
      map['message'] = map['message'] ?? successMessage;
      return GenericResponse.fromJson(map);
    }
    return GenericResponse(success: true, message: successMessage);
  }
}
