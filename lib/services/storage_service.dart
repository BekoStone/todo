import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

abstract class StorageService {
  Future<void> writeJson(String key, Object value);
  Map<String, dynamic>? readJson(String key);
}

class StorageServiceImpl implements StorageService {
  final SharedPreferences _prefs;
  StorageServiceImpl(this._prefs);

  @override
  Future<void> writeJson(String key, Object value) async {
    await _prefs.setString(key, jsonEncode(value));
  }

  @override
  Map<String, dynamic>? readJson(String key) {
    final str = _prefs.getString(key);
    if (str == null) return null;
    return jsonDecode(str) as Map<String, dynamic>;
  }
}
