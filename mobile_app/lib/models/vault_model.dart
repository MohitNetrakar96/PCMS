class VaultSubmissionModel {
  final int? id;
  final String agentEmail;
  final String submissionDate;
  final double expectedCash;
  final double cashSubmitted;
  final double differenceAmount;
  final String status;
  final bool managerOtpVerified;
  final bool cashierAccepted;
  final String? bankReference;
  final String? signatureUrl;

  VaultSubmissionModel({
    this.id,
    required this.agentEmail,
    required this.submissionDate,
    required this.expectedCash,
    required this.cashSubmitted,
    required this.differenceAmount,
    required this.status,
    required this.managerOtpVerified,
    required this.cashierAccepted,
    this.bankReference,
    this.signatureUrl,
  });

  factory VaultSubmissionModel.fromJson(Map<String, dynamic> json) {
    return VaultSubmissionModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      agentEmail: json['agent_email'] ?? '',
      submissionDate: json['submission_date'] ?? '',
      expectedCash: (json['expected_cash'] as num?)?.toDouble() ?? 0.0,
      cashSubmitted: (json['cash_submitted'] as num?)?.toDouble() ?? 0.0,
      differenceAmount: (json['difference_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'not_submitted',
      managerOtpVerified: json['manager_otp_verified'] == 1 || json['manager_otp_verified'] == true,
      cashierAccepted: json['cashier_accepted'] == 1 || json['cashier_accepted'] == true,
      bankReference: json['bank_reference'],
      signatureUrl: json['signature_url'],
    );
  }
}
