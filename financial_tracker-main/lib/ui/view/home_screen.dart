import 'package:financial_tracker/common/config/dependencies.dart';
import 'package:financial_tracker/common/types/date_filter_type.dart';
import 'package:financial_tracker/domain/entity/transaction_entity.dart';
import 'package:financial_tracker/ui/controller/home_page_controller.dart';
import 'package:financial_tracker/ui/widget/date_filter_transactions.dart';
import 'package:financial_tracker/ui/widget/summary_carousel.dart';
import 'package:financial_tracker/ui/widget/transaction_sheet.dart';
import 'package:financial_tracker/ui/widget/transaction_sheets_card.dart';
import 'package:financial_tracker/ui/view/chart_screen.dart';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

const _emerald     = Color(0xFF00897B);
const _emeraldL    = Color(0xFF4DB6AC);
const _violet      = Color(0xFF7C4DFF);
const _violetD     = Color(0xFF512DA8);
const _slate400    = Color(0xFF94A3B8);
const _slate700    = Color(0xFF334155);
const _incomeGrad  = LinearGradient(colors: [_emerald, _emeraldL],  begin: Alignment.topLeft, end: Alignment.bottomRight);
const _expenseGrad = LinearGradient(colors: [_violetD, _violet],    begin: Alignment.topLeft, end: Alignment.bottomRight);
const _heroGrad    = LinearGradient(colors: [Color(0xFF004D40), _emerald], begin: Alignment.topLeft, end: Alignment.bottomRight);
const _heroGradDk  = LinearGradient(colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)], begin: Alignment.topLeft, end: Alignment.bottomRight);

// Filtro de tipo de transação
enum _TypeFilter { all, income, expense }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late HomePageController viewModelController;
  _TypeFilter _typeFilter = _TypeFilter.all;

  @override
  void initState() {
    viewModelController = injector.get<HomePageController>();
    viewModelController.load.execute();
    super.initState();
  }

  List<TransactionEntity> _filterByType(List<TransactionEntity> incomes, List<TransactionEntity> expenses) {
    switch (_typeFilter) {
      case _TypeFilter.income:  return incomes;
      case _TypeFilter.expense: return expenses;
      case _TypeFilter.all:     return [...incomes, ...expenses]..sort((a, b) => b.date.compareTo(a.date));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 80,
            collapsedHeight: 64,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 0, 16),
              title: const Text('Controle Financeiro',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
              background: Container(decoration: BoxDecoration(gradient: isDark ? _heroGradDk : _heroGrad)),
            ),
            actions: [
              Watch((context) {
                final isVisible = viewModelController.isFilterVisible.value;
                return _AppBarIconBtn(
                  icon: isVisible ? Icons.filter_list_off : Icons.filter_list,
                  tooltip: isVisible ? 'Ocultar filtros' : 'Mostrar filtros',
                  onPressed: viewModelController.toggleFilterVisibility,
                );
              }),
              Watch((context) {
                final incomes  = viewModelController.incomes.value;
                final expenses = viewModelController.expenses.value;
                return _AppBarIconBtn(
                  icon: Icons.bar_chart_rounded,
                  tooltip: 'Análise financeira',
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ChartScreen(incomes: incomes, expenses: expenses),
                  )),
                );
              }),
              const SizedBox(width: 4),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                Watch((context) {
                  final income  = viewModelController.totalIncome.value;
                  final expense = viewModelController.totalExpense.value;
                  return SummaryCarousel(totalIncome: income, totalExpense: expense);
                }),

                // ── Filtro de período ──
                Watch((context) {
                  final isVisible = viewModelController.isFilterVisible.value;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: isVisible ? null : 0,
                    child: isVisible
                        ? DateFilterTransactions(
                            filtro: (type: viewModelController.filterType, startDate: viewModelController.startDate, endDate: viewModelController.endDate),
                            onFilterChanged: (startDate, endDate) => viewModelController.searchTransactionsByDate.execute(startDate!, endDate!),
                            onUpdateFilter: (type, startDate, endDate) => viewModelController.setFiltersParams(type, startDate, endDate),
                            onAllTransactionsFiltered: () => viewModelController.load.execute(),
                            onTapHideFilter: () {},
                          )
                        : const SizedBox.shrink(),
                  );
                }),

                // ── Filtro por tipo ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      Container(width: 3, height: 16, decoration: BoxDecoration(gradient: _incomeGrad, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 8),
                      Text('Filtrar por tipo', style: TextStyle(color: isDark ? _slate400 : _slate700, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                      const SizedBox(width: 12),
                      _TypeChip(label: 'Todos',    selected: _typeFilter == _TypeFilter.all,     color: _emerald, onTap: () => setState(() => _typeFilter = _TypeFilter.all)),
                      const SizedBox(width: 6),
                      _TypeChip(label: 'Receitas', selected: _typeFilter == _TypeFilter.income,  color: _emerald, onTap: () => setState(() => _typeFilter = _TypeFilter.income)),
                      const SizedBox(width: 6),
                      _TypeChip(label: 'Despesas', selected: _typeFilter == _TypeFilter.expense, color: _violet,  onTap: () => setState(() => _typeFilter = _TypeFilter.expense)),
                    ],
                  ),
                ),

                // ── Botões nova transação ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Row(
                    children: [
                      Container(width: 3, height: 16, decoration: BoxDecoration(gradient: _incomeGrad, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 8),
                      Text('Nova Transação', style: TextStyle(color: isDark ? _slate400 : _slate700, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(children: [
                    Expanded(child: _GradientActionButton(label: 'Receita',  icon: Icons.add_rounded,    gradient: _incomeGrad,  shadowColor: _emerald, onPressed: () => _showIncomeSheet(context))),
                    const SizedBox(width: 12),
                    Expanded(child: _GradientActionButton(label: 'Despesa',  icon: Icons.remove_rounded, gradient: _expenseGrad, shadowColor: _violet,  onPressed: () => _showExpenseSheet(context))),
                  ]),
                ),

                const SizedBox(height: 8),

                // ── Lista filtrada ──
                Watch((context) {
                  final incomes  = viewModelController.incomes.value;
                  final expenses = viewModelController.expenses.value;
                  final filtered = _filterByType(incomes, expenses);

                  // Filtro "Todos": lista combinada e ordenada por data
                  if (_typeFilter == _TypeFilter.all) {
                    return _FilteredList(
                      transactions: filtered,
                      color: _emerald,
                      type: null, // null indica lista mista
                      onDelete: (id) => viewModelController.deleteTransaction.execute(id),
                      onEdit:   (t)  => _showEditSheet(context, t),
                      onUndo:   (t)  => viewModelController.undoDelectedTransaction.execute(t),
                      scaffoldContext: context,
                    );
                  }

                  // Lista filtrada por tipo (Receitas ou Despesas)
                  return _FilteredList(
                    transactions: filtered,
                    color: _typeFilter == _TypeFilter.income ? _emerald : _violet,
                    type: _typeFilter == _TypeFilter.income ? TransactionType.income : TransactionType.expense,
                    onDelete: (id) => viewModelController.deleteTransaction.execute(id),
                    onEdit:   (t)  => _showEditSheet(context, t),
                    onUndo:   (t)  => viewModelController.undoDelectedTransaction.execute(t),
                    scaffoldContext: context,
                  );
                }),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, TransactionEntity transaction) =>
      TransactionSheet.show(context: context, type: transaction.type, submitCommand: viewModelController.editTransaction, existingTransaction: transaction);

  void _showIncomeSheet(BuildContext context) =>
      TransactionSheet.show(context: context, type: TransactionType.income,  submitCommand: viewModelController.saveTransaction);

  void _showExpenseSheet(BuildContext context) =>
      TransactionSheet.show(context: context, type: TransactionType.expense, submitCommand: viewModelController.saveTransaction);
}

// ── Chip de tipo ──
class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _TypeChip({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: selected ? color : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: selected ? color : color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? Colors.white : color)),
    ),
  );
}

// ── Lista filtrada por tipo (ou mista quando type == null) ──
class _FilteredList extends StatelessWidget {
  final List<TransactionEntity> transactions;
  final Color color;
  final TransactionType? type; // null = lista mista (Todos)
  final Function(String) onDelete;
  final Function(TransactionEntity) onEdit;
  final Function(TransactionEntity) onUndo;
  final BuildContext scaffoldContext;
  const _FilteredList({required this.transactions, required this.color, required this.type, required this.onDelete, required this.onEdit, required this.onUndo, required this.scaffoldContext});

  Color _colorFor(TransactionType t) =>
      t == TransactionType.income ? _emerald : _violet;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEmpty = transactions.isEmpty;
    final emptyLabel = type == null ? 'transações' : type!.namePlural.toLowerCase();

    if (isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(child: Text('Sem $emptyLabel', style: const TextStyle(color: _slate400))),
      );
    }

    // Cabeçalho "Todas as transações" só para o modo misto
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (type == null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                Container(width: 3, height: 16, decoration: BoxDecoration(gradient: _incomeGrad, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Text('Todas as transações', style: TextStyle(color: isDark ? _slate400 : _slate700, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                const Spacer(),
                Text('${transactions.length} itens', style: const TextStyle(color: _slate400, fontSize: 11)),
              ]),
            ),
          ],
          ...transactions.map((t) {
            final itemColor = type != null ? color : _colorFor(t.type);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Dismissible(
                key: Key('filtered_${t.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.transparent, const Color(0xFFEF4444).withValues(alpha: 0.9)], begin: Alignment.centerLeft, end: Alignment.centerRight),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete_rounded, color: Colors.white, size: 22),
                ),
                onDismissed: (_) {
                  final undo = t.copyWith();
                  onDelete(t.id);
                  ScaffoldMessenger.of(scaffoldContext).clearSnackBars();
                  ScaffoldMessenger.of(scaffoldContext).showSnackBar(SnackBar(
                    content: Text('${t.title} excluída'),
                    action: SnackBarAction(label: 'DESFAZER', textColor: itemColor, onPressed: () => onUndo(undo)),
                  ));
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? const Color(0xFF334155).withValues(alpha: 0.4) : const Color(0xFFF1F5F9)),
                  ),
                  child: Row(children: [
                    Container(width: 4, height: 60, decoration: BoxDecoration(color: itemColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Container(width: 38, height: 38, decoration: BoxDecoration(color: itemColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: Icon(t.type == TransactionType.income ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: itemColor, size: 18)),
                    ),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(t.title, style: Theme.of(context).textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${t.date.day.toString().padLeft(2,'0')}/${t.date.month.toString().padLeft(2,'0')}/${t.date.year}', style: Theme.of(context).textTheme.bodySmall),
                    ])),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('R\$ ${t.amount.toStringAsFixed(2).replaceAll('.', ',')}', style: TextStyle(color: itemColor, fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: () => onEdit(t),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: itemColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.edit_rounded, size: 11, color: itemColor.withValues(alpha: 0.8)),
                              const SizedBox(width: 3),
                              Text('Editar', style: TextStyle(fontSize: 10, color: itemColor.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ),
                        const SizedBox(width: 5),
                        GestureDetector(
                          onTap: () {
                            final undo = t.copyWith();
                            onDelete(t.id);
                            ScaffoldMessenger.of(scaffoldContext).clearSnackBars();
                            ScaffoldMessenger.of(scaffoldContext).showSnackBar(SnackBar(
                              content: Text('${t.title} excluída'),
                              action: SnackBarAction(label: 'DESFAZER', textColor: itemColor, onPressed: () => onUndo(undo)),
                            ));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.delete_rounded, size: 11, color: const Color(0xFFEF4444).withValues(alpha: 0.8)),
                              const SizedBox(width: 3),
                              Text('Excluir', style: TextStyle(fontSize: 10, color: const Color(0xFFEF4444).withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ),
                      ]),
                    ),
                  ]),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _AppBarIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  const _AppBarIconBtn({required this.icon, required this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    ),
  );
}

class _GradientActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final Color shadowColor;
  final VoidCallback onPressed;
  const _GradientActionButton({required this.label, required this.icon, required this.gradient, required this.shadowColor, required this.onPressed});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onPressed,
    child: Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: shadowColor.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 18)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
      ]),
    ),
  );
}