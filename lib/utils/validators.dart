class Validators {
  static final RegExp email = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}$',
  );

  static final RegExp personName = RegExp(r"^[A-Za-zÀ-ÿ][A-Za-zÀ-ÿ' .-]{1,39}$");

  static final RegExp uppercase = RegExp(r'[A-Z]');
  static final RegExp lowercase = RegExp(r'[a-z]');
  static final RegExp digit = RegExp(r'[0-9]');
  static final RegExp special = RegExp(r'[^A-Za-z0-9\s]');

  static const int minPasswordLength = 8;

  static String? nameError(String? value, String label) {
    final String text = (value ?? '').trim();
    if (text.isEmpty) return '$label is required.';
    if (!personName.hasMatch(text)) {
      return '$label must be 2-40 letters with no numbers or symbols.';
    }
    return null;
  }

  static String? emailError(String? value) {
    final String text = (value ?? '').trim();
    if (text.isEmpty) return 'Email is required.';
    if (!email.hasMatch(text)) return 'Enter a valid email address.';
    return null;
  }

  static String? passwordError(String? value) {
    final String text = value ?? '';
    if (text.isEmpty) return 'Password is required.';
    if (text.length < minPasswordLength) {
      return 'Password must be at least $minPasswordLength characters.';
    }
    if (!uppercase.hasMatch(text)) return 'Add at least one uppercase letter.';
    if (!lowercase.hasMatch(text)) return 'Add at least one lowercase letter.';
    if (!digit.hasMatch(text)) return 'Add at least one number.';
    if (!special.hasMatch(text)) return 'Add at least one special character.';
    return null;
  }

  static String? confirmError(String? value, String original) {
    if ((value ?? '').isEmpty) return 'Confirm your password.';
    if (value != original) return 'Passwords do not match.';
    return null;
  }

  static bool hasLength(String value) => value.length >= minPasswordLength;
  static bool hasUppercase(String value) => uppercase.hasMatch(value);
  static bool hasLowercase(String value) => lowercase.hasMatch(value);
  static bool hasDigit(String value) => digit.hasMatch(value);
  static bool hasSpecial(String value) => special.hasMatch(value);
}
