import '../../common/config/dependencies.dart';
import '../../common/theme/app_theme.dart';
import '../../common/types/date_filter_type.dart';
import '../../domain/entity/transaction_entity.dart';
import 'package:financial_tracker/ui/controller/home_page_controller.dart';
import 'package:financial_tracker/ui/widget/date_filter_transactions.dart';
import 'package:financial_tracker/ui/widget/summary_carousel.dart';
import 'package:financial_tracker/ui/widget/transaction_sheet.dart';
import 'package:financial_tracker/ui/widget/transaction_sheets_card.dart';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late HomePageController viewModelController;

  @override
  void initState() {
    viewModelController = injector.get<HomePageController>();
    viewModelController.load.execute();
    super.initState();
  }

  void _toggleFilterVisibility() {}

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── AppBar com gradiente ──
          SliverAppBar(
            expandedHeight: 120,
            collapsedHeight: 64,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Container(
                decoration: BoxDecoration(
                  gradient: isDark
                      ? AppColors.darkHeroGradient
                      : const LinearGradient(
                          colors: [Color(0xFF004D40), Color(0xFF00897B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Olá 👋',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Controle Financeiro',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Título colapsado
            title: const Text(
              'Controle Financeiro',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
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
              _AppBarIconBtn(
                icon: Icons.receipt_long_rounded,
                tooltip: 'Todas as transações',
                onPressed: () {},
              ),
              const SizedBox(width: 4),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // ── Carrossel de resumo ──
                Watch((context) {
                  final income = viewModelController.totalIncome.value;
                  final expense = viewModelController.totalExpense.value;
                  return SummaryCarousel(
                    totalIncome: income,
                    totalExpense: expense,
                  );
                }),

                // ── Filtro animado ──
                Watch((context) {
                  final isVisible = viewModelController.isFilterVisible.value;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: isVisible ? null : 0,
                    child: isVisible
                        ? DateFilterTransactions(
                            filtro: (
                              type: viewModelController.filterType,
                              startDate: viewModelController.startDate,
                              endDate: viewModelController.endDate,
                            ),
                            onFilterChanged: (startDate, endDate) {
                              viewModelController.searchTransactionsByDate
                                  .execute(startDate!, endDate!);
                            },
                            onUpdateFilter: (type, startDate, endDate) {
                              viewModelController.setFiltersParams(
                                  type, startDate, endDate);
                            },
                            onAllTransactionsFiltered: () {
                              viewModelController.load.execute();
                            },
                            onTapHideFilter: _toggleFilterVisibility,
                          )
                        : const SizedBox.shrink(),
                  );
                }),

                // ── Seção "Nova Transação" ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 16,
                        decoration: BoxDecoration(
                          gradient: AppColors.incomeGradient,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Nova Transação',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ],
                  ),
                ),

                // ── Botões de ação com gradiente ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: _GradientActionButton(
                          label: 'Receita',
                          icon: Icons.add_rounded,
                          gradient: AppColors.incomeGradient,
                          shadowColor: AppColors.emerald,
                          onPressed: () => _showIncomeSheet(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _GradientActionButton(
                          label: 'Despesa',
                          icon: Icons.remove_rounded,
                          gradient: AppColors.expenseGradient,
                          shadowColor: AppColors.violet,
                          onPressed: () => _showExpenseSheet(context),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Lista de transações ──
                Watch((context) {
                  final incomes = viewModelController.incomes.value;
                  final expenses = viewModelController.expenses.value;
                  return TransactionCardSheets(
                    incomeTransactions: incomes,
                    expenseTransactions: expenses,
                    onDelete: (id) {
                      viewModelController.deleteTransaction.execute(id);
                    },
                    onEdit: (transaction) {
                      _showEditSheet(context, transaction);
                    },
                    undoDelete: viewModelController.undoDelectedTransaction,
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

  void _showEditSheet(BuildContext context, TransactionEntity transaction) {
    TransactionSheet.show(
      context: context,
      type: transaction.type,
      submitCommand: viewModelController.editTransaction,
      existingTransaction: transaction,
    );
  }

  void _showIncomeSheet(BuildContext context) {
    TransactionSheet.show(
      context: context,
      type: TransactionType.income,
      submitCommand: viewModelController.saveTransaction,
    );
  }

  void _showExpenseSheet(BuildContext context) {
    TransactionSheet.show(
      context: context,
      type: TransactionType.expense,
      submitCommand: viewModelController.saveTransaction,
    );
  }
}

// ── Ícone da AppBar estilizado ──
class _AppBarIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _AppBarIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

// ── Botão de ação com gradiente ──
class _GradientActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final Color shadowColor;
  final VoidCallback onPressed;

  const _GradientActionButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.shadowColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}