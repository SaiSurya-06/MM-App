import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../core/database/daos/user_profile_dao.dart';
import '../models/user_profile.dart';
import '../core/notifications/notification_service.dart';
import '../core/utils/encryption_service.dart';

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
      } catch (_) {}
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
        state = AuthState(
          status: AuthStatus.unauthenticated,
          profile: activeProfile,
          profiles: profiles,
          isBiometricAvailable: isBioAvailable,
        );
        if (activeProfile != null) {
          await _scheduleReminderIfEnabled(activeProfile);
        }
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

  void selectProfile(UserProfile profile) {
    state = state.copyWith(
      profile: profile,
      status: AuthStatus.unauthenticated,
      wrongAttempts: 0,
      clearLockedUntil: true,
    );
    _scheduleReminderIfEnabled(profile);
  }

  void showSelector() {
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

  Future<bool> setupPin(String name, String currency, String pin) async {
    try {
      // Generate a unique salt for this user
      final salt = EncryptionService.instance.generateSalt();
      final pinHash = _hashPin(pin, salt);
      final profile = UserProfile(
        name: name,
        preferredCurrency: currency,
        pinHash: pinHash,
        pinSalt: salt, // Store the salt with the profile
        biometricEnabled: false,
        themePreference: 'dark',
        reminderEnabled: true,
        reminderTime: '20:00',
      );

      final id = await _profileDao.insertProfile(profile);
      final createdProfile = profile.copyWith(id: id);
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
    if (state.lockedUntil != null && DateTime.now().isBefore(state.lockedUntil!)) {
      final remaining = state.lockedUntil!.difference(DateTime.now());
      state = state.copyWith(
        errorMessage: 'App locked. Try again in ${remaining.inMinutes} minutes ${remaining.inSeconds % 60} seconds.',
      );
      return false;
    }

    // Use the stored salt to hash the input PIN
    final salt = profile.pinSalt ?? '';
    final inputHash = _hashPin(pin, salt);
    if (profile.pinHash == inputHash) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        wrongAttempts: 0,
        clearLockedUntil: true,
      );
      await _scheduleReminderIfEnabled(profile);
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
        } catch (_) {}
      }
      
      final attemptsRemaining = 5 - newAttempts;
      state = state.copyWith(
        errorMessage: lockoutTime != null 
            ? errMsg 
            : '$errMsg ($attemptsRemaining attempts remaining)',
        wrongAttempts: newAttempts,
        lockedUntil: lockoutTime,
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
    if (state.profile != null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } else {
      state = state.copyWith(status: AuthStatus.pinSetupRequired);
    }
  }

  String _hashPin(String pin, String salt) {
    // Use PBKDF2-based key derivation with salt for secure PIN hashing
    final key = EncryptionService.instance.deriveKey(pin, salt);
    // Hash the derived key to create the stored PIN hash
    final bytes = key.bytes;
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
