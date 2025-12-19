import 'dart:convert';
import 'dart:io';

/// Simple script to patch data/seed_products.json:
/// - Ensures every product has a `description` (adds a placeholder when missing)
/// - Ensures every product has a `currency` field (defaults to "USD")
/// - Computes `priceAfterDiscount` when only a discount percent exists
///   (applies to main product and variants)
///
/// Usage:
/// dart run scripts/patch_seed_products.dart

void main(List<String> args) async {
  final file = File('data/seed_products.json');
  if (!(await file.exists())) {
    stderr.writeln('data/seed_products.json not found in project root');
    exit(2);
  }

  final backup = File('data/seed_products.json.bak');
  if (!await backup.exists()) {
    await file.copy(backup.path);
    print('Backup created at ${backup.path}');
  } else {
    print('Backup already exists at ${backup.path}');
  }

  final content = await file.readAsString();
  final Map<String, dynamic> root = json.decode(content) as Map<String, dynamic>;
  final products = (root['products'] as List<dynamic>?)?.cast<Map<String, dynamic>>();
  if (products == null) {
    stderr.writeln('No products array found in data/seed_products.json');
    exit(3);
  }

  int patched = 0;
  for (final p in products) {
    var changed = false;

    // Ensure description
    final desc = p['description'];
    if (desc == null || (desc is String && desc.trim().isEmpty)) {
      p['description'] = 'No description available.';
      changed = true;
    }

    // Ensure currency
    final cur = p['currency'];
    if (cur == null || (cur is String && cur.trim().isEmpty)) {
      p['currency'] = 'USD';
      changed = true;
    }

    // Normalize discount percent keys
    final dpRaw = p['discountPercent'] ?? p['discount_percent'] ?? p['discount'];
    int? dp;
    if (dpRaw != null) {
      if (dpRaw is int) dp = dpRaw;
      if (dpRaw is num) dp = (dpRaw as num).toInt();
      if (dpRaw is String) dp = int.tryParse(dpRaw);
    }

    final priceRaw = p['price'];
    double price = 0.0;
    if (priceRaw is num) price = priceRaw.toDouble();
    if (priceRaw is String) price = double.tryParse(priceRaw) ?? 0.0;

    // Compute priceAfterDiscount when percent exists but priceAfterDiscount missing
    final padRaw = p['priceAfterDiscount'] ?? p['discountPrice'];
    if (padRaw == null && dp != null && price > 0) {
      final pad = double.parse((price * (1 - dp / 100)).toStringAsFixed(2));
      p['priceAfterDiscount'] = pad;
      // keep discountPercent normalized to discountPercent
      p['discountPercent'] = dp;
      changed = true;
    }

    // Also handle variants if present
    if (p.containsKey('variants') && p['variants'] is List) {
      final variants = (p['variants'] as List).cast<Map<String, dynamic>>();
      for (final v in variants) {
        var vchanged = false;
        if (v['description'] == null || (v['description'] is String && (v['description'] as String).trim().isEmpty)) {
          v['description'] = p['description'];
          vchanged = true;
        }
        if (v['currency'] == null || (v['currency'] is String && (v['currency'] as String).trim().isEmpty)) {
          v['currency'] = p['currency'] ?? 'USD';
          vchanged = true;
        }
        final vdpRaw = v['discountPercent'] ?? v['discount_percent'] ?? v['discount'];
        int? vdp;
        if (vdpRaw != null) {
          if (vdpRaw is int) vdp = vdpRaw;
          if (vdpRaw is num) vdp = (vdpRaw as num).toInt();
          if (vdpRaw is String) vdp = int.tryParse(vdpRaw);
        }
        final vpriceRaw = v['price'];
        double vprice = 0.0;
        if (vpriceRaw is num) vprice = vpriceRaw.toDouble();
        if (vpriceRaw is String) vprice = double.tryParse(vpriceRaw) ?? 0.0;
        if ((v['priceAfterDiscount'] == null || v['discountPrice'] == null) && vdp != null && vprice > 0) {
          v['priceAfterDiscount'] = double.parse((vprice * (1 - vdp / 100)).toStringAsFixed(2));
          v['discountPercent'] = vdp;
          vchanged = true;
        }
        if (vchanged) changed = true;
      }
    }

    if (changed) patched++;
  }

  // Write back
  final out = JsonEncoder.withIndent('  ').convert(root);
  await file.writeAsString(out);
  print('Patched $patched products (wrote ${file.path}). Backup at ${backup.path}');
}
