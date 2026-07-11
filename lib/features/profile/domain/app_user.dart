import '../../../core/utils/firestore_date.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.bio,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String? bio;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser copyWith({
    String? id,
    String? displayName,
    String? email,
    String? photoUrl,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'bio': bio,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory AppUser.fromMap(Map<String, Object?> map) {
    return AppUser(
      id: map['id'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      bio: map['bio'] as String?,
      createdAt: readFirestoreDate(map['createdAt']),
      updatedAt: readFirestoreDate(map['updatedAt']),
    );
  }
}
