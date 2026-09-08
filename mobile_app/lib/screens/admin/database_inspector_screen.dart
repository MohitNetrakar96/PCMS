import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/app_card.dart';

class DatabaseInspectorScreen extends StatefulWidget {
  const DatabaseInspectorScreen({super.key});

  @override
  State<DatabaseInspectorScreen> createState() => _DatabaseInspectorScreenState();
}

class _DatabaseInspectorScreenState extends State<DatabaseInspectorScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _dbData;
  bool _loading = true;
  TabController? _tabController;
  final List<String> _tableNames = ['users', 'customers', 'accounts', 'collections', 'collection_history', 'vault_submissions', 'audit_trail'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tableNames.length, vsync: this);
    _loadDb();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadDb() async {
    try {
      final res = await ApiService.getDbTables();
      setState(() {
        _dbData = res;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Database & Ledger Inspector', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF2563EB),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: _tableNames.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _tableNames.map((tableName) {
                final tables = _dbData?['tables'] as Map<String, dynamic>? ?? {};
                final rows = (tables[tableName] as List?) ?? [];

                if (rows.isEmpty) {
                  return Center(
                    child: Text('Table $tableName is empty.', style: const TextStyle(color: Color(0xFF94A3B8))),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: rows.length,
                  itemBuilder: (ctx, idx) {
                    final row = rows[idx] as Map<String, dynamic>;
                    return AppCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('#${idx + 1} ID: ${row['id'] ?? row['account_number'] ?? ""}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2563EB))),
                              Text('Table: $tableName', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(6)),
                            child: SelectableText(
                              const JsonEncoder.withIndent('  ').convert(row),
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF334155)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }).toList(),
            ),
    );
  }
}
