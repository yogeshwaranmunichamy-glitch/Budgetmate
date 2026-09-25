import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../utils.dart';
import '../widgets/tx_modal.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

enum _Sort { dateDesc, dateAsc, amtDesc, amtAsc }

class _TransactionsScreenState extends State<TransactionsScreen> {
  String search = '';
  TxType? typeFilter;
  _Sort sort = _Sort.dateDesc;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    var list = state.data.transactions.where((t) {
      if (typeFilter != null && t.type != typeFilter) return false;
      final hay = '${t.category} ${t.merchant} ${t.notes} ${t.source}'.toLowerCase();
      return search.isEmpty || hay.contains(search.toLowerCase());
    }).toList();

    list.sort((a, b) => switch (sort) {
          _Sort.dateDesc => b.date.compareTo(a.date),
          _Sort.dateAsc => a.date.compareTo(b.date),
          _Sort.amtDesc => b.amount.compareTo(a.amount),
          _Sort.amtAsc => a.amount.compareTo(b.amount),
        });

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            decoration: const InputDecoration(labelText: 'Search merchant, notes, category...'),
            onChanged: (v) => setState(() => search = v),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<TxType?>(
                  value: typeFilter,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Types')),
                    DropdownMenuItem(value: TxType.income, child: Text('Income')),
                    DropdownMenuItem(value: TxType.expense, child: Text('Expense')),
                  ],
                  onChanged: (v) => setState(() => typeFilter = v),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<_Sort>(
                  value: sort,
                  decoration: const InputDecoration(labelText: 'Sort'),
                  items: const [
                    DropdownMenuItem(value: _Sort.dateDesc, child: Text('Newest First')),
                    DropdownMenuItem(value: _Sort.dateAsc, child: Text('Oldest First')),
                    DropdownMenuItem(value: _Sort.amtDesc, child: Text('Amount High-Low')),
                    DropdownMenuItem(value: _Sort.amtAsc, child: Text('Amount Low-High')),
                  ],
                  onChanged: (v) => setState(() => sort = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('No matching transactions.'))
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final t = list[i];
                      final isIncome = t.type == TxType.income;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text('${t.category}${t.merchant.isNotEmpty ? ' · ${t.merchant}' : ''}'),
                          subtitle: Text('${t.date} · ${t.payment}${t.notes.isNotEmpty ? ' · ${t.notes}' : ''}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${isIncome ? '+' : '-'}${fmtInr(t.amount)}',
                                  style: TextStyle(color: isIncome ? Colors.green : Colors.redAccent, fontWeight: FontWeight.w600)),
                              IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => showTransactionModal(context, existing: t)),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Delete this transaction?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) state.deleteTransaction(t.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
