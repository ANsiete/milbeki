import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:milbeki_app/core/utils/date_format.dart';
import 'package:milbeki_app/core/utils/money.dart';
import 'package:milbeki_app/features/transactions/domain/expense_validators.dart';
import 'package:milbeki_app/features/transactions/domain/transaction_models.dart';

DateTime _systemNow() => DateTime.now();

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({
    super.key,
    required this.categories,
    required this.accounts,
    this.now = _systemNow,
  });

  final List<ExpenseCategory> categories;
  final List<PaymentAccount> accounts;

  /// The clock. Tests pass a fixed time here.
  final DateTime Function() now;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  ExpenseCategory? _category;

  // "late" means: no value yet, but it is set in initState before first use.
  late PaymentAccount _account;
  late DateTime _occurredAt;

  String? _categoryError;
  String? _dateError;

  // Stops a double-tap on Save from submitting twice.
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _account = widget.accounts.first; // sensible default
    _occurredAt = widget.now(); // default: right now
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// The amount typed so far, or null while it is empty or invalid.
  Money? _parsedAmount() {
    final text = _amountController.text.trim();
    if (ExpenseValidators.amount(text) != null) return null;
    return Money.parse(text);
  }

  Future<void> _pickDate() async {
    final now = widget.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(
        _occurredAt.year,
        _occurredAt.month,
        _occurredAt.day,
      ),
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    // The screen may have closed while the picker was open.
    if (picked == null || !mounted) return;

    setState(() {
      _occurredAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _occurredAt.hour,
        _occurredAt.minute,
      );
      _dateError = null;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt),
    );
    if (picked == null || !mounted) return;

    setState(() {
      _occurredAt = DateTime(
        _occurredAt.year,
        _occurredAt.month,
        _occurredAt.day,
        picked.hour,
        picked.minute,
      );
      _dateError = null;
    });
  }

  void _save() {
    if (_saving) return;

    final fieldsValid = _formKey.currentState!.validate();
    final category = _category;
    final dateError = ExpenseValidators.occurredAt(_occurredAt, widget.now());

    setState(() {
      _categoryError = category == null ? 'Choose a category' : null;
      _dateError = dateError;
    });

    if (!fieldsValid || category == null || dateError != null) return;

    _saving = true;
    final description = _descriptionController.text.trim();

    // pop(value) closes this screen and hands the value to whoever opened it.
    Navigator.of(context).pop(
      NewExpense(
        amount: Money.parse(_amountController.text.trim()),
        category: category,
        account: _account,
        occurredAt: _occurredAt,
        description: description.isEmpty ? null : description,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = _parsedAmount();
    final overBalance = amount != null && amount.paisa > _account.balance.paisa;

    return Scaffold(
      appBar: AppBar(title: const Text('Add expense')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('amountField'),
                  controller: _amountController,
                  autofocus: true, // the keyboard opens immediately
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
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
                  // Rebuild so the low-balance warning can update as you type.
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 24),
                Text('Category', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final category in widget.categories)
                      ChoiceChip(
                        avatar: Icon(category.icon, size: 18),
                        label: Text(category.name),
                        showCheckmark: false,
                        selected: _category?.id == category.id,
                        onSelected: (_) => setState(() {
                          _category = category;
                          _categoryError = null;
                        }),
                      ),
                  ],
                ),
                if (_categoryError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _categoryError!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                const SizedBox(height: 24),
                Text('Paid from', style: theme.textTheme.titleSmall),
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
                if (overBalance)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'That is more than the ${_account.name} balance of '
                      '${_account.balance.format()}. The balance would go '
                      'below zero.',
                      style: TextStyle(color: Colors.orange.shade800),
                    ),
                  ),
                const SizedBox(height: 24),
                Text('When', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      key: const Key('dateButton'),
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text(AppDates.weekdayDate(_occurredAt)),
                    ),
                    OutlinedButton.icon(
                      key: const Key('timeButton'),
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time, size: 18),
                      label: Text(AppDates.time12h(_occurredAt)),
                    ),
                  ],
                ),
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
                  key: const Key('descriptionField'),
                  controller: _descriptionController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'What was it for? (optional)',
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    key: const Key('saveExpenseButton'),
                    onPressed: _save,
                    child: const Text('Save expense'),
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