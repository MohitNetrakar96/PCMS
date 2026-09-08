import 'package:flutter/material.dart';

class DenominationDialog extends StatefulWidget {
  final double expectedAmount;
  final Function(double total, Map<int, int> counts) onConfirm;

  const DenominationDialog({
    super.key,
    required this.expectedAmount,
    required this.onConfirm,
  });

  static void show(BuildContext context, double expectedAmount, Function(double total, Map<int, int> counts) onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => DenominationDialog(expectedAmount: expectedAmount, onConfirm: onConfirm),
    );
  }

  @override
  State<DenominationDialog> createState() => _DenominationDialogState();
}

class _DenominationDialogState extends State<DenominationDialog> {
  final Map<int, TextEditingController> _controllers = {};
  final List<int> _denominations = [2000, 500, 200, 100, 50, 20, 10, 5, 2, 1];

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

  Map<int, int> get _counts {
    final map = <int, int>{};
    for (var d in _denominations) {
      map[d] = int.tryParse(_controllers[d]?.text ?? '0') ?? 0;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final total = _totalCalculated;
    final diff = total - widget.expectedAmount;
    final isMatched = (diff.abs() < 0.01);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 620),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cash Denomination Counter',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const Text(
              'Enter piece counts for physical cash verification',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),

            // Summary Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMatched ? const Color(0xFFDCFCE7) : const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isMatched ? const Color(0xFFBBF7D0) : const Color(0xFFFED7AA)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Counted', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                      Text(
                        '₹${total.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isMatched ? const Color(0xFF16A34A) : const Color(0xFFEA580C)),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Target: ₹${widget.expectedAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      Text(
                        isMatched ? '✓ Exact Match' : diff > 0 ? 'Excess: +₹${diff.toStringAsFixed(0)}' : 'Shortage: -₹${(-diff).toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isMatched ? const Color(0xFF16A34A) : diff > 0 ? const Color(0xFF2563EB) : const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // List of Denominations
            Expanded(
              child: ListView.separated(
                itemCount: _denominations.length,
                separatorBuilder: (ctx, idx) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (ctx, idx) {
                  final denom = _denominations[idx];
                  final isCoin = denom <= 5;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Container(
                          width: 65,
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                          decoration: BoxDecoration(
                            color: isCoin ? const Color(0xFFFEF3C7) : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '₹$denom',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isCoin ? const Color(0xFFB45309) : const Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('×', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: TextField(
                              controller: _controllers[denom],
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '0',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 75,
                          child: Text(
                            '= ₹${((int.tryParse(_controllers[denom]?.text ?? '0') ?? 0) * denom).toStringAsFixed(0)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF334155)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Confirm Button
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onConfirm(total, _counts);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isMatched ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Confirm Verification (₹${total.toStringAsFixed(0)})',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
