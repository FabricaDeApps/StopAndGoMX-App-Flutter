import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopandgo/core/network/api_request_exception.dart';

void main() {
  test('422 usa el primer mensaje de validación del backend', () {
    final request = RequestOptions(path: '/manager/12/games/create');
    final dioError = DioException(
      requestOptions: request,
      response: Response<dynamic>(
        requestOptions: request,
        statusCode: 422,
        data: {
          'message': 'Validation failed.',
          'errors': {
            'opponent_name': ['The opponent name field is required.'],
            'venue_id': ['The venue id field is required.'],
          },
        },
      ),
    );

    final error = ApiRequestException.fromDio(dioError);

    expect(error.statusCode, 422);
    expect(error.message, 'The opponent name field is required.');
  });

  test('409 conserva el mensaje de conflicto del backend', () {
    final request = RequestOptions(path: '/manager/12/games/create');
    final dioError = DioException(
      requestOptions: request,
      response: Response<dynamic>(
        requestOptions: request,
        statusCode: 409,
        data: {
          'success': false,
          'message': 'Ya existe un juego con ese rival.',
        },
      ),
    );

    final error = ApiRequestException.fromDio(dioError);

    expect(error.statusCode, 409);
    expect(error.message, 'Ya existe un juego con ese rival.');
  });
}
