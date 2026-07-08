class UserProfile {
  final int? id;
  final String name;
  final String preferredCurrency;
  final String pinHash;
  final bool biometricEnabled;
  final String themePreference; // 'light' or 'dark'
  final bool reminderEnabled;
  final String reminderTime; // 'HH:mm' format

  UserProfile({
    this.id,
    required this.name,
    required this.preferredCurrency,
    required this.pinHash,
    required this.biometricEnabled,
    required this.themePreference,
    required this.reminderEnabled,
    required this.reminderTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'preferred_currency': preferredCurrency,
      'pin_hash': pinHash,
      'biometric_enabled': biometricEnabled ? 1 : 0,
      'theme_preference': themePreference,
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'reminder_time': reminderTime,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as int?,
      name: map['name'] as String,
      preferredCurrency: map['preferred_currency'] as String,
      pinHash: map['pin_hash'] as String,
      biometricEnabled: (map['biometric_enabled'] as int) == 1,
      themePreference: map['theme_preference'] as String,
      reminderEnabled: (map['reminder_enabled'] as int) == 1,
      reminderTime: map['reminder_time'] as String,
    );
  }

  UserProfile copyWith({
    int? id,
    String? name,
    String? preferredCurrency,
    String? pinHash,
    bool? biometricEnabled,
    String? themePreference,
    bool? reminderEnabled,
    String? reminderTime,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      pinHash: pinHash ?? this.pinHash,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      themePreference: themePreference ?? this.themePreference,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }
}
