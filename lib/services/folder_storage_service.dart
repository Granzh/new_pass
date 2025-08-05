import 'package:shared_preferences/shared_preferences.dart';

class FolderStorageService {


  static const _key = 'password_folder_path';

  Future<void> savePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, path);
  }

  Future<String?> getPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  Future<void> clearPath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}