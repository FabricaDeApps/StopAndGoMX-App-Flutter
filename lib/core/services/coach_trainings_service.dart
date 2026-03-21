import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/responses/generic_response.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/network/api_request_exception.dart';

class CoachTrainingsService extends GetxService {
  final ApiRepository _api = Get.find<ApiRepository>();

  Future<GenericResponse> createTraining({
    required int categoryId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final res = await _api.managerCreateTrainingRequest(
        categoryId: categoryId,
        data: data,
      );
      return _toGenericResponse(
        res.data,
        successMessage: 'Entrenamiento creado.',
      );
    } on DioException catch (e) {
      throw ApiRequestException.fromDio(
        e,
        fallbackMessage: 'No se pudo crear el entrenamiento.',
      );
    }
  }

  Future<GenericResponse> updateTraining({
    required int categoryId,
    required int trainingId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final res = await _api.managerUpdateTrainingRequest(
        categoryId: categoryId,
        trainingId: trainingId,
        data: data,
      );
      return _toGenericResponse(
        res.data,
        successMessage: 'Entrenamiento actualizado.',
      );
    } on DioException catch (e) {
      throw ApiRequestException.fromDio(
        e,
        fallbackMessage: 'No se pudo actualizar el entrenamiento.',
      );
    }
  }

  GenericResponse _toGenericResponse(
    dynamic raw, {
    required String successMessage,
  }) {
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      map['success'] = map['success'] ?? true;
      map['message'] = map['message'] ?? successMessage;
      return GenericResponse.fromJson(map);
    }
    return GenericResponse(success: true, message: successMessage);
  }
}
