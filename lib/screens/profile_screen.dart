import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final curCtrl = TextEditingController();
  final newCtrl = TextEditingController();
  String? message;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Profile', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Username', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(state.currentUser ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Change Password', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              TextField(controller: curCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password')),
              const SizedBox(height: 10),
              TextField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final ok = await state.changePassword(curCtrl.text, newCtrl.text);
                    setState(() => message = ok ? 'Password updated.' : 'Could not update password — check current password and try a new one with 6+ characters.');
                  },
                  child: const Text('Update Password'),
                ),
              ),
              if (message != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(message!)),
            ]),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: state.logOut,
            child: const Text('Log Out'),
          ),
        ),
      ],
    );
  }
}
