import 'package:financial_tracker/common/errors/errors_classes.dart';
import 'package:financial_tracker/common/patterns/command.dart';
import 'package:financial_tracker/domain/entity/transaction_entity.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

// Cores inline
const _emerald     = Color(0xFF00897B);
const _emeraldL    = Color(0xFF4DB6AC);
const _violet      = Color(0xFF7C4DFF);
const _violetD     = Color(0xFF512DA8);
const _danger      = Color(0xFFEF4444);
const _slate50     = Color(0xFFF8FAFC);
const _slate100    = Color(0xFFF1F5F9);
const _slate400    = Color(0xFF94A3B8);
const _slate700    = Color(0xFF334155);
const _slate800    = Color(0xFF1E293B);
const _incomeGrad  = LinearGradient(colors: [_emerald, _emeraldL], begin: Alignment.topLeft, end: Alignment.bottomRight);
const _expenseGrad = LinearGradient(colors: [_violetD, _violet],   begin: Alignment.topLeft, end: Alignment.bottomRight);

class TransactionForm extends StatefulWidget {
  final Command1<void, Failure, TransactionEntity> submitCommand;
  final TransactionType type;
  final Color color;
  final TransactionEntity? existingTransaction;

  const TransactionForm({
    super.key,
    required this.type,
    required this.color,
    required this.submitCommand,
    this.existingTransaction,
  });

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  late DateTime _selectedDate;

  bool get _isEditing => widget.existingTransaction != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final t = widget.existingTransaction!;
      _titleController.text = t.title;
      _amountController.text = t.amount.toStringAsFixed(2);
      _selectedDate = t.date;
    } else {
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _presentDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: Theme.of(context).colorScheme.copyWith(primary: widget.color)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final transaction = TransactionEntity(
      id: widget.existingTransaction?.id,
      title: _titleController.text.trim(),
      amount: double.parse(_amountController.text),
      date: _selectedDate,
      type: widget.type,
    );

    await widget.submitCommand.execute(transaction);

    if (widget.submitCommand.resultSignal.value?.isFailure ?? false) {
      final msg = widget.submitCommand.resultSignal.value?.failureValueOrNull;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro: ${msg ?? 'Erro desconhecido'}'),
        backgroundColor: _danger,
      ));
      Navigator.pop(context);
      return;
    }

    if (!_isEditing) {
      _titleController.clear();
      _amountController.clear();
      setState(() => _selectedDate = DateTime.now());
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${widget.type.nameSingular} ${_isEditing ? 'editada' : 'adicionada'} com sucesso!'),
      backgroundColor: widget.color,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _label('Descrição'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Ex: Salário, Mercado...',
                prefixIcon: _prefixIcon(Icons.description_rounded),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe uma descrição' : null,
            ),
            const SizedBox(height: 16),

            _label('Valor'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(hintText: '0,00', prefixIcon: _prefixIcon(Icons.attach_money_rounded)),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Informe um valor';
                if (double.tryParse(v) == null) return 'Digite um número válido';
                if (double.parse(v) <= 0) return 'O valor deve ser maior que zero';
                return null;
              },
            ),
            const SizedBox(height: 16),

            _label('Data'),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _presentDatePicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? _slate800.withValues(alpha: 0.6) : _slate50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? _slate700 : _slate100),
                ),
                child: Row(
                  children: [
                    _prefixIcon(Icons.calendar_today_rounded),
                    const SizedBox(width: 4),
                    Expanded(child: Text(DateFormat("d 'de' MMMM 'de' yyyy", 'pt_BR').format(_selectedDate), style: Theme.of(context).textTheme.bodyMedium)),
                    const Icon(Icons.chevron_right_rounded, color: _slate400, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            Watch((context) {
              final isRunning = widget.submitCommand.runningSignal.value;
              return GestureDetector(
                onTap: isRunning ? null : _submitForm,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: isRunning
                        ? LinearGradient(colors: [widget.color.withValues(alpha: 0.5), widget.color.withValues(alpha: 0.5)])
                        : (widget.type == TransactionType.income ? _incomeGrad : _expenseGrad),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isRunning ? [] : [BoxShadow(color: widget.color.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Center(
                    child: isRunning
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(_isEditing ? Icons.check_rounded : Icons.add_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(_isEditing ? 'Salvar Alterações' : 'Adicionar ${widget.type.nameSingular}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                          ]),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: _slate700, fontSize: 12, letterSpacing: 0.8));

  Widget _prefixIcon(IconData icon) => Container(
    margin: const EdgeInsets.all(10),
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
    child: Icon(icon, color: widget.color, size: 16),
  );
}