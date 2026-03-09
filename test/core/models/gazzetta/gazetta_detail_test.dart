import 'package:flutter_test/flutter_test.dart';
import 'package:stopandgo/core/models/gazzetta/gazetta_detail.dart';

void main() {
  test('parse detail con json_payload', () {
    final detail = GazettaDetail.fromJson({
      'id': 9,
      'organization_id': 3,
      'subject': 'Semana 10',
      'published_at': '2026-03-01T12:00:00Z',
      'json_payload': {
        'summary': 'Resumen',
        'highlights': ['H1'],
      },
    });

    expect(detail.id, 9);
    expect(detail.organizationId, 3);
    expect(detail.subject, 'Semana 10');
    expect(detail.jsonPayload.summary, 'Resumen');
    expect(detail.jsonPayload.highlights, ['H1']);
  });

  test('parse detail con html nuevo', () {
    final detail = GazettaDetail.fromJson({
      'id': 10,
      'html': '<html><body>Contenido</body></html>',
      'json_payload': {'highlights': []},
    });

    expect(detail.id, 10);
    expect(detail.html, '<html><body>Contenido</body></html>');
  });
}
