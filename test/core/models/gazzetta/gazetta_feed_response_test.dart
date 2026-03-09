import 'package:flutter_test/flutter_test.dart';
import 'package:stopandgo/core/models/gazzetta/gazetta_feed_response.dart';

void main() {
  test('feed acepta data null', () {
    final feed = GazettaFeedResponse.fromJson({'data': null});
    expect(feed.data, isNull);
  });

  test('feed parsea data map', () {
    final feed = GazettaFeedResponse.fromJson({
      'data': {
        'id': 55,
        'subject': 'Última edición',
        'json_payload': {'highlights': []},
      },
    });

    expect(feed.data, isNotNull);
    expect(feed.data!.id, 55);
    expect(feed.data!.subject, 'Última edición');
  });
}
