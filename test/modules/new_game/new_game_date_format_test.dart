import 'package:flutter_test/flutter_test.dart';
import 'package:stopandgo/modules/new_game/new_game_controller.dart';

void main() {
  test('fecha de partido se envía como ISO 8601 con zona horaria', () {
    final localDate = DateTime(2026, 8, 15, 18, 30);

    final formatted = formatGameDateForApi(localDate);

    expect(formatted, matches(RegExp(r'^2026-08-15T18:30:00[+-]\d{2}:\d{2}$')));
    expect(DateTime.parse(formatted).toUtc(), localDate.toUtc());
  });
}
