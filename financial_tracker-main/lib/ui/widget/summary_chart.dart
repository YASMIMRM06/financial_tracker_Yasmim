import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';


import '../../common/utils/formatter.dart';

class SummaryChart extends StatefulWidget {
  final double totalIncome;
  final double totalExpense;

  const SummaryChart({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
  });

  @override
  State<SummaryChart> createState() => _SummaryChartState();
}

class _SummaryChartState extends State<SummaryChart>
    with SingleTickerProviderStateMixin {
  int _touchedIndex = -1;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF243044) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00897B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.donut_large_rounded,
                      color: const Color(0xFF00897B), size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  'Receitas vs Despesas',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),

          if (widget.totalIncome == 0 && widget.totalExpense == 0)
            _buildEmpty(context)
          else
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    // Gráfico animado
                    Expanded(
                      flex: 5,
                      child: AnimatedBuilder(
                        animation: _animation,
                        builder: (context, _) {
                          return PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 36,
                              startDegreeOffset: -90,
                              pieTouchData: PieTouchData(
                                touchCallback: (event, response) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        response == null ||
                                        response.touchedSection == null) {
                                      _touchedIndex = -1;
                                      return;
                                    }
                                    _touchedIndex = response
                                        .touchedSection!.touchedSectionIndex;
                                  });
                                },
                              ),
                              sections: _buildSections(),
                            ),
                            swapAnimationDuration:
                                const Duration(milliseconds: 600),
                            swapAnimationCurve: Curves.easeInOutCubic,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Legenda
                    Expanded(
                      flex: 4,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LegendItem(
                            color: const Color(0xFF00897B),
                            label: 'Receitas',
                            value: Formatter.formatCurrency(widget.totalIncome),
                            isHighlighted: _touchedIndex == 0,
                          ),
                          const SizedBox(height: 12),
                          _LegendItem(
                            color: const Color(0xFF7C4DFF),
                            label: 'Despesas',
                            value: Formatter.formatCurrency(widget.totalExpense),
                            isHighlighted: _touchedIndex == 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    final total = widget.totalIncome + widget.totalExpense;
    final incomePercent = total > 0 ? widget.totalIncome / total * 100 : 50;
    final expensePercent = total > 0 ? widget.totalExpense / total * 100 : 50;

    return [
      PieChartSectionData(
        value: widget.totalIncome > 0 ? widget.totalIncome : 0.001,
        color: const Color(0xFF00897B),
        radius: _touchedIndex == 0 ? 52 : 44,
        title: '${incomePercent.toStringAsFixed(0)}%',
        titleStyle: TextStyle(
          fontSize: _touchedIndex == 0 ? 13 : 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        showTitle: widget.totalIncome > 0,
      ),
      PieChartSectionData(
        value: widget.totalExpense > 0 ? widget.totalExpense : 0.001,
        color: const Color(0xFF7C4DFF),
        radius: _touchedIndex == 1 ? 52 : 44,
        title: '${expensePercent.toStringAsFixed(0)}%',
        titleStyle: TextStyle(
          fontSize: _touchedIndex == 1 ? 13 : 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        showTitle: widget.totalExpense > 0,
      ),
    ];
  }

  Widget _buildEmpty(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.donut_large_rounded, size: 44,
              color: const Color(0xFF94A3B8).withValues(alpha: 0.4)),
          const SizedBox(height: 8),
          Text(
            'Sem dados para exibir',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final bool isHighlighted;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
    required this.isHighlighted,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(
        horizontal: isHighlighted ? 8 : 0,
        vertical: isHighlighted ? 4 : 0,
      ),
      decoration: BoxDecoration(
        color: isHighlighted ? color.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}