import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  static const platform = MethodChannel("com.example.floating/widget");

  void showOverlay() async {
    try {
      await platform.invokeMethod("showOverlay");
    } on PlatformException catch (e) {
      print("Failed to show overlay: ${e.message}");
    }
  }

  void closeOverlay() async {
    try {
      await platform.invokeMethod("closeOverlay");
    } on PlatformException catch (e) {
      print("Failed to close overlay: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Overlay Example',
      home: Scaffold(
        appBar: AppBar(title: Text("Overlay Demo")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: showOverlay,
                child: Text("Show Floating Widget"),
              ),
              ElevatedButton(
                onPressed: closeOverlay,
                child: Text("Close Floating Widget"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
