import 'dart:convert';
import 'dart:io';

/// Simple Firestore REST seeder that writes products into the emulator.
///
/// Usage:
///   dart scripts/seed_products.dart --project=my-project --count=30
/// Environment:
///   FIREBASE_PROJECT can be used instead of --project
///   EMULATOR_HOST (defaults to 127.0.0.1)
///   EMULATOR_PORT (defaults to 8080)

Future<void> main(List<String> args) async {
  final argMap = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a.startsWith('--') && i + 1 < args.length) {
      argMap[a.substring(2)] = args[i + 1];
      i++;
    }
  }

  final projectId = argMap['project'] ??
      Platform.environment['FIREBASE_PROJECT'] ??
      'demo-project';
  final count = int.tryParse(argMap['count'] ?? '') ?? 30;
  final host =
      Platform.environment['EMULATOR_HOST'] ?? argMap['host'] ?? '127.0.0.1';
  final port =
      Platform.environment['EMULATOR_PORT'] ?? argMap['port'] ?? '8080';

  final base =
      'http://$host:$port/v1/projects/$projectId/databases/(default)/documents/products';

  final dataFile = File('data/seed_products.json');
  if (!await dataFile.exists()) {
    stderr.writeln('data/seed_products.json not found');
    exit(2);
  }

  final List<dynamic> allProducts =
      jsonDecode(await dataFile.readAsString())['products'];
  if (allProducts.isEmpty) {
    stderr.writeln('No template products found in data/seed_products.json');
    exit(3);
  }

  stdout
      .writeln('Seeding $count products to $host:$port (project: $projectId)');

  final client = HttpClient();
  var created = 0;
  for (var i = 0; i < count; i++) {
    final t = allProducts[i % allProducts.length] as Map<String, dynamic>;
    final id = 'p_${DateTime.now().millisecondsSinceEpoch}_$i';
    final body = {
      'fields': t.map((k, v) {
        if (v is String) return MapEntry(k, {'stringValue': v});
        if (v is int) return MapEntry(k, {'integerValue': v.toString()});
        if (v is double) return MapEntry(k, {'doubleValue': v});
        if (v is bool) return MapEntry(k, {'booleanValue': v});
        return MapEntry(k, {'stringValue': v.toString()});
      })
    };

    final uri = Uri.parse('$base?documentId=$id');
    final req = await client.postUrl(uri);
    req.headers.set('Content-Type', 'application/json');
    req.add(utf8.encode(jsonEncode(body)));
    final resp = await req.close();
    final respBody = await resp.transform(utf8.decoder).join();
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      created++;
      stdout.writeln('Created product $id');
    } else {
      stderr.writeln('Failed to create $id: ${resp.statusCode} $respBody');
    }
    // small throttle
    await Future.delayed(Duration(milliseconds: 50));
  }

  stdout.writeln('Seeding complete. Created $created products');
  client.close();
}
