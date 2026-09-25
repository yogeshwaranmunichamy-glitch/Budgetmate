import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../utils.dart';

Future<void> showTransactionModal(BuildContext context, {Transaction? existing}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _TxModalContent(existing: existing),
  );
}

class _TxModalContent extends StatefulWidget {
  final Transaction? existing;
  const _TxModalContent({this.existing});
  @override
  State<_TxModalContent> createState() => _TxModalContentState();
}

class _TxModalContentState extends State<_TxModalContent> {
  late TxType type;
  final amountCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final merchantCtrl = TextEditingController();
  final sourceCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  String category = kExpenseCategories.first;
  String payment = kPaymentMethods.first;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    type = e?.type ?? TxType.expense;
    amountCtrl.text = e != null ? e.amount.toStringAsFixed(0) : '';
    dateCtrl.text = e?.date ?? todayIso();
    merchantCtrl.text = e?.merchant ?? '';
    sourceCtrl.text = e?.source ?? '';
    notesCtrl.text = e?.notes ?? '';
    category = e?.category ?? (type == TxType.expense ? kExpenseCategories.first : kIncomeCategories.first);
    payment = e?.payment ?? kPaymentMethods.first;
  }

  @override
  Widget build(BuildContext context) {
    final cats = type == TxType.expense ? kExpenseCategories : kIncomeCategories;
    if (!cats.contains(category)) category = cats.first;

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.existing == null ? 'Add Transaction' : 'Edit Transaction',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SegmentedButton<TxType>(
              segments: const [
                ButtonSegment(value: TxType.expense, label: Text('Expense')),
                ButtonSegment(value: TxType.income, label: Text('Income')),
              ],
              selected: {type},
              onSelectionChanged: (s) => setState(() => type = s.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount (₹)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: dateCtrl,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Date'),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.tryParse(dateCtrl.text) ?? DateTime.now(),
                  firstDate: DateTime(2015),
                  lastDate: DateTime(2100),
                );
                if (picked != null) dateCtrl.text = picked.toIso8601String().substring(0, 10);
                setState(() {});
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => category = v!),
            ),
            const SizedBox(height: 10),
            if (type == TxType.expense)
              TextField(controller: merchantCtrl, decoration: const InputDecoration(labelText: 'Merchant'))
            else
              TextField(controller: sourceCtrl, decoration: const InputDecoration(labelText: 'Source')),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: payment,
              decoration: const InputDecoration(labelText: 'Payment Method'),
              items: kPaymentMethods.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => payment = v!),
            ),
            const SizedBox(height: 10),
            TextField(controller: notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes')),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(onPressed: _save, child: const Text('Save'))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final amount = double.tryParse(amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount.')));
      return;
    }
    final tx = Transaction(
      id: widget.existing?.id ?? newId(),
      type: type,
      amount: amount,
      date: dateCtrl.text,
      category: category,
      payment: payment,
      merchant: merchantCtrl.text,
      source: sourceCtrl.text,
      notes: notesCtrl.text,
    );
    context.read<AppState>().addOrUpdateTransaction(tx);
    Navigator.pop(context);
  }
}
