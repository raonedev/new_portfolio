class Song {
  final String id;
  final String title;
  final String album;
  final String image;
  final String artist;
  final int playCount;
  final String year;
  final String duration;
  final String permaUrl;

  Song({
    required this.id,
    required this.title,
    required this.album,
    required this.image,
    required this.artist,
    required this.playCount,
    required this.year,
    required this.duration,
    required this.permaUrl,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    final details = json['details'] ?? json;
    return Song(
      id: details['id'] ?? '',
      title: details['song'] ?? details['title'] ?? '',
      album: details['album'] ?? '',
      image: (details['image'] ?? '').replaceAll('50x50', '500x500'),
      artist: details['primary_artists'] ?? details['singers'] ?? '',
      playCount: details['play_count'] is int 
          ? details['play_count'] 
          : int.tryParse(details['play_count']?.toString() ?? '0') ?? 0,
      year: details['year']?.toString() ?? '',
      duration: details['duration']?.toString() ?? '0',
      permaUrl: details['perma_url'] ?? '',
    );
  }
}