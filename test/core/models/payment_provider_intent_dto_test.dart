import 'package:flutter_test/flutter_test.dart';
import 'package:stopandgo/core/models/dto/payment_provider_intent_dto.dart';

void main() {
  test('parsea el contrato SPEI y prefiere instructions_url', () {
    final intent = PaymentProviderIntentDto.fromJson({
      'payment_id': 456,
      'provider': 'mercadopago',
      'payment_method': 'spei_transfer',
      'amount': '850.00',
      'currency': 'MXN',
      'intent_id': 123,
      'provider_intent_id': 'ORD01ABC123',
      'init_url': 'https://example.com/init',
      'status': 'action_required',
      'status_detail': 'waiting_transfer',
      'reference': '646010349353743569',
      'ticket_url': 'https://example.com/ticket',
      'expires_at': '2026-08-06T10:00:00.000-06:00',
      'payment_instructions': {
        'type': 'spei_transfer',
        'provider': 'mercadopago',
        'status': 'action_required',
        'reference': '646010349353743569',
        'instructions_url': 'https://example.com/instructions',
        'instructions_url_content_type': 'text/html',
        'steps': ['Abre las instrucciones.', 'Completa la transferencia.'],
      },
      'reused': true,
    });

    expect(intent.paymentId, 456);
    expect(intent.amount, '850.00');
    expect(intent.paymentMethod, 'spei_transfer');
    expect(intent.instructionsUrl, 'https://example.com/instructions');
    expect(intent.speiReference, '646010349353743569');
    expect(intent.paymentInstructions?.steps, hasLength(2));
    expect(intent.reused, isTrue);
  });

  test('tolera campos anulables de un intent de tarjeta', () {
    final intent = PaymentProviderIntentDto.fromJson({
      'provider': 'mercadopago',
      'intent_id': 9,
      'init_url': null,
      'payment_instructions': null,
    });

    expect(intent.paymentMethod, 'card');
    expect(intent.initUrl, isNull);
    expect(intent.paymentInstructions, isNull);
    expect(intent.instructionsUrl, isNull);
  });
}
