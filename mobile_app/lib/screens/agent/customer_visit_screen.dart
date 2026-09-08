import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/collection_provider.dart';
import '../../models/collection_model.dart';
import '../../services/payment_config_service.dart';
import '../../widgets/agent_qr_config_sheet.dart';
import '../../widgets/signature_pad_widget.dart';
import '../../widgets/doorstep_geotag_photo_widget.dart';
import '../../widgets/receipt_dialog.dart';
import '../../widgets/status_badge.dart';

class CustomerVisitScreen extends StatefulWidget {
  final CollectionModel collection;

  const CustomerVisitScreen({super.key, required this.collection});

  @override
  State<CustomerVisitScreen> createState() => _CustomerVisitScreenState();
}

class _CustomerVisitScreenState extends State<CustomerVisitScreen> {
  late TextEditingController _amountCtrl;
  final TextEditingController _remarksCtrl = TextEditingController();
  String _paymentMode = 'CASH'; // 'CASH' or 'UPI'
  String _visitStatus = 'collected'; // 'collected', 'not_available', 'house_locked', 'rescheduled'
  bool _photoCaptured = false;
  String? _photoBase64;
  bool _signatureCaptured = false;
  bool _isSubmitting = false;

  // Agent Custom Payment Scanner Configuration
  String _agentUpiVpa = 'bankflow@upi';
  String _agentUpiName = 'BankFlow Pigmy Deposit';
  String? _agentCustomQrImageBase64;
  String _agentQrMode = 'DYNAMIC';

  @override
  void initState() {
    super.initState();
    final defaultAmt = widget.collection.amount > 0 ? widget.collection.amount : 500.0;
    _amountCtrl = TextEditingController(text: defaultAmt.toInt().toString());
    _loadUpiConfig();
  }

  Future<void> _loadUpiConfig() async {
    final vpa = await PaymentConfigService.getUpiVpa();
    final name = await PaymentConfigService.getUpiName();
    final img = await PaymentConfigService.getCustomQrImageBase64();
    final mode = await PaymentConfigService.getQrMode();
    if (mounted) {
      setState(() {
        _agentUpiVpa = vpa;
        _agentUpiName = name;
        _agentCustomQrImageBase64 = img;
        _agentQrMode = mode;
      });
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    final amt = double.tryParse(_amountCtrl.text) ?? 0.0;
    if (_visitStatus == 'collected' && amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid collection amount.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final colProvider = Provider.of<CollectionProvider>(context, listen: false);

    try {
      final isPhotoAttached = _photoCaptured || (_photoBase64 != null && _photoBase64!.isNotEmpty);
      final res = await colProvider.recordDeposit(
        customerId: widget.collection.customerId,
        agentEmail: auth.email,
        status: _visitStatus,
        collectedAmount: _visitStatus == 'collected' ? amt : 0.0,
        paymentMode: _paymentMode,
        remarks: _remarksCtrl.text.trim(),
        latitude: widget.collection.latitude,
        longitude: widget.collection.longitude,
        photoCaptured: isPhotoAttached,
        photoUrl: _photoBase64,
        signatureCaptured: _signatureCaptured,
      );

      setState(() => _isSubmitting = false);

      if (res != null && mounted) {
        if (_visitStatus == 'collected') {
          final serverReceiptId = res['receiptId'] ?? 'RCP-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
          final serverTime = res['visitTime'] ?? '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}';
          // Open receipt dialog
          ReceiptDialog.show(context, {
            'receiptId': serverReceiptId,
            'customerName': widget.collection.name,
            'account': widget.collection.pigmyAccountNumber,
            'amount': amt,
            'paymentMode': _paymentMode,
            'balance': widget.collection.balance + amt,
            'agentName': auth.name,
            'date': DateTime.now().toString().split(' ')[0],
            'time': serverTime,
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Visit logged as $_visitStatus ✓'),
              backgroundColor: const Color(0xFF16A34A),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cust = widget.collection;
    final upiUrl = 'upi://pay?pa=pcmsbank@upi&pn=PCMS+Bank&am=${_amountCtrl.text}&tn=Deposit+${cust.pigmyAccountNumber}';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Doorstep Visit Logger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        backgroundColor: const Color(0xFF55356E),
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Customer Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFFEFF6FF),
                    child: Text(
                      cust.name.isNotEmpty ? cust.name[0].toUpperCase() : 'C',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                cust.name,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            StatusBadge(status: cust.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('A/C: ${cust.pigmyAccountNumber} · ${cust.phone}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        Text('Balance: ₹${cust.balance.toStringAsFixed(2)} · Due: ₹${cust.amount.toInt()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Visit Status Selector
            const Text('Visit Outcome', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusChoice('collected', '✓ Collected', const Color(0xFF16A34A)),
                  const SizedBox(width: 8),
                  _buildStatusChoice('not_available', '👤 Not Available', const Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  _buildStatusChoice('house_locked', '🔒 House Locked', const Color(0xFFDC2626)),
                  const SizedBox(width: 8),
                  _buildStatusChoice('rescheduled', '📅 Rescheduled', const Color(0xFF7C3AED)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_visitStatus == 'collected') ...[
              // Amount Collection Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Amount Collected (₹)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A)),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.currency_rupee, color: Color(0xFF2563EB)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 10),
                    // Quick Preset Chips
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildPresetChip(100),
                        _buildPresetChip(200),
                        _buildPresetChip(500),
                        _buildPresetChip(1000),
                        _buildPresetChip(cust.amount.toInt(), label: 'Full Due (₹${cust.amount.toInt()})'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Payment Mode Toggle
                    const Text('Payment Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _paymentMode = 'CASH'),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _paymentMode == 'CASH' ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _paymentMode == 'CASH' ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0), width: 1.5),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.money_rounded, color: _paymentMode == 'CASH' ? const Color(0xFF2563EB) : const Color(0xFF64748B), size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Cash Collection',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: _paymentMode == 'CASH' ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _paymentMode = 'UPI'),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _paymentMode == 'UPI' ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _paymentMode == 'UPI' ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0), width: 1.5),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.qr_code_rounded, color: _paymentMode == 'UPI' ? const Color(0xFF2563EB) : const Color(0xFF64748B), size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'UPI / Dynamic QR',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: _paymentMode == 'UPI' ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_paymentMode == 'UPI') ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
                          boxShadow: const [
                            BoxShadow(color: Color(0x142563EB), blurRadius: 10, offset: Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _agentQrMode == 'IMAGE' && _agentCustomQrImageBase64 != null
                                          ? '📸 Agent PhonePe / GPay QR'
                                          : '⚡ Dynamic Payment QR',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                    ),
                                    Text(
                                      _agentUpiVpa,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                TextButton.icon(
                                  onPressed: () => AgentQrConfigSheet.show(context, onSaved: _loadUpiConfig),
                                  icon: const Icon(Icons.tune_rounded, size: 14, color: Color(0xFF2563EB)),
                                  label: const Text('Set QR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                                  style: TextButton.styleFrom(
                                    backgroundColor: const Color(0xFFEFF6FF),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_agentQrMode == 'IMAGE' && _agentCustomQrImageBase64 != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  base64Decode(_agentCustomQrImageBase64!),
                                  height: 180,
                                  width: 180,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '📱 Scan with PhonePe / GPay / Paytm / BHIM',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                ),
                              ),
                            ] else ...[
                              Center(
                                child: QrImageView(
                                  data: 'upi://pay?pa=$_agentUpiVpa&pn=${Uri.encodeComponent(_agentUpiName)}&am=${_amountCtrl.text}&tn=Deposit+${cust.pigmyAccountNumber}',
                                  version: QrVersions.auto,
                                  size: 150.0,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('Amount: ₹${_amountCtrl.text} · VPA: $_agentUpiVpa', style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Digital Signature Pad
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Customer Digital Signature', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        if (_signatureCaptured)
                          const StatusBadge(status: 'Verified', label: 'Captured ✓')
                      ],
                    ),
                    const SizedBox(height: 10),
                    SignaturePadWidget(
                      onSigned: (points) {
                        setState(() {
                          _signatureCaptured = points.isNotEmpty;
                        });
                      },
                      onClear: () {
                        setState(() {
                          _signatureCaptured = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Doorstep Geotagged Photo Capture
              DoorstepGeotagPhotoWidget(
                customerName: widget.collection.name,
                customerId: widget.collection.customerId,
                area: widget.collection.area,
                address: widget.collection.address,
                latitude: widget.collection.latitude,
                longitude: widget.collection.longitude,
                agentName: auth.name,
                initialPhotoBase64: _photoBase64,
                onPhotoChanged: (base64) {
                  setState(() {
                    _photoBase64 = base64;
                    _photoCaptured = (base64 != null && base64.isNotEmpty);
                  });
                },
              ),
              const SizedBox(height: 16),
            ],

            // Remarks / Notes
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Agent Field Remarks (Optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _remarksCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'e.g. Shop open, deposited on time / Customer requested passbook update…',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _visitStatus == 'collected' ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        _visitStatus == 'collected' ? '✓ Record Deposit & Generate Receipt' : 'Submit Visit Status',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChoice(String statusKey, String label, Color color) {
    final isSelected = _visitStatus == statusKey;
    return InkWell(
      onTap: () => setState(() => _visitStatus = statusKey),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? color : const Color(0xFFCBD5E1), width: isSelected ? 1.5 : 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? color : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(int amt, {String? label}) {
    return ActionChip(
      label: Text(label ?? '₹$amt', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
      backgroundColor: const Color(0xFFEFF6FF),
      side: const BorderSide(color: Color(0xFFBFDBFE)),
      onPressed: () {
        setState(() {
          _amountCtrl.text = amt.toString();
        });
      },
    );
  }
}
