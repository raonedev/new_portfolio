import 'dart:ui';
import 'package:aman_protfolio/presentation/pages/apps/musicplayer/screens/main_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../apps/calender/calender.dart';
import '../apps/calculator/calculator.dart';
import '../apps/finder/pdf_viewer.dart';
import '../apps/mail/mail_screen.dart';
import '../apps/messanger/messanger.dart';
import '../apps/notes/notes.dart';
import '../apps/web/webpage.dart';
import '../desktop/models/desktop_app.dart';

class MobileScreen extends StatefulWidget {
  const MobileScreen({super.key});

  @override
  State<MobileScreen> createState() => _MobileScreenState();
}

class _MobileScreenState extends State<MobileScreen> {
  // Define the apps list.
  final List<DesktopApp> _allApps = [
    DesktopApp(
      name: 'Finder',
      icon: CupertinoIcons.folder_badge_person_crop,
      color: Color(0xFF3B99FC),
      child: PdfViewer(),
    ),
    DesktopApp(
      name: 'Safari',
      icon: CupertinoIcons.globe,
      color: Color(0xFF0A84FF),
      child: SearchEngineScreen(),
    ),
    DesktopApp(
      name: 'Mail',
      icon: CupertinoIcons.mail,
      color: Color(0xFF007AFF),
      child: MailScreen(),
    ),
    DesktopApp(
      name: 'Messages',
      icon: CupertinoIcons.chat_bubble,
      color: Color(0xFF34C759),
      child: MacOSMessengerScreen(),
    ),
    DesktopApp(
      name: 'Photos',
      icon: CupertinoIcons.photo,
      color: Color(0xFFFF9500),
      child: Container(), // Placeholder
    ),
    DesktopApp(
      name: 'Music',
      icon: CupertinoIcons.music_note,
      color: Color(0xFFFF2D55),
      child: MainMusicScreen(),
    ),
    DesktopApp(
      name: 'Notes',
      icon: CupertinoIcons.pencil_circle,
      color: Color(0xFFFFCC00),
      child: MacOSNotesScreen(),
    ),
    DesktopApp(
      name: 'Calendar',
      icon: CupertinoIcons.calendar,
      color: Color(0xFFFF3B30),
      child: MacOSCalendarScreen(),
    ),
    DesktopApp(
      name: 'Calculator',
      icon: Icons.calculate,
      color: Colors.amber,
      child: CalculatorScreen(),
    ),
  ];

  // Helper to get time for status bar
  String _getTimeString() {
    final now = DateTime.now();
    return '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }

  void _openApp(DesktopApp app) {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => app.child),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Split apps: First 4 for dock, the rest for the home grid
    final dockApps = _allApps.sublist(0, 4);
    final gridApps = _allApps.sublist(4);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 1. Wallpaper
            _buildWallpaper(),

            // 2. Safe Area Content
            Column(
              children: [
                // Fake iOS Status Bar
                _buildFakeStatusBar(),

                const SizedBox(height: 20),

                // 3. App Grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 25,
                            crossAxisSpacing: 15,
                            childAspectRatio:
                                0.8, // Adjusts icon+label height ratio
                          ),
                      itemCount: gridApps.length,
                      itemBuilder: (context, index) {
                        return _buildAppIcon(gridApps[index]);
                      },
                    ),
                  ),
                ),

                // 4. Page Indicator (Dots)
                _buildPageIndicator(),

                // 5. Dock
                _buildDock(dockApps),

                // Bottom Safe Area
                SizedBox(height: MediaQuery.of(context).padding.bottom + 5),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- WIDGETS ----------------

  Widget _buildWallpaper() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1511300636408-a63a89df3482?q=80&w=1470&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        color: Colors.black.withOpacity(
          0.1,
        ), // Slight dimming for better contrast
      ),
    );
  }

  Widget _buildFakeStatusBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _getTimeString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              Icon(
                CupertinoIcons.antenna_radiowaves_left_right,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 5),
              Icon(CupertinoIcons.wifi, color: Colors.white, size: 16),
              const SizedBox(width: 5),
              Icon(CupertinoIcons.battery_full, color: Colors.white, size: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppIcon(DesktopApp app) {
    return GestureDetector(
      onTap: () => _openApp(app),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon Container
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: app.color,
              borderRadius: BorderRadius.circular(
                14,
              ), // iOS rounded super-ellipse style
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(app.icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 6),
          // Label
          Text(
            app.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDock(List<DesktopApp> dockApps) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 15),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 85,
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: dockApps.map((app) => _buildDockIcon(app)).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDockIcon(DesktopApp app) {
    return GestureDetector(
      onTap: () => _openApp(app),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: app.color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(app.icon, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 6,
            width: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == 0 ? Colors.white : Colors.white.withOpacity(0.4),
            ),
          );
        }),
      ),
    );
  }
}
