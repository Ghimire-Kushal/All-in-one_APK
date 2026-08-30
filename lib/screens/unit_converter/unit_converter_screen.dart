import 'package:flutter/material.dart';

enum UnitCategory { length, weight, temperature, storage, area, speed }

class UnitConverterScreen extends StatefulWidget {
  const UnitConverterScreen({super.key});

  @override
  State<UnitConverterScreen> createState() => _UnitConverterScreenState();
}

class _UnitConverterScreenState extends State<UnitConverterScreen> {
  UnitCategory _category = UnitCategory.length;
  final _inputCtrl = TextEditingController();
  String _fromUnit = '';
  String _toUnit = '';
  double? _result;

  static const _units = <UnitCategory, List<String>>{
    UnitCategory.length: [
      'Meter',
      'Kilometer',
      'Mile',
      'Foot',
      'Inch',
      'Centimeter',
      'Millimeter',
    ],
    UnitCategory.weight: ['Kilogram', 'Gram', 'Pound', 'Ounce', 'Ton'],
    UnitCategory.temperature: ['Celsius', 'Fahrenheit', 'Kelvin'],
    UnitCategory.storage: [
      'Byte',
      'Kilobyte',
      'Megabyte',
      'Gigabyte',
      'Terabyte',
    ],
    UnitCategory.area: [
      'Square Meter',
      'Square Kilometer',
      'Square Mile',
      'Acre',
      'Hectare',
      'Square Foot',
    ],
    UnitCategory.speed: ['m/s', 'km/h', 'mph', 'Knot'],
  };

  // All convert TO base unit, then FROM base unit
  static const _toBase = <UnitCategory, Map<String, double>>{
    UnitCategory.length: {
      'Meter': 1,
      'Kilometer': 1000,
      'Mile': 1609.34,
      'Foot': 0.3048,
      'Inch': 0.0254,
      'Centimeter': 0.01,
      'Millimeter': 0.001,
    },
    UnitCategory.weight: {
      'Kilogram': 1,
      'Gram': 0.001,
      'Pound': 0.453592,
      'Ounce': 0.0283495,
      'Ton': 1000,
    },
    UnitCategory.storage: {
      'Byte': 1,
      'Kilobyte': 1024,
      'Megabyte': 1048576,
      'Gigabyte': 1073741824,
      'Terabyte': 1099511627776,
    },
    UnitCategory.area: {
      'Square Meter': 1,
      'Square Kilometer': 1e6,
      'Square Mile': 2.58999e6,
      'Acre': 4046.86,
      'Hectare': 10000,
      'Square Foot': 0.092903,
    },
    UnitCategory.speed: {
      'm/s': 1,
      'km/h': 0.277778,
      'mph': 0.44704,
      'Knot': 0.514444,
    },
  };

  @override
  void initState() {
    super.initState();
    _initCategory();
  }

  void _initCategory() {
    final units = _units[_category]!;
    _fromUnit = units[0];
    _toUnit = units.length > 1 ? units[1] : units[0];
    _result = null;
    _inputCtrl.clear();
  }

  void _convert() {
    final input = double.tryParse(_inputCtrl.text);
    if (input == null) return;

    double result;
    if (_category == UnitCategory.temperature) {
      result = _convertTemp(input, _fromUnit, _toUnit);
    } else {
      final toBase = _toBase[_category]!;
      final inBase = input * (toBase[_fromUnit] ?? 1);
      result = inBase / (toBase[_toUnit] ?? 1);
    }
    setState(() => _result = result);
  }

  double _convertTemp(double val, String from, String to) {
    double celsius;
    switch (from) {
      case 'Fahrenheit':
        celsius = (val - 32) * 5 / 9;
        break;
      case 'Kelvin':
        celsius = val - 273.15;
        break;
      default:
        celsius = val;
    }
    switch (to) {
      case 'Fahrenheit':
        return celsius * 9 / 5 + 32;
      case 'Kelvin':
        return celsius + 273.15;
      default:
        return celsius;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final units = _units[_category]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Unit Converter',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: UnitCategory.values.map((cat) {
                  final isSelected = cat == _category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _category = cat;
                        _initCategory();
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? cs.primaryContainer
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? cs.primary : Colors.grey[300]!,
                          ),
                        ),
                        child: Text(
                          _catLabel(cat),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? cs.primary : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _inputCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Enter value',
                prefixIcon: Icon(Icons.numbers_rounded),
              ),
              onChanged: (_) => _convert(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _unitDropdown(
                    'From',
                    _fromUnit,
                    units,
                    (v) => setState(() {
                      _fromUnit = v!;
                      _convert();
                    }),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      final tmp = _fromUnit;
                      _fromUnit = _toUnit;
                      _toUnit = tmp;
                      _convert();
                    }),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.swap_horiz_rounded, color: cs.primary),
                    ),
                  ),
                ),
                Expanded(
                  child: _unitDropdown(
                    'To',
                    _toUnit,
                    units,
                    (v) => setState(() {
                      _toUnit = v!;
                      _convert();
                    }),
                  ),
                ),
              ],
            ),
            if (_result != null) ...[
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      '${_inputCtrl.text} $_fromUnit =',
                      style: TextStyle(
                        fontSize: 14,
                        color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_formatResult(_result!)} $_toUnit',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _unitDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        InputDecorator(
          decoration: const InputDecoration(),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            items: items
                .map(
                  (u) => DropdownMenuItem(
                    value: u,
                    child: Text(u, style: const TextStyle(fontSize: 13)),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  String _formatResult(double val) {
    if (val.abs() >= 1e9 || (val.abs() < 0.001 && val != 0)) {
      return val.toStringAsExponential(4);
    }
    if (val == val.roundToDouble()) return val.toInt().toString();
    return val
        .toStringAsFixed(6)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  String _catLabel(UnitCategory cat) {
    switch (cat) {
      case UnitCategory.length:
        return 'Length';
      case UnitCategory.weight:
        return 'Weight';
      case UnitCategory.temperature:
        return 'Temp';
      case UnitCategory.storage:
        return 'Storage';
      case UnitCategory.area:
        return 'Area';
      case UnitCategory.speed:
        return 'Speed';
    }
  }
}
