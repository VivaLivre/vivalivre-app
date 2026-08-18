class UserModel {
  final int id;
  final String name;
  final String email;
  final String? avatarUrl;
  final int? height;
  final double? weight;
  final DateTime? birthDate;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.height,
    this.weight,
    this.birthDate,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      avatarUrl: json['avatar_url'],
      height: json['height'],
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      birthDate: json['date_of_birth'] != null 
          ? DateTime.parse(json['date_of_birth']) 
          : (json['birth_date'] != null ? DateTime.parse(json['birth_date']) : null),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar_url': avatarUrl,
      'height': height,
      'weight': weight,
      'birth_date': birthDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? avatarUrl,
    int? height,
    double? weight,
    DateTime? birthDate,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      birthDate: birthDate ?? this.birthDate,
      createdAt: createdAt,
    );
  }
}
