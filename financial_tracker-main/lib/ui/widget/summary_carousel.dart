import 'summary_card.dart';
import 'summary_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SummaryCarousel extends StatefulWidget {
  final double totalIncome;
  final double totalExpense;

  const SummaryCarousel({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
  });

  @override
  State<SummaryCarousel> createState() => _SummaryCarouselState();
}

class _SummaryCarouselState extends State<SummaryCarousel> {
  int _currentPage = 0;

  void _goTo(int index) {
    HapticFeedback.lightImpact();
    setState(() => _currentPage = index);
  }

  @override
  Widget build(BuildContext context) {
    final isFirst = _currentPage == 0;

    return Column(
      children: [
        Stack(
          children: [
            // Conteúdo atual
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(isFirst ? -0.08 : 0.08, 0),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: SizedBox(
                key: ValueKey(_currentPage),
                height: 240,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _currentPage == 0
                      ? SummaryCard(
                          totalIncome: widget.totalIncome,
                          totalExpense: widget.totalExpense,
                          balance: widget.totalIncome - widget.totalExpense,
                        )
                      : Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: SummaryChart(
                            totalIncome: widget.totalIncome,
                            totalExpense: widget.totalExpense,
                          ),
                        ),
                ),
              ),
            ),

            // Seta esquerda
            if (_currentPage == 1)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () => _goTo(0),
                    child: Container(
                      margin: const EdgeInsets.only(left: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_left_rounded,
                          color: Colors.white, size: 26),
                    ),
                  ),
                ),
              ),

            // Seta direita
            if (_currentPage == 0)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () => _goTo(1),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_right_rounded,
                          color: Colors.white, size: 26),
                    ),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 8),

        // Indicadores de página
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: _currentPage == index ? 32 : 8,
            decoration: BoxDecoration(
              color: _currentPage == index
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          )),
        ),

        const SizedBox(height: 8),

        Text(
          _currentPage == 0
              ? 'Toque em › para ver o Gráfico'
              : 'Toque em ‹ para ver o Resumo',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}