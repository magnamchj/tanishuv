import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioPlayerManager {
  static final AudioPlayerManager _instance = AudioPlayerManager._internal();
  static AudioPlayerManager get instance => _instance;

  final AudioPlayer audioPlayer = AudioPlayer();
  final ValueNotifier<String?> currentlyPlayingId = ValueNotifier<String?>(null);

  AudioPlayerManager._internal();

  /// Stops current playback if any and prepares for new audio if different
  Future<void> prepareOrStop(String messageId) async {
    if (currentlyPlayingId.value != null && currentlyPlayingId.value != messageId) {
      await audioPlayer.stop();
    }
  }

  /// Sets the currently playing ID so other bubbles know to update their UI
  void setPlaying(String messageId) {
    currentlyPlayingId.value = messageId;
  }
}
