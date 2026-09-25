import 'models.dart';

/// Deterministic, keyword + regex based transaction extraction.
/// This is intentionally NOT machine-learned or generative — it is the
/// rule-based NLP layer specified for BudgetMate. Swap the keyword maps
/// or extend with a trained TF-IDF/Naive Bayes classifier later without
/// changing the calling code (ParsedTransaction stays the same shape).
class ParsedTransaction {
  final TxType type;
  final double? amount;
  final String category;
  final String payment;
  final String date;
  final double amountConf, typeConf, catConf, payConf;
  final String raw;

  ParsedTransaction({
    required this.type,
    required this.amount,
    required this.category,
    required this.payment,
    required this.date,
    required this.amountConf,
    required this.typeConf,
    required this.catConf,
    required this.payConf,
    required this.raw,
  });
}

class NlpService {
  static final Map<String, List<String>> expenseCatKeywords = {
    'Food': ['food', 'khana', 'saapadu', 'saappadu', 'lunch', 'dinner', 'breakfast', 'swiggy', 'zomato', 'restaurant', 'சாப்பாடு', 'खाने', 'खाना'],
    'Groceries': ['grocery', 'groceries', 'kirana', 'maligai', 'மளிகை', 'किराना'],
    'Transport': ['transport', 'bus', 'taxi', 'ola', 'uber', 'auto', 'பேருந்து'],
    'Petrol': ['petrol', 'diesel', 'fuel', 'petrol bunk', 'பெட்ரோல்', 'पेट्रोल'],
    'Shopping': ['shopping', 'amazon', 'flipkart', 'myntra', 'ஷாப்பிங்'],
    'Rent': ['rent', 'vaadagai', 'kiraya', 'வாடகை', 'किराया'],
    'Electricity': ['electricity', 'eb bill', 'current bill', 'bijli', 'மின்சாரம்', 'बिजली'],
    'Water': ['water bill', 'thanni bill', 'पानी'],
    'Internet': ['internet', 'wifi', 'broadband'],
    'Mobile Recharge': ['recharge', 'top up', 'topup'],
    'Medical': ['medical', 'hospital', 'doctor', 'marundhu', 'dawai', 'மருந்து', 'दवाई'],
    'Education': ['education', 'school', 'college', 'fee', 'padippu', 'कॉलेज'],
    'Entertainment': ['movie', 'cinema', 'padam', 'entertainment', 'சினிமா'],
    'Travel': ['travel', 'trip', 'flight', 'train', 'payanam', 'यात्रा'],
    'Insurance': ['insurance', 'bima', 'बीमा'],
    'EMI': ['emi', 'loan'],
    'Subscriptions': ['netflix', 'subscription', 'spotify', 'prime', 'hotstar'],
  };

  static final Map<String, List<String>> incomeCatKeywords = {
    'Salary': ['salary', 'sambalam', 'vetanam', 'tanka', 'mila', 'सैलरी', 'वेतन', 'சம்பளம்'],
    'Freelance': ['freelance'],
    'Business': ['business'],
    'Interest': ['interest'],
    'Bonus': ['bonus'],
  };

  static final List<String> expenseVerbs = ['spend', 'spent', 'paid', 'kudu', 'kuduthen', 'செலவு', 'selavu', 'kharch', 'kharcha', 'खर्च'];
  static final List<String> incomeVerbs = ['vandhudhu', 'vandhuchu', 'kidaicha', 'received', 'got', 'credited', 'मिला', 'आया'];

  static final Map<String, List<String>> paymentMap = {
    'UPI': ['gpay', 'g pay', 'upi', 'phonepe', 'paytm'],
    'Credit Card': ['credit card'],
    'Debit Card': ['debit card'],
    'Bank Transfer': ['bank transfer', 'neft', 'imps'],
    'Cash': ['cash', 'nagadhu', 'nagad', 'कैश'],
  };

  static final RegExp _amountRe = RegExp(r'(\d[\d,]*\.?\d*)');
  static final RegExp _yesterdayRe = RegExp(r'yesterday|nethiku|\bkal\b|நேற்று|कल');

  ParsedTransaction parse(String text) {
    final t = ' ${text.toLowerCase()} ';

    final amtMatch = _amountRe.firstMatch(t);
    final amount = amtMatch != null ? double.tryParse(amtMatch.group(1)!.replaceAll(',', '')) : null;
    final amountConf = amtMatch != null ? 0.9 : 0.3;

    TxType type = TxType.expense;
    double typeConf = 0.55;
    final allIncomeWords = incomeCatKeywords.values.expand((x) => x);
    if (incomeVerbs.any(t.contains) || allIncomeWords.any(t.contains)) {
      type = TxType.income;
      typeConf = 0.8;
    }
    if (expenseVerbs.any(t.contains)) {
      type = TxType.expense;
      typeConf = 0.85;
    }

    String category = 'Other';
    double catConf = 0.3;
    final dict = type == TxType.income ? incomeCatKeywords : expenseCatKeywords;
    for (final entry in dict.entries) {
      if (entry.value.any(t.contains)) {
        category = entry.key;
        catConf = 0.82;
        break;
      }
    }

    String payment = 'Cash';
    double payConf = 0.4;
    for (final entry in paymentMap.entries) {
      if (entry.value.any(t.contains)) {
        payment = entry.key;
        payConf = 0.85;
        break;
      }
    }

    String date = DateTime.now().toIso8601String().substring(0, 10);
    if (_yesterdayRe.hasMatch(t)) {
      final d = DateTime.now().subtract(const Duration(days: 1));
      date = d.toIso8601String().substring(0, 10);
    }

    return ParsedTransaction(
      type: type,
      amount: amount,
      category: category,
      payment: payment,
      date: date,
      amountConf: amountConf,
      typeConf: typeConf,
      catConf: catConf,
      payConf: payConf,
      raw: text,
    );
  }
}

/// Voice budget query intent classification — predefined intents only,
/// resolved by keyword matching then answered from real local data
/// (caller supplies the numbers; this class only classifies intent + category).
class QueryIntentResult {
  final String intent;
  final String? category;
  QueryIntentResult(this.intent, [this.category]);
}

class QueryClassifier {
  QueryIntentResult classify(String text) {
    final t = text.toLowerCase();
    if (RegExp(r'balance').hasMatch(t)) return QueryIntentResult('GET_BALANCE');
    if (RegExp(r'income').hasMatch(t)) return QueryIntentResult('GET_INCOME');
    if (RegExp(r'remaining|left|budget').hasMatch(t)) return QueryIntentResult('GET_REMAINING_BUDGET');
    if (RegExp(r'savings|goal').hasMatch(t)) return QueryIntentResult('GET_SAVINGS_PROGRESS');
    for (final entry in NlpService.expenseCatKeywords.entries) {
      if (entry.value.any(t.contains) || t.contains(entry.key.toLowerCase())) {
        return QueryIntentResult('GET_CATEGORY_EXPENSE', entry.key);
      }
    }
    if (RegExp(r'spend|expense|kharch|செலவு').hasMatch(t)) return QueryIntentResult('GET_TOTAL_EXPENSE');
    return QueryIntentResult('UNKNOWN');
  }
}
