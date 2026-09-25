import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../utils.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final goals = state.data.goals;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Savings Goals', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        if (goals.isEmpty) const Text('No goals yet.'),
        ...List.generate(goals.length, (i) {
          final g = goals[i];
          final pct = g.target > 0 ? (g.current / g.target * 100).clamp(0, 100).round() : 0;
          final remaining = (g.target - g.current).clamp(0, double.infinity);
          int months = 1;
          if (g.targetDate.isNotEmpty) {
            final target = DateTime.tryParse(g.targetDate);
            if (target != null) months = (target.difference(DateTime.now()).inDays / 30).round().clamp(1, 1000);
          }
          final perMonth = remaining / months;

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(g.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Chip(label: Text('$pct%'), padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                  ]),
                  Text('${fmtInr(g.current)} of ${fmtInr(g.target)} · target ${g.targetDate.isEmpty ? '—' : g.targetDate}',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(value: pct / 100, minHeight: 8, color: const Color(0xFF3FA796), backgroundColor: Theme.of(context).dividerColor),
                  ),
                  const SizedBox(height: 6),
                  Text('Remaining: ${fmtInr(remaining)} · Save ~${fmtInr(perMonth)}/mo', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: OutlinedButton(onPressed: () => _addFunds(context, i), child: const Text('Add Funds'))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                        onPressed: () => context.read<AppState>().deleteGoal(i),
                        child: const Text('Delete'),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          );
        }),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _newGoal(context), child: const Text('+ New Goal'))),
      ],
    );
  }

  Future<void> _addFunds(BuildContext context, int index) async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Funds'),
        content: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (₹)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final amt = double.tryParse(ctrl.text);
              if (amt != null && amt > 0) {
                context.read<AppState>().addToGoal(index, amt);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _newGoal(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Savings Goal'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Goal Name')),
          const SizedBox(height: 10),
          TextField(controller: targetCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Target Amount (₹)')),
          const SizedBox(height: 10),
          TextField(
            controller: dateCtrl,
            readOnly: true,
            decoration: const InputDecoration(labelText: 'Target Date (optional)'),
            onTap: () async {
              final picked = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
              if (picked != null) dateCtrl.text = picked.toIso8601String().substring(0, 10);
            },
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final target = double.tryParse(targetCtrl.text);
              if (nameCtrl.text.trim().isNotEmpty && target != null && target > 0) {
                context.read<AppState>().addGoal(SavingsGoal(name: nameCtrl.text.trim(), target: target, targetDate: dateCtrl.text));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
