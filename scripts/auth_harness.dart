// Minimal auth + firestore harness for emulator validation
// Usage: dart run scripts/auth_harness.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const defaultProject = 'demo-no-project';

void main(List<String> args) async {
  final authHost =
      Platform.environment['AUTH_EMULATOR_HOST'] ?? '127.0.0.1:9099';
  final firestoreHost =
      Platform.environment['FIRESTORE_EMULATOR_HOST'] ?? '127.0.0.1:8080';
  final projectId = Platform.environment['FIREBASE_PROJECT'] ?? defaultProject;

  final email = 'harness_test_user@local.test';
  final password = 'password123';

  print('Using Auth emulator: http://$authHost');
  print('Using Firestore emulator: http://$firestoreHost');
  print('Project: $projectId');

  try {
    // 1) create user
    final signUpResult = await signUp(authHost, email, password);
    if (signUpResult == null) {
      print('Failed to sign up user');
      exit(2);
    }
    final uid = signUpResult['localId'] as String?;
    print('User created (uid=$uid)');

    // 2) sign in to get idToken
    final signInResult = await signIn(authHost, email, password);
    if (signInResult == null) {
      print('Failed to sign in user');
      exit(3);
    }
    final idToken = signInResult['idToken'] as String?;
    final returnedUid = signInResult['localId'] as String?;
    print('Signed in (uid=$returnedUid) idToken length=${idToken?.length}');

    if (uid == null || idToken == null) {
      print('Missing uid or idToken');
      exit(4);
    }

    // 3) create users/{uid} document as the authenticated user
    final created =
        await createUserDocument(firestoreHost, projectId, uid, email, idToken);
    if (!created) {
      print('Failed to create users/{uid} document as authenticated user');
      exit(5);
    }
    print('Created users/$uid document');

    // 4) read the same document as authenticated user
    final doc = await getUserDocument(firestoreHost, projectId, uid, idToken);
    if (doc == null) {
      print('Failed to read back users/$uid document');
      exit(6);
    }
    print('Read users/$uid document successfully: ${doc['name']}');

    // 5) try to write another user's document (should be forbidden by rules)
    final otherUid = 'some-other-uid-${DateTime.now().millisecondsSinceEpoch}';
    final writeOther = await createUserDocument(
        firestoreHost, projectId, otherUid, 'other@local.test', idToken);
    if (writeOther) {
      print(
          'WARNING: Was able to write users/$otherUid with this idToken — rules may be too permissive');
    } else {
      print('As expected: writing users/$otherUid was denied (rules enforced)');
    }

    print('\nAll harness checks completed.');
    exit(0);
  } catch (e, st) {
    print('Error running harness: $e');
    print(st);
    exit(10);
  }
}

Future<Map<String, dynamic>?> signUp(
    String authHost, String email, String password) async {
  final url = Uri.parse(
      'http://$authHost/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key');
  final body = jsonEncode({
    'email': email,
    'password': password,
    'returnSecureToken': true,
  });
  final res = await http
      .post(url, headers: {'Content-Type': 'application/json'}, body: body)
      .timeout(Duration(seconds: 10));
  if (res.statusCode == 200) {
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
  print('signUp failed: ${res.statusCode} ${res.body}');
  return null;
}

Future<Map<String, dynamic>?> signIn(
    String authHost, String email, String password) async {
  final url = Uri.parse(
      'http://$authHost/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-api-key');
  final body = jsonEncode({
    'email': email,
    'password': password,
    'returnSecureToken': true,
  });
  final res = await http
      .post(url, headers: {'Content-Type': 'application/json'}, body: body)
      .timeout(Duration(seconds: 10));
  if (res.statusCode == 200) {
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
  print('signIn failed: ${res.statusCode} ${res.body}');
  return null;
}

String _docName(String projectId, String collection, String docId) {
  return 'projects/$projectId/databases/(default)/documents/$collection/$docId';
}

Future<bool> createUserDocument(String firestoreHost, String projectId,
    String uid, String email, String idToken) async {
  final url = Uri.parse(
      'http://$firestoreHost/v1/${_docName(projectId, 'users', uid)}');
  final bodyMap = {
    'fields': {
      'uid': {'stringValue': uid},
      'email': {'stringValue': email},
      'createdAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
      'role': {'stringValue': 'user'}
    }
  };
  final headers = {
    'Content-Type': 'application/json',
    if (idToken.isNotEmpty) 'Authorization': 'Bearer $idToken',
  };
  final res = await http
      .patch(url, headers: headers, body: jsonEncode(bodyMap))
      .timeout(Duration(seconds: 10));
  if (res.statusCode == 200) return true;
  print('createUserDocument failed: ${res.statusCode} ${res.body}');
  return false;
}

Future<Map<String, dynamic>?> getUserDocument(
    String firestoreHost, String projectId, String uid, String idToken) async {
  final url = Uri.parse(
      'http://$firestoreHost/v1/${_docName(projectId, 'users', uid)}');
  final headers = {
    if (idToken.isNotEmpty) 'Authorization': 'Bearer $idToken',
  };
  final res =
      await http.get(url, headers: headers).timeout(Duration(seconds: 10));
  if (res.statusCode == 200)
    return jsonDecode(res.body) as Map<String, dynamic>;
  print('getUserDocument failed: ${res.statusCode} ${res.body}');
  return null;
}
