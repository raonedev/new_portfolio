import 'dart:developer' as dev;

class Playlist {
  final String id;
  final String title;
  final String image;
  final String description;
  final int songCount;
  final String permaUrl;

  Playlist({
    required this.id,
    required this.title,
    required this.image,
    required this.description,
    required this.songCount,
    required this.permaUrl,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    dev.log(json.toString());
    return Playlist(
      id: json['listid']?.toString() ?? json['id']?.toString() ?? '',
      title: json['listname'] ?? json['title'] ?? '',
      image: (json['image'] ?? '').replaceAll('50x50', '500x500'),
      description: json['description'] ?? '',
      songCount: () {
        final raw =
            json['count'] ?? json['list_count'] ?? json['song_count'] ?? 0;

        final count = switch (raw) {
          int() => raw,
          String() => int.tryParse(raw) ?? 0,
          _ => 0,
        };

        // Optional: log for debugging
        if (count == 0 &&
            (json['count'] == null && json['list_count'] == null)) {
          dev.log(
            'No song count field found in playlist JSON: ${json['listname'] ?? 'unknown'}',
          );
        }

        return count;
      }(),
      permaUrl: json['perma_url'] ?? '',
    );
  }
}
