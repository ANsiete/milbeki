// Each validator returns an error message, or null when the input is fine.
// This is the format Flutter's TextFormField expects.
class Validators {
  // Something@something.something, with no spaces. Simple on purpose:
  // the only real proof an email works is sending one to it.
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? email(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Enter your email';
    if (!_emailPattern.hasMatch(text)) return 'Enter a valid email address';
    return null;
  }

  /// For creating a password: length 8+, with a letter and a number.
  static String? newPassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Enter a password';
    if (text.length < 8) return 'Use at least 8 characters';
    final hasLetter = text.contains(RegExp(r'[A-Za-z]'));
    final hasDigit = text.contains(RegExp(r'\d'));
    if (!hasLetter || !hasDigit) return 'Use letters and at least one number';
    return null;
  }

  /// For logging in: only check that something was typed.
  /// The server decides whether the password is correct.
  static String? loginPassword(String? value) {
    if ((value ?? '').isEmpty) return 'Enter your password';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if ((value ?? '').isEmpty) return 'Confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? displayName(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Enter your name';
    if (text.length < 2) return 'Name must be at least 2 characters';
    if (text.length > 50) return 'Name must be 50 characters or fewer';
    return null;
  }
}