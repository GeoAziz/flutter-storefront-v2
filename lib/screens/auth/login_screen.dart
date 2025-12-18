import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shop/route/route_names.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(firebaseAuthStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              key: const Key('login_user'),
              controller: _userCtrl,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              key: const Key('login_pass'),
              controller: _passCtrl,
              obscureText: _obscurePass,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscurePass ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              key: const Key('login_btn'),
              onPressed: () async {
                try {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Signing in...')));
                  await ref.read(authControllerProvider).signIn(
                      email: _userCtrl.text.trim(), password: _passCtrl.text);
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Logged in')));
                  Navigator.of(context)
                      .pushReplacementNamed(RouteNames.entryPoint);
                } on FirebaseAuthException catch (err) {
                  final msg = _mapAuthError(err);
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(msg)));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Login failed: $e')));
                }
              },
              child: const Text('Login'),
            ),
            const SizedBox(height: 16),
            authAsync.when(
              data: (u) => Text('Logged in: ${u != null}'),
              loading: () => const Text('Auth: loading...'),
              error: (e, st) => const Text('Auth error'),
            ),
          ],
        ),
      ),
    );
  }

  String _mapAuthError(FirebaseAuthException err) {
    switch (err.code) {
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
        return 'Incorrect password — please try again.';
      case 'invalid-email':
        return 'The email address is invalid.';
      default:
        return 'Authentication error: ${err.message}';
    }
  }
}
