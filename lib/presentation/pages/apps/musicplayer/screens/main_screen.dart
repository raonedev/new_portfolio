import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/playlist.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../providers/providers.dart';
import '../services/player_service.dart';
import 'music_player.dart';

class MainMusicScreen extends ConsumerStatefulWidget {
  const MainMusicScreen({super.key});

  @override
  ConsumerState<MainMusicScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainMusicScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [HomePage(), NewPage(), RadioPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 220,
            color: const Color(0xFF1A1A1A),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.music_note, color: Colors.white, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'Music',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildNavItem(Icons.home_rounded, 'Home', 0),
                _buildNavItem(Icons.fiber_new_rounded, 'New', 1),
                _buildNavItem(Icons.radio, 'Radio', 2),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A).withValues(alpha: 0.8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search',
                              hintStyle: TextStyle(color: Colors.grey[600]),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.grey[600],
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                            onChanged: (value) {
                              ref.read(searchQueryProvider.notifier).state =
                                  value;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: const Icon(
                          Icons.account_circle,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                // Page content
                Expanded(child: _pages[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        color: isSelected ? const Color(0xFF2A2A2A) : Colors.transparent,
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============= Pages =============
class NewPage extends StatelessWidget {
  const NewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Home Page',
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingSongs = ref.watch(trendingSongsProvider);
    final charts = ref.watch(chartsProvider);

    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text('New'),
              ),
              const SizedBox(height: 40),

              // Trending Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text('Trending Now'),
              ),
              const SizedBox(height: 20),
              trendingSongs.when(
                data: (songs) => SizedBox(
                  height: 280,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: GestureDetector(
                          onTap: () {
                            ref.read(playerServiceProvider).play(song);
                          },
                          child: _buildMusicCard(song),
                        ),
                      );
                    },
                  ),
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFC3C44)),
                ),
                error: (e, stack) => Center(
                  child: Text(
                    'Error: $e',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),

              const SizedBox(height: 60),

              // Charts Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text('Charts'),
              ),
              const SizedBox(height: 20),
              charts.when(
                data: (playlists) => SizedBox(
                  height: 280,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = playlists[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: _buildPlaylistCard(context, playlist),
                      );
                    },
                  ),
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFC3C44)),
                ),
                error: (e, stack) => Center(
                  child: Text(
                    'Error: $e',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),

        if (ref.watch(isPlayingProvider))
          Positioned(left: 0, bottom: 0, right: 0, child: MusicPlayerScreen()),
      ],
    );
  }

  Widget _buildMusicCard(Song song) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: song.image,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: const Color(0xFF2A2A2A),
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFC3C44)),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: const Color(0xFF2A2A2A),
                child: const Icon(
                  Icons.music_note,
                  color: Colors.grey,
                  size: 60,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            song.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            song.artist,
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistCard(BuildContext context, Playlist playlist) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: playlist.image,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: const Color(0xFF2A2A2A),
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFC3C44)),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: const Color(0xFF2A2A2A),
                child: const Icon(
                  Icons.playlist_play,
                  color: Colors.grey,
                  size: 60,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            playlist.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${playlist.songCount} Songs',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class RadioPage extends StatelessWidget {
  const RadioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Radio Page',
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }
}
