import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/collection_provider.dart';
import '../utils/map_utils.dart';
import 'agent/customer_visit_screen.dart';

class RouteMapScreen extends StatelessWidget {
  const RouteMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CollectionProvider>();
    final pending = provider.pendingCustomers;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FA),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF55356E),
              boxShadow: [
                BoxShadow(color: Color(0x1A55356E), blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6F5FF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFD6F5FF), width: 1),
                      ),
                      child: const Icon(Icons.explore, color: Color(0xFFD6F5FF), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Optimized Doorstep Sequence',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${pending.length} pending waypoints • Est. 42 mins field time',
                            style: const TextStyle(color: Color(0xFFD6F5FF), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (pending.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final first = pending.first;
                        MapUtils.openMap(
                          context: context,
                          latitude: first.latitude,
                          longitude: first.longitude,
                          title: first.name,
                          address: first.address.isNotEmpty ? first.address : '${first.area}, ${first.route}',
                        );
                      },
                      icon: const Icon(Icons.navigation_rounded, size: 16),
                      label: Text('Navigate to Next Stop (${pending.first.name})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD6F5FF),
                        foregroundColor: const Color(0xFF55356E),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          Expanded(
            child: pending.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check_circle, color: Color(0xFF76A787), size: 48),
                        SizedBox(height: 8),
                        Text('All route waypoints visited for today!', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: pending.length,
                    itemBuilder: (context, index) {
                      final item = pending[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE9E2F3)),
                          boxShadow: const [
                            BoxShadow(color: Color(0x0655356E), blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFF55356E),
                                  foregroundColor: const Color(0xFFD6F5FF),
                                  radius: 18,
                                  child: Text(
                                    (index + 1).toString(),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF191308)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${item.area} • Route ${item.route} • ₹${item.amount.toStringAsFixed(1)} due',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16, color: Color(0xFFF1F5F9)),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      MapUtils.openMap(
                                        context: context,
                                        latitude: item.latitude,
                                        longitude: item.longitude,
                                        title: item.name,
                                        address: item.address.isNotEmpty ? item.address : '${item.area}, ${item.route}',
                                      );
                                    },
                                    icon: const Icon(Icons.directions_rounded, size: 15, color: Color(0xFF55356E)),
                                    label: const Text('Navigate', style: TextStyle(color: Color(0xFF55356E), fontSize: 12, fontWeight: FontWeight.bold)),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFF55356E), width: 1.2),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => CustomerVisitScreen(collection: item)),
                                      );
                                    },
                                    icon: const Icon(Icons.check_circle_outline, size: 15),
                                    label: const Text('Visit & Collect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF55356E),
                                      foregroundColor: const Color(0xFFD6F5FF),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                  ),
                                ),
                              ],
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
