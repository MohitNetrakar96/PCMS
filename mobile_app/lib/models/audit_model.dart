class AuditLogModel {
  final int id;
  final String action;
  final String userName;
  final String? userEmail;
  final String? role;
  final String status;
  final String details;
  final String createdAt;

  AuditLogModel({
    required this.id,
    required this.action,
    required this.userName,
    this.userEmail,
    this.role,
    required this.status,
    required this.details,
    required this.createdAt,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      action: json['action'] ?? 'Unknown Action',
      userName: json['user_name'] ?? 'System',
      userEmail: json['user_email'],
      role: json['role'] ?? 'System',
      status: json['status'] ?? 'ok',
      details: json['details'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'action': action,
    'user_name': userName,
    'user_email': userEmail,
    'role': role,
    'status': status,
    'details': details,
    'created_at': createdAt,
  };
}
