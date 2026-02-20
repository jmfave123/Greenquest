enum AuthErrorScenario {
  generic,
  login,
  register,
  passwordChange,
  resetPassword,
}

/// Utility helpers for translating Firebase Auth error codes into
/// user-friendly messages that can be reused across the app.
class AuthErrorUtils {
  static const Map<AuthErrorScenario, Map<String, String>> _scenarioMessages = {
    AuthErrorScenario.passwordChange: {
      'wrong-password': 'The current password you entered is incorrect.',
      'invalid-credential': 'The current password you entered is incorrect.',
      'weak-password':
          'The new password is too weak. Please choose a stronger one.',
      'requires-recent-login':
          'Please sign in again to continue, then retry changing your password.',
    },
    AuthErrorScenario.login: {
      'user-not-found': 'No account found with that email address.',
      'wrong-password': 'The password you entered is incorrect.',
      'invalid-credential': 'Invalid email or password. Please try again.',
      'user-disabled': 'This account has been disabled.',
      'email-not-verified': 'Please verify your email before logging in.',
    },
    AuthErrorScenario.register: {
      'email-already-in-use': 'An account already exists for that email.',
      'weak-password': 'The password provided is too weak.',
      'invalid-email': 'Please enter a valid email address.',
    },
    AuthErrorScenario.resetPassword: {
      'user-not-found': 'No account found with this email address.',
      'invalid-email': 'The email address is not valid.',
    },
    AuthErrorScenario.generic: {
      'too-many-requests':
          'Too many attempts. Please wait a moment before trying again.',
      'network-request-failed':
          'Network error. Check your internet connection and try again.',
      'internal-error': 'Something went wrong. Please try again later.',
    },
  };

  static String friendlyMessage({
    required String code,
    AuthErrorScenario scenario = AuthErrorScenario.generic,
    String? fallback,
    String? rawMessage,
  }) {
    final normalizedCode = code.trim().toLowerCase();

    final scenarioMessage = _scenarioMessages[scenario]?[normalizedCode];
    if (scenarioMessage != null) {
      return scenarioMessage;
    }

    final genericMessage =
        _scenarioMessages[AuthErrorScenario.generic]?[normalizedCode];
    if (genericMessage != null) {
      return genericMessage;
    }

    return fallback ?? rawMessage ?? 'Something went wrong. Please try again.';
  }
}
