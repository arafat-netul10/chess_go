import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/user_profile.dart';

/// Local persistence service for preferences and offline/guest stats
class LocalStorageService {
  static const _guestProfileKey = 'chessgo_guest_profile';
  static const _soundEnabledKey = 'chessgo_sound_enabled';
  static const _preferredDifficultyKey = 'chessgo_preferred_difficulty';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static Future<LocalStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  UserProfile getGuestProfile() {
    final data = _prefs.getString(_guestProfileKey);
    if (data == null) {
      return UserProfile.guest();
    }
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      return UserProfile.fromJson(json).copyWith(isGuest: true);
    } catch (_) {
      return UserProfile.guest();
    }
  }

  Future<void> saveGuestProfile(UserProfile profile) async {
    await _prefs.setString(_guestProfileKey, jsonEncode(profile.toJson()));
  }

  bool get isSoundEnabled => _prefs.getBool(_soundEnabledKey) ?? true;

  Future<void> setSoundEnabled(bool enabled) async {
    await _prefs.setBool(_soundEnabledKey, enabled);
  }

  String get preferredDifficulty =>
      _prefs.getString(_preferredDifficultyKey) ?? 'Medium';

  Future<void> setPreferredDifficulty(String difficulty) async {
    await _prefs.setString(_preferredDifficultyKey, difficulty);
  }
}
