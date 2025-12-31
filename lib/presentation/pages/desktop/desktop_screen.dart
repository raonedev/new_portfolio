import 'dart:ui';
import 'package:aman_protfolio/presentation/pages/apps/calculator/calculator.dart';
import 'package:aman_protfolio/presentation/pages/apps/musicplayer/screens/main_screen.dart';
import 'package:flutter/material.dart';

import 'models/desktop_app.dart';
import 'widgets/draggable_window.dart';

class Desktop extends StatefulWidget {
  const Desktop({super.key});

  @override
  State<Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<Desktop> {
  final List<DesktopApp> apps = [
    DesktopApp(
      name: 'Finder',
      icon: Icons.folder,
      color: Color(0xFF3B99FC),
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Color(0xFF3B99FC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.folder, size: 32, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Finder',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Version 1.0',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to Finder!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This is a draggable macOS-style window. You can:\n\n'
              '• Drag the window by clicking and moving the title bar\n'
              '• Close the window (red button)\n'
              '• Minimize the window (yellow button)\n'
              '• Maximize/restore the window (green button)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    ),
    DesktopApp(
      name: 'Safari',
      icon: Icons.public,
      color: Color(0xFF0A84FF),
      child: Container(),
    ),
    DesktopApp(
      name: 'Mail',
      icon: Icons.mail,
      color: Color(0xFF007AFF),
      child: Container(),
    ),
    DesktopApp(
      name: 'Messages',
      icon: Icons.message,
      color: Color(0xFF34C759),
      child: Container(),
    ),
    DesktopApp(
      name: 'Photos',
      icon: Icons.photo_library,
      color: Color(0xFFFF9500),
      child: Container(),
    ),
    DesktopApp(
      name: 'Music',
      icon: Icons.music_note,
      color: Color(0xFFFF2D55),
      child: MainScreen(),
    ),
    DesktopApp(
      name: 'Notes',
      icon: Icons.note,
      color: Color(0xFFFFCC00),
      child: Container(),
    ),
    DesktopApp(
      name: 'Calendar',
      icon: Icons.calendar_today,
      color: Color(0xFFFF3B30),
      child: Container(),
    ),
    DesktopApp(
      name: 'Settings',
      icon: Icons.settings,
      color: Color(0xFF8E8E93),
      child: Container(),
    ),
    DesktopApp(
      name: 'Calculator',
      icon: Icons.calculate,
      color: Colors.amber,
      child: CalculatorScreen(),
    ),
  ];

  int? hoveredDockIndex;
  List<DesktopApp> openWindows = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _wallpaper(),
          _desktopGrid(),
          ...openWindows.asMap().entries.map((entry) {
            return KeyedSubtree(
              key: ValueKey(entry.value.name),
              child: _dialogOverlay(entry.value),
            );
          }),
          _topMenuBar(),
          _dock(),
        ],
      ),
    );
  }

  // ---------------- WALLPAPER ----------------
  Widget _wallpaper() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1511300636408-a63a89df3482?q=80&w=1470&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8',
          ),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // ---------------- TOP MENU BAR ----------------
  Widget _topMenuBar() {
    return Align(
      alignment: Alignment.topCenter,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.apple, size: 16, color: Colors.white),
                const SizedBox(width: 16),
                Text(
                  'Finder',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 20),
                ..._menuItems(['File', 'Edit', 'View', 'Go', 'Window']),
                Spacer(),
                Icon(Icons.battery_full, size: 16, color: Colors.white),
                const SizedBox(width: 12),
                Icon(Icons.wifi, size: 16, color: Colors.white),
                const SizedBox(width: 12),
                Icon(Icons.search, size: 16, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 13, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _menuItems(List<String> items) {
    return items.map((item) {
      return Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Text(item, style: TextStyle(fontSize: 13, color: Colors.white)),
      );
    }).toList();
  }

  // ---------------- DESKTOP GRID (Top-Right) ----------------
  Widget _desktopGrid() {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 48, right: 20),
        child: SizedBox(
          width: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate((apps.length / 1).ceil().clamp(0, 6), (
              index,
            ) {
              if (index >= apps.length) return SizedBox.shrink();
              final app = apps[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (!openWindows.any((w) => w.name == app.name)) {
                        openWindows.add(app);
                      }
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 64,
                        width: 64,
                        decoration: BoxDecoration(
                          color: app.color.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(app.icon, size: 36, color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        app.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ---------------- DOCK ----------------
  Widget _dock() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(
                  width: apps.length * 60,
                  margin: EdgeInsets.only(bottom: 10),
                  height: 60,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(apps.length, (index) {
                  return _buildDockIcon(index);
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDockIcon(int index) {
    final isHovered = hoveredDockIndex == index;
    final distance = hoveredDockIndex != null
        ? (index - hoveredDockIndex!).abs()
        : 0;

    double scale = 1.0;
    if (isHovered) {
      scale = 1.5;
    } else if (hoveredDockIndex != null && distance == 1) {
      scale = 1.25;
    } else if (hoveredDockIndex != null && distance == 2) {
      scale = 1.1;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => hoveredDockIndex = index),
      onExit: (_) => setState(() => hoveredDockIndex = null),
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (!openWindows.any((w) => w.name == apps[index].name)) {
              openWindows.add(apps[index]);
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          transformAlignment: Alignment.bottomCenter,
          transform: Matrix4.identity()..scale(scale, scale),
          child: Container(
            height: 48,
            width: 48,
            margin: EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: apps[index].color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(apps[index].icon, size: 28, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // ---------------- DIALOG OVERLAY ----------------
  Widget _dialogOverlay(DesktopApp app) {
    return DraggableWindow(
      appName: app.name,
      onBringToFront: () {
        setState(() {
          openWindows.removeWhere((w) => w.name == app.name);
          openWindows.add(app);
        });
      },
      app: app,
      onClose: () =>setState(() => openWindows.removeWhere((w) => w.name == app.name)),
      windowSize: app.name=="Calculator"?Size(400, 600):null,
    );
  }
}
