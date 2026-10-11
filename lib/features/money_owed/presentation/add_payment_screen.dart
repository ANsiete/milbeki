import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:milbeki_app/core/utils/date_format.dart';
import 'package:milbeki_app/core/utils/date_only.dart';
import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/features/money_owed/domain/debt_models.dart';
import 'package:milbeki_app/features/money_owed/domain/debt_rules.dart';
import 'package:milbeki_app/features/transactions/domain/expense_validators.dart';

// Records one payment towards a debt. It returns a DebtPayment, or null if
// the user backs out. The amount typing rules are the same as for expenses.
class AddPaymentScreen extends StatefulWidget {
  const AddPaymentScreen({super.key, required this.debt, required this.now});

  final Debt debt;

  /// The clock. Tests pass a fixed time here.
  final DateTime Function() now;

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  static int _counter = 0;

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _referenceController = TextEditingController();

  late DateTime _paidAt;

  // Created when the form opens, so a double-tap on Save sends the same id
  // twice and the duplicate is ignored. The server will do the same job with
  // an Idempotency-Key.
  late final String _paymentId;

  String? _ruleError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _paidAt = widget.now();
    _paymentId = 'pay-${DateTime.now().microsecondsSinceEpoch}-${_counter++}';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  // "300" or "300.50", with no symbol or commas, so it fits in the field.
  String _plainAmount(Money money) {
    final whole = money.paisa ~/ 100;
    final fraction = money.paisa % 100;
    if (fraction == 0) return '$whole';
    return '$whole.${fraction.toString().padLeft(2, '0')}';
  }

  void _payFull() {
    _amountController.text = _plainAmount(widget.debt.outstanding);
    setState(() => _ruleError = null);
  }

  Future<void> _pickDate() async {
    final first = widget.debt.startDate.dateOnly;
    final today = widget.now().dateOnly;
    final last = today.isBefore(first) ? first : today;

    var initial = _paidAt.dateOnly;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    // The screen may have closed while the picker was open.
    if (picked == null || !mounted) return;

    setState(() {
      _paidAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _paidAt.hour,
        _paidAt.minute,
      );
      _ruleError = null;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_paidAt),
    );
    if (picked == null || !mounted) return;

    setState(() {
      _paidAt = DateTime(
        _paidAt.year,
        _paidAt.month,
        _paidAt.day,
        picked.hour,
        picked.minute,
      );
      _ruleError = null;
    });
  }

  void _save() {
    if (_saving) return;

    // Step 1: is the amount a valid number?
    if (!_formKey.currentState!.validate()) return;

    // Step 2: do the debt rules allow this payment?
    final amount = Money.parse(_amountController.text.trim());
    final error = DebtRules.validatePayment(
      debt: widget.debt,
      amount: amount,
      paidAt: _paidAt,
      now: widget.now(),
    );
    if (error != null) {
      setState(() => _ruleError = error);
      return;
    }

    _saving = true;
    final note = _noteController.text.trim();
    final reference = _referenceController.text.trim();

    Navigator.of(context).pop(
      DebtPayment(
        id: _paymentId,
        amount: amount,
        paidAt: _paidAt,
        reference: reference.isEmpty ? null : reference,
        note: note.isEmpty ? null : note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final debt = widget.debt;
    final youOwe = debt.direction == DebtDirection.youOwe;

    return Scaffold(
      appBar: AppBar(title: const Text('Record payment')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          youOwe
                              ? 'You owe ${debt.personName}'
                              : '${debt.personName} owes you',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text('Outstanding: ${debt.outstanding.format()}'),
                        const SizedBox(height: 8),
                        Text(
                          youOwe
                              ? 'This repays what you borrowed. '
                                  'It is not counted as an expense.'
                              : 'This is money coming back to you. '
                                  'It is not counted as income.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('paymentAmountField'),
                  controller: _amountController,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '৳ ',
                  ),
                  validator: ExpenseValidators.amount,
                  onChanged: (_) => setState(() => _ruleError = null),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ActionChip(
                    key: const Key('payFullChip'),
                    label: Text(
                      youOwe
                          ? 'Pay full ${debt.outstanding.format()}'
                          : 'Received in full ${debt.outstanding.format()}',
                    ),
                    onPressed: _payFull,
                  ),
                ),
                const SizedBox(height: 16),
                Text('When', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      key: const Key('paymentDateButton'),
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text(AppDates.weekdayDate(_paidAt)),
                    ),
                    OutlinedButton.icon(
                      key: const Key('paymentTimeButton'),
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time, size: 18),
                      label: Text(AppDates.time12h(_paidAt)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('paymentNoteField'),
                  controller: _noteController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                  ),
                ),
                TextFormField(
                  key: const Key('paymentReferenceField'),
                  controller: _referenceController,
                  maxLength: 40,
                  decoration: const InputDecoration(
                    labelText: 'Reference, such as a bKash ID (optional)',
                  ),
                ),
                if (_ruleError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _ruleError!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    key: const Key('savePaymentButton'),
                    onPressed: _save,
                    child: const Text('Save payment'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}