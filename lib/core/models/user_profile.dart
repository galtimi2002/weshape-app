import 'package:flutter/material.dart';

/// The signed-in person as the backend stores them.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.userCode,
    required this.email,
    this.firstName,
    this.lastName,
    this.country,
    this.preferredLanguage = 'en',
    this.themeMode = ThemeMode.system,
    this.authProvider = 'UNKNOWN',
    this.profileComplete = false,
  });

  final String id;

  /// Personal code like WSE-K7M2-P9QR, generated once at sign-up.
  final String userCode;
  final String email;
  final String? firstName;
  final String? lastName;

  /// ISO 3166-1 alpha-2.
  final String? country;
  final String preferredLanguage;
  final ThemeMode themeMode;
  final String authProvider;

  /// False until first name, last name and country are set.
  final bool profileComplete;

  String get displayName {
    final full = [firstName, lastName].whereType<String>().where((s) => s.trim().isNotEmpty).join(' ');
    return full.isEmpty ? email : full;
  }

  String get initials {
    final f = firstName?.trim() ?? '';
    final l = lastName?.trim() ?? '';
    final letters = '${f.isNotEmpty ? f[0] : ''}${l.isNotEmpty ? l[0] : ''}';
    return (letters.isEmpty ? email[0] : letters).toUpperCase();
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        userCode: json['userCode'] as String,
        email: json['email'] as String,
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
        country: json['country'] as String?,
        preferredLanguage: json['preferredLanguage'] as String? ?? 'en',
        themeMode: themeModeFromApi(json['themeMode'] as String?),
        authProvider: json['authProvider'] as String? ?? 'UNKNOWN',
        profileComplete: json['profileComplete'] as bool? ?? false,
      );
}

ThemeMode themeModeFromApi(String? value) => switch (value) {
      'LIGHT' => ThemeMode.light,
      'DARK' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

String themeModeToApi(ThemeMode mode) => switch (mode) {
      ThemeMode.light => 'LIGHT',
      ThemeMode.dark => 'DARK',
      ThemeMode.system => 'SYSTEM',
    };

/// What the registration form collects beyond email and password.
class ProfileDraft {
  const ProfileDraft({
    required this.firstName,
    required this.lastName,
    required this.country,
    required this.preferredLanguage,
    required this.themeMode,
  });

  final String firstName;
  final String lastName;
  final String country;
  final String preferredLanguage;
  final ThemeMode themeMode;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'country': country,
        'preferredLanguage': preferredLanguage,
        'themeMode': themeModeToApi(themeMode),
      };
}
