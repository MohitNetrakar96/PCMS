class CollectionModel {
  final String id;
  final String customerId;
  final String name;
  final String phone;
  final String email;
  final String area;
  final String route;
  final String pigmyAccountNumber;
  final double amount;
  final double pendingAmount;
  final double collectedAmount;
  final double balance;
  final String status;
  final String? visitTime;
  final String? paymentMode;
  final String? remarks;
  final double? latitude;
  final double? longitude;
  final String? photoUrl;
  final String? receiptId;
  final String address;

  CollectionModel({
    required this.id,
    required this.customerId,
    required this.name,
    required this.phone,
    required this.email,
    required this.area,
    required this.route,
    required this.pigmyAccountNumber,
    required this.amount,
    required this.pendingAmount,
    required this.collectedAmount,
    required this.balance,
    required this.status,
    this.visitTime,
    this.paymentMode,
    this.remarks,
    this.latitude,
    this.longitude,
    this.photoUrl,
    this.receiptId,
    required this.address,
  });

  factory CollectionModel.fromJson(Map<String, dynamic> json) {
    return CollectionModel(
      id: json['id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      area: json['area'] ?? '',
      route: json['route'] ?? '',
      pigmyAccountNumber: json['pigmy_account_number'] ?? json['account'] ?? 'PCMS-000',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      pendingAmount: (json['pending_amount'] as num?)?.toDouble() ?? 0.0,
      collectedAmount: (json['collected_amount'] as num?)?.toDouble() ?? 0.0,
      balance: (json['balance'] as num?)?.toDouble() ?? (json['opening_balance'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'pending',
      visitTime: json['visit_time'],
      paymentMode: json['payment_mode'],
      remarks: json['remarks'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      photoUrl: json['photo_url'],
      receiptId: json['receipt_id'],
      address: json['address'] ?? '${json['area'] ?? ""}, ${json['route'] ?? ""}',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'name': name,
      'phone': phone,
      'email': email,
      'area': area,
      'route': route,
      'pigmy_account_number': pigmyAccountNumber,
      'amount': amount,
      'pending_amount': pendingAmount,
      'collected_amount': collectedAmount,
      'balance': balance,
      'status': status,
      'visit_time': visitTime,
      'payment_mode': paymentMode,
      'remarks': remarks,
      'latitude': latitude,
      'longitude': longitude,
      'photo_url': photoUrl,
      'receipt_id': receiptId,
      'address': address,
    };
  }
}
