import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MacOSMessengerScreen extends StatefulWidget {
  const MacOSMessengerScreen({super.key});

  @override
  State<MacOSMessengerScreen> createState() => _MacOSMessengerScreenState();
}

class _MacOSMessengerScreenState extends State<MacOSMessengerScreen> {
  final TextEditingController _controller = TextEditingController();
  final String phoneNumber = "919999999999";

  void _sendToWhatsApp() async {
    final text = Uri.encodeComponent(_controller.text);
    if (text.isEmpty) return;
    final url = Uri.parse("https://wa.me/$phoneNumber?text=$text");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 700;

          return Row(
            children: [
              // Sidebar (macOS style)
              if (isWide)
                Container(
                  width: 300,
                  color: CupertinoColors.systemGroupedBackground,
                  child: Column(
                    children: [
                      const SizedBox(height: 50),
                      _buildSidebarSearch(),
                      Expanded(child: _buildChatList()),
                    ],
                  ),
                ),

              // Main Chat Area
              Expanded(
                child: Container(
                  color: CupertinoColors.white,
                  child: Column(
                    children: [
                      _buildMacHeader(),
                      const Expanded(child: _ChatPlaceholder()),
                      _buildMessageBar(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMacHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 40, bottom: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CupertinoColors.systemGrey5)),
      ),
      child: const Center(
        child: Column(
          children: [
            Text(
              "To: +91 99999 99999",
              style: TextStyle(
                fontWeight: FontWeight.w400,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarSearch() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: CupertinoSearchTextField(
        placeholder: "Search",
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      itemCount: 1,
      itemBuilder: (context, index) => Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: CupertinoColors.activeBlue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          "Support Team",
          style: TextStyle(color: CupertinoColors.white),
        ),
      ),
    );
  }

  Widget _buildMessageBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(
              CupertinoIcons.add_circled,
              color: CupertinoColors.systemGrey,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CupertinoTextField(
                controller: _controller,
                placeholder: "iMessage",
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey4),
                  borderRadius: BorderRadius.circular(20),
                ),
                suffix: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _sendToWhatsApp,
                    child: const Icon(
                      CupertinoIcons.arrow_up_circle_fill,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatPlaceholder extends StatelessWidget {
  const _ChatPlaceholder();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: CupertinoColors.activeBlue,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              "Hi! I'm Aman Kumar. How can I help you?",
              style: TextStyle(color: CupertinoColors.white),
            ),
          ),
        ),
      ],
    );
  }
}
