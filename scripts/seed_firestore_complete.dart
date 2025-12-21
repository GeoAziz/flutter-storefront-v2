import 'dart:convert';
import 'dart:io';

/// Comprehensive Firestore seeder that populates ALL collections
///
/// Usage:
///   dart scripts/seed_firestore_complete.dart --project=my-project
/// Environment:
///   FIREBASE_PROJECT can be used instead of --project
///   EMULATOR_HOST (defaults to 127.0.0.1)
///   EMULATOR_PORT (defaults to 8080)
///
/// Seeds data in dependency order:
///   1. Categories
///   2. Products (with dynamic search terms)
///   3. Inventory
///   4. Users
///   5. Home Config

Future<void> main(List<String> args) async {
  final argMap = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a.startsWith('--')) {
      final parts = a.substring(2).split('=');
      if (parts.length == 2) {
        argMap[parts[0]] = parts[1];
      } else if (i + 1 < args.length) {
        argMap[parts[0]] = args[i + 1];
        i++;
      }
    }
  }

  final projectId = argMap['project'] ??
      Platform.environment['FIREBASE_PROJECT'] ??
      'demo-project';
  final host =
      Platform.environment['EMULATOR_HOST'] ?? argMap['host'] ?? '127.0.0.1';
  final port =
      Platform.environment['EMULATOR_PORT'] ?? argMap['port'] ?? '8080';

  final baseUrl = 'http://$host:$port/v1/projects/$projectId/databases/(default)/documents';

  stdout.writeln('\n🚀 Starting comprehensive Firestore seeding...');
  stdout.writeln('📍 Target: $host:$port (project: $projectId)\n');

  final client = HttpClient();
  var totalCreated = 0;

  try {
    // 1. Seed Categories
    stdout.writeln('📂 Seeding categories...');
    final categoriesCreated = await seedCategories(client, baseUrl);
    totalCreated += categoriesCreated;
    stdout.writeln('✅ Created $categoriesCreated categories\n');

    // 2. Seed Products
    stdout.writeln('📦 Seeding products...');
    final productsCreated = await seedProducts(client, baseUrl);
    totalCreated += productsCreated;
    stdout.writeln('✅ Created $productsCreated products\n');

    // 3. Seed Inventory
    stdout.writeln('📊 Seeding inventory...');
    final inventoryCreated = await seedInventory(client, baseUrl);
    totalCreated += inventoryCreated;
    stdout.writeln('✅ Created $inventoryCreated inventory records\n');

    // 4. Seed Users
    stdout.writeln('👥 Seeding users...');
    final usersCreated = await seedUsers(client, baseUrl);
    totalCreated += usersCreated;
    stdout.writeln('✅ Created $usersCreated users\n');

    // 5. Seed Home Config
    stdout.writeln('🏠 Seeding home configuration...');
    final homeConfigCreated = await seedHomeConfig(client, baseUrl);
    totalCreated += homeConfigCreated;
    stdout.writeln('✅ Created home configuration\n');

    // Summary
    stdout.writeln('═══════════════════════════════════════');
    stdout.writeln('🎉 SEEDING COMPLETE!');
    stdout.writeln('═══════════════════════════════════════');
    stdout.writeln('Total documents created: $totalCreated');
    stdout.writeln('  • Categories: $categoriesCreated');
    stdout.writeln('  • Products: $productsCreated');
    stdout.writeln('  • Inventory: $inventoryCreated');
    stdout.writeln('  • Users: $usersCreated');
    stdout.writeln('  • Config: $homeConfigCreated');
    stdout.writeln('═══════════════════════════════════════\n');
  } catch (e, stack) {
    stderr.writeln('\n❌ Error during seeding: $e');
    stderr.writeln(stack);
    exit(1);
  } finally {
    client.close();
  }
}

Future<int> seedCategories(HttpClient client, String baseUrl) async {
  final file = File('data/seed_categories.json');
  if (!await file.exists()) {
    stderr.writeln('❌ data/seed_categories.json not found');
    return 0;
  }

  final data = jsonDecode(await file.readAsString());
  final categories = data['categories'] as List<dynamic>;

  var created = 0;
  for (final category in categories) {
    final categoryMap = category as Map<String, dynamic>;
    final id = categoryMap['id'] as String;

    // Add timestamps
    categoryMap['createdAt'] = DateTime.now().toIso8601String();
    categoryMap['updatedAt'] = DateTime.now().toIso8601String();

    final success = await createDocument(
      client,
      baseUrl,
      'categories',
      id,
      categoryMap,
    );

    if (success) {
      created++;
      stdout.write('.');
    } else {
      stdout.write('x');
    }
  }
  stdout.writeln();
  return created;
}

Future<int> seedProducts(HttpClient client, String baseUrl) async {
  final file = File('data/seed_products.json');
  if (!await file.exists()) {
    stderr.writeln('❌ data/seed_products.json not found');
    return 0;
  }

  final data = jsonDecode(await file.readAsString());
  final products = data['products'] as List<dynamic>;

  var created = 0;
  for (final product in products) {
    final productMap = product as Map<String, dynamic>;
    final id = productMap['id'] as String;

    // Add timestamps if not present
    productMap['createdAt'] ??= DateTime.now().toIso8601String();
    productMap['updatedAt'] = DateTime.now().toIso8601String();

    // Generate search terms dynamically
    productMap['searchTerms'] = _generateSearchTerms(productMap);

    final success = await createDocument(
      client,
      baseUrl,
      'products',
      id,
      productMap,
    );

    if (success) {
      created++;
      stdout.write('.');
    } else {
      stdout.write('x');
    }

    // Small throttle to avoid overwhelming the emulator
    await Future.delayed(Duration(milliseconds: 20));
  }
  stdout.writeln();
  return created;
}

Future<int> seedInventory(HttpClient client, String baseUrl) async {
  final file = File('data/seed_inventory.json');
  if (!await file.exists()) {
    stderr.writeln('❌ data/seed_inventory.json not found');
    return 0;
  }

  final data = jsonDecode(await file.readAsString());
  final inventory = data['inventory'] as List<dynamic>;

  var created = 0;
  for (final item in inventory) {
    final itemMap = item as Map<String, dynamic>;
    final productId = itemMap['productId'] as String;

    // Add timestamps
    itemMap['createdAt'] = DateTime.now().toIso8601String();
    itemMap['updatedAt'] = DateTime.now().toIso8601String();

    final success = await createDocument(
      client,
      baseUrl,
      'inventory',
      productId,
      itemMap,
    );

    if (success) {
      created++;
      stdout.write('.');
    } else {
      stdout.write('x');
    }
  }
  stdout.writeln();
  return created;
}

Future<int> seedUsers(HttpClient client, String baseUrl) async {
  final file = File('data/seed_users.json');
  if (!await file.exists()) {
    stderr.writeln('❌ data/seed_users.json not found');
    return 0;
  }

  final data = jsonDecode(await file.readAsString());
  final users = data['users'] as List<dynamic>;

  var created = 0;
  for (final user in users) {
    final userMap = user as Map<String, dynamic>;
    final uid = userMap['uid'] as String;

    // Add timestamps if not present
    userMap['updatedAt'] = DateTime.now().toIso8601String();

    final success = await createDocument(
      client,
      baseUrl,
      'users',
      uid,
      userMap,
    );

    if (success) {
      created++;
      stdout.write('.');
    } else {
      stdout.write('x');
    }
  }
  stdout.writeln();
  return created;
}

Future<int> seedHomeConfig(HttpClient client, String baseUrl) async {
  final file = File('data/seed_home_config.json');
  if (!await file.exists()) {
    stderr.writeln('❌ data/seed_home_config.json not found');
    return 0;
  }

  final data = jsonDecode(await file.readAsString());
  final homeScreen = data['homeScreen'] as Map<String, dynamic>;

  // Add timestamps
  homeScreen['createdAt'] = DateTime.now().toIso8601String();
  homeScreen['updatedAt'] = DateTime.now().toIso8601String();

  final success = await createDocument(
    client,
    baseUrl,
    'appConfig',
    'homeScreen',
    homeScreen,
  );

  return success ? 1 : 0;
}

Future<bool> createDocument(
  HttpClient client,
  String baseUrl,
  String collection,
  String documentId,
  Map<String, dynamic> data,
) async {
  try {
    final body = {'fields': _toFirestoreFields(data)};
    final uri = Uri.parse('$baseUrl/$collection?documentId=$documentId');

    final req = await client.postUrl(uri);
    req.headers.set('Content-Type', 'application/json');
    req.add(utf8.encode(jsonEncode(body)));

    final resp = await req.close();
    final respBody = await resp.transform(utf8.decoder).join();

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return true;
    } else {
      stderr.writeln(
          '\n❌ Failed to create $collection/$documentId: ${resp.statusCode}');
      if (respBody.length < 500) {
        stderr.writeln('   Response: $respBody');
      }
      return false;
    }
  } catch (e) {
    stderr.writeln('\n❌ Exception creating $collection/$documentId: $e');
    return false;
  }
}

Map<String, dynamic> _toFirestoreFields(Map<String, dynamic> data) {
  final fields = <String, dynamic>{};

  for (final entry in data.entries) {
    fields[entry.key] = _toFirestoreValue(entry.value);
  }

  return fields;
}

dynamic _toFirestoreValue(dynamic value) {
  if (value == null) {
    return {'nullValue': null};
  } else if (value is String) {
    return {'stringValue': value};
  } else if (value is int) {
    return {'integerValue': value.toString()};
  } else if (value is double) {
    return {'doubleValue': value};
  } else if (value is bool) {
    return {'booleanValue': value};
  } else if (value is List) {
    return {
      'arrayValue': {
        'values': value.map((item) => _toFirestoreValue(item)).toList()
      }
    };
  } else if (value is Map) {
    return {
      'mapValue': {'fields': _toFirestoreFields(value.cast<String, dynamic>())}
    };
  } else {
    // Fallback for unknown types
    return {'stringValue': value.toString()};
  }
}

List<String> _generateSearchTerms(Map<String, dynamic> product) {
  final terms = <String>{};

  // Add product title words
  final title = product['title']?.toString().toLowerCase() ?? '';
  terms.addAll(title.split(' ').where((w) => w.length > 2));

  // Add description words (first 50 chars)
  final description = product['description']?.toString().toLowerCase() ?? '';
  final descWords = description.substring(0, description.length > 50 ? 50 : description.length);
  terms.addAll(descWords.split(' ').where((w) => w.length > 2));

  // Add tags
  if (product['tags'] is List) {
    final tags = product['tags'] as List;
    terms.addAll(tags.map((t) => t.toString().toLowerCase()));
  }

  // Add category
  final categoryId = product['categoryId']?.toString() ?? '';
  if (categoryId.isNotEmpty) {
    terms.add(categoryId);
    // Add category parts (e.g., "electronics-phones" -> ["electronics", "phones"])
    terms.addAll(categoryId.split('-'));
  }

  // Add SKU
  final sku = product['sku']?.toString().toLowerCase() ?? '';
  if (sku.isNotEmpty) {
    terms.add(sku);
  }

  return terms.toList();
}
