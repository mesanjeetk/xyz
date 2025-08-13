import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  static const _channel = MethodChannel('com.sanjeet.universalops/channel');

  // -------- Link Opening --------
  Future<void> openLink(String url, {String? packageName}) async {
    try {
      await _channel.invokeMethod("openLink", {
        "url": url,
        "packageName": packageName, // optional
      });
    } on PlatformException catch (e) {
      debugPrint("openLink error: ${e.message}");
    }
  }

  // -------- Notifications --------
  Future<void> requestNotificationPermission() async {
    try {
      await _channel.invokeMethod("requestNotificationPermission");
    } catch (e) {
      debugPrint("requestNotificationPermission error: $e");
    }
  }

  Future<void> showPersistentNotification({
    required String title,
    required String text,
    String? imageUrl,
  }) async {
    try {
      await _channel.invokeMethod("showNotification", {
        "title": title,
        "text": text,
        "imageUrl": imageUrl ?? "",
      });
    } catch (e) {
      debugPrint("showNotification error: $e");
    }
  }

  Future<void> updatePersistentNotification({
    String? title,
    String? text,
    String? imageUrl,
  }) async {
    try {
      await _channel.invokeMethod("updateNotification", {
        "title": title,
        "text": text,
        "imageUrl": imageUrl ?? "",
      });
    } catch (e) {
      debugPrint("updateNotification error: $e");
    }
  }

  Future<void> stopPersistentNotification() async {
    try {
      await _channel.invokeMethod("stopNotification");
    } catch (e) {
      debugPrint("stopNotification error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Universal Ops',
      home: Scaffold(
        appBar: AppBar(title: const Text('Universal Ops (Flutter + Kotlin)')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text("Link opener", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => openLink(
                "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
                packageName: "com.google.android.youtube", // optional force + Play Store fallback
              ),
              child: const Text("Open YouTube link (force YouTube)"),
            ),
            ElevatedButton(
              onPressed: () => openLink("https://twitter.com/elonmusk/status/123"),
              child: const Text("Open Twitter/X link (WhatsApp-style)"),
            ),
            ElevatedButton(
              onPressed: () => openLink(
                "https://www.instagram.com/p/Cxyz",
                packageName: "com.instagram.android",
              ),
              child: const Text("Open Instagram (force app)"),
            ),
            const SizedBox(height: 24),
            const Text("Persistent notification", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                await requestNotificationPermission();
                await showPersistentNotification(
                  title: "Chill Lo-Fi",
                  text: "Now playing • 2:34 / 3:50",
                  imageUrl: "https://upload.wikimedia.org/wikipedia/commons/7/74/Lo-fi_music_logo.png",
                );
              },
              child: const Text("Show persistent notification"),
            ),
            ElevatedButton(
              onPressed: () => updatePersistentNotification(
                title: "Chill Lo-Fi (Paused)",
                text: "Paused • 2:34 / 3:50",
              ),
              child: const Text("Update notification (Paused)"),
            ),
            ElevatedButton(
              onPressed: () => stopPersistentNotification(),
              child: const Text("Stop notification"),
            ),
          ],
        ),
      ),
    );
  }
}
