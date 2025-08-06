import 'dart:math';

class PasswordGenerator {
  static const _lower = 'abcdefghijklmnopqrstuvwxyz';
  static const _upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const _digits = '0123456789';
  static const _symbols = '!@#\$%^&*()-_=+[]{}|;:,.<>?';

  static String generate({
    int length = 16,
    bool includeLower = true,
    bool includeUpper = true,
    bool includeDigits = true,
    bool includeSymbols = true,
  }) {
    final chars = StringBuffer();
    if (includeLower) chars.write(_lower);
    if (includeUpper) chars.write(_upper);
    if (includeDigits) chars.write(_digits);
    if (includeSymbols) chars.write(_symbols);

    final all = chars.toString();
    if (all.isEmpty) return '';

    final rand = Random.secure();
    return List.generate(length, (_) => all[rand.nextInt(all.length)]).join();
  }
}