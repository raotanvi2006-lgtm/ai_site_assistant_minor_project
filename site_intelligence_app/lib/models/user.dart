class AppUser {
  final String name;
  final String phone;
  final String passwordHash;

  const AppUser({
    required this.name,
    required this.phone,
    required this.passwordHash,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'passwordHash': passwordHash,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        name: json['name'] as String,
        phone: json['phone'] as String,
        passwordHash: json['passwordHash'] as String,
      );
}