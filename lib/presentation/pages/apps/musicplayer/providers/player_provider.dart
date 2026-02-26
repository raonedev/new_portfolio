import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/song.dart';

final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  ref.onDispose(() => player.dispose());
  return player;
});

final currentSongProvider = StateProvider<Song?>((ref) => null);
final isPlayingProvider = StateProvider<bool>((ref) => false);
final positionProvider = StateProvider<Duration>((ref) => Duration.zero);
final durationProvider = StateProvider<Duration>((ref) => Duration.zero);
