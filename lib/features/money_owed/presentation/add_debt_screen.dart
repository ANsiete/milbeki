import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:milbeki_app/core/utils/date_format.dart';
import 'package:milbeki_app/core/utils/date_only.dart';
import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/features/money_owed/domain/debt_form_validators.dart';
import 'package:milbeki_app/features/money_owed/domain/debt_models.dart';
import 'package:milbeki_app/features/transactions/domain/expense_validators.dart';

// Creates a new debt. It returns a Debt, or null if the user backs out.
class AddDebtScreen extends StatefulWidget {
  const AddDebtScreen({super.key, required this.now});

  /// The clock. Tests pass a fixed time here.
  final DateTime Function() now;

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  static int _counter = 0;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  // null means "not chosen yet". The form will not save until it is chosen.
  DebtDirection? _direction;
  late DateTime _startDate;
  DateTime? _dueDate;

  // Created when the form opens, so a double-tap on Save cannot create two debts.
  late final String _debtId;

  String? _directionError;
  String? _startError;
  String? _dueError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _startDate = widget.now().dateOnly;
    _debtId = 'debt-${DateTime.now().microsecondsSinceEpoch}-${_counter++}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final now = widget.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(now.year - 5),
      lastDate: now.dateOnly,
    );
    // The screen may have closed while the picker was open.
    if (picked == null || !mounted) return;

    setState(() {
      _startDate = picked.dateOnly;
      _startError = null;
    });
  }

  Future<void> _pickDueDate() async {
    final first = _startDate;
    final last = DateTime(widget.now().year + 5, 12, 31);

    // The picker needs the starting date to sit inside its allowed range.
    var initial = _dueDate ?? widget.now().dateOnly;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked == null || !mounted) return;

    setState(() {
      _dueDate = picked.dateOnly;
      _dueError = null;
    });
  }

  // DateTime adds days across month ends by itself: 28 Oct + 7 = 4 Nov.
  void _setDueInDays(int days) {
    setState(() {
      _dueDate = DateTime(_startDate.year, _startDate.month, _startDate.day + days);
      _dueError = null;
    });
  }

  void _save() {
    if (_saving) return;

    final fieldsValid = _formKey.currentState!.validate();
    final direction = _direction;
    final due = _dueDate;
    final startError = DebtFormValidators.startDate(_startDate, widget.now());
    final dueError = DebtFormValidators.dueDate(due, _startDate);

    setState(() {
      _directionError = direction == null ? 'Choose who owes whom' : null;
      _startError = startError;
      _dueError = dueError;
    });

    if (!fieldsValid ||
        direction == null ||
        due == null ||
        startError != null ||
        dueError != null) {
      return;
    }

    _saving = true;
    final description = _descriptionController.text.trim();

    Navigator.of(context).pop(
      Debt(
        id: _debtId,
        personName: _nameController.text.trim(),
        direction: direction,
        originalAmount: Money.parse(_amountController.text.trim()),
        startDate: _startDate.dateOnly,
        dueDate: due.dateOnly,
        description: description.isEmpty ? null : description,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final direction = _direction;
    final due = _dueDate;
    final willBeOverdue = due != null && due.isBefore(widget.now().dateOnly);

    return Scaffold(
      appBar: AppBar(title: const Text('Add money owed')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Who owes whom?', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<DebtDirection>(
                  key: const Key('debtDirectionToggle'),
                  expandedInsets: EdgeInsets.zero,
                  showSelectedIcon: false,
                  emptySelectionAllowed: true, // starts with nothing chosen
                  segments: const [
                    ButtonSegment(
                      value: DebtDirection.youOwe,
                      label: Text('You owe'),
                    ),
                    ButtonSegment(
                      value: DebtDirection.owedToYou,
                      label: Text('Owed to you'),
                    ),
                  ],
                  selected: direction == null ? <DebtDirection>{} : {direction},
                  onSelectionChanged: (selection) {
                    if (selection.isEmpty) return;
                    setState(() {
                      _direction = selection.first;
                      _directionError = null;
                    });
                  },
                ),
                if (direction != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      direction == DebtDirection.youOwe
                          ? 'You borrowed this money and must pay it back.'
                          : 'You lent this money and expect it back.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                if (_directionError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _directionError!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('debtNameField'),
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  maxLength: 50,
                  decoration: const InputDecoration(
                    labelText: 'Person',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: DebtFormValidators.personName,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('debtAmountField'),
                  controller: _amountController,
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
                ),
                const SizedBox(height: 16),
                Text('When did it start?', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    key: const Key('debtStartButton'),
                    onPressed: _pickStartDate,
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(AppDates.weekdayDate(_startDate)),
                  ),
                ),
                if (_startError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _startError!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                const SizedBox(height: 16),
                Text('When is it due?', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    key: const Key('debtDueButton'),
                    onPressed: _pickDueDate,
                    icon: const Icon(Icons.event, size: 18),
                    label: Text(
                      due == null
                          ? 'Choose due date'
                          : AppDates.weekdayDate(due),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final days in const [7, 14, 30])
                      ActionChip(
                        label: Text('In $days days'),
                        onPressed: () => _setDueInDays(days),
                      ),
                  ],
                ),
                if (_dueError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _dueError!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                if (willBeOverdue)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'This debt will show as overdue.',
                      style: TextStyle(color: Colors.orange.shade800),
                    ),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('debtDescriptionField'),
                  controller: _descriptionController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Reason (optional)',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This only records the debt. It does not change your '
                  'account balances yet.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    key: const Key('saveDebtButton'),
                    onPressed: _save,
                    child: const Text('Save'),
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