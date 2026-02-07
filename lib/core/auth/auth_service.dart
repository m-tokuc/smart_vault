import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

/// Service responsible for handling local biometric authentication.
///
/// Wraps the [LocalAuthentication] package to provide simple methods for
/// checking availability and performing authentication.
class AuthService {
  final LocalAuthentication auth = LocalAuthentication();

  /// Checks if the device supports biometric authentication.
  ///
  /// Returns `true` if biometrics (FaceID/TouchID) or device passcode
  /// authentication is available.
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (e) {
      print("Error checking biometrics: $e");
      return false;
    }
  }

  /// Attempts to authenticate the user.
  ///
  /// Shows the system's biometric prompt. Returns `true` if authentication
  /// is successful, `false` otherwise (including cancellations).
  Future<bool> authenticate() async {
    try {
      return await auth.authenticate(
        localizedReason: 'Please authenticate to access SmartVault',
      );
    } on PlatformException catch (e) {
      print("Error authenticating: $e");
      return false;
    }
  }
}
