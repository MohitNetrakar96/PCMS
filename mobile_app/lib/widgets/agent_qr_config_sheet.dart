import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/payment_config_service.dart';

class AgentQrConfigSheet extends StatefulWidget {
  final VoidCallback onSaved;

  const AgentQrConfigSheet({super.key, required this.onSaved});

  static Future<void> show(BuildContext context, {required VoidCallback onSaved}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AgentQrConfigSheet(onSaved: onSaved),
    );
  }

  @override
  State<AgentQrConfigSheet> createState() => _AgentQrConfigSheetState();
}

class _AgentQrConfigSheetState extends State<AgentQrConfigSheet> {
  final TextEditingController _vpaCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  String? _qrImageBase64;
  String _qrMode = 'DYNAMIC';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _vpaCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final vpa = await PaymentConfigService.getUpiVpa();
    final name = await PaymentConfigService.getUpiName();
    final img = await PaymentConfigService.getCustomQrImageBase64();
    final mode = await PaymentConfigService.getQrMode();

    if (mounted) {
      setState(() {
        _vpaCtrl.text = vpa;
        _nameCtrl.text = name;
        _qrImageBase64 = img;
        _qrMode = mode;
        _loading = false;
      });
    }
  }

  Future<void> _pickGallery() async {
    final img = await PaymentConfigService.pickQrImageFromGallery();
    if (img != null && mounted) {
      setState(() {
        _qrImageBase64 = img;
        _qrMode = 'IMAGE';
      });
    }
  }

  Future<void> _pickCamera() async {
    final img = await PaymentConfigService.captureQrImageFromCamera();
    if (img != null && mounted) {
      setState(() {
        _qrImageBase64 = img;
        _qrMode = 'IMAGE';
      });
    }
  }

  Future<void> _save() async {
    await PaymentConfigService.saveConfig(
      upiVpa: _vpaCtrl.text.trim().isNotEmpty ? _vpaCtrl.text.trim() : 'bankflow@upi',
      upiName: _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : 'BankFlow Pigmy Deposit',
      qrImageBase64: _qrImageBase64 ?? '',
      qrMode: _qrMode,
    );
    widget.onSaved();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Agent Payment & Scanner Configuration Saved!'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: 200,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(child: CircularProgressIndicator(color: Color(0xFF55356E))),
      );
    }

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF55356E), size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Payment QR / Scanner Setup',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF191308)),
                    ),
                  ],
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Add your PhonePe / GPay / Paytm QR standee photo or custom UPI ID so depositors can scan & pay directly to your account.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),

            // Mode Selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _qrMode = 'DYNAMIC'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _qrMode == 'DYNAMIC' ? const Color(0xFF55356E) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '⚡ Dynamic Amount QR',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _qrMode == 'DYNAMIC' ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _qrMode = 'IMAGE'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _qrMode == 'IMAGE' ? const Color(0xFF55356E) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '📸 PhonePe / GPay Photo',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _qrMode == 'IMAGE' ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // QR Image Picker Section
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PhonePe / Google Pay / Paytm QR Standee', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF191308))),
                  const SizedBox(height: 4),
                  const Text('Upload your physical standee photo or scanner image', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  const SizedBox(height: 12),
                  if (_qrImageBase64 != null && _qrImageBase64!.isNotEmpty) ...[
                    Center(
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              base64Decode(_qrImageBase64!),
                              height: 160,
                              width: 160,
                              fit: BoxFit.cover,
                            ),
                          ),
                          IconButton(
                            icon: const CircleAvatar(
                              backgroundColor: Colors.redAccent,
                              radius: 12,
                              child: Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                            onPressed: () => setState(() => _qrImageBase64 = null),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickGallery,
                          icon: const Icon(Icons.photo_library_rounded, size: 16),
                          label: const Text('From Gallery', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF55356E),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickCamera,
                          icon: const Icon(Icons.camera_alt_rounded, size: 16),
                          label: const Text('Take Photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2563EB),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // UPI VPA / ID Input
            TextField(
              controller: _vpaCtrl,
              decoration: const InputDecoration(
                labelText: 'Agent UPI ID / VPA *',
                hintText: 'e.g. 9880011223@ybl or mohit@okhdfcbank',
                prefixIcon: Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF55356E)),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            // Receiver Name Input
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Payee / Account Name',
                hintText: 'e.g. BankFlow Pigmy Collection',
                prefixIcon: Icon(Icons.badge_rounded, color: Color(0xFF55356E)),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Save Payment & Scanner Configuration', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF55356E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
