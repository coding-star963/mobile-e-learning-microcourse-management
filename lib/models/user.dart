/// Student/user model for Module 1 (Authentication & Profile Management).
/// Pure Dart: no Flutter imports (AGENT.md §7).
class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.photoUrl,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        email: json['email'] as String,
        photoUrl: json['photoUrl'] as String?,
      );

  final String id;
  final String fullName;
  final String email;
  final String? photoUrl;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'fullName': fullName,
        'email': email,
        'photoUrl': photoUrl,
      };

  AppUser copyWith({String? fullName, String? email, String? photoUrl}) =>
      AppUser(
        id: id,
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        photoUrl: photoUrl ?? this.photoUrl,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          other.id == id &&
          other.fullName == fullName &&
          other.email == email &&
          other.photoUrl == photoUrl;

  @override
  int get hashCode => Object.hash(id, fullName, email, photoUrl);
}
