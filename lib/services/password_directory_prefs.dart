import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';

class PasswordDirectoryPrefs {
  static final _log = Logger('PasswordDirectoryPrefs');
  static const _key = 'password_folder_path';

  static Future<void> save(String path) async {
    _log.info('Saving password folder path: $path');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, path);
  }

  static Future<String?> load() async {
    _log.info('Loading password folder path');
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<void> clear() async {
    _log.info('Clearing password folder path');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}