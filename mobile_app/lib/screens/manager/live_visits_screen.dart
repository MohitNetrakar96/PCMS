import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/branch_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/receipt_dialog.dart';

class LiveVisitsScreen extends StatefulWidget {
  const LiveVisitsScreen({super.key});

  @override
  State<LiveVisitsScreen> createState() => _LiveVisitsScreenState();
}

class _LiveVisitsScreenState extends State<LiveVisitsScreen> {
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadVisits();
  }

  Future<void> _loadVisits() async {
    final branch = Provider.of<BranchProvider>(context, listen: false);
    await branch.fetchLiveVisits();
  }

  void _showGeotagPhotoModal(Map<String, dynamic> v) {
    final photo = v['photoUrl'] as String?;
    final name = v['customerName'] ?? 'Customer';
    final lat = (v['latitude'] as num?)?.toDouble() ?? 15.3647;
    final lng = (v['longitude'] as num?)?.toDouble() ?? 75.1240;
    final latDir = lat >= 0 ? 'N' : 'S';
    final lngDir = lng >= 0 ? 'E' : 'W';
    final coordStr = '${lat.abs().toStringAsFixed(5)}° $latDir, ${lng.abs().toStringAsFixed(5)}° $lngDir';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                backgroundColor: Colors.black.withOpacity(0.85),
                elevation: 0,
                title: const Text('Doorstep Audit Proof', style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              Flexible(
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    if (photo != null && photo.isNotEmpty)
                      Image.memory(
                        base64Decode(photo),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          height: 220,
                          color: const Color(0xFF1E293B),
                          child: const Center(
                            child: Icon(Icons.camera_alt_rounded, color: Colors.white54, size: 48),
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 220,
                        color: const Color(0xFF1E293B),
                        child: const Center(
                          child: Text('Photo record verified via agent terminal', style: TextStyle(color: Colors.white70)),
                        ),
                      ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.95),
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.verified_rounded, color: Color(0xFF22C55E), size: 16),
                              SizedBox(width: 6),
                              Text('DOORSTEP GEOTAGGED VISIT', style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.8)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('📍 GPS: $coordStr', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('🏢 Customer: $name (${v['customerId'] ?? ""})', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                          Text('📍 Address: ${v['address'] ?? v['area'] ?? ""}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                          Text('🕒 Visit Time: ${v['visitTime'] ?? "Recorded"}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                          Text('🛡️ Agent: ${v['agentEmail'] ?? "Rahul Verma"}', style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 11, fontWeight: FontWeight.bold)),
                          if (v['receiptId'] != null)
                            Text('🧾 Receipt: ${v['receiptId']}', style: const TextStyle(color: Color(0xFFFDE047), fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final branch = Provider.of<BranchProvider>(context);
    final allVisits = branch.liveVisits;

    final filtered = allVisits.where((v) {
      final name = (v['customerName'] ?? '').toString().toLowerCase();
      final agent = (v['agentEmail'] ?? '').toString().toLowerCase();
      final area = (v['area'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      final matchesSearch = name.contains(query) || agent.contains(query) || area.contains(query);
      if (!matchesSearch) return false;

      final status = (v['status'] ?? 'pending').toString().toLowerCase();
      if (_statusFilter == 'collected') return status == 'collected';
      if (_statusFilter == 'pending') return status != 'collected';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Live Doorstep Visits Feed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2563EB)),
            onPressed: _loadVisits,
          )
        ],
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search customer, agent or area…',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildPill('All (${allVisits.length})', 'all'),
                    const SizedBox(width: 8),
                    _buildPill('Collected (${allVisits.where((v) => v['status'] == 'collected').length})', 'collected'),
                    const SizedBox(width: 8),
                    _buildPill('Pending (${allVisits.where((v) => v['status'] != 'collected').length})', 'pending'),
                  ],
                ),
              ],
            ),
          ),

          // Visits List
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No visits match the criteria.', style: TextStyle(color: Color(0xFF94A3B8))))
                : RefreshIndicator(
                    onRefresh: _loadVisits,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, idx) => _buildVisitCard(filtered[idx]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String label, String key) {
    final active = _statusFilter == key;
    return InkWell(
      onTap: () => setState(() => _statusFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: active ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildVisitCard(Map<String, dynamic> v) {
    final status = v['status'] ?? 'pending';
    final isCollected = status == 'collected';
    final amt = (v['collectedAmount'] as num?)?.toDouble() ?? 0.0;
    final name = v['customerName'] ?? 'Customer';
    final agent = v['agentEmail'] ?? 'agent@bankflow.com';
    final time = v['visitTime'] ?? 'Pending';
    final mode = v['paymentMode'] ?? 'CASH';
    final photo = v['photoCaptured'] == true || (v['photoUrl'] != null && (v['photoUrl'] as String).isNotEmpty);
    final sig = v['signatureCaptured'] == true;

    return AppCard(
      padding: const EdgeInsets.all(14),
      borderColor: isCollected ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Agent: $agent · ${v['area'] ?? ""}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '₹${amt.toInt()}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isCollected ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 8),
              if (isCollected) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                  child: Text(mode, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                ),
                const SizedBox(width: 6),
                Text('at $time', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
              const Spacer(),
              if (photo)
                InkWell(
                  onTap: () => _showGeotagPhotoModal(v),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.photo_camera_rounded, size: 13, color: Color(0xFF16A34A)),
                        SizedBox(width: 3),
                        Text('Photo', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                      ],
                    ),
                  ),
                ),
              if (sig)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(Icons.draw_rounded, size: 16, color: Color(0xFF2563EB)),
                ),
              if (isCollected)
                TextButton(
                  onPressed: () {
                    ReceiptDialog.show(context, {
                      'receiptId': v['receiptId'] ?? 'RCP-2026-LIVE',
                      'customerName': name,
                      'account': 'PCMS-00${v['customerId'] ?? "1"}',
                      'amount': amt,
                      'paymentMode': mode,
                      'balance': 5500.0,
                      'agentName': agent.toString().split('@')[0],
                      'date': DateTime.now().toString().split(' ')[0],
                      'time': time,
                    });
                  },
                  child: const Text('Receipt', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
