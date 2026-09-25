import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../app_state.dart';
import '../models.dart';
import '../nlp_service.dart';
import '../utils.dart';

/// Voice entry never auto-saves — it always shows a confirmation screen
/// with per-field confidence, matching the "show confirmation, allow
/// Confirm & Save / Edit / Cancel / Record Again" requirement.
class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});
  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final NlpService nlp = NlpService();
  final QueryClassifier classifier = QueryClassifier();
  bool available = false;
  bool listening = false;
  String status = 'Tap to speak';
  String transcript = 'Transcript will appear here...';
  String langCode = 'en-IN';
  ParsedTransaction? parsed;

  String queryTranscript = '';
  String queryAnswer = '';
  String queryIntent = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    available = await _speech.initialize(
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') setState(() => listening = false);
      },
      onError: (e) => setState(() {
        listening = false;
        status = 'Could not hear you clearly (${e.errorMsg}). Please try again.';
      }),
    );
    setState(() {});
  }

  Future<void> _startListenFor(void Function(String text) onResult) async {
    if (!available) {
      setState(() => status = 'Speech recognition not available on this device.');
      return;
    }
    setState(() {
      listening = true;
      status = 'Listening...';
    });
    await _speech.listen(
      localeId: langCode,
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
          setState(() {
            listening = false;
            status = 'Tap to speak';
          });
        }
      },
    );
  }

  void _startTransactionVoice() {
    _startListenFor((text) {
      setState(() {
        transcript = text;
        parsed = nlp.parse(text);
      });
    });
  }

  void _startQueryVoice() {
    _startListenFor((text) {
      final intent = classifier.classify(text);
      final state = context.read<AppState>();
      setState(() {
        queryTranscript = text;
        queryIntent = intent.intent;
        queryAnswer = _answerFor(intent, state);
      });
    });
  }

  String _answerFor(QueryIntentResult r, AppState state) {
    switch (r.intent) {
      case 'GET_BALANCE':
        return 'Your current balance is ${fmtInr(state.balance)}.';
      case 'GET_INCOME':
        return 'Total income this month is ${fmtInr(state.monthIncome)}.';
      case 'GET_REMAINING_BUDGET':
        final totalBudget = state.data.budgets.values.fold(0.0, (s, v) => s + v);
        final spent = state.categorySpend().values.fold(0.0, (s, v) => s + v);
        final remaining = (totalBudget - spent).clamp(0, double.infinity);
        return 'You have ${fmtInr(remaining)} left in your monthly budget.';
      case 'GET_SAVINGS_PROGRESS':
        if (state.data.goals.isEmpty) return 'You have no savings goals yet.';
        final g = state.data.goals.first;
        final pct = g.target > 0 ? (g.current / g.target * 100).round() : 0;
        return 'Your "${g.name}" goal is $pct% complete.';
      case 'GET_CATEGORY_EXPENSE':
        final cs = state.categorySpend();
        return "You've spent ${fmtInr(cs[r.category] ?? 0)} on ${r.category} this month.";
      case 'GET_TOTAL_EXPENSE':
        return 'Total expenses this month are ${fmtInr(state.monthExpense)}.';
      default:
        return 'Sorry, I didn\'t understand that. Try "How much did I spend this month?"';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Voice Transaction Entry', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('Speak naturally — English, Tamil, Hindi, or mixed speech (e.g. "Inniku food-ku 250 rupees spend panninen").',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: langCode,
          decoration: const InputDecoration(labelText: 'Language'),
          items: const [
            DropdownMenuItem(value: 'en-IN', child: Text('English')),
            DropdownMenuItem(value: 'ta-IN', child: Text('Tamil')),
            DropdownMenuItem(value: 'hi-IN', child: Text('Hindi')),
          ],
          onChanged: (v) => setState(() => langCode = v!),
        ),
        const SizedBox(height: 20),
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: _startTransactionVoice,
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: listening ? Colors.redAccent : Theme.of(context).colorScheme.primary,
                  child: Icon(listening ? Icons.mic : Icons.mic_none, size: 32, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 8),
              Text(status, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(padding: const EdgeInsets.all(12), child: Text(transcript)),
        ),
        if (parsed != null) ...[
          const SizedBox(height: 10),
          _ConfirmationCard(
            parsed: parsed!,
            onConfirm: () {
              if (parsed!.amount == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Amount was not detected — use Edit to enter it.')));
                return;
              }
              context.read<AppState>().addOrUpdateTransaction(Transaction(
                    id: newId(),
                    type: parsed!.type,
                    amount: parsed!.amount!,
                    date: parsed!.date,
                    category: parsed!.category,
                    payment: parsed!.payment,
                    notes: 'Voice: ${parsed!.raw}',
                  ));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved ✓')));
              setState(() => parsed = null);
            },
            onCancel: () => setState(() => parsed = null),
            onRecordAgain: _startTransactionVoice,
          ),
        ],
        const Divider(height: 40),
        Text('Voice Budget Query', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('Ask things like "How much did I spend this month?" or "Food spending this month?"',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 10),
        OutlinedButton.icon(onPressed: _startQueryVoice, icon: const Icon(Icons.mic_none), label: const Text('Ask a Question')),
        if (queryTranscript.isNotEmpty) ...[
          const SizedBox(height: 10),
          Card(child: Padding(padding: const EdgeInsets.all(12), child: Text('"$queryTranscript"'))),
          const SizedBox(height: 6),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Intent: $queryIntent', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Text(queryAnswer),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ConfirmationCard extends StatelessWidget {
  final ParsedTransaction parsed;
  final VoidCallback onConfirm, onCancel, onRecordAgain;
  const _ConfirmationCard({required this.parsed, required this.onConfirm, required this.onCancel, required this.onRecordAgain});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _row(context, 'Type', parsed.type.name, parsed.typeConf),
            _row(context, 'Amount', parsed.amount != null ? fmtInr(parsed.amount!) : 'not detected', parsed.amountConf),
            _row(context, 'Category', parsed.category, parsed.catConf),
            _row(context, 'Payment', parsed.payment, parsed.payConf),
            _row(context, 'Date', parsed.date, 1.0),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(onPressed: onConfirm, child: const Text('Confirm & Save')),
                OutlinedButton(onPressed: onCancel, child: const Text('Cancel')),
                OutlinedButton(onPressed: onRecordAgain, child: const Text('Record Again')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, double conf) {
    final low = conf < 0.65;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            low ? '$value (${(conf * 100).round()}%)' : value,
            style: TextStyle(color: low ? const Color(0xFFE8A93A) : null, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
