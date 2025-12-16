import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Minimal Firebase Storage helper for uploading product images and retrieving URLs.
class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  /// Upload a file to storage at `path` and return the download URL.
  Future<String> uploadFile(File file, String path) async {
    final ref = _storage.ref().child(path);
    final task = await ref.putFile(file);
    final url = await task.ref.getDownloadURL();
    return url;
  }

  /// Get a download URL for an existing storage path.
  Future<String> getDownloadUrl(String path) async {
    final ref = _storage.ref().child(path);
    return await ref.getDownloadURL();
  }
}
