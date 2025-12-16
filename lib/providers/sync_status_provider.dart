import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A lightweight sync status provider for Sprint 1.
/// This is a placeholder that can be enhanced to monitor connectivity
/// (via connectivity_plus) and Firestore isConnected-like heuristics.
final syncStatusProvider = StateProvider<bool>((ref) {
  // Default to true (assume online). Tests and emulator can override.
  return true;
});
