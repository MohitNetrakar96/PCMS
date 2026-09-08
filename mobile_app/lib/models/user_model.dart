class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? employeeId;
  final String? phone;
  final String? photoUrl;
  final String? area;
  final String? route;
  final String? address;
  final String? token;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.employeeId,
    this.phone,
    this.photoUrl,
    this.area,
    this.route,
    this.address,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    return UserModel(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'Collection Agent',
      employeeId: json['employee_id'] ?? json['employeeId'],
      phone: json['phone']?.toString(),
      photoUrl: json['photo_url'] ?? json['photoUrl'],
      area: json['area']?.toString(),
      route: json['route']?.toString(),
      address: json['address']?.toString(),
      token: token ?? json['token'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'employee_id': employeeId,
    'phone': phone,
    'photo_url': photoUrl,
    'area': area,
    'route': route,
    'address': address,
    'token': token,
  };

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? role,
    String? employeeId,
    String? phone,
    String? photoUrl,
    String? area,
    String? route,
    String? address,
    String? token,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      employeeId: employeeId ?? this.employeeId,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      area: area ?? this.area,
      route: route ?? this.route,
      address: address ?? this.address,
      token: token ?? this.token,
    );
  }
}
