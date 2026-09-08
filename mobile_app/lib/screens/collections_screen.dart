import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/collection_provider.dart';
import '../models/collection_model.dart';
import 'agent/customer_visit_screen.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<CollectionProvider>();
    List<CollectionModel> list = provider.collections;

    if (_selectedFilter == 'pending') {
      list = provider.pendingCustomers;
    } else if (_selectedFilter == 'completed') {
      list = provider.collections.where((c) => c.status == 'collected').toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FA),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                _buildFilterChip('All (' + provider.collections.length.toString() + ')', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Pending (' + provider.pendingCustomers.length.toString() + ')', 'pending'),
                const SizedBox(width: 8),
                _buildFilterChip('Completed (' + provider.completedCount.toString() + ')', 'completed'),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE9E2F3)),

          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF55356E)))
                : list.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.menu_book, size: 48, color: Color(0xFF55356E)),
                            SizedBox(height: 8),
                            Text('No records found in this category.', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => provider.fetchTodayCollections(auth.email),
                        color: const Color(0xFF55356E),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final item = list[index];
                            final isDone = item.status.toLowerCase() == 'completed' || item.status.toLowerCase() == 'collected';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDone ? const Color(0xFF76A787) : const Color(0xFFE9E2F3),
                                  width: 1.2,
                                ),
                                boxShadow: const [
                                  BoxShadow(color: Color(0x0855356E), blurRadius: 8, offset: Offset(0, 2)),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: isDone ? const Color(0xFF76A787).withOpacity(0.15) : const Color(0xFFE9E2F3),
                                  child: Icon(
                                    isDone ? Icons.check_circle : Icons.person,
                                    color: isDone ? const Color(0xFF76A787) : const Color(0xFF55356E),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF191308)),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '₹' + item.amount.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                        color: isDone ? const Color(0xFF76A787) : const Color(0xFF55356E),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, size: 12, color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Text(item.area + ' • Route: ' + item.route, style: const TextStyle(fontSize: 11)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isDone ? const Color(0xFF76A787).withOpacity(0.15) : const Color(0xFFD6F5FF),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isDone ? 'COLLECTED' : 'PENDING VISIT',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: isDone ? const Color(0xFF191308) : const Color(0xFF55356E),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF55356E)),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => CustomerVisitScreen(collection: item)),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF55356E) : const Color(0xFFE9E2F3).withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF55356E) : const Color(0xFFE9E2F3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF191308),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
