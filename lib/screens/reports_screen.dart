import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../app_state.dart';
import '../models.dart';
import '../utils.dart';
import '../ad_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late String from;
  late String to;
  List<Transaction>? results;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    from = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    to = todayIso();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Reports', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _dateField('From', from, (v) => setState(() => from = v))),
          const SizedBox(width: 10),
          Expanded(child: _dateField('To', to, (v) => setState(() => to = v))),
        ]),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              setState(() => results = state.data.transactions.where((t) => t.date.compareTo(from) >= 0 && t.date.compareTo(to) <= 0).toList());
              // Only offered right after a generated summary — never mid-task.
              AdService.instance.maybeShowAfterReport();
            },
            child: const Text('Generate'),
          ),
        ),
        if (results != null) _ReportOutput(results: results!, from: from, to: to),
      ],
    );
  }

  Widget _dateField(String label, String value, void Function(String) onPick) {
    return TextField(
      readOnly: true,
      decoration: InputDecoration(labelText: label),
      controller: TextEditingController(text: value),
      onTap: () async {
        final picked = await showDatePicker(context: context, initialDate: DateTime.tryParse(value) ?? DateTime.now(), firstDate: DateTime(2015), lastDate: DateTime(2100));
        if (picked != null) onPick(picked.toIso8601String().substring(0, 10));
      },
    );
  }
}

class _ReportOutput extends StatelessWidget {
  final List<Transaction> results;
  final String from, to;
  const _ReportOutput({required this.results, required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    final inc = results.where((t) => t.type == TxType.income).fold(0.0, (s, t) => s + t.amount);
    final exp = results.where((t) => t.type == TxType.expense).fold(0.0, (s, t) => s + t.amount);
    final byCat = <String, double>{};
    for (final t in results.where((t) => t.type == TxType.expense)) {
      byCat[t.category] = (byCat[t.category] ?? 0) + t.amount;
    }
    final sortedCats = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.8,
          children: [
            _stat(context, 'Total Income', fmtInr(inc), Colors.green),
            _stat(context, 'Total Expense', fmtInr(exp), Colors.redAccent),
            _stat(context, 'Net Savings', fmtInr(inc - exp), (inc - exp) < 0 ? Colors.redAccent : Colors.green),
            _stat(context, 'Transactions', '${results.length}', null),
          ],
        ),
        const SizedBox(height: 16),
        Text('Category Breakdown', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: sortedCats.isEmpty
              ? const Padding(padding: EdgeInsets.all(12), child: Text('No expenses in range.'))
              : Column(children: sortedCats.map((e) => ListTile(dense: true, title: Text(e.key), trailing: Text(fmtInr(e.value)))).toList()),
        ),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: () => _exportCsv(context), child: const Text('Export CSV')),
      ],
    );
  }

  Widget _stat(BuildContext context, String label, String value, Color? color) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      );

  Future<void> _exportCsv(BuildContext context) async {
    final buffer = StringBuffer('Date,Type,Category,Amount,Payment,Merchant/Source,Notes\n');
    for (final t in results) {
      final notes = t.notes.replaceAll('"', '""');
      buffer.writeln('${t.date},${t.type.name},${t.category},${t.amount},${t.payment},${t.merchant.isNotEmpty ? t.merchant : t.source},"$notes"');
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/budgetmate_report_${from}_to_$to.csv');
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([XFile(file.path)], text: 'BudgetMate report $from to $to');
  }
}
