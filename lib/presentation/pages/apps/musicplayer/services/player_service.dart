import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/song.dart';
import '../providers/player_provider.dart';

class PlayerService {
  PlayerService(this.ref);
  final Ref ref;

  String _getProxiedAudioUrl(String originalUrl) {
    // From: https://jiotunepreview.jio.com/content/Converted/xxxxx.mp3
    // To: https://bitter-bird-7816.kumaraman33063.workers.dev/audio/content/Converted/xxxxx.mp3

    final uri = Uri.parse(originalUrl);
    return 'https://bitter-bird-7816.kumaraman33063.workers.dev/audio${uri.path}';
  }

  AudioPlayer get _player => ref.read(audioPlayerProvider);

  // Future<void> play(Song song) async {
  //   ref.read(currentSongProvider.notifier).state = song;
  //   await _player.play(UrlSource(song.vlink));
  //   ref.read(isPlayingProvider.notifier).state = true;
  // }
  Future<void> play(Song song) async {
    try {
      ref.read(currentSongProvider.notifier).state = song;

      final audioUrl = _getProxiedAudioUrl(song.vlink);
      print('Playing: $audioUrl');

      await _player.stop();
      await _player.setSource(UrlSource(audioUrl));
      await _player.resume();

      ref.read(isPlayingProvider.notifier).state = true;
    } catch (e) {
      print('Error playing song: $e');
    }
  }

  Future<void> toggle() async {
    final playing = ref.read(isPlayingProvider);
    playing ? await _player.pause() : await _player.resume();
    ref.read(isPlayingProvider.notifier).state = !playing;
  }

  void bindListeners() {
    _player.onPositionChanged.listen(
      (p) => ref.read(positionProvider.notifier).state = p,
    );
    _player.onDurationChanged.listen(
      (d) => ref.read(durationProvider.notifier).state = d,
    );
  }
}

final playerServiceProvider = Provider((ref) {
  final service = PlayerService(ref);
  service.bindListeners();
  return service;
});
