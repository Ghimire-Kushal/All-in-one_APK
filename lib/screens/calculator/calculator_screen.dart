import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _SavedResult {
  const _SavedResult({required this.expression, required this.answer});
  final String expression;
  final double answer;

  Map<String, dynamic> toJson() => {'expression': expression, 'answer': answer};
  factory _SavedResult.fromJson(Map<String, dynamic> json) => _SavedResult(
        expression: json['expression'] as String,
        answer: (json['answer'] as num).toDouble(),
      );
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  static const _savedResultsKey = 'calculator_saved_results';
  String _display = '0';
  String _expression = '';
  double _operand1 = 0;
  String _operator = '';
  bool _newInput = false;
  bool _hasSavedCurrent = false;
  List<_SavedResult> _savedResults = [];

  @override
  void initState() {
    super.initState();
    _loadSavedResults();
  }

  Future<void> _loadSavedResults() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_savedResultsKey);
    if (raw == null) return;
    final values = jsonDecode(raw) as List<dynamic>;
    if (!mounted) return;
    setState(() => _savedResults = values
        .map((value) => _SavedResult.fromJson(Map<String, dynamic>.from(value as Map)))
        .toList());
  }

  Future<void> _persistSavedResults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _savedResultsKey,
      jsonEncode(_savedResults.map((result) => result.toJson()).toList()),
    );
  }

  void _onDigit(String digit) {
    setState(() {
      _hasSavedCurrent = false;
      if (_newInput || _display == '0') {
        _display = digit;
        _newInput = false;
      } else if (_display.length < 15) {
        _display += digit;
      }
    });
  }

  void _onDecimal() {
    setState(() {
      _hasSavedCurrent = false;
      if (_newInput) {
        _display = '0.';
        _newInput = false;
      } else if (!_display.contains('.')) {
        _display += '.';
      }
    });
  }

  void _onOperator(String op) {
    setState(() {
      _hasSavedCurrent = false;
      _operand1 = double.tryParse(_display) ?? 0;
      _operator = op;
      _expression = '${_fmt(_operand1)} $op';
      _newInput = true;
    });
  }

  void _onEquals() {
    if (_operator.isEmpty) return;
    final op2 = double.tryParse(_display);
    if (op2 == null || (_operator == '÷' && op2 == 0)) {
      setState(() => _display = 'Error');
      return;
    }
    double result;
    switch (_operator) {
      case '+': result = _operand1 + op2; break;
      case '-': result = _operand1 - op2; break;
      case '×': result = _operand1 * op2; break;
      case '÷': result = _operand1 / op2; break;
      case '%': result = _operand1 * op2 / 100; break;
      default: return;
    }
    setState(() {
      _expression = '$_expression ${_fmt(op2)} =';
      _display = _fmt(result);
      _operator = '';
      _newInput = true;
      _hasSavedCurrent = false;
    });
  }

  void _onClear() => setState(() {
        _display = '0';
        _expression = '';
        _operator = '';
        _operand1 = 0;
        _newInput = false;
        _hasSavedCurrent = false;
      });

  void _onBackspace() => setState(() {
        _hasSavedCurrent = false;
        _display = _display.length > 1 ? _display.substring(0, _display.length - 1) : '0';
      });

  void _onToggleSign() => setState(() {
        _hasSavedCurrent = false;
        final value = double.tryParse(_display) ?? 0;
        _display = _fmt(-value);
      });

  String _fmt(double value) {
    if (value == value.roundToDouble() && value.abs() < 1e10) return value.toInt().toString();
    return value.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  double get _savedTotal => _savedResults.fold(0, (sum, result) => sum + result.answer);
  bool get _canSave => !_hasSavedCurrent && double.tryParse(_display)?.isFinite == true;

  Future<void> _saveAnswer() async {
    final answer = double.tryParse(_display);
    if (answer == null || !answer.isFinite || _hasSavedCurrent) return;
    setState(() {
      _savedResults.add(_SavedResult(
        expression: _expression.isEmpty ? _display : _expression,
        answer: answer,
      ));
      _hasSavedCurrent = true;
    });
    await _persistSavedResults();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Answer saved')));
  }

  Future<void> _deleteResult(int index, StateSetter updateSheet) async {
    setState(() => _savedResults.removeAt(index));
    updateSheet(() {});
    await _persistSavedResults();
  }

  Future<void> _clearResults(StateSetter updateSheet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear saved results?'),
        content: const Text('This will permanently delete every saved answer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear Records')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _savedResults = []);
    updateSheet(() {});
    await _persistSavedResults();
  }

  void _showSavedResults() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, updateSheet) => SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * .68,
            child: Column(children: [
              ListTile(
                title: const Text('Saved Results', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${_savedResults.length} saved record${_savedResults.length == 1 ? '' : 's'}'),
                trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Card(child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Total of Saved Answers', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(_fmt(_savedTotal), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
                  ]),
                )),
              ),
              Expanded(
                child: _savedResults.isEmpty
                    ? const Center(child: Text('No saved answers yet.'))
                    : ListView.builder(
                        itemCount: _savedResults.length,
                        itemBuilder: (context, index) {
                          final record = _savedResults[index];
                          return ListTile(
                            leading: CircleAvatar(child: Text('${index + 1}')),
                            title: Text(record.expression),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(_fmt(record.answer), style: const TextStyle(fontWeight: FontWeight.w700)),
                              IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _deleteResult(index, updateSheet)),
                            ]),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  onPressed: _savedResults.isEmpty ? null : () => _clearResults(updateSheet),
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('Clear Records'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _showBaseConverter() => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => const _BaseConverterSheet(),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Calculator', style: TextStyle(fontWeight: FontWeight.w700)),
          actions: [
            IconButton(tooltip: 'Base Converter', onPressed: _showBaseConverter, icon: const Icon(Icons.numbers_rounded)),
            IconButton(tooltip: 'Saved Results', onPressed: _showSavedResults, icon: Badge(label: Text('${_savedResults.length}'), isLabelVisible: _savedResults.isNotEmpty, child: const Icon(Icons.bookmark_outline))),
          ],
        ),
        body: Column(children: [
          Expanded(child: Container(width: double.infinity, padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.end, children: [
            Text(_expression, style: TextStyle(fontSize: 16, color: Colors.grey[500])),
            const SizedBox(height: 8),
            FittedBox(fit: BoxFit.scaleDown, child: Text(_display, style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w300))),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: _canSave ? _saveAnswer : null, icon: const Icon(Icons.save_outlined), label: const Text('Save')),
          ]))),
          Container(padding: const EdgeInsets.all(16), child: Column(children: [
            _row([_btn('AC', _onClear, type: _BtnType.func), _btn('+/-', _onToggleSign, type: _BtnType.func), _btn('%', () => _onOperator('%'), type: _BtnType.func), _btn('÷', () => _onOperator('÷'), type: _BtnType.op)]),
            _row([_btn('7', () => _onDigit('7')), _btn('8', () => _onDigit('8')), _btn('9', () => _onDigit('9')), _btn('×', () => _onOperator('×'), type: _BtnType.op)]),
            _row([_btn('4', () => _onDigit('4')), _btn('5', () => _onDigit('5')), _btn('6', () => _onDigit('6')), _btn('-', () => _onOperator('-'), type: _BtnType.op)]),
            _row([_btn('1', () => _onDigit('1')), _btn('2', () => _onDigit('2')), _btn('3', () => _onDigit('3')), _btn('+', () => _onOperator('+'), type: _BtnType.op)]),
            _row([_btn('⌫', _onBackspace, type: _BtnType.func), _btn('0', () => _onDigit('0')), _btn('.', _onDecimal), _btn('=', _onEquals, type: _BtnType.eq)]),
          ])),
        ]),
      );

  Widget _row(List<Widget> children) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: children.map((child) => Expanded(child: Padding(padding: const EdgeInsets.all(4), child: child))).toList()));
  Widget _btn(String label, VoidCallback onTap, {_BtnType type = _BtnType.num}) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    final bg = type == _BtnType.op ? colors.primary : type == _BtnType.eq ? colors.secondary : type == _BtnType.func ? (dark ? const Color(0xFF2C2F3E) : const Color(0xFFE8EAF0)) : (dark ? const Color(0xFF1C1F2A) : Colors.white);
    final fg = type == _BtnType.op ? colors.onPrimary : type == _BtnType.eq ? colors.onSecondary : colors.onSurface;
    return GestureDetector(onTap: onTap, child: AnimatedContainer(duration: const Duration(milliseconds: 80), height: 68, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 4, offset: const Offset(0, 2))]), child: Center(child: Text(label, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: fg))));
  }
}

enum _BtnType { num, op, func, eq }

class _BaseConverterSheet extends StatefulWidget {
  const _BaseConverterSheet();
  @override State<_BaseConverterSheet> createState() => _BaseConverterSheetState();
}

class _BaseConverterSheetState extends State<_BaseConverterSheet> {
  final _controller = TextEditingController();
  int _base = 10;
  String? _error;
  int? _value;
  void _convert() { final text = _controller.text.trim(); final value = int.tryParse(text, radix: _base); setState(() { _value = value; _error = text.isEmpty ? null : value == null ? 'Invalid base $_base number.' : null; }); }
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => SafeArea(child: Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Base Converter', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)), const SizedBox(height: 16),
    DropdownButtonFormField<int>(value: _base, decoration: const InputDecoration(labelText: 'Input base'), items: const [DropdownMenuItem(value: 2, child: Text('Binary — Base 2')), DropdownMenuItem(value: 8, child: Text('Octal — Base 8')), DropdownMenuItem(value: 10, child: Text('Decimal — Base 10')), DropdownMenuItem(value: 16, child: Text('Hexadecimal — Base 16'))], onChanged: (value) => setState(() { _base = value!; _convert(); })),
    const SizedBox(height: 12), TextField(controller: _controller, textCapitalization: TextCapitalization.characters, onChanged: (_) => _convert(), decoration: InputDecoration(labelText: 'Input', errorText: _error)),
    if (_value != null) ...[const SizedBox(height: 16), _output('Binary', _value!.toRadixString(2)), _output('Octal', _value!.toRadixString(8)), _output('Decimal', _value!.toString()), _output('Hexadecimal', _value!.toRadixString(16).toUpperCase())],
  ])));
  Widget _output(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [SizedBox(width: 105, child: Text(label)), SelectableText(value, style: const TextStyle(fontWeight: FontWeight.w700))]));
}
