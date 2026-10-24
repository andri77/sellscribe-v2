// Guard 1 (pact plan M5): the pacts are written in TypeScript, so this test proves the Dart
// models still agree with them. Every successful response example is parsed with the same
// fromJson the app uses, and the listing insert body is compared to ProductListing.toJson().
//
// Run from the repo root after `cd pact && npm run test:consumer`:
//   flutter test test/contract

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sellscribe/models/product_listing.dart';
import 'package:sellscribe/models/user.dart';

const _pactDir = 'pact/pacts';

List<Map<String, dynamic>> _interactions(String provider) {
  final file = File('$_pactDir/sellscribe-app-$provider.json');
  if (!file.existsSync()) {
    fail('${file.path} not found — run `npm run test:consumer` in pact/ first');
  }
  final pact = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return (pact['interactions'] as List).cast<Map<String, dynamic>>();
}

// Pact V4 stores the example under body.content; matchers live separately in matchingRules.
Object? _body(Map<String, dynamic> message) =>
    (message['body'] as Map<String, dynamic>?)?['content'];

int _status(Map<String, dynamic> interaction) =>
    (interaction['response'] as Map<String, dynamic>)['status'] as int;

String _path(Map<String, dynamic> interaction) =>
    (interaction['request'] as Map<String, dynamic>)['path'] as String;

// maybeSingle/list responses are arrays; single() responses are objects.
Iterable<Map<String, dynamic>> _rows(Object? body) => switch (body) {
      List rows => rows.cast<Map<String, dynamic>>(),
      Map<String, dynamic> row => [row],
      _ => const [],
    };

void main() {
  group('sellscribe-postgrest pact ↔ Dart models', () {
    final interactions = _interactions('sellscribe-postgrest')
        .where((i) => _status(i) >= 200 && _status(i) < 300)
        .toList();

    for (final interaction in interactions) {
      final description = interaction['description'] as String;
      final rows = _rows(_body(interaction['response'] as Map<String, dynamic>));
      if (rows.isEmpty) continue;

      test('parses response of "$description"', () {
        final path = _path(interaction);
        for (final row in rows) {
          if (path.endsWith('/profiles')) {
            final profile = UserProfile.fromJson(row);
            expect(profile.toJson().keys, containsAll(row.keys));
          } else if (path.endsWith('/listings')) {
            final listing = ProductListing.fromJson(row);
            expect(listing.toJson().keys, containsAll(row.keys));
          } else {
            fail('No Dart model mapped for $path');
          }
        }
      });
    }

    test('listing insert body matches ProductListing.toJson()', () {
      final insert = _interactions('sellscribe-postgrest').firstWhere((i) =>
          _path(i).endsWith('/listings') &&
          (i['request'] as Map<String, dynamic>)['method'] == 'POST');
      final body = _body(insert['request'] as Map<String, dynamic>) as Map<String, dynamic>;

      // id and created_at are only serialised once the row exists
      final dartKeys = ProductListing.fromJson(body).toJson().keys.toSet()..remove('id');
      expect(body.keys.toSet(), equals(dartKeys));
    });
  });

  group('sellscribe-generate-listing pact ↔ ListingProvider', () {
    for (final interaction in _interactions('sellscribe-generate-listing')
        .where((i) => _status(i) == 200)) {
      test('reads the fields of "${interaction['description']}"', () {
        final ai = _body(interaction['response'] as Map<String, dynamic>) as Map<String, dynamic>;

        // Same casts as ListingProvider.generateListing
        expect(ai['title'] as String?, isNotNull);
        expect(ai['description'] as String?, isNotNull);
        expect((ai['bullets'] as List<dynamic>?)?.map((e) => e.toString()).toList(), isNotEmpty);
        expect((ai['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList(), isNotEmpty);
      });
    }
  });
}
