import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../widgets/tx_modal.dart';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';
import 'voice_screen.dart';
import 'budget_screen.dart';
import 'savings_screen.dart';
import 'reports_screen.dart';
import 'profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  final pages = const [
    DashboardScreen(),
    TransactionsScreen(),
    VoiceScreen(),
    BudgetScreen(),
    SavingsScreen(),
    ReportsScreen(),
    ProfileScreen(),
  ];
  final titles = const ['Dashboard', 'Transactions', 'Voice', 'Budget', 'Savings', 'Reports', 'Profile'];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[index], style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.brightness_6_outlined), onPressed: state.toggleTheme),
          IconButton(icon: const Icon(Icons.logout), onPressed: state.logOut),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              const Padding(padding: EdgeInsets.all(16), child: Text('More', style: TextStyle(fontWeight: FontWeight.w700))),
              ListTile(
                leading: const Icon(Icons.savings_outlined),
                title: const Text('Savings Goals'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => index = 4);
                },
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart_outlined),
                title: const Text('Reports'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => index = 5);
                },
              ),
            ],
          ),
        ),
      ),
      body: pages[index],
      floatingActionButton: FloatingActionButton(
        onPressed: () => showTransactionModal(context),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: [0, 1, 2, 3, 6].contains(index) ? [0, 1, 2, 3, 6].indexOf(index) : 0,
        onTap: (tabIdx) => setState(() => index = [0, 1, 2, 3, 6][tabIdx]),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.mic_none), label: 'Voice'),
          BottomNavigationBarItem(icon: Icon(Icons.track_changes_outlined), label: 'Budget'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
