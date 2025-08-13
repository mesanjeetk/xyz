import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const platform = MethodChannel("com.example.universal_link_opener");

  Future<void> openLink(String url) async {
    try {
      await platform.invokeMethod("openLink", {"url": url});
    } on PlatformException catch (e) {
      debugPrint("Error opening link: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("Universal Link Opener")),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ElevatedButton(
              onPressed: () => openLink("https://youtu.be/e4_uY4YEv-I?si=SVRPPRqhtJMfrsGZ"),
              child: const Text("Open YouTube"),
            ),
            ElevatedButton(
              onPressed: () => openLink("https://www.instagram.com/reel/DLMJRQJzcVc/?igsh=d3BmNjd6cGdycjFy"),
              child: const Text("Open Instagram"),
            )
          ],
        ),
      ),
    );
  }
}
