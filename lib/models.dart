// Core data models for BudgetMate.
// Kept as plain JSON-serializable classes for simple local persistence.

class AppUser {
  final String username;
  final String passwordHash;
  AppUser({required this.username, required this.passwordHash});

  Map<String, dynamic> toJson() => {'username': username, 'passwordHash': passwordHash};
  factory AppUser.fromJson(Map<String, dynamic> j) =>
      AppUser(username: j['username'], passwordHash: j['passwordHash']);
}

enum TxType { income, expense }

class Transaction {
  String id;
  TxType type;
  double amount;
  String date; // ISO yyyy-MM-dd
  String category;
  String payment; // Cash/UPI/Credit Card/Debit Card/Bank Transfer/Other
  String merchant;
  String source;
  String notes;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.category,
    required this.payment,
    this.merchant = '',
    this.source = '',
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'amount': amount,
        'date': date,
        'category': category,
        'payment': payment,
        'merchant': merchant,
        'source': source,
        'notes': notes,
      };

  factory Transaction.fromJson(Map<String, dynamic> j) => Transaction(
        id: j['id'],
        type: j['type'] == 'income' ? TxType.income : TxType.expense,
        amount: (j['amount'] as num).toDouble(),
        date: j['date'],
        category: j['category'],
        payment: j['payment'] ?? 'Cash',
        merchant: j['merchant'] ?? '',
        source: j['source'] ?? '',
        notes: j['notes'] ?? '',
      );

  String get monthKey => date.substring(0, 7);
}

class SavingsGoal {
  String name;
  double target;
  double current;
  String targetDate; // ISO date, optional
  String notes;

  SavingsGoal({
    required this.name,
    required this.target,
    this.current = 0,
    this.targetDate = '',
    this.notes = '',
  });

  Map<String, dynamic> toJson() =>
      {'name': name, 'target': target, 'current': current, 'targetDate': targetDate, 'notes': notes};

  factory SavingsGoal.fromJson(Map<String, dynamic> j) => SavingsGoal(
        name: j['name'],
        target: (j['target'] as num).toDouble(),
        current: (j['current'] as num?)?.toDouble() ?? 0,
        targetDate: j['targetDate'] ?? '',
        notes: j['notes'] ?? '',
      );
}

class Thresholds {
  int moderate; // % where "moderate" starts
  int warning; // % where "warning" starts
  Thresholds({this.moderate = 50, this.warning = 80});

  Map<String, dynamic> toJson() => {'moderate': moderate, 'warning': warning};
  factory Thresholds.fromJson(Map<String, dynamic>? j) =>
      j == null ? Thresholds() : Thresholds(moderate: j['moderate'] ?? 50, warning: j['warning'] ?? 80);
}

class UserData {
  List<Transaction> transactions;
  Map<String, double> budgets; // category -> monthly budget
  List<SavingsGoal> goals;
  Thresholds thresholds;

  UserData({
    List<Transaction>? transactions,
    Map<String, double>? budgets,
    List<SavingsGoal>? goals,
    Thresholds? thresholds,
  })  : transactions = transactions ?? [],
        budgets = budgets ?? {},
        goals = goals ?? [],
        thresholds = thresholds ?? Thresholds();

  Map<String, dynamic> toJson() => {
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'budgets': budgets,
        'goals': goals.map((g) => g.toJson()).toList(),
        'thresholds': thresholds.toJson(),
      };

  factory UserData.fromJson(Map<String, dynamic> j) => UserData(
        transactions: (j['transactions'] as List? ?? [])
            .map((e) => Transaction.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        budgets: Map<String, double>.from(
            (j['budgets'] as Map? ?? {}).map((k, v) => MapEntry(k as String, (v as num).toDouble()))),
        goals: (j['goals'] as List? ?? []).map((e) => SavingsGoal.fromJson(Map<String, dynamic>.from(e))).toList(),
        thresholds: Thresholds.fromJson(j['thresholds']),
      );
}

const List<String> kExpenseCategories = [
  'Food', 'Groceries', 'Transport', 'Petrol', 'Shopping', 'Rent', 'Electricity', 'Water',
  'Internet', 'Mobile Recharge', 'Medical', 'Education', 'Entertainment', 'Travel',
  'Insurance', 'EMI', 'Subscriptions', 'Other'
];

const List<String> kIncomeCategories = ['Salary', 'Freelance', 'Business', 'Interest', 'Bonus', 'Other'];

const List<String> kPaymentMethods = ['Cash', 'UPI', 'Credit Card', 'Debit Card', 'Bank Transfer', 'Other'];
