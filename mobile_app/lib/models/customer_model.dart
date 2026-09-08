class CustomerModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String area;
  final String route;
  final double openingBalance;
  final double? latitude;
  final double? longitude;
  final String kycStatus;
  final String aadharNumber;
  final String panNumber;
  final String address;
  final String? photoUrl;
  final String? assignedAgentEmail;
  final String? assignedAgentName;
  final List<dynamic>? accounts;
  final List<dynamic>? history;

  CustomerModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.area,
    required this.route,
    required this.openingBalance,
    this.latitude,
    this.longitude,
    required this.kycStatus,
    required this.aadharNumber,
    required this.panNumber,
    required this.address,
    this.photoUrl,
    this.assignedAgentEmail,
    this.assignedAgentName,
    this.accounts,
    this.history,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      area: json['area'] ?? '',
      route: json['route'] ?? '',
      openingBalance: (json['opening_balance'] as num?)?.toDouble() ?? 0.0,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      kycStatus: json['kyc_status'] ?? 'Pending',
      aadharNumber: json['aadhar_number'] ?? '',
      panNumber: json['pan_number'] ?? '',
      address: json['address'] ?? '',
      photoUrl: json['photo_url'],
      assignedAgentEmail: json['assigned_agent_email'] ?? json['agent_email'],
      assignedAgentName: json['assigned_agent_name'] ?? json['agent_name'],
      accounts: json['accounts'],
      history: json['history'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'area': area,
    'route': route,
    'opening_balance': openingBalance,
    'latitude': latitude,
    'longitude': longitude,
    'kyc_status': kycStatus,
    'aadhar_number': aadharNumber,
    'pan_number': panNumber,
    'address': address,
    'photo_url': photoUrl,
    'assigned_agent_email': assignedAgentEmail,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
