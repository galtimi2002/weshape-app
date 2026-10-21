/// Provider-agnostic signed-in user, so the UI never imports firebase_auth.
class AppUser {
  const AppUser({required this.uid, this.email, this.displayName});

  final String uid;
  final String? email;
  final String? displayName;

  Map<String, dynamic> toJson() => <String, dynamic>{'uid': uid, 'email': email, 'displayName': displayName};

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        uid: json['uid'] as String,
        email: json['email'] as String?,
        displayName: json['displayName'] as String?,
      );
}
