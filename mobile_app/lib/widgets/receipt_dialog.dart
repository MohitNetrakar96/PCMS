import 'package:flutter/material.dart';

class ReceiptDialog extends StatelessWidget {
  final Map<String, dynamic> receipt;

  const ReceiptDialog({super.key, required this.receipt});

  static void show(BuildContext context, Map<String, dynamic> receipt) {
    showDialog(
      context: context,
      builder: (ctx) => ReceiptDialog(receipt: receipt),
    );
  }

  @override
  Widget build(BuildContext context) {
    final receiptId = receipt['receiptId'] ?? receipt['receipt_id'] ?? 'RCP-2026-0001';
    final customerName = receipt['customerName'] ?? receipt['name'] ?? 'Customer';
    final accountNumber = receipt['account'] ?? receipt['account_number'] ?? 'PCMS-00120';
    final date = receipt['date'] ?? receipt['collection_date'] ?? DateTime.now().toString().split(' ')[0];
    final time = receipt['time'] ?? receipt['visit_time'] ?? '10:30 AM';
    final amount = (receipt['amount'] as num?)?.toDouble() ?? (receipt['collected_amount'] as num?)?.toDouble() ?? 500.0;
    final paymentMode = (receipt['paymentMode'] ?? receipt['payment_mode'] ?? 'CASH').toString().toUpperCase();
    final balance = (receipt['balance'] as num?)?.toDouble() ?? (receipt['opening_balance'] as num?)?.toDouble() ?? 0.0;
    final agentName = receipt['agentName'] ?? 'Field Agent';

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Checkmark
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFBBF7D0), width: 2),
                ),
                child: const Icon(Icons.check_rounded, color: Color(0xFF16A34A), size: 36),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Collection Receipt',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
            ),
            const Center(
              child: Text(
                'BankFlow Pigmy Daily Deposit',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 16),

            // Amount Banner
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                children: [
                  const Text('AMOUNT RECEIVED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8), letterSpacing: 1.1)),
                  const SizedBox(height: 4),
                  Text(
                    '₹${amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Details List
            _buildRow('Receipt ID', receiptId),
            _buildRow('Customer Name', customerName),
            _buildRow('Pigmy Account', accountNumber),
            _buildRow('Payment Mode', paymentMode),
            _buildRow('Date & Time', '$date at $time'),
            _buildRow('Updated Balance', '₹${balance.toStringAsFixed(2)}'),
            _buildRow('Agent In-Charge', agentName),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFFE2E8F0)),
            const SizedBox(height: 8),

            const Center(
              child: Text(
                'Instant SMS & Ledger Synchronized ✓',
                style: TextStyle(fontSize: 10, color: Color(0xFF16A34A), fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Close'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Receipt downloaded / ready to print'),
                          backgroundColor: Color(0xFF2563EB),
                        ),
                      );
                    },
                    icon: const Icon(Icons.share_rounded, size: 16),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }
}
