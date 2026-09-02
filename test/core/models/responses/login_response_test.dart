import 'package:flutter_test/flutter_test.dart';
import 'package:stopandgo/core/models/responses/login_response.dart';

void main() {
  group('User player_id contract', () {
    test('keeps users.id and players.id as different values', () {
      final user = User.fromJson({
        'id': 1089,
        'player_id': 1088,
        'role': 'player',
        'roles': ['parent', 'player'],
        'primary_role': 'parent',
        'active_role': 'player',
      });

      expect(user.id, 1089);
      expect(user.playerId, 1088);
      expect(user.toJson()['player_id'], 1088);
    });

    test('preserves an explicit null player_id for the parent role', () {
      final player = User.fromJson({
        'id': 1089,
        'player_id': 1088,
        'active_role': 'player',
      });

      final parent = player.copyWith(
        role: 'parent',
        activeRole: 'parent',
        playerId: null,
      );

      expect(parent.id, 1089);
      expect(parent.playerId, isNull);
      expect(parent.toJson()['player_id'], isNull);
    });
  });
}
