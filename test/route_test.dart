// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop/route/router.dart';
// imports for specific screens are unnecessary for these route shape tests

void main() {
  test('generateRoute returns a MaterialPageRoute for /home', () {
    final route = generateRoute(const RouteSettings(name: '/home'));
    expect(route, isA<MaterialPageRoute>());
    final builder = (route as MaterialPageRoute).builder;
    expect(builder, isNotNull);
  });

  test('generateRoute returns a MaterialPageRoute for /product_details', () {
    final route = generateRoute(const RouteSettings(name: '/product_details', arguments: true));
    expect(route, isA<MaterialPageRoute>());
    final builder = (route as MaterialPageRoute).builder;
    expect(builder, isNotNull);
  });
}
