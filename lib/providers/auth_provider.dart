import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';
import '../core/database/daos/user_profile_dao.dart';
import '../models/user_profile.dart';
import '../core/notifications/notification_service.dart';
import '../core/agent/agent_service.dart';

enum AuthStatus {
  undetermined,
  pinSetupRequired,
  unauthenticated,
  authenticated,
}

class AuthState {
  final AuthStatus status;
  final UserProfile? profile;
  final List<UserProfile> profiles;
  final String? errorMessage;
  final bool isBiometricAvailable;
  final int wrongAttempts;
  final DateTime? lockedUntil;

  AuthState({
    required this.status,
    this.profile,
    this.profiles = const [],
    this.errorMessage,
    this.isBiometricAvailable = false,
    this.wrongAttempts = 0,
    this.lockedUntil,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserProfile? profile,
    List<UserProfile>? profiles,
    String? errorMessage,
    bool? isBiometricAvailable,
    int? wrongAttempts,
    DateTime? lockedUntil,
    bool clearLockedUntil = false,
    bool clearProfile = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      profile: clearProfile ? null : (profile ?? this.profile),
      profiles: profiles ?? this.profiles,
      errorMessage: errorMessage ?? this.errorMessage,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
      wrongAttempts: wrongAttempts ?? this.wrongAttempts,
      lockedUntil: clearLockedUntil ? null : (lockedUntil ?? this.lockedUntil),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final UserProfileDao _profileDao = UserProfileDao();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  AuthNotifier()
      : super(AuthState(status: AuthStatus.undetermined)) {
    checkProfile();
  }

  Future<void> _scheduleReminderIfEnabled(UserProfile? profile) async {
    if (profile != null && profile.reminderEnabled) {
      try {
        final timeParts = profile.reminderTime.split(':');
        if (timeParts.length == 2) {
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          await NotificationService.instance.scheduleDailyReminder(hour, minute);
        }
      } catch (e) {
        // ignore errors during scheduling
      }
    } else {
      try {
        await NotificationService.instance.cancelDailyReminder();
      } catch (e, stackTrace) {
        debugPrint('Silent error canceling daily reminder in AuthNotifier: $e\n$stackTrace');
      }
    }
  }

  Future<void> checkProfile() async {
    try {
      final profiles = await _profileDao.getAllProfiles();
      final isBioAvailable = await _checkBiometricsAvailability();
      
      if (profiles.isEmpty) {
        state = AuthState(
          status: AuthStatus.pinSetupRequired,
          profiles: [],
          isBiometricAvailable: isBioAvailable,
        );
      } else {
        final activeProfile = state.profile ?? (profiles.length == 1 ? profiles.first : null);
        if (activeProfile != null) {
          AgentService.activeProfileId = activeProfile.id;
        }

        // Load profile-specific lockout state
        int wrongAttempts = 0;
        DateTime? lockedUntil;
        if (activeProfile?.id != null) {
          final profileId = activeProfile!.id;
          final wrongAttemptsStr = await _secureStorage.read(key: 'lockout_attempts_$profileId');
          final lockedUntilStr = await _secureStorage.read(key: 'lockout_until_$profileId');
          wrongAttempts = wrongAttemptsStr != null ? int.tryParse(wrongAttemptsStr) ?? 0 : 0;
          lockedUntil = lockedUntilStr != null ? DateTime.tryParse(lockedUntilStr) : null;
        }

        state = AuthState(
          status: AuthStatus.unauthenticated,
          profile: activeProfile,
          profiles: profiles,
          isBiometricAvailable: isBioAvailable,
          wrongAttempts: wrongAttempts,
          lockedUntil: lockedUntil,
        );
        if (activeProfile != null) {
          await _scheduleReminderIfEnabled(activeProfile);
        }
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Database error: $e');
    }
  }

  Future<void> checkProfileAndKeepAuthenticated({String? syncPinHash, String? syncPinSalt}) async {
    try {
      final profiles = await _profileDao.getAllProfiles();
      final isBioAvailable = await _checkBiometricsAvailability();
      
      if (profiles.isEmpty) {
        state = AuthState(
          status: AuthStatus.pinSetupRequired,
          profiles: [],
          isBiometricAvailable: isBioAvailable,
        );
      } else {
        var activeProfile = profiles.first;
        
        // If active session PIN credentials were provided, sync them to the restored profile
        if (syncPinHash != null && syncPinHash.isNotEmpty) {
          activeProfile = activeProfile.copyWith(
            pinHash: syncPinHash,
            pinSalt: syncPinSalt,
          );
          await _profileDao.updateProfile(activeProfile);
        }

        AgentService.activeProfileId = activeProfile.id;

        state = AuthState(
          status: AuthStatus.authenticated,
          profile: activeProfile,
          profiles: profiles,
          isBiometricAvailable: isBioAvailable,
          wrongAttempts: 0,
        );
        await _scheduleReminderIfEnabled(activeProfile);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Database error: $e');
    }
  }

  Future<bool> _checkBiometricsAvailability() async {
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      return false;
    }
  }

  void selectProfile(UserProfile profile) async {
    final profileId = profile.id;
    int wrongAttempts = 0;
    DateTime? lockedUntil;
    if (profileId != null) {
      final wrongAttemptsStr = await _secureStorage.read(key: 'lockout_attempts_$profileId');
      final lockedUntilStr = await _secureStorage.read(key: 'lockout_until_$profileId');
      wrongAttempts = wrongAttemptsStr != null ? int.tryParse(wrongAttemptsStr) ?? 0 : 0;
      lockedUntil = lockedUntilStr != null ? DateTime.tryParse(lockedUntilStr) : null;
    }

    AgentService.activeProfileId = profile.id;

    state = state.copyWith(
      profile: profile,
      status: AuthStatus.unauthenticated,
      wrongAttempts: wrongAttempts,
      lockedUntil: lockedUntil,
      clearLockedUntil: lockedUntil == null,
    );
    _scheduleReminderIfEnabled(profile);
  }

  void showSelector() {
    AgentService.activeProfileId = null;
    state = state.copyWith(
      profile: null,
      clearProfile: true,
      status: AuthStatus.unauthenticated,
      wrongAttempts: 0,
      clearLockedUntil: true,
    );
  }

  void startCreateProfile() {
    state = state.copyWith(
      status: AuthStatus.pinSetupRequired,
      profile: null,
      clearProfile: true,
    );
  }

  Future<void> _updateLockoutState({required int wrongAttempts, DateTime? lockedUntil}) async {
    final profileId = state.profile?.id;
    state = state.copyWith(
      wrongAttempts: wrongAttempts,
      lockedUntil: lockedUntil,
      clearLockedUntil: lockedUntil == null,
    );

    if (profileId != null) {
      await _secureStorage.write(key: 'lockout_attempts_$profileId', value: wrongAttempts.toString());
      if (lockedUntil != null) {
        await _secureStorage.write(key: 'lockout_until_$profileId', value: lockedUntil.toIso8601String());
      } else {
        await _secureStorage.delete(key: 'lockout_until_$profileId');
      }
    }
  }

  String _generateSalt() {
    final rand = Random.secure();
    final saltBytes = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      saltBytes[i] = rand.nextInt(256);
    }
    return base64.encode(saltBytes);
  }

  String _hashPinPbkdf2(String pin, String salt) {
    final pinBytes = utf8.encode(pin);
    final saltBytes = base64.decode(salt);
    final pbkdf2Derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(saltBytes, 10000, 32));
    final hashBytes = pbkdf2Derivator.process(pinBytes);
    return base64.encode(hashBytes);
  }

  Future<bool> setupPin(String name, String currency, String pin) async {
    try {
      final salt = _generateSalt();
      final pinHash = _hashPinPbkdf2(pin, salt);
      final profile = UserProfile(
        name: name,
        preferredCurrency: currency,
        pinHash: pinHash,
        pinSalt: salt,
        biometricEnabled: false,
        themePreference: 'dark',
        reminderEnabled: true,
        reminderTime: '20:00',
      );

      final id = await _profileDao.insertProfile(profile);
      final createdProfile = profile.copyWith(id: id);
      
      AgentService.activeProfileId = id;
      await checkProfile();

      state = state.copyWith(
        profile: createdProfile,
        status: AuthStatus.authenticated,
      );
      await _scheduleReminderIfEnabled(createdProfile);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to save PIN: $e');
      return false;
    }
  }

  Future<bool> verifyPin(String pin) async {
    final profile = state.profile;
    if (profile == null) return false;

    // Check if currently locked out
    if (state.lockedUntil != null) {
      if (DateTime.now().isBefore(state.lockedUntil!)) {
        final remaining = state.lockedUntil!.difference(DateTime.now());
        state = state.copyWith(
          errorMessage: 'App locked. Try again in ${remaining.inMinutes} minutes ${remaining.inSeconds % 60} seconds.',
        );
        return false;
      } else {
        // Lockout expired, reset attempts
        await _updateLockoutState(wrongAttempts: 0, lockedUntil: null);
      }
    }

    String inputHash;
    bool isMatch = false;

    if (profile.pinSalt == null || profile.pinSalt!.isEmpty) {
      // Fallback for old unsalted SHA-256 hash
      final bytes = utf8.encode(pin);
      final digest = sha256.convert(bytes);
      inputHash = digest.toString();
      if (profile.pinHash == inputHash) {
        isMatch = true;
        // Auto-upgrade this profile to PBKDF2!
        final newSalt = _generateSalt();
        final newHash = _hashPinPbkdf2(pin, newSalt);
        final upgradedProfile = profile.copyWith(pinHash: newHash, pinSalt: newSalt);
        await updateProfile(upgradedProfile);
      }
    } else {
      inputHash = _hashPinPbkdf2(pin, profile.pinSalt!);
      if (profile.pinHash == inputHash) {
        isMatch = true;
      }
    }

    if (isMatch) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
      );
      await _updateLockoutState(wrongAttempts: 0, lockedUntil: null);
      await _scheduleReminderIfEnabled(state.profile);
      return true;
    } else {
      final newAttempts = state.wrongAttempts + 1;
      DateTime? lockoutTime;
      String errMsg = 'Incorrect PIN. Please try again.';
      
      if (newAttempts >= 5) {
        lockoutTime = DateTime.now().add(const Duration(minutes: 30));
        errMsg = 'Too many failed attempts. App locked for 30 minutes.';
        try {
          await NotificationService.instance.showLockoutAlert();
        } catch (e, stackTrace) {
          debugPrint('Silent error showing lockout alert in AuthNotifier.verifyPin: $e\n$stackTrace');
        }
      }
      
      final attemptsRemaining = 5 - newAttempts;
      await _updateLockoutState(wrongAttempts: newAttempts, lockedUntil: lockoutTime);
      state = state.copyWith(
        errorMessage: lockoutTime != null 
            ? errMsg 
            : '$errMsg ($attemptsRemaining attempts remaining)',
      );
      return false;
    }
  }

  Future<bool> authenticateBiometrically() async {
    final profile = state.profile;
    if (profile == null || !profile.biometricEnabled) return false;

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your Money Manager',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        state = state.copyWith(status: AuthStatus.authenticated);
        await _scheduleReminderIfEnabled(profile);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Biometric authentication failed: $e');
      return false;
    }
  }

  Future<void> updateProfile(UserProfile updatedProfile) async {
    try {
      await _profileDao.updateProfile(updatedProfile);
      state = state.copyWith(profile: updatedProfile);
      await _scheduleReminderIfEnabled(updatedProfile);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update profile: $e');
    }
  }

  void logout() {
    AgentService.activeProfileId = null;
    if (state.profile != null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } else {
      state = state.copyWith(status: AuthStatus.pinSetupRequired);
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
