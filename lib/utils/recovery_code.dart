import 'dart:math';

class RecoveryCode {
  static const String _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static String generate() {
    final Random random = Random.secure();
    final List<String> chars = List<String>.generate(
      8,
      (int index) => _alphabet[random.nextInt(_alphabet.length)],
    );
    return '${chars.sublist(0, 4).join()}-${chars.sublist(4).join()}';
  }

  static String normalize(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();

  static bool isWellFormed(String value) => normalize(value).length == 8;
}
