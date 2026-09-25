import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../utils.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final recent = [...state.data.transactions]..sort((a, b) => b.date.compareTo(a.date));
    final recentList = recent.take(6).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.7,
          children: [
            _StatCard(label: 'Total Balance', value: fmtInr(state.balance)),
            _StatCard(label: 'This Month Savings', value: fmtInr(state.monthSavings), positive: state.monthSavings >= 0),
            _StatCard(label: 'Total Income', value: fmtInr(state.totalIncome), positive: true),
            _StatCard(label: 'Total Expenses', value: fmtInr(state.totalExpense), positive: false),
            _StatCard(label: 'This Month Income', value: fmtInr(state.monthIncome), positive: true),
            _StatCard(label: 'This Month Expenses', value: fmtInr(state.monthExpense), positive: false),
          ],
        ),
        const SizedBox(height: 22),
        Text('Income vs Expense (6 months)', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _IncomeExpenseChart(state: state),
        const SizedBox(height: 22),
        Text('This Month by Category', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _CategoryPieChart(state: state),
        const SizedBox(height: 22),
        Text('Recent Transactions', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: recentList.isEmpty
                ? const Padding(padding: EdgeInsets.all(12), child: Text('No transactions yet. Tap + to add one.'))
                : Column(children: recentList.map((t) => _TxTile(t: t)).toList()),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final bool? positive;
  const _StatCard({required this.label, required this.value, this.positive});
  @override
  Widget build(BuildContext context) {
    final color = positive == null ? null : (positive! ? okColor : dangerColor);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  final Transaction t;
  const _TxTile({required this.t});
  @override
  Widget build(BuildContext context) {
    final isIncome = t.type == TxType.income;
    return ListTile(
      dense: true,
      title: Text(t.category),
      subtitle: Text('${t.date} · ${t.payment}'),
      trailing: Text('${isIncome ? '+' : '-'}${fmtInr(t.amount)}',
          style: TextStyle(color: isIncome ? okColor : dangerColor, fontWeight: FontWeight.w600)),
    );
  }
}

class _IncomeExpenseChart extends StatelessWidget {
  final AppState state;
  const _IncomeExpenseChart({required this.state});
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final d = DateTime(now.year, now.month - (5 - i), 1);
      return '${d.year}-${d.month.toString().padLeft(2, '0')}';
    });
    final inc = months.map((mk) => state.data.transactions.where((t) => t.type == TxType.income && t.monthKey == mk).fold(0.0, (s, t) => s + t.amount)).toList();
    final exp = months.map((mk) => state.data.transactions.where((t) => t.type == TxType.expense && t.monthKey == mk).fold(0.0, (s, t) => s + t.amount)).toList();
    final maxY = ([...inc, ...exp].fold(0.0, (m, v) => v > m ? v : m)) * 1.2 + 1;

    return SizedBox(
      height: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
          child: BarChart(
            BarChartData(
              maxY: maxY,
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, meta) {
                      final i = v.toInt();
                      if (i < 0 || i >= months.length) return const SizedBox();
                      return Padding(padding: const EdgeInsets.only(top: 6), child: Text(months[i].substring(5), style: const TextStyle(fontSize: 10)));
                    },
                  ),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(months.length, (i) => BarChartGroupData(x: i, barRods: [
                    BarChartRodData(toY: inc[i], color: const Color(0xFF3FA796), width: 9, borderRadius: BorderRadius.circular(3)),
                    BarChartRodData(toY: exp[i], color: const Color(0xFFD9634A), width: 9, borderRadius: BorderRadius.circular(3)),
                  ])),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryPieChart extends StatelessWidget {
  final AppState state;
  const _CategoryPieChart({required this.state});
  static const palette = [
    Color(0xFFE8A93A), Color(0xFF3FA796), Color(0xFFD9634A), Color(0xFF6C8EBF), Color(0xFF9C6ADE),
    Color(0xFF4CAF7D), Color(0xFFC77DFF), Color(0xFFE85D75), Color(0xFF5DADE2), Color(0xFFF4A261),
  ];
  @override
  Widget build(BuildContext context) {
    final cs = state.categorySpend();
    if (cs.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No expenses recorded this month yet.')));
    }
    final entries = cs.entries.toList();
    return SizedBox(
      height: 240,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: PieChart(PieChartData(
                  sections: List.generate(entries.length, (i) => PieChartSectionData(
                        value: entries[i].value,
                        color: palette[i % palette.length],
                        title: '',
                        radius: 60,
                      )),
                  centerSpaceRadius: 30,
                )),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ListView(
                  children: List.generate(entries.length, (i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(children: [
                          Container(width: 10, height: 10, color: palette[i % palette.length]),
                          const SizedBox(width: 6),
                          Expanded(child: Text('${entries[i].key}', style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                        ]),
                      )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const okColor = Color(0xFF4CAF7D);
const dangerColor = Color(0xFFD9634A);
