import 'package:flutter_test/flutter_test.dart';
import 'package:stopandgo/core/models/gazzetta/gazetta_meta.dart';

void main() {
  test('parse meta con seen bool/int/string', () {
    final a = GazettaMeta.fromJson({'id': 1, 'seen': true});
    final b = GazettaMeta.fromJson({'id': 2, 'seen': 1});
    final c = GazettaMeta.fromJson({'id': 3, 'seen': '0'});

    expect(a.seen, isTrue);
    expect(b.seen, isTrue);
    expect(c.seen, isFalse);
  });
}
