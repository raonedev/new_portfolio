import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/playlist.dart';
import '../models/song.dart';
import '../services/api_service.dart';

final apiProvider = Provider((ref) => JioSaavnApi());

final  trendingSongsProvider = FutureProvider<List<Song>>((ref) async {
  final api = ref.watch(apiProvider);
  return api.getTrending();
});

final chartsProvider = FutureProvider<List<Playlist>>((ref) async {
  final api = ref.watch(apiProvider);
  return api.getCharts();
});

final playlistDetailsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, playlistId) async {
  final api = ref.watch(apiProvider);
  return api.getPlaylistDetails(playlistId);
});


final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return {};
  
  final api = ref.watch(apiProvider);
  return api.search(query);
});
