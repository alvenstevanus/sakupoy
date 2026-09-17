import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  static const String _keyHasSeenWelcome = 'has_seen_welcome';

  /// Cek apakah pengguna sudah pernah membuka tampilan pembuka / onboarding
  static Future<bool> hasSeenWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasSeenWelcome) ?? false;
  }

  /// Tandai bahwa pengguna sudah menekan tombol mulai
  static Future<void> setHasSeenWelcome(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasSeenWelcome, value);
  }
}
