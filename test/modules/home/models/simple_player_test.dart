import 'package:flutter_test/flutter_test.dart';
import 'package:stopandgo/modules/home/models/simple_player.dart';

void main() {
  group('resolveAuthorizedPlayerId', () {
    final players = <SimplePlayer>[
      SimplePlayer(id: 1088, name: 'Jugador uno'),
      SimplePlayer(id: 1090, name: 'Jugador dos'),
    ];

    test('preserves a selected Player id returned by my-players', () {
      expect(resolveAuthorizedPlayerId(players, 1090), 1090);
    });

    test('rejects a persisted User id and selects the first Player', () {
      expect(resolveAuthorizedPlayerId(players, 1089), 1088);
    });

    test('selects the first Player when there is no persisted selection', () {
      expect(resolveAuthorizedPlayerId(players, null), 1088);
    });

    test('returns null when the parent has no authorized players', () {
      expect(resolveAuthorizedPlayerId(const [], 1089), isNull);
    });
  });
}
