import 'package:financial_tracker/common/types/date_filter_type.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const _emerald  = Color(0xFF00897B);
const _emeraldL = Color(0xFF4DB6AC);
const _slate50  = Color(0xFFF8FAFC);
const _slate100 = Color(0xFFF1F5F9);
const _slate400 = Color(0xFF94A3B8);
const _slate700 = Color(0xFF334155);
const _slate800 = Color(0xFF1E293B);
const _cardDark = Color(0xFF243044);

class DateFilterTransactions extends StatefulWidget {
  final Function(DateTime? startDate, DateTime? endDate) onFilterChanged;
  final Function() onAllTransactionsFiltered;
  final Function(DateFilterType type, DateTime? startDate, DateTime? endDate) onUpdateFilter;
  final VoidCallback? onTapHideFilter;
  final ({DateFilterType type, DateTime? startDate, DateTime? endDate}) filtro;

  const DateFilterTransactions({
    super.key,
    required this.onFilterChanged,
    required this.filtro,
    this.onTapHideFilter,
    required this.onAllTransactionsFiltered,
    required this.onUpdateFilter,
  });

  @override
  State<DateFilterTransactions> createState() => _DateFilterWidgetState();
}

class _DateFilterWidgetState extends State<DateFilterTransactions> with SingleTickerProviderStateMixin {
  late DateFilterType _filterType;
  DateTime? _startDate;
  DateTime? _endDate;
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _filterType = widget.filtro.type;
    _startDate  = widget.filtro.startDate;
    _endDate    = widget.filtro.endDate;
    _initializeDates();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() { _animController.dispose(); super.dispose(); }

  void _initializeDates() {
    final now   = DateTime.now();
    final range = _filterType.resolveRange(now, _startDate, _endDate);
    setState(() { _startDate = range?.start; _endDate = range?.end; });
  }

  void _applyFilter(DateFilterType type) {
    setState(() { _filterType = type; _initializeDates(); });
    if (type == DateFilterType.all) {
      widget.onAllTransactionsFiltered();
    } else {
      widget.onFilterChanged(_startDate, _endDate);
    }
    widget.onUpdateFilter(_filterType, _startDate, _endDate);
  }

  Future<void> _selectCustomDateRange() async {
    final now      = DateTime.now();
    final maxDate  = now.add(const Duration(days: 1));
    final safeRange = _filterType.resolveRange(now, _startDate, _endDate)?.cappedAt(maxDate);

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: safeRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('pt', 'BR'),
      builder: (context, child) {
        // Tema limpo para o calendário — fundo branco, cores definidas
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary:          _emerald,
              onPrimary:        Colors.white,
              surface:          Colors.white,
              onSurface:        Color(0xFF0F172A),
              secondaryContainer: Color(0xFFB2DFDB),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: _emerald),
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _filterType = DateFilterType.custom;
        _startDate  = picked.start;
        _endDate    = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      });
      widget.onFilterChanged(_startDate, _endDate);
      widget.onUpdateFilter(_filterType, _startDate, _endDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeIn,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        decoration: BoxDecoration(
          color: isDark ? _cardDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? _slate800 : _emerald.withValues(alpha: 0.2)),
          boxShadow: isDark ? [] : [BoxShadow(color: _emerald.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              decoration: BoxDecoration(
                color: _emerald.withValues(alpha: 0.06),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              ),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: _emerald.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.filter_alt_outlined, color: _emerald, size: 16)),
                const SizedBox(width: 10),
                const Text('Filtrar por período', style: TextStyle(color: _emerald, fontSize: 13, fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 18, color: isDark ? _slate400 : _slate700),
                  onPressed: widget.onTapHideFilter,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
              ]),
            ),

            // Chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip(DateFilterType.all,    'Tudo',         Icons.all_inclusive_rounded,  isDark),
                  _chip(DateFilterType.today,  'Hoje',         Icons.today_rounded,           isDark),
                  _chip(DateFilterType.week,   'Esta semana',  Icons.view_week_rounded,       isDark),
                  _chip(DateFilterType.month,  'Este mês',     Icons.calendar_month_rounded,  isDark),
                  _chip(DateFilterType.custom, 'Personalizado',Icons.date_range_rounded,      isDark),
                ],
              ),
            ),

            // Range personalizado selecionado
            if (_filterType == DateFilterType.custom && _startDate != null && _endDate != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: GestureDetector(
                  onTap: _selectCustomDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _emerald.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _emerald.withValues(alpha: 0.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.date_range_rounded, size: 15, color: _emerald),
                      const SizedBox(width: 8),
                      Text(
                        '${DateFormat('dd/MM/yyyy').format(_startDate!)} → ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _emerald),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.edit_outlined, size: 13, color: _emerald),
                    ]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(DateFilterType type, String label, IconData icon, bool isDark) {
    final isSelected = _filterType == type;
    return GestureDetector(
      onTap: () => type == DateFilterType.custom ? _selectCustomDateRange() : _applyFilter(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: isSelected ? const LinearGradient(colors: [_emerald, _emeraldL]) : null,
          color: isSelected ? null : (isDark ? _slate800 : _slate100.withValues(alpha: 0.8)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? _emerald : _slate400.withValues(alpha: 0.3)),
          boxShadow: isSelected ? [BoxShadow(color: _emerald.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))] : [],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: isSelected ? Colors.white : _slate400),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? Colors.white : (isDark ? _slate400 : _slate700))),
        ]),
      ),
    );
  }
}

//para funcionar o filtro de data personalizada, é necessário implementar a lógica de resolução do intervalo no DateFilterType e garantir que o repositório suporte a consulta por intervalo de datas. O widget é projetado para ser flexível e responsivo, com animações suaves e um design limpo que se encaixa bem tanto em temas claros quanto escuros.