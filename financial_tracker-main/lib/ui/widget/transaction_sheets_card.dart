import 'package:financial_tracker/common/errors/errors_classes.dart';
import 'package:financial_tracker/common/patterns/command.dart';
import 'package:financial_tracker/common/utils/formatter.dart';
import 'package:financial_tracker/domain/entity/transaction_entity.dart';
import 'package:flutter/material.dart';

const _emerald     = Color(0xFF00897B);
const _emeraldL    = Color(0xFF4DB6AC);
const _violet      = Color(0xFF7C4DFF);
const _violetD     = Color(0xFF512DA8);
const _danger      = Color(0xFFEF4444);
const _success     = Color(0xFF22C55E);
const _slate50     = Color(0xFFF8FAFC);
const _slate100    = Color(0xFFF1F5F9);
const _slate400    = Color(0xFF94A3B8);
const _slate700    = Color(0xFF334155);
const _slate800    = Color(0xFF1E293B);
const _cardDark    = Color(0xFF243044);
const _incomeGrad  = LinearGradient(colors: [_emerald, _emeraldL], begin: Alignment.topLeft, end: Alignment.bottomRight);
const _expenseGrad = LinearGradient(colors: [_violetD, _violet],   begin: Alignment.topLeft, end: Alignment.bottomRight);

class TransactionCardSheets extends StatefulWidget {
  final List<TransactionEntity> incomeTransactions;
  final List<TransactionEntity> expenseTransactions;
  final Function(String id) onDelete;
  final Function(TransactionEntity transaction) onEdit;
  final Command1<void, Failure, TransactionEntity> undoDelete;
  final BuildContext scaffoldContext;

  const TransactionCardSheets({
    super.key,
    required this.incomeTransactions,
    required this.expenseTransactions,
    required this.onDelete,
    required this.onEdit,
    required this.undoDelete,
    required this.scaffoldContext,
  });

  @override
  State<TransactionCardSheets> createState() => _TransactionCardSheetsState();
}

class _TransactionCardSheetsState extends State<TransactionCardSheets>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _incomeScroll  = ScrollController();
  final ScrollController _expenseScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() { if (mounted) setState(() {}); });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _incomeScroll.dispose();
    _expenseScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              Container(width: 3, height: 16, decoration: BoxDecoration(gradient: _expenseGrad, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text('Transações', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: isDark ? _slate400 : _slate700, letterSpacing: 0.5)),
            ]),
          ),

          Container(
            decoration: BoxDecoration(
              color: isDark ? _cardDark : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? _slate700.withValues(alpha: 0.5) : _slate100),
              boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 4))],
            ),
            child: Column(children: [
              _buildTabBar(context, isDark),
              ClipRRect(
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                child: SizedBox(
                  height: 340,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(context, widget.incomeTransactions,  _emerald, TransactionType.income,  _incomeScroll),
                      _buildList(context, widget.expenseTransactions, _violet,  TransactionType.expense, _expenseScroll),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, bool isDark) {
    final isIncome = _tabController.index == 0;
    final activeColor = isIncome ? _emerald : _violet;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? _slate800.withValues(alpha: 0.6) : _slate50,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: TabBar(
        controller: _tabController,
        padding: const EdgeInsets.all(6),
        indicator: BoxDecoration(
          gradient: isIncome ? _incomeGrad : _expenseGrad,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: activeColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? _slate400 : _slate700,
        tabs: [
          _tab(TransactionType.income.namePlural,  Icons.arrow_upward_rounded,   0),
          _tab(TransactionType.expense.namePlural, Icons.arrow_downward_rounded, 1),
        ],
      ),
    );
  }

  Widget _tab(String title, IconData icon, int index) {
    final sel = _tabController.index == index;
    return Tab(
      height: 40,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        Text(title, style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
      ]),
    );
  }

  Widget _buildList(BuildContext context, List<TransactionEntity> transactions, Color color, TransactionType type, ScrollController scrollController) {
    if (transactions.isEmpty) return _emptyState(context, color, type);
    return Scrollbar(
      controller: scrollController,
      thumbVisibility: true,
      child: ListView.separated(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: transactions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final t = transactions[index];
          final undo = t.copyWith();
          return _TransactionTile(
            transaction: t,
            color: color,
            type: type,
            onDelete: () async {
              await widget.onDelete(t.id);
              ScaffoldMessenger.of(widget.scaffoldContext).clearSnackBars();
              ScaffoldMessenger.of(widget.scaffoldContext).showSnackBar(SnackBar(
                content: Text('${t.title} excluída'),
                action: SnackBarAction(
                  label: 'DESFAZER',
                  textColor: color,
                  onPressed: () async {
                    await widget.undoDelete.execute(undo);
                    final ok = widget.undoDelete.resultSignal.value?.isSuccess ?? false;
                    ScaffoldMessenger.of(widget.scaffoldContext).showSnackBar(SnackBar(
                      content: Text(ok ? '${t.title} restaurada!' : 'Erro ao restaurar'),
                      backgroundColor: ok ? _success : _danger,
                    ));
                  },
                ),
              ));
            },
            onEdit: () => widget.onEdit(t),
          );
        },
      ),
    );
  }

  Widget _emptyState(BuildContext context, Color color, TransactionType type) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), shape: BoxShape.circle),
        child: Icon(type == TransactionType.income ? Icons.savings_rounded : Icons.shopping_cart_rounded, size: 40, color: color.withValues(alpha: 0.5)),
      ),
      const SizedBox(height: 12),
      Text('Sem ${type.namePlural.toLowerCase()}', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: _slate400)),
      const SizedBox(height: 4),
      Text('Toque no botão acima para adicionar', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _slate400.withValues(alpha: 0.7))),
    ]),
  );
}

class _TransactionTile extends StatelessWidget {
  final TransactionEntity transaction;
  final Color color;
  final TransactionType type;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _TransactionTile({
    required this.transaction,
    required this.color,
    required this.type,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.transparent, _danger.withValues(alpha: 0.9)], begin: Alignment.centerLeft, end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.delete_rounded, color: Colors.white, size: 22),
          const SizedBox(height: 2),
          Text('Excluir', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 10, fontWeight: FontWeight.w600)),
        ]),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? _slate800.withValues(alpha: 0.5) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? _slate700.withValues(alpha: 0.4) : _slate100),
        ),
        child: Row(children: [
          // Barra lateral colorida
          Container(
            width: 4, height: 68,
            decoration: BoxDecoration(
              gradient: type == TransactionType.income ? _incomeGrad : _expenseGrad,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
            ),
          ),

          // Ícone
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(type == TransactionType.income ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: color, size: 18),
            ),
          ),

          // Título e data
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(transaction.title, style: Theme.of(context).textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(Formatter.formatDate(transaction.date), style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
          ),

          // Valor + botões Editar e Excluir
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(Formatter.formatCurrency(transaction.amount),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Row(mainAxisSize: MainAxisSize.min, children: [
                // Editar
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.edit_rounded, size: 11, color: color.withValues(alpha: 0.8)),
                      const SizedBox(width: 3),
                      Text('Editar', style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
                const SizedBox(width: 5),
                // Excluir
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: _danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.delete_rounded, size: 11, color: _danger.withValues(alpha: 0.8)),
                      const SizedBox(width: 3),
                      Text('Excluir', style: TextStyle(fontSize: 10, color: _danger.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}