// Add to pubspec.yaml: url_launcher: ^6.2.2

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MailScreen extends StatefulWidget {
  const MailScreen({super.key});

  @override
  State<MailScreen> createState() => _MailScreenState();
}

class _MailScreenState extends State<MailScreen> {
  final _fromController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _fromController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final subject = Uri.encodeComponent(_subjectController.text);
    final body = Uri.encodeComponent(_bodyController.text);
    final from = Uri.encodeComponent(_fromController.text);

    final emailUrl = Uri.parse(
      'mailto:kumaraman33063@gmail.com?subject=$subject&body=$body',
    );

    try {
      if (await canLaunchUrl(emailUrl)) {
        await launchUrl(emailUrl, mode: LaunchMode.externalApplication);
      } else {
        _showError('Could not launch email client');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Column(
        children: [
          // Top Navigation Bar
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              border: Border(
                bottom: BorderSide(
                  color: Colors.black.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF007AFF),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 17)),
                ),
                const Spacer(),
                const Text(
                  'New Message',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _sendEmail,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF007AFF),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: const Icon(Icons.arrow_upward, size: 16),
                  label: const Text(
                    'Send',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),

          // Mail Compose Area
          Expanded(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // From Field
                    _buildFieldContainer(
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 80,
                            child: Text(
                              'From:',
                              style: TextStyle(
                                fontSize: 17,
                                color: Color(0xFF8E8E93),
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _fromController,
                              style: const TextStyle(
                                fontSize: 17,
                                color: Colors.black,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'your.email@example.com',
                                hintStyle: TextStyle(color: Color(0xFFC7C7CC)),
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    _buildDivider(),

                    // To Field (Read-only)
                    _buildFieldContainer(
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 80,
                            child: Text(
                              'To:',
                              style: TextStyle(
                                fontSize: 17,
                                color: Color(0xFF8E8E93),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5E5EA),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'kumaraman33063@gmail.com',
                                style: TextStyle(
                                  fontSize: 17,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    _buildDivider(),

                    // Subject Field
                    _buildFieldContainer(
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 80,
                            child: Text(
                              'Subject:',
                              style: TextStyle(
                                fontSize: 17,
                                color: Color(0xFF8E8E93),
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _subjectController,
                              style: const TextStyle(
                                fontSize: 17,
                                color: Colors.black,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Subject',
                                hintStyle: TextStyle(color: Color(0xFFC7C7CC)),
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a subject';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 1),

                    // Message Body
                    Container(
                      constraints: const BoxConstraints(minHeight: 400),
                      decoration: const BoxDecoration(color: Colors.white),
                      padding: const EdgeInsets.all(16),
                      child: TextFormField(
                        controller: _bodyController,
                        maxLines: null,
                        style: const TextStyle(
                          fontSize: 17,
                          color: Colors.black,
                          height: 1.4,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Message',
                          hintStyle: TextStyle(color: Color(0xFFC7C7CC)),
                          contentPadding: EdgeInsets.zero,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a message';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(color: Colors.white),
      child: child,
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.only(left: 96),
      color: const Color(0xFFC6C6C8),
    );
  }
}
