class AppUser {
  final String id;
  final String email;
  final String displayName;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['display_name'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'display_name': displayName,
      };
}
