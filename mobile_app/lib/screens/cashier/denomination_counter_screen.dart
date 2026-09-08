import 'package:flutter/material.dart';
import '../../widgets/app_card.dart';

class DenominationCounterScreen extends StatefulWidget {
  const DenominationCounterScreen({super.key});

  @override
  State<DenominationCounterScreen> createState() => _DenominationCounterScreenState();
}

class _DenominationCounterScreenState extends State<DenominationCounterScreen> {
  final Map<int, TextEditingController> _controllers = {};
  final List<int> _denominations = [2000, 500, 200, 100, 50, 20, 10, 5, 2, 1];
  final _expectedCtrl = TextEditingController(text: '15000');

  @override
  void initState() {
    super.initState();
    for (var d in _denominations) {
      _controllers[d] = TextEditingController(text: '');
    }
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    _expectedCtrl.dispose();
    super.dispose();
  }

  double get _totalCalculated {
    double sum = 0;
    for (var d in _denominations) {
      final count = int.tryParse(_controllers[d]?.text ?? '0') ?? 0;
      sum += (d * count);
    }
    return sum;
  }

  int get _totalNotes {
    int sum = 0;
    for (var d in _denominations) {
      final count = int.tryParse(_controllers[d]?.text ?? '0') ?? 0;
      sum += count;
    }
    return sum;
  }

  void _clearAll() {
    for (var c in _controllers.values) {
      c.clear();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final total = _totalCalculated;
    final expected = double.tryParse(_expectedCtrl.text) ?? 0.0;
    final diff = total - expected;
    final isMatch = (diff.abs() < 0.01);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Cash Denomination Calculator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
            onPressed: _clearAll,
            tooltip: 'Clear All',
          )
        ],
      ),
      body: Column(
        children: [
          // Total Top Banner
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('EXPECTED TARGET', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 36,
                            child: TextField(
                              controller: _expectedCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                prefixText: '₹ ',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('TOTAL COUNTED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          Text(
                            '₹${total.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: isMatch ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Pieces: $_totalNotes', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                    Text(
                      isMatch ? '✓ Exact Match' : diff > 0 ? 'Excess: +₹${diff.toStringAsFixed(0)}' : 'Shortage: -₹${(-diff).toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isMatch ? const Color(0xFF16A34A) : diff > 0 ? const Color(0xFF2563EB) : const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),

          // Denomination items
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _denominations.length,
              separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
              itemBuilder: (ctx, idx) {
                final denom = _denominations[idx];
                final count = int.tryParse(_controllers[denom]?.text ?? '0') ?? 0;
                final subtotal = denom * count;
                final isCoin = denom <= 5;

                return AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isCoin ? const Color(0xFFFEF3C7) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '₹$denom',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isCoin ? const Color(0xFFB45309) : const Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('×', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: TextField(
                            controller: _controllers[denom],
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '0 pieces',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      SizedBox(
                        width: 80,
                        child: Text(
                          '= ₹$subtotal',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
