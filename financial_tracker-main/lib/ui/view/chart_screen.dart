import 'package:financial_tracker/common/utils/formatter.dart';
import 'package:financial_tracker/domain/entity/transaction_entity.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

const _emerald     = Color(0xFF00897B);
const _emeraldL    = Color(0xFF4DB6AC);
const _violet      = Color(0xFF7C4DFF);
const _violetD     = Color(0xFF512DA8);
const _slate100    = Color(0xFFF1F5F9);
const _slate400    = Color(0xFF94A3B8);
const _slate700    = Color(0xFF334155);
const _slate800    = Color(0xFF1E293B);
const _cardDark    = Color(0xFF243044);
const _heroGrad    = LinearGradient(colors: [Color(0xFF004D40), _emerald], begin: Alignment.topLeft, end: Alignment.bottomRight);
const _heroGradDk  = LinearGradient(colors: [Color(0xFF0F2027), Color(0xFF203A43)], begin: Alignment.topLeft, end: Alignment.bottomRight);

class ChartScreen extends StatefulWidget {
  final List<TransactionEntity> incomes;
  final List<TransactionEntity> expenses;

  const ChartScreen({super.key, required this.incomes, required this.expenses});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _touchedIndex = -1;

  double get _totalIncome  => widget.incomes.fold(0, (s, t) => s + t.amount);
  double get _totalExpense => widget.expenses.fold(0, (s, t) => s + t.amount);
  double get _balance      => _totalIncome - _totalExpense;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() { if (mounted) setState(() {}); });
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 80,
            collapsedHeight: 64,
            pinned: true,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(52, 0, 0, 16),
              title: const Text('Análise Financeira', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              background: Container(decoration: BoxDecoration(gradient: isDark ? _heroGradDk : _heroGrad)),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [

                  // ── Cards de resumo ──
                  Row(children: [
                    Expanded(child: _SummaryMiniCard(label: 'Receitas',  value: _totalIncome,  color: _emerald)),
                    const SizedBox(width: 10),
                    Expanded(child: _SummaryMiniCard(label: 'Despesas',  value: _totalExpense, color: _violet)),
                    const SizedBox(width: 10),
                    Expanded(child: _SummaryMiniCard(label: 'Saldo',     value: _balance,      color: _balance >= 0 ? _emerald : _violet)),
                  ]),

                  const SizedBox(height: 20),

                  // ── Gráfico de pizza ──
                  _buildPieCard(isDark),

                  const SizedBox(height: 20),

                  // ── Tabs receitas/despesas ──
                  _buildTransactionList(isDark),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieCard(bool isDark) {
    final hasData = _totalIncome > 0 || _totalExpense > 0;
    final total   = _totalIncome + _totalExpense;

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? _cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? _slate800 : _slate100),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          // Pizza
          Expanded(
            flex: 5,
            child: hasData
                ? PieChart(PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 38,
                    startDegreeOffset: -90,
                    pieTouchData: PieTouchData(touchCallback: (event, response) {
                      setState(() {
                        _touchedIndex = (!event.isInterestedForInteractions || response?.touchedSection == null) ? -1 : response!.touchedSection!.touchedSectionIndex;
                      });
                    }),
                    sections: [
                      PieChartSectionData(
                        value: _totalIncome > 0 ? _totalIncome : 0.001,
                        color: _emerald,
                        radius: _touchedIndex == 0 ? 54 : 46,
                        title: total > 0 ? '${(_totalIncome / total * 100).toStringAsFixed(0)}%' : '',
                        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                        showTitle: _totalIncome > 0,
                      ),
                      PieChartSectionData(
                        value: _totalExpense > 0 ? _totalExpense : 0.001,
                        color: _violet,
                        radius: _touchedIndex == 1 ? 54 : 46,
                        title: total > 0 ? '${(_totalExpense / total * 100).toStringAsFixed(0)}%' : '',
                        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                        showTitle: _totalExpense > 0,
                      ),
                    ],
                  ), swapAnimationDuration: const Duration(milliseconds: 400))
                : const Center(child: Icon(Icons.donut_large_rounded, size: 64, color: _slate400)),
          ),

          const SizedBox(width: 16),

          // Legenda
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegendTile(color: _emerald, label: 'Receitas', value: Formatter.formatCurrency(_totalIncome), highlighted: _touchedIndex == 0),
                const SizedBox(height: 16),
                _LegendTile(color: _violet,  label: 'Despesas', value: Formatter.formatCurrency(_totalExpense), highlighted: _touchedIndex == 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? _cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? _slate800 : _slate100),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // TabBar
          Container(
            decoration: BoxDecoration(
              color: isDark ? _slate800.withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            ),
            child: TabBar(
              controller: _tabController,
              padding: const EdgeInsets.all(6),
              indicator: BoxDecoration(
                gradient: _tabController.index == 0
                    ? const LinearGradient(colors: [_emerald, _emeraldL])
                    : const LinearGradient(colors: [_violetD, _violet]),
                borderRadius: BorderRadius.circular(16),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? _slate400 : _slate700,
              tabs: [
                Tab(height: 38, child: Row(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.arrow_upward_rounded, size: 15), SizedBox(width: 6), Text('Receitas', style: TextStyle(fontSize: 13))])),
                Tab(height: 38, child: Row(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.arrow_downward_rounded, size: 15), SizedBox(width: 6), Text('Despesas', style: TextStyle(fontSize: 13))])),
              ],
            ),
          ),

          // Lista
          SizedBox(
            height: 300,
            child: TabBarView(
              controller: _tabController,
              children: [
                _listView(widget.incomes,  _emerald, TransactionType.income),
                _listView(widget.expenses, _violet,  TransactionType.expense),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _listView(List<TransactionEntity> list, Color color, TransactionType type) {
    if (list.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(type == TransactionType.income ? Icons.savings_rounded : Icons.shopping_cart_rounded, size: 40, color: color.withValues(alpha: 0.3)),
        const SizedBox(height: 8),
        Text('Sem ${type.namePlural.toLowerCase()}', style: const TextStyle(color: _slate400, fontSize: 13)),
      ]));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, i) {
        final t = list[i];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(type == TransactionType.income ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: color, size: 18)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(Formatter.formatDate(t.date), style: const TextStyle(color: _slate400, fontSize: 11)),
            ])),
            Text(Formatter.formatCurrency(t.amount), style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
          ]),
        );
      },
    );
  }
}

class _SummaryMiniCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _SummaryMiniCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? _cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? _slate800 : _slate100),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: _slate400, fontSize: 10, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(Formatter.formatCurrency(value), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

class _LegendTile extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final bool highlighted;
  const _LegendTile({required this.color, required this.label, required this.value, required this.highlighted});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    padding: EdgeInsets.symmetric(horizontal: highlighted ? 8 : 0, vertical: highlighted ? 4 : 0),
    decoration: BoxDecoration(color: highlighted ? color.withValues(alpha: 0.1) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
    child: Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: _slate400, fontSize: 11)),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
      ]),
    ]),
  );
}