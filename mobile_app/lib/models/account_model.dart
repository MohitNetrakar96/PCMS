class AccountModel {
  final int id;
  final String accountNumber;
  final String customerId;
  final String accountType;
  final double balance;
  final double dailyTarget;
  final double arrear;
  final double interestRate;
  final String? maturityDate;
  final String? schemeType;
  final String? closedAt;
  final double? payoutAmount;
  final String? openedAt;
  final String status;
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;
  final int? daysToMaturity;
  final double? projectedPayout;

  AccountModel({
    required this.id,
    required this.accountNumber,
    required this.customerId,
    required this.accountType,
    required this.balance,
    required this.dailyTarget,
    required this.arrear,
    required this.interestRate,
    this.maturityDate,
    this.schemeType,
    this.closedAt,
    this.payoutAmount,
    this.openedAt,
    required this.status,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.daysToMaturity,
    this.projectedPayout,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      accountNumber: json['account_number'] ?? json['accountNumber'] ?? '',
      customerId: json['customer_id']?.toString() ?? json['customerId']?.toString() ?? '',
      accountType: json['account_type'] ?? json['accountType'] ?? 'Savings Passbook',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      dailyTarget: (json['daily_target'] as num?)?.toDouble() ?? (json['dailyTarget'] as num?)?.toDouble() ?? 0.0,
      arrear: (json['arrear'] as num?)?.toDouble() ?? 0.0,
      interestRate: (json['interest_rate'] as num?)?.toDouble() ?? (json['interestRate'] as num?)?.toDouble() ?? 4.5,
      maturityDate: json['maturity_date'] ?? json['maturityDate'],
      schemeType: json['scheme_type'] ?? json['schemeType'],
      closedAt: json['closed_at'] ?? json['closedAt'],
      payoutAmount: (json['payout_amount'] as num?)?.toDouble() ?? (json['payoutAmount'] as num?)?.toDouble(),
      openedAt: json['opened_at'] ?? json['openedAt'],
      status: json['status'] ?? 'ACTIVE',
      customerName: json['customer_name'] ?? json['customerName'],
      customerPhone: json['customer_phone'] ?? json['customerPhone'],
      customerEmail: json['customer_email'] ?? json['customerEmail'],
      daysToMaturity: json['daysToMaturity'] is int ? json['daysToMaturity'] : int.tryParse(json['daysToMaturity']?.toString() ?? ''),
      projectedPayout: (json['projectedPayout'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'account_number': accountNumber,
    'customer_id': customerId,
    'account_type': accountType,
    'balance': balance,
    'daily_target': dailyTarget,
    'arrear': arrear,
    'interest_rate': interestRate,
    'maturity_date': maturityDate,
    'scheme_type': schemeType,
    'closed_at': closedAt,
    'payout_amount': payoutAmount,
    'opened_at': openedAt,
    'status': status,
    'customer_name': customerName,
  };
}

class InterestEntryModel {
  final int id;
  final int accountId;
  final double interestAmount;
  final String accrualMonth;
  final double balanceSnapshot;
  final String creditedAt;

  InterestEntryModel({
    required this.id,
    required this.accountId,
    required this.interestAmount,
    required this.accrualMonth,
    required this.balanceSnapshot,
    required this.creditedAt,
  });

  factory InterestEntryModel.fromJson(Map<String, dynamic> json) {
    return InterestEntryModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      accountId: json['account_id'] is int ? json['account_id'] : int.tryParse(json['account_id']?.toString() ?? '0') ?? 0,
      interestAmount: (json['interest_amount'] as num?)?.toDouble() ?? 0.0,
      accrualMonth: json['accrual_month'] ?? '',
      balanceSnapshot: (json['balance_snapshot'] as num?)?.toDouble() ?? 0.0,
      creditedAt: json['credited_at'] ?? '',
    );
  }
}
