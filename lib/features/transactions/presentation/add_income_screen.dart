import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:milbeki_app/core/utils/date_format.dart';
import 'package:milbeki_app/core/utils/date_only.dart';
import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/features/transactions/domain/expense_validators.dart';
import 'package:milbeki_app/features/transactions/domain/income_models.dart';
import 'package:milbeki_app/features/transactions/domain/income_validators.dart';
import 'package:milbeki_app/features/transactions/domain/transaction_models.dart';

DateTime _systemNow() => DateTime.now();

class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({
    super.key,
    required this.sources,
    required this.accounts,
    this.now = _systemNow,
  });

  final List<IncomeSource> sources;
  final List<PaymentAccount> accounts;

  /// The clock. Tests pass a fixed time here.
  final DateTime Function() now;

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  IncomeStatus _status = IncomeStatus.received; // the common case
  IncomeSource? _source;
  late PaymentAccount _account;

  // Two separate dates, so switching between Received and Expected does not
  // lose what you picked on the other side.
  late DateTime _receivedAt;
  DateTime? _expectedOn;

  String? _sourceError;
  String? _dateError;

  // Stops a double-tap on Save from submitting twice.
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _account = widget.accounts.first; // sensible default
    _receivedAt = widget.now(); // default: right now
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickReceivedDate() async {
    final now = widget.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _receivedAt.dateOnly,
      firstDate: DateTime(now.year - 2),
      lastDate: now.dateOnly,
    );
    // The screen may have closed while the picker was open.
    if (picked == null || !mounted) return;

    setState(() {
      _receivedAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _receivedAt.hour,
        _receivedAt.minute,
      );
      _dateError = null;
    });
  }

  Future<void> _pickReceivedTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_receivedAt),
    );
    if (picked == null || !mounted) return;

    setState(() {
      _receivedAt = DateTime(
        _receivedAt.year,
        _receivedAt.month,
        _receivedAt.day,
        picked.hour,
        picked.minute,
      );
      _dateError = null;
    });
  }

  Future<void> _pickExpectedDate() async {
    final today = widget.now().dateOnly;
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedOn ?? today,
      firstDate: today,
      lastDate: DateTime(today.year + 5, 12, 31),
    );
    if (picked == null || !mounted) return;

    setState(() {
      _expectedOn = picked.dateOnly;
      _dateError = null;
    });
  }

  // DateTime adds days across month ends by itself: 28 Oct + 7 = 4 Nov.
  void _setExpectedInDays(int days) {
    final today = widget.now().dateOnly;
    setState(() {
      _expectedOn = DateTime(today.year, today.month, today.day + days);
      _dateError = null;
    });
  }

  void _save() {
    if (_saving) return;

    final fieldsValid = _formKey.currentState!.validate();
    final source = _source;
    final isReceived = _status == IncomeStatus.received;
    final expectedOn = _expectedOn;
    final now = widget.now();

    // Which date rule applies depends on the mode.
    final String? dateError;
    if (isReceived) {
      dateError = IncomeValidators.receivedAt(_receivedAt, now);
    } else if (expectedOn == null) {
      dateError = 'Choose the expected date';
    } else {
      dateError = IncomeValidators.expectedDate(expectedOn, now);
    }

    setState(() {
      _sourceError = source == null ? 'Choose where the money came from' : null;
      _dateError = dateError;
    });

    if (!fieldsValid || source == null || dateError != null) return;

    _saving = true;
    final note = _noteController.text.trim();

    // pop(value) closes this screen and hands the value to whoever opened it.
    Navigator.of(context).pop(
      NewIncome(
        amount: Money.parse(_amountController.text.trim()),
        source: source,
        status: _status,
        date: isReceived ? _receivedAt : expectedOn!,
        // Expected money is not in any account yet.
        account: isReceived ? _account : null,
        note: note.isEmpty ? null : note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isReceived = _status == IncomeStatus.received;
    final expectedOn = _expectedOn;

    return Scaffold(
      appBar: AppBar(title: const Text('Add income')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Has the money arrived?', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<IncomeStatus>(
                  key: const Key('incomeStatusToggle'),
                  expandedInsets: EdgeInsets.zero,
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: IncomeStatus.received,
                      label: Text('Received'),
                    ),
                    ButtonSegment(
                      value: IncomeStatus.expected,
                      label: Text('Expected'),
                    ),
                  ],
                  selected: {_status},
                  onSelectionChanged: (selection) => setState(() {
                    _status = selection.first;
                    _dateError = null;
                  }),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('incomeAmountField'),
                  controller: _amountController,
                  autofocus: true, // the keyboard opens immediately
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  // Keeps digits, one dot, and at most two decimal places.
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
                ),
                const SizedBox(height: 24),
                Text('Where did it come from?', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final source in widget.sources)
                      ChoiceChip(
                        avatar: Icon(source.icon, size: 18),
                        label: Text(source.name),
                        showCheckmark: false,
                        selected: _source?.id == source.id,
                        onSelected: (_) => setState(() {
                          _source = source;
                          _sourceError = null;
                        }),
                      ),
                  ],
                ),
                if (_sourceError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _sourceError!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Money someone pays back to you is recorded under Money '
                  'Owed, not here. Repayments and borrowed money are not income.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                if (isReceived) ...[
                  Text('Received into', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final account in widget.accounts)
                        ChoiceChip(
                          label: Text(
                            '${account.name} · ${account.balance.format()}',
                          ),
                          showCheckmark: false,
                          selected: _account.id == account.id,
                          onSelected: (_) => setState(() => _account = account),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('When it arrived', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        key: const Key('incomeDateButton'),
                        onPressed: _pickReceivedDate,
                        icon: const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                        ),
                        label: Text(AppDates.weekdayDate(_receivedAt)),
                      ),
                      OutlinedButton.icon(
                        key: const Key('incomeTimeButton'),
                        onPressed: _pickReceivedTime,
                        icon: const Icon(Icons.access_time, size: 18),
                        label: Text(AppDates.time12h(_receivedAt)),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    'When do you expect it?',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      key: const Key('expectedDateButton'),
                      onPressed: _pickExpectedDate,
                      icon: const Icon(Icons.event, size: 18),
                      label: Text(
                        expectedOn == null
                            ? 'Choose date'
                            : AppDates.weekdayDate(expectedOn),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final days in const [7, 30])
                        ActionChip(
                          label: Text('In $days days'),
                          onPressed: () => _setExpectedInDays(days),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Expected income is not counted in your balance or income '
                    'totals until you mark it as received.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                if (_dateError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _dateError!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                const SizedBox(height: 24),
                TextFormField(
                  key: const Key('incomeNoteField'),
                  controller: _noteController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    key: const Key('saveIncomeButton'),
                    onPressed: _save,
                    child: const Text('Save income'),
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