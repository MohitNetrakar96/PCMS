import 'package:flutter/material.dart';
import '../../models/customer_model.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';
import '../customer_detail_screen.dart';
import '../../utils/map_utils.dart';

class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  State<CustomerManagementScreen> createState() => _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  List<CustomerModel> _customers = [];
  List<UserModel> _agents = [];
  bool _loading = true;
  String _searchQuery = '';
  String _kycFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _loadAgents();
  }

  Future<void> _loadCustomers() async {
    try {
      final list = await ApiService.getCustomers(requesterRole: 'Administrator');
      setState(() {
        _customers = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadAgents() async {
    try {
      final list = await ApiService.getCollectionAgents();
      setState(() => _agents = list);
    } catch (_) {}
  }

  void _showAddCustomerDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String selectedArea = 'Sector 12';
    String selectedRoute = 'Route A';
    final balanceCtrl = TextEditingController(text: '5000');
    final targetCtrl = TextEditingController(text: '500');
    final addressCtrl = TextEditingController(text: 'BankFlow Sector 12 Field Branch, Hubli, Karnataka');
    final aadharCtrl = TextEditingController();
    final panCtrl = TextEditingController();
    String? selectedAgentEmail = 'agent@bankflow.com';

    UserModel? getMatchedAgent(String area, String route) {
      final exact = _agents.where((a) =>
          (a.area ?? '').toLowerCase() == area.toLowerCase() &&
          (a.route ?? '').toLowerCase() == route.toLowerCase()).toList();
      if (exact.isNotEmpty) return exact.first;

      final byArea = _agents.where((a) {
        final agArea = (a.area ?? '').toLowerCase();
        final searchArea = area.toLowerCase();
        return agArea.isNotEmpty && (agArea.contains(searchArea) || searchArea.contains(agArea));
      }).toList();
      if (byArea.isNotEmpty) return byArea.first;

      return _agents.isNotEmpty ? _agents.first : null;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (sheetCtx, setModalState) {
          final matchedAgent = getMatchedAgent(selectedArea, selectedRoute);
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Onboard New Customer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(sheetCtx)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Customer Full Name *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone Number *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email (Optional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: ['Sector 12', 'Station Road', 'Market Yard', 'Gokul Road'].contains(selectedArea) ? selectedArea : 'Sector 12',
                          decoration: const InputDecoration(labelText: 'Area / Sector', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'Sector 12', child: Text('Sector 12')),
                            DropdownMenuItem(value: 'Station Road', child: Text('Station Road')),
                            DropdownMenuItem(value: 'Market Yard', child: Text('Market Yard')),
                            DropdownMenuItem(value: 'Gokul Road', child: Text('Gokul Road')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() {
                                selectedArea = val;
                                if (val == 'Sector 12') selectedRoute = 'Route A';
                                if (val == 'Station Road') selectedRoute = 'Route B';
                                if (val == 'Market Yard') selectedRoute = 'Route C';
                                if (val == 'Gokul Road') selectedRoute = 'Route D';
                                final m = getMatchedAgent(selectedArea, selectedRoute);
                                selectedAgentEmail = m?.email;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: ['Route A', 'Route B', 'Route C', 'Route D'].contains(selectedRoute) ? selectedRoute : 'Route A',
                          decoration: const InputDecoration(labelText: 'Route Code', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'Route A', child: Text('Route A')),
                            DropdownMenuItem(value: 'Route B', child: Text('Route B')),
                            DropdownMenuItem(value: 'Route C', child: Text('Route C')),
                            DropdownMenuItem(value: 'Route D', child: Text('Route D')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() {
                                selectedRoute = val;
                                final m = getMatchedAgent(selectedArea, selectedRoute);
                                selectedAgentEmail = m?.email;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Auto-Matched Collection Agent Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9E2F3).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF55356E).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.flash_on_rounded, color: Color(0xFF55356E), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Matched Collection Agent (By Area/Route)',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF55356E)),
                              ),
                              Text(
                                '${matchedAgent?.name ?? "Rahul Verma"} (${matchedAgent?.email ?? "agent@bankflow.com"})',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF191308)),
                              ),
                              Text(
                                'Field Office: ${matchedAgent?.address ?? "Hubli Field Hub"}',
                                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Matched', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: balanceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Opening Balance (₹)', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: targetCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Daily Target (₹)', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(labelText: 'Physical Address (Auto-Geocoded GPS)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: aadharCtrl,
                          decoration: const InputDecoration(labelText: 'Aadhaar (12-digit)', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: panCtrl,
                          decoration: const InputDecoration(labelText: 'PAN Number', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and Phone are required.')));
                        return;
                      }
                      try {
                        final chosenAgent = selectedAgentEmail ?? matchedAgent?.email ?? 'agent@bankflow.com';
                        await ApiService.createCustomer({
                          'name': nameCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim(),
                          'email': emailCtrl.text.trim(),
                          'area': selectedArea.trim(),
                          'route': selectedRoute.trim(),
                          'opening_balance': double.tryParse(balanceCtrl.text) ?? 5000,
                          'daily_target': double.tryParse(targetCtrl.text) ?? 500,
                          'address': addressCtrl.text.trim(),
                          'aadhar_number': aadharCtrl.text.trim(),
                          'pan_number': panCtrl.text.trim(),
                          'assigned_agent_email': chosenAgent,
                          'agent_email': chosenAgent,
                        });
                        Navigator.pop(sheetCtx);
                        _loadCustomers();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Customer assigned to ${matchedAgent?.name ?? "Collection Agent"} ($chosenAgent)!'),
                            backgroundColor: const Color(0xFF16A34A),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Enroll Customer & Assign Agent', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleDeleteCustomer(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Customer $name?'),
        content: const Text('This will permanently remove the customer record, passbook accounts, and collection schedule.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.deleteCustomer(id);
      _loadCustomers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _customers.where((c) {
      final q = _searchQuery.toLowerCase();
      final matchesQuery = c.name.toLowerCase().contains(q) || c.phone.contains(q) || c.area.toLowerCase().contains(q);
      if (!matchesQuery) return false;

      if (_kycFilter == 'verified') return c.kycStatus.toLowerCase() == 'verified';
      if (_kycFilter == 'pending') return c.kycStatus.toLowerCase() != 'verified';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Customer Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCustomerDialog,
        backgroundColor: const Color(0xFF16A34A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Customer'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search customer name, phone, area…',
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
                    _buildPill('All (${_customers.length})', 'all'),
                    const SizedBox(width: 8),
                    _buildPill('KYC Verified (${_customers.where((c) => c.kycStatus.toLowerCase() == "verified").length})', 'verified'),
                    const SizedBox(width: 8),
                    _buildPill('KYC Pending (${_customers.where((c) => c.kycStatus.toLowerCase() != "verified").length})', 'pending'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(child: Text('No customers found.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, idx) {
                          final c = filtered[idx];
                          return AppCard(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => CustomerDetailScreen(customerId: c.id)),
                              );
                            },
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFFEFF6FF),
                                  child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : 'C', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                                          StatusBadge(status: c.kycStatus),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text('${c.phone} · ${c.area} · ${c.route}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                      if (c.assignedAgentEmail != null && c.assignedAgentEmail!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.person_pin_rounded, size: 12, color: Color(0xFF55356E)),
                                            const SizedBox(width: 3),
                                            Text('Agent: ${c.assignedAgentName ?? c.assignedAgentEmail}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF55356E))),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Text('Balance: ₹${c.openingBalance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.navigation_rounded, color: Color(0xFF2563EB), size: 20),
                                  tooltip: 'Open Google Maps Navigation',
                                  onPressed: () {
                                    MapUtils.openMap(
                                      context: context,
                                      latitude: c.latitude,
                                      longitude: c.longitude,
                                      title: c.name,
                                      address: c.address.isNotEmpty ? c.address : '${c.area}, ${c.route}',
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
                                  onPressed: () => _handleDeleteCustomer(c.id, c.name),
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

  Widget _buildPill(String label, String key) {
    final active = _kycFilter == key;
    return InkWell(
      onTap: () => setState(() => _kycFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
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
}
