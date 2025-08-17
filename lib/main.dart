import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: UrlLauncherPage(),
    );
  }
}

class UrlLauncherPage extends StatefulWidget {
  @override
  _UrlLauncherPageState createState() => _UrlLauncherPageState();
}

class _UrlLauncherPageState extends State<UrlLauncherPage> {
  static const platform = MethodChannel('com.example.app/launcher');
  final TextEditingController _controller = TextEditingController();

  Future<void> _launchUrl() async {
    final url = _controller.text.trim();
    if (url.isEmpty) return;

    try {
      await platform.invokeMethod('openUrl', {'url': url});
    } on PlatformException catch (e) {
      print("Failed to launch URL: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('App Launcher')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                  labelText: 'Enter URL',
                  border: OutlineInputBorder()
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _launchUrl,
              child: Text('Open URL'),
            ),
          ],
        ),
      ),
    );
  }
}
