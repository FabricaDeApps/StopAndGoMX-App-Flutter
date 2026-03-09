import 'package:flutter_test/flutter_test.dart';
import 'package:stopandgo/core/models/gazzetta/gazetta_payload.dart';

void main() {
  test('parse payload completo', () {
    final payload = GazettaPayload.fromJson({
      'summary': 'Resumen semanal',
      'highlights': ['A', 'B'],
      'matches': [
        {
          'opponent': 'Rival FC',
          'home_score': 21,
          'opponent_score': 14,
          'image_url': 'https://img.test/match.png',
        },
      ],
      'sections': [
        {'title': 'Ofensiva', 'content': 'Gran ejecución'},
      ],
    });

    expect(payload.summary, 'Resumen semanal');
    expect(payload.highlights.length, 2);
    expect(payload.matches.first.opponent, 'Rival FC');
    expect(payload.sections.first.title, 'Ofensiva');
  });

  test('parse payload parcial/null-safe', () {
    final payload = GazettaPayload.fromJson({'highlights': null});

    expect(payload.summary, isNull);
    expect(payload.highlights, isEmpty);
    expect(payload.matches, isEmpty);
    expect(payload.sections, isEmpty);
  });
}
