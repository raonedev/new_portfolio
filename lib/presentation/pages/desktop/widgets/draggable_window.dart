// ---------------- DRAGGABLE WINDOW WIDGET ----------------
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../models/desktop_app.dart';

class DraggableWindow extends StatefulWidget {
  final String appName;
  final DesktopApp app;
  final VoidCallback onClose;
  final VoidCallback onBringToFront; 

  const DraggableWindow({super.key, 
    required this.appName,
    required this.app,
    required this.onClose,
    required this.onBringToFront, 
  });

  @override
  State<DraggableWindow> createState() => _DraggableWindowState();
}

class _DraggableWindowState extends State<DraggableWindow> {
  Offset position = Offset(200, 150);
  bool isMinimized = false;
  bool isMaximized = false;
  Size windowSize = Size(600, 400);
  Offset? savedPosition;
  Size? savedSize;

  void bringToFront() {
    widget.onBringToFront(); // Call the callback
  }

  

  @override
  Widget build(BuildContext context) {
    if (isMinimized) return SizedBox.shrink();

    final effectivePosition = isMaximized ? Offset.zero : position;
    final effectiveSize = isMaximized 
        ? Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height - 28)
        : windowSize;

    return Positioned(
      left: effectivePosition.dx,
      top: effectivePosition.dy + 28,
      child: GestureDetector(
        onTapDown: (_) => bringToFront(),
        onPanUpdate: isMaximized ? null : (details) {
          setState(() {
            position = Offset(
              position.dx + details.delta.dx,
              position.dy + details.delta.dy,
            );
          });
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              width: effectiveSize.width,
              height: effectiveSize.height,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:  0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Title Bar
                  Container(
                    height: 40,
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        // Traffic Lights
                        GestureDetector(
                          onTap: widget.onClose,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Color(0xFFFF5F57),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.close,
                                size: 8,
                                color: Colors.black.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() => isMinimized = true);
                          },
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Color(0xFFFEBC2E),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.remove,
                                size: 8,
                                color: Colors.black.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            bringToFront();
                            setState(() {
                              if (isMaximized) {
                                isMaximized = false;
                                if (savedPosition != null) position = savedPosition!;
                                if (savedSize != null) windowSize = savedSize!;
                              } else {
                                isMaximized = true;
                                savedPosition = position;
                                savedSize = windowSize;
                              }
                            });
                          },
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Color(0xFF28C840),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                isMaximized ? Icons.fullscreen_exit : Icons.fullscreen,
                                size: 8,
                                color: Colors.black.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                        Spacer(),
                        Text(
                          widget.appName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Spacer(),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey.withValues(alpha: 0.3)),
                  // Content
                  Expanded(
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
                                  color: widget.app.color,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  widget.app.icon,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.appName,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'Version 1.0',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Welcome to ${widget.appName}!',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}