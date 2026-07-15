import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:anime_watchlist_app/services/jikan_service.dart';

Map<String, dynamic> _entry(int malId, {String title = 'Test'}) => {
      'mal_id': malId,
      'title': title,
      'images': {
        'jpg': {'image_url': 'https://cdn.example/$malId.jpg'}
      },
      'episodes': 12,
      'score': 8.1,
      'airing': false,
      'genres': [
        {'name': 'Action'}
      ],
    };

String _body(List<Map<String, dynamic>> entries) =>
    jsonEncode({'data': entries});

void main() {
  group('JikanService.search', () {
    test('parses a successful response', () async {
      final service = JikanService(
        client: MockClient((_) async =>
            http.Response(_body([_entry(1, title: 'One'), _entry(2)]), 200)),
        retryBaseDelay: Duration.zero,
      );

      final results = await service.search('one');

      expect(results, hasLength(2));
      expect(results.first.malId, 1);
      expect(results.first.title, 'One');
      expect(results.first.score, 8.1);
    });

    test('returns an empty list for a blank query without a request',
        () async {
      var requests = 0;
      final service = JikanService(
        client: MockClient((_) async {
          requests++;
          return http.Response(_body([]), 200);
        }),
      );

      expect(await service.search('   '), isEmpty);
      expect(requests, 0);
    });

    test('retries a 429 and succeeds on the next attempt', () async {
      var requests = 0;
      final service = JikanService(
        client: MockClient((_) async {
          requests++;
          return requests == 1
              ? http.Response('rate limited', 429)
              : http.Response(_body([_entry(1)]), 200);
        }),
        retryBaseDelay: Duration.zero,
        sleep: (_) async {},
      );

      final results = await service.search('naruto');

      expect(results, hasLength(1));
      expect(requests, 2);
    });

    test('honors an integer Retry-After header', () async {
      var requests = 0;
      final slept = <Duration>[];
      final service = JikanService(
        client: MockClient((_) async {
          requests++;
          return requests == 1
              ? http.Response('rate limited', 429,
                  headers: {'retry-after': '1'})
              : http.Response(_body([_entry(1)]), 200);
        }),
        retryBaseDelay: Duration.zero,
        sleep: (d) async => slept.add(d),
      );

      await service.search('naruto');

      expect(slept, [const Duration(seconds: 1)]);
    });

    test('fails fast when Retry-After is too long to honor interactively',
        () async {
      var requests = 0;
      final service = JikanService(
        client: MockClient((_) async {
          requests++;
          return http.Response('rate limited', 429,
              headers: {'retry-after': '60'});
        }),
        sleep: (_) async {},
      );

      await expectLater(service.search('naruto'),
          throwsA(isA<JikanRateLimitException>()));
      expect(requests, 1);
    });

    test('throws JikanRateLimitException after persistent 429s', () async {
      var requests = 0;
      final service = JikanService(
        client: MockClient((_) async {
          requests++;
          return http.Response('rate limited', 429);
        }),
        maxAttempts: 3,
        retryBaseDelay: Duration.zero,
        sleep: (_) async {},
      );

      await expectLater(service.search('naruto'),
          throwsA(isA<JikanRateLimitException>()));
      expect(requests, 3);
    });

    test('retries 5xx and throws JikanApiException when exhausted', () async {
      var requests = 0;
      final service = JikanService(
        client: MockClient((_) async {
          requests++;
          return http.Response('oops', 503);
        }),
        maxAttempts: 2,
        retryBaseDelay: Duration.zero,
        sleep: (_) async {},
      );

      await expectLater(
          service.search('naruto'), throwsA(isA<JikanApiException>()));
      expect(requests, 2);
    });

    test('does not retry other 4xx errors', () async {
      var requests = 0;
      final service = JikanService(
        client: MockClient((_) async {
          requests++;
          return http.Response('bad request', 400);
        }),
        sleep: (_) async {},
      );

      await expectLater(
          service.search('naruto'), throwsA(isA<JikanApiException>()));
      expect(requests, 1);
    });

    test('throws JikanNetworkException after persistent network errors',
        () async {
      var requests = 0;
      final service = JikanService(
        client: MockClient((_) async {
          requests++;
          throw http.ClientException('connection refused');
        }),
        maxAttempts: 3,
        retryBaseDelay: Duration.zero,
        sleep: (_) async {},
      );

      await expectLater(service.search('naruto'),
          throwsA(isA<JikanNetworkException>()));
      expect(requests, 3);
    });

    test('skips malformed entries instead of failing the whole search',
        () async {
      final malformed = _entry(0)..['mal_id'] = null;
      final service = JikanService(
        client: MockClient((_) async => http.Response(
            _body([_entry(1), malformed, _entry(2)]), 200)),
      );

      final results = await service.search('naruto');

      expect(results.map((a) => a.malId), [1, 2]);
    });

    test('de-duplicates entries sharing a mal_id', () async {
      final service = JikanService(
        client: MockClient((_) async => http.Response(
            _body([_entry(1, title: 'First'), _entry(1, title: 'Dup')]), 200)),
      );

      final results = await service.search('naruto');

      expect(results, hasLength(1));
      expect(results.single.title, 'First');
    });

    test('throws JikanApiException on a non-JSON 200 body', () async {
      final service = JikanService(
        client: MockClient(
            (_) async => http.Response('<html>proxy error</html>', 200)),
      );

      await expectLater(
          service.search('naruto'), throwsA(isA<JikanApiException>()));
    });
  });
}
