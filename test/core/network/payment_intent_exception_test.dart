import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopandgo/core/network/payment_intent_exception.dart';

void main() {
  test('conserva code y detecta un pago cubierto', () {
    final request = RequestOptions(
      path: '/payments/1/providers/mercadopago/intent',
    );
    final dioError = DioException(
      requestOptions: request,
      response: Response<dynamic>(
        requestOptions: request,
        statusCode: 422,
        data: {
          'code': 'PAYMENT_ALREADY_COVERED',
          'message': 'Este pago ya está cubierto.',
        },
      ),
    );

    final error = PaymentIntentException.fromDio(dioError);

    expect(error.statusCode, 422);
    expect(error.code, 'PAYMENT_ALREADY_COVERED');
    expect(error.isPaymentCovered, isTrue);
    expect(error.isRetryable, isFalse);
  });

  test('marca errores temporales del proveedor como reintentables', () {
    final request = RequestOptions(
      path: '/payments/1/providers/mercadopago/intent',
    );
    final dioError = DioException(
      requestOptions: request,
      response: Response<dynamic>(
        requestOptions: request,
        statusCode: 503,
        data: {
          'code': 'PROVIDER_COMMUNICATION_ERROR',
          'message': 'No se pudo comunicar con Mercado Pago.',
        },
      ),
    );

    final error = PaymentIntentException.fromDio(dioError);

    expect(error.isRetryable, isTrue);
    expect(error.toString(), 'No se pudo comunicar con Mercado Pago.');
  });
}
