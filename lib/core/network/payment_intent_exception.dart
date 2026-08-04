import 'package:dio/dio.dart';

class PaymentIntentException implements Exception {
  final int? statusCode;
  final String code;
  final String message;
  final Map<String, List<String>> fieldErrors;

  const PaymentIntentException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.fieldErrors = const {},
  });

  factory PaymentIntentException.fromDio(DioException error) {
    final payload = error.response?.data;
    final map = payload is Map ? Map<String, dynamic>.from(payload) : null;
    final code = map?['code']?.toString().trim() ?? '';
    final message = map?['message']?.toString().trim() ?? '';

    return PaymentIntentException(
      statusCode: error.response?.statusCode,
      code: code.isEmpty ? 'UNKNOWN_ERROR' : code,
      message: message.isEmpty
          ? _fallbackMessage(error.response?.statusCode)
          : message,
      fieldErrors: _parseFieldErrors(map?['errors']),
    );
  }

  bool get isAuthenticationError =>
      statusCode == 401 || code == 'UNAUTHENTICATED';

  bool get isPaymentCovered => code == 'PAYMENT_ALREADY_COVERED';

  bool get isRetryable =>
      statusCode == 503 ||
      code == 'PROVIDER_TEMPORARILY_UNAVAILABLE' ||
      code == 'PROVIDER_COMMUNICATION_ERROR';

  static String _fallbackMessage(int? statusCode) => switch (statusCode) {
    401 => 'Tu sesión expiró. Inicia sesión nuevamente.',
    404 => 'No encontramos el pago solicitado.',
    422 => 'No fue posible generar las instrucciones de pago.',
    503 => 'El servicio de pagos no está disponible por el momento.',
    _ => 'No fue posible comunicarse con el servicio de pagos.',
  };

  static Map<String, List<String>> _parseFieldErrors(dynamic raw) {
    if (raw is! Map) return const {};
    final result = <String, List<String>>{};
    raw.forEach((key, value) {
      final messages = value is List ? value : [value];
      final parsed = messages
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
      if (parsed.isNotEmpty) result[key.toString()] = parsed;
    });
    return result;
  }

  @override
  String toString() => message;
}
