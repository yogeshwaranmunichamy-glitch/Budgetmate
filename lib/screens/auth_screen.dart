import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

enum _Mode { login, signup, forgot }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  _Mode mode = _Mode.login;
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('BudgetMate',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 32, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 6),
                Text('Smart budgeting, no cloud AI required.',
                    style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
                const SizedBox(height: 28),
                TextField(controller: userCtrl, decoration: const InputDecoration(labelText: 'Username')),
                const SizedBox(height: 12),
                TextField(controller: passCtrl, obscureText: true, decoration: InputDecoration(labelText: _passwordLabel())),
                const SizedBox(height: 18),
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _submit, child: Text(_buttonLabel()))),
                if (state.authError != null) ...[
                  const SizedBox(height: 10),
                  Text(state.authError!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
                ],
                const SizedBox(height: 16),
                if (mode == _Mode.login) ...[
                  _link('New here? Create an account', () => setState(() => mode = _Mode.signup)),
                  _link('Forgot password?', () => setState(() => mode = _Mode.forgot)),
                ] else
                  _link('Back to login', () => setState(() => mode = _Mode.login)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _passwordLabel() => mode == _Mode.forgot ? 'New Password (min 6 characters)' : 'Password';
  String _buttonLabel() => switch (mode) { _Mode.login => 'Log In', _Mode.signup => 'Sign Up', _Mode.forgot => 'Reset Password' };

  Widget _link(String label, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: GestureDetector(
          onTap: onTap,
          child: Text(label, style: const TextStyle(color: accent2Const, fontSize: 13.5)),
        ),
      );

  Future<void> _submit() async {
    final state = context.read<AppState>();
    final u = userCtrl.text.trim();
    final p = passCtrl.text;
    bool ok;
    if (mode == _Mode.login) {
      ok = await state.logIn(u, p);
    } else if (mode == _Mode.signup) {
      ok = await state.signUp(u, p);
    } else {
      ok = await state.resetPassword(u, p);
      if (ok && mounted) setState(() => mode = _Mode.login);
    }
    if (ok) {
      // handled by Consumer rebuild in main.dart
    }
  }
}

const accent2Const = Color(0xFF3FA796);
