import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CartStorage {
  static const _key = 'cart_items_v1';

  Future<void> persist(Map<String, int> cart) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(cart);
    await prefs.setString(_key, jsonStr);
  }

  Future<Map<String, int>?> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null) return null;
    final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
  }
}
