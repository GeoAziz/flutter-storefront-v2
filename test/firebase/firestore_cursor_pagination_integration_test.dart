import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

// REST-based Firestore emulator pagination test.
// Requires the emulator to be running locally and FIREBASE_EMULATOR=true in environment.

void main() {
  final runEmulator = (Platform.environment['FIREBASE_EMULATOR'] ?? '').toLowerCase() == 'true';
  const host = '127.0.0.1';
  const port = 8080;
  const project = 'demo-no-project';
  final baseUrl = Uri.parse('http://$host:$port/v1/projects/$project/databases/(default)');

  group('Firestore cursor pagination integration (REST)', () {
    test('cursor pagination returns multiple pages', () async {
      if (!runEmulator) {
        print('Skipping emulator integration test. Set FIREBASE_EMULATOR=true to run.');
        return;
      }

      final client = HttpClient();
      final collection = 'products_test_cursor';

      // Helper: create a document (auto-id) in the collection via POST to /documents/{collection}
      Future<void> putDoc(DateTime createdAt, int price, String name) async {
  final url = baseUrl.resolve('documents/$collection');
        final body = json.encode({
          'fields': {
            'name': {'stringValue': name},
            'createdAt': {'timestampValue': createdAt.toUtc().toIso8601String()},
            'price': {'integerValue': price.toString()},
          }
        });
        final req = await client.postUrl(url);
        req.headers.set('content-type', 'application/json');
        req.add(utf8.encode(body));
        final resp = await req.close();
        final respBody = await resp.transform(utf8.decoder).join();
        if (resp.statusCode < 200 || resp.statusCode >= 300) {
          // Debug aid: print URL and response body
          // ignore: avoid_print
          print('PUT-POST to ${url.toString()} returned ${resp.statusCode}: $respBody');
          throw StateError('Failed to put doc: ${resp.statusCode} $respBody');
        }
      }

      // Helper: run structuredQuery via REST runQuery
      Future<List<Map<String, dynamic>>> runQuery({DateTime? startAfter, int limit = 10}) async {
  final url = baseUrl.resolve('documents:runQuery');
        final orderBy = [
          {
            'field': {'fieldPath': 'createdAt'},
            'direction': 'DESCENDING'
          }
        ];

        final structuredQuery = {
          'from': [ {'collectionId': collection} ],
          'orderBy': orderBy,
          'limit': limit,
        };

        if (startAfter != null) {
          structuredQuery['startAfter'] = {
            'values': [
              {'timestampValue': startAfter.toUtc().toIso8601String()}
            ]
          };
        }

        final body = json.encode({'structuredQuery': structuredQuery});
        final req = await client.postUrl(url);
        req.headers.set('content-type', 'application/json');
        req.add(utf8.encode(body));
        final resp = await req.close();
        final respBody = await resp.transform(utf8.decoder).join();
        if (resp.statusCode < 200 || resp.statusCode >= 300) {
          throw StateError('runQuery failed: ${resp.statusCode} $respBody');
        }

        final List<dynamic> arr = json.decode(respBody) as List<dynamic>;
        final docs = <Map<String, dynamic>>[];
        for (final item in arr) {
          if (item is Map && item.containsKey('document')) {
            docs.add(item['document'] as Map<String, dynamic>);
          }
        }
        return docs;
      }

      // Clean up previous test docs by listing and deleting existing docs in the collection.
      try {
  final listUrl = baseUrl.resolve('documents/$collection');
        final listReq = await client.getUrl(listUrl);
        final listResp = await listReq.close();
        final listBody = await listResp.transform(utf8.decoder).join();
        if (listResp.statusCode == 200) {
          final parsed = json.decode(listBody) as Map<String, dynamic>?;
          final docs = parsed?['documents'] as List<dynamic>?;
          if (docs != null) {
            for (final d in docs) {
              final name = d['name'] as String?;
              if (name != null) {
                // name is full resource path; convert to relative '/documents/...' path
                try {
                  final uri = Uri.parse(name);
                  final rel = uri.path.replaceFirst('/v1/projects/$project/databases/(default)', '');
                  final delUrl = baseUrl.resolve(rel);
                  final delReq = await client.deleteUrl(delUrl);
                  final delResp = await delReq.close();
                  await delResp.drain();
                } catch (_) {}
              }
            }
          }
        }
      } catch (_) {}

      // Seed 25 documents with distinct createdAt timestamps (descending)
      final now = DateTime.now();
      for (var i = 0; i < 25; i++) {
        final createdAt = now.subtract(Duration(minutes: i));
        await putDoc(createdAt, 100 + i, 'Product $i');
      }

      // Fetch pages
      final page1Docs = await runQuery(limit: 10);
      expect(page1Docs.length, 10);
      final last1 = page1Docs.last;
      final last1Created = DateTime.parse((last1['fields']['createdAt']['timestampValue'] as String));

      final page2Docs = await runQuery(startAfter: last1Created, limit: 10);
      expect(page2Docs.length, 10);
      final last2 = page2Docs.last;
      final last2Created = DateTime.parse((last2['fields']['createdAt']['timestampValue'] as String));

      final page3Docs = await runQuery(startAfter: last2Created, limit: 10);
      expect(page3Docs.length, 5);

      client.close(force: true);
    });
  });
}
