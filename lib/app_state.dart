import 'package:flutter/material.dart';
import 'models.dart';
import 'storage_service.dart';

class AppState extends ChangeNotifier {
  final StorageService storage = StorageService();
  String? currentUser;
  UserData data = UserData();
  bool loading = true;
  bool darkMode = true;
  String? authError;

  AppState() {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final session = await storage.currentSession();
    if (session != null) {
      currentUser = session;
      data = await storage.loadUserData(session);
    }
    loading = false;
    notifyListeners();
  }

  Future<bool> signUp(String u, String p) async {
    final err = await storage.signUp(u, p);
    if (err != null) {
      authError = err;
      notifyListeners();
      return false;
    }
    currentUser = u;
    data = await storage.loadUserData(u);
    authError = null;
    notifyListeners();
    return true;
  }

  Future<bool> logIn(String u, String p) async {
    final err = await storage.logIn(u, p);
    if (err != null) {
      authError = err;
      notifyListeners();
      return false;
    }
    currentUser = u;
    data = await storage.loadUserData(u);
    authError = null;
    notifyListeners();
    return true;
  }

  Future<bool> resetPassword(String u, String p) async {
    final err = await storage.resetPassword(u, p);
    authError = err;
    notifyListeners();
    return err == null;
  }

  Future<bool> changePassword(String cur, String next) async {
    if (currentUser == null) return false;
    final err = await storage.changePassword(currentUser!, cur, next);
    notifyListeners();
    return err == null;
  }

  Future<void> logOut() async {
    await storage.setSession(null);
    currentUser = null;
    data = UserData();
    notifyListeners();
  }

  Future<void> _persist() async {
    if (currentUser != null) await storage.saveUserData(currentUser!, data);
  }

  Future<void> addOrUpdateTransaction(Transaction t) async {
    final idx = data.transactions.indexWhere((x) => x.id == t.id);
    if (idx >= 0) {
      data.transactions[idx] = t;
    } else {
      data.transactions.add(t);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    data.transactions.removeWhere((x) => x.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> setBudget(String category, double amount) async {
    data.budgets[category] = amount;
    await _persist();
    notifyListeners();
  }

  Future<void> setThresholds(int moderate, int warning) async {
    data.thresholds = Thresholds(moderate: moderate, warning: warning);
    await _persist();
    notifyListeners();
  }

  Future<void> addGoal(SavingsGoal g) async {
    data.goals.add(g);
    await _persist();
    notifyListeners();
  }

  Future<void> addToGoal(int index, double amount) async {
    data.goals[index].current += amount;
    await _persist();
    notifyListeners();
  }

  Future<void> deleteGoal(int index) async {
    data.goals.removeAt(index);
    await _persist();
    notifyListeners();
  }

  void toggleTheme() {
    darkMode = !darkMode;
    notifyListeners();
  }

  // ---------- Aggregations ----------
  String get currentMonthKey => DateTime.now().toIso8601String().substring(0, 7);

  double get totalIncome => data.transactions.where((t) => t.type == TxType.income).fold(0, (s, t) => s + t.amount);
  double get totalExpense => data.transactions.where((t) => t.type == TxType.expense).fold(0, (s, t) => s + t.amount);
  double get balance => totalIncome - totalExpense;

  double get monthIncome => data.transactions
      .where((t) => t.type == TxType.income && t.monthKey == currentMonthKey)
      .fold(0, (s, t) => s + t.amount);
  double get monthExpense => data.transactions
      .where((t) => t.type == TxType.expense && t.monthKey == currentMonthKey)
      .fold(0, (s, t) => s + t.amount);
  double get monthSavings => monthIncome - monthExpense;

  Map<String, double> categorySpend([String? monthKey]) {
    final mk = monthKey ?? currentMonthKey;
    final m = <String, double>{};
    for (final t in data.transactions.where((t) => t.type == TxType.expense && t.monthKey == mk)) {
      m[t.category] = (m[t.category] ?? 0) + t.amount;
    }
    return m;
  }
}
