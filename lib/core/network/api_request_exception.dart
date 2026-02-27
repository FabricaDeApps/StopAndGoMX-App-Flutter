import 'package:dio/dio.dart';

class ApiRequestException implements Exception {
  final int? statusCode;
  final String message;
  final Map<String, List<String>> fieldErrors;

  ApiRequestException({
    required this.statusCode,
    required this.message,
    this.fieldErrors = const {},
  });

  factory ApiRequestException.fromDio(
    DioException e, {
    String fallbackMessage = 'Ocurrió un error al procesar la solicitud.',
  }) {
    final status = e.response?.statusCode;
    final payload = e.response?.data;
    final apiMessage = _extractApiMessage(payload);
    final errors = _extractFieldErrors(payload);

    if (status == 403) {
      return ApiRequestException(
        statusCode: status,
        message: 'No autorizado para esta categoría',
      );
    }

    if (status == 422) {
      final validation = _formatFieldErrors(errors);
      return ApiRequestException(
        statusCode: status,
        message: validation ?? apiMessage ?? fallbackMessage,
        fieldErrors: errors,
      );
    }

    if (status == 409) {
      return ApiRequestException(
        statusCode: status,
        message: apiMessage ?? fallbackMessage,
      );
    }

    return ApiRequestException(
      statusCode: status,
      message: apiMessage ?? e.message ?? fallbackMessage,
      fieldErrors: errors,
    );
  }

  static String? _extractApiMessage(dynamic payload) {
    if (payload is Map) {
      final raw = payload['message'];
      if (raw is String && raw.trim().isNotEmpty) {
        return raw.trim();
      }
    }
    return null;
  }

  static Map<String, List<String>> _extractFieldErrors(dynamic payload) {
    if (payload is! Map) return const {};
    final rawErrors = payload['errors'];
    if (rawErrors is! Map) return const {};

    final result = <String, List<String>>{};

    rawErrors.forEach((key, value) {
      final field = key.toString();
      if (value is List) {
        final items = value
            .map((e) => e?.toString().trim() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
        if (items.isNotEmpty) result[field] = items;
        return;
      }

      final one = value?.toString().trim() ?? '';
      if (one.isNotEmpty) {
        result[field] = [one];
      }
    });

    return result;
  }

  static String? _formatFieldErrors(Map<String, List<String>> errors) {
    if (errors.isEmpty) return null;

    final chunks = <String>[];
    errors.forEach((field, messages) {
      if (messages.isEmpty) return;
      chunks.add('$field: ${messages.join(', ')}');
    });
    if (chunks.isEmpty) return null;
    return chunks.join('\n');
  }

  @override
  String toString() => 'ApiRequestException($statusCode): $message';
}
