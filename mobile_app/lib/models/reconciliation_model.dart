class ReconciliationRecordModel {
  final int id;
  final String agentEmail;
  final String? agentName;
  final String date;
  final double totalCollected;
  final double totalSubmitted;
  final double difference;
  final String status;
  final String? resolvedBy;
  final String? resolvedAt;
  final String? note;
  final bool hasMismatch;
  final List<dynamic>? breakdown;

  ReconciliationRecordModel({
    required this.id,
    required this.agentEmail,
    this.agentName,
    required this.date,
    required this.totalCollected,
    required this.totalSubmitted,
    required this.difference,
    required this.status,
    this.resolvedBy,
    this.resolvedAt,
    this.note,
    required this.hasMismatch,
    this.breakdown,
  });

  factory ReconciliationRecordModel.fromJson(Map<String, dynamic> json) {
    return ReconciliationRecordModel(
      id: json['recordId'] is int
          ? json['recordId']
          : json['id'] is int
              ? json['id']
              : int.tryParse(json['recordId']?.toString() ?? json['id']?.toString() ?? '0') ?? 0,
      agentEmail: json['agentEmail'] ?? json['agent_email'] ?? '',
      agentName: json['agentName'],
      date: json['date'] ?? json['recon_date'] ?? '',
      totalCollected: (json['totalCollected'] as num?)?.toDouble() ?? (json['total_collected'] as num?)?.toDouble() ?? 0.0,
      totalSubmitted: (json['totalSubmitted'] as num?)?.toDouble() ?? (json['total_submitted'] as num?)?.toDouble() ?? 0.0,
      difference: (json['difference'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'MATCHED',
      resolvedBy: json['resolvedBy'] ?? json['resolved_by'],
      resolvedAt: json['resolvedAt'] ?? json['resolved_at'],
      note: json['note'],
      hasMismatch: json['hasMismatch'] == true || (json['status'] == 'MISMATCH'),
      breakdown: json['breakdown'],
    );
  }
}
