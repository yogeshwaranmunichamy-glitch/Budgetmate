import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../utils.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  late TextEditingController modCtrl, warnCtrl;

  @override
  void initState() {
    super.initState();
    final th = context.read<AppState>().data.thresholds;
    modCtrl = TextEditingController(text: th.moderate.toString());
    warnCtrl = TextEditingController(text: th.warning.toString());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = state.categorySpend();
    final th = state.data.thresholds;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Monthly Budgets', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        if (state.data.budgets.isEmpty) const Text('No budgets set yet.'),
        ...state.data.budgets.entries.map((e) {
          final spent = cs[e.key] ?? 0;
          final pct = e.value > 0 ? (spent / e.value * 100).round() : 0;
          Color color;
          String label;
          if (pct < th.moderate) {
            color = const Color(0xFF4CAF7D);
            label = 'Normal';
          } else if (pct < th.warning) {
            color = const Color(0xFFE8A93A);
            label = 'Moderate';
          } else if (pct < 100) {
            color = const Color(0xFFE85D75);
            label = 'Warning';
          } else {
            color = const Color(0xFFD9634A);
            label = 'Exceeded';
          }
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Chip(label: Text(label, style: const TextStyle(fontSize: 11)), padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                  ]),
                  const SizedBox(height: 4),
                  Text('${fmtInr(spent)} of ${fmtInr(e.value)} ($pct%)', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (pct / 100).clamp(0, 1).toDouble(),
                      minHeight: 8,
                      backgroundColor: Theme.of(context).dividerColor,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _openBudgetDialog(context), child: const Text('Set / Update Budget'))),
        const SizedBox(height: 24),
        Text('Alert Thresholds', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              TextField(controller: modCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Moderate at (%)')),
              const SizedBox(height: 10),
              TextField(controller: warnCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Warning at (%)')),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    context.read<AppState>().setThresholds(int.tryParse(modCtrl.text) ?? 50, int.tryParse(warnCtrl.text) ?? 80);
                  },
                  child: const Text('Save Thresholds'),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Future<void> _openBudgetDialog(BuildContext context) async {
    String category = kExpenseCategories.first;
    final amountCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Set Category Budget'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              value: category,
              items: kExpenseCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setD(() => category = v!),
            ),
            const SizedBox(height: 10),
            TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monthly Budget (₹)')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final amt = double.tryParse(amountCtrl.text);
                if (amt != null && amt > 0) {
                  context.read<AppState>().setBudget(category, amt);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
