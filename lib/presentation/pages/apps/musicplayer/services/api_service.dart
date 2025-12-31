import 'dart:convert';
import 'dart:developer' as dev;

import '../models/playlist.dart';
import '../models/song.dart';
import 'package:http/http.dart' as http;

class JioSaavnApi {
  // static const String baseUrl = 'https://proxy.cors.sh/https://www.jiosaavn.com/api.php';
  // static const String baseUrl = 'https://corsproxy.io/?/https://www.jiosaavn.com/api.php';
  static const String baseUrl = 'https://www.jiosaavn.com/api.php';

  Future<List<Song>> getTrending() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl?__call=content.getTrending&_format=json&_marker=0&ctx=web6dot0&entity_type=song&entity_language=hindi',
        ),
        headers: {
          'Referer': 'https://www.jiosaavn.com/',
          'Origin': 'https://www.jiosaavn.com',
        }
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Song.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching trending: $e');
      return [];
    }
  }

  Future<List<Playlist>> getCharts() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl?__call=content.getCharts&_format=json&_marker=0&ctx=web6dot0',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Playlist.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching charts: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getPlaylistDetails(String playlistId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl?__call=playlist.getDetails&_format=json&_marker=0&ctx=web6dot0&listid=$playlistId',
        ),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      print('Error fetching playlist details: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> search(String query) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl?query=${Uri.encodeComponent(query)}&_format=json&__call=autocomplete.get',
        ),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      print('Error searching: $e');
      return {};
    }
  }
}
