import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Provides audio and haptic feedback for chess move events.
///
/// Uses [AudioPool] for each sound type, which pre-caches the asset and
/// supports rapid/overlapping playback with minimal latency — ideal for
/// the quick tapping pattern of chess moves.
///
/// Haptic feedback is layered on top of audio for tactile reinforcement
/// on mobile devices.
class AudioService {
  bool enabled;

  AudioPool? _movePool;
  AudioPool? _capturePool;
  AudioPool? _checkPool;
  AudioPool? _gameOverPool;
  AudioPool? _notifyPool;

  bool _initialized = false;

  AudioService({this.enabled = true});

  /// Initialise all [AudioPool]s. Call once at app startup.
  ///
  /// Uses `minPlayers: 1, maxPlayers: 2` which is plenty for chess speeds.
  Future<void> init() async {
    if (_initialized) return;
    try {
      _movePool = await AudioPool.createFromAsset(
        path: 'sounds/move.wav',
        maxPlayers: 2,
      );
      _capturePool = await AudioPool.createFromAsset(
        path: 'sounds/capture.wav',
        maxPlayers: 2,
      );
      _checkPool = await AudioPool.createFromAsset(
        path: 'sounds/check.wav',
        maxPlayers: 2,
      );
      _gameOverPool = await AudioPool.createFromAsset(
        path: 'sounds/game_over.wav',
        maxPlayers: 1,
      );
      _notifyPool = await AudioPool.createFromAsset(
        path: 'sounds/notify.wav',
        maxPlayers: 2,
      );
      _initialized = true;
    } catch (_) {
      // Audio init failed — haptics will still work, audio silently disabled
    }
  }

  void _start(AudioPool? pool) {
    if (!enabled || pool == null) return;
    try {
      pool.start();
    } catch (_) {}
  }

  void _haptic(void Function() fn) {
    try {
      fn();
    } catch (_) {}
  }

  /// Plays the piece-moved sound (soft wooden knock).
  void playMove() {
    _haptic(HapticFeedback.lightImpact);
    _start(_movePool);
  }

  /// Plays the piece-captured sound (sharper thud).
  void playCapture() {
    _haptic(HapticFeedback.mediumImpact);
    _start(_capturePool);
  }

  /// Plays the check-alert sound (two-tone ascending ping).
  void playCheck() {
    _haptic(HapticFeedback.heavyImpact);
    _start(_checkPool);
  }

  /// Plays the game-over sound (descending arpeggio).
  void playGameOver() {
    _haptic(HapticFeedback.vibrate);
    _start(_gameOverPool);
  }

  /// Plays the notification sound for online match events.
  void playNotify() {
    _haptic(HapticFeedback.selectionClick);
    _start(_notifyPool);
  }

  /// Releases all audio resources.
  Future<void> dispose() async {
    await Future.wait([
      if (_movePool != null) _movePool!.dispose(),
      if (_capturePool != null) _capturePool!.dispose(),
      if (_checkPool != null) _checkPool!.dispose(),
      if (_gameOverPool != null) _gameOverPool!.dispose(),
      if (_notifyPool != null) _notifyPool!.dispose(),
    ]);
  }
}
