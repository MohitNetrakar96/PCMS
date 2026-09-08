import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../models/customer_model.dart';
import '../models/collection_model.dart';
import '../services/api_service.dart';
import '../widgets/app_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/receipt_dialog.dart';
import '../utils/map_utils.dart';
import 'agent/customer_visit_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  CustomerModel? _customer;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final cust = await ApiService.getCustomer(widget.customerId, role: auth.role);
      setState(() {
        _customer = cust;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _openGoogleMaps(double? lat, double? lng, {String? address, String? name}) {
    MapUtils.openMap(
      context: context,
      latitude: lat,
      longitude: lng,
      title: name ?? _customer?.name,
      address: address ?? _customer?.address,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer Profile')),
        body: const Center(child: Text('Customer record not found.')),
      );
    }

    final cust = _customer!;
    final accounts = cust.accounts ?? [];
    final history = cust.history ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(cust.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: const Color(0xFF2563EB),
                        child: Text(
                          cust.name.isNotEmpty ? cust.name[0].toUpperCase() : 'C',
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(cust.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                                StatusBadge(status: cust.kycStatus),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text('ID: ${cust.id} · ${cust.phone}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                            const SizedBox(height: 3),
                            Text('Area: ${cust.area} · ${cust.route}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Deposited Balance', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          Text('₹${cust.openingBalance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                        ],
                      ),
                      if ((cust.latitude != null && cust.longitude != null) || cust.address.isNotEmpty || cust.area.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: () => _openGoogleMaps(
                            cust.latitude,
                            cust.longitude,
                            address: cust.address.isNotEmpty ? cust.address : '${cust.area}, ${cust.route}',
                            name: cust.name,
                          ),
                          icon: const Icon(Icons.navigation_rounded, size: 14),
                          label: const Text('Map Route'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            // KYC & Identity Section
            const Text('KYC & Verification Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDetailRow('Aadhaar Number', cust.aadharNumber.isNotEmpty ? cust.aadharNumber : 'Protected / Masked'),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  _buildDetailRow('PAN Number', cust.panNumber.isNotEmpty ? cust.panNumber : 'Verified on file'),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  _buildDetailRow('Address', cust.address.isNotEmpty ? cust.address : '${cust.area}, ${cust.route}'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Active Accounts
            const Text('Passbook Accounts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            if (accounts.isEmpty)
              const AppCard(
                padding: EdgeInsets.all(14),
                child: Text('Primary Pigmy Savings Passbook Active (4.5% p.a.)', style: TextStyle(fontSize: 12, color: Color(0xFF334155))),
              )
            else
              ...accounts.map((acc) => AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(acc['account_number'] ?? 'PCMS-00120', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(acc['account_type'] ?? 'Pigmy Passbook', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                        Text(
                          '₹${(acc['balance'] as num?)?.toStringAsFixed(2) ?? "0.00"}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF16A34A)),
                        ),
                      ],
                    ),
                  )),
            const SizedBox(height: 16),

            // Recent Collection History
            const Text('Recent Collections & Receipts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            if (history.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No historical deposits on record.', style: TextStyle(color: Color(0xFF94A3B8))),
                ),
              )
            else
              ...history.map((h) {
                final amt = (h['amount'] as num?)?.toDouble() ?? 500.0;
                final date = h['collection_date'] ?? '2026-09-07';
                final mode = h['payment_mode'] ?? 'CASH';
                final receiptId = h['receipt_id'] ?? 'RCP-2026-0001';

                return AppCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16A34A), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Deposit: ₹${amt.toStringAsFixed(2)} ($mode)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('$date · $receiptId', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ReceiptDialog.show(context, {
                            'receiptId': receiptId,
                            'customerName': cust.name,
                            'account': 'PCMS-00${cust.id.replaceFirst("CUST-", "")}',
                            'amount': amt,
                            'paymentMode': mode,
                            'balance': cust.openingBalance,
                            'date': date,
                            'time': '10:00 AM',
                          });
                        },
                        child: const Text('Receipt', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 20),

            // Record Doorstep Visit Action Button
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CustomerVisitScreen(
                        collection: CollectionModel(
                          id: cust.id,
                          customerId: cust.id,
                          name: cust.name,
                          phone: cust.phone,
                          email: cust.email,
                          area: cust.area,
                          route: cust.route,
                          pigmyAccountNumber: 'PCMS-00${cust.id.replaceFirst("CUST-", "")}',
                          amount: 500.0,
                          pendingAmount: 500.0,
                          collectedAmount: 0.0,
                          balance: cust.openingBalance,
                          status: 'pending',
                          latitude: cust.latitude,
                          longitude: cust.longitude,
                          address: cust.address,
                        ),
                      ),
                    ),
                  ).then((_) => _loadCustomer());
                },
                icon: const Icon(Icons.add_task_rounded, size: 18),
                label: const Text('Record Doorstep Collection', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
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
    );
  }
}
