import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

// Overlay entry point - This is called from Kotlin side
@pragma("vm:entry-point") 
void overlayMain() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: OverlayWidget(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Overlay Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const MethodChannel _channel = MethodChannel('com.example.overlay/channel');
  
  bool _isOverlayActive = false;

  @override
  void initState() {
    super.initState();
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'updateOverlayStatus':
        setState(() {
          _isOverlayActive = call.arguments as bool;
        });
        break;
      case 'closeApp':
        SystemNavigator.pop();
        break;
    }
  }

  Future<void> _checkOverlayPermission() async {
    try {
      final bool hasPermission = await _channel.invokeMethod('hasOverlayPermission');
      if (!hasPermission) {
        _requestOverlayPermission();
      } else {
        _showOverlay();
      }
    } on PlatformException catch (e) {
      print("Failed to check permission: ${e.message}");
    }
  }

  Future<void> _requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } on PlatformException catch (e) {
      print("Failed to request permission: ${e.message}");
    }
  }

  Future<void> _showOverlay() async {
    try {
      await _channel.invokeMethod('showOverlay');
    } on PlatformException catch (e) {
      print("Failed to show overlay: ${e.message}");
    }
  }

  Future<void> _hideOverlay() async {
    try {
      await _channel.invokeMethod('hideOverlay');
    } on PlatformException catch (e) {
      print("Failed to hide overlay: ${e.message}");
    }
  }

  Future<void> _updateOverlayContent() async {
    try {
      await _channel.invokeMethod('updateOverlay', {
        'text': 'Updated at ${DateTime.now().toLocal()}',
        'color': Colors.red.value,
      });
    } on PlatformException catch (e) {
      print("Failed to update overlay: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Overlay Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Overlay Status: ${_isOverlayActive ? "Active" : "Inactive"}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _checkOverlayPermission,
              child: const Text('Show Floating Widget'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isOverlayActive ? _hideOverlay : null,
              child: const Text('Hide Floating Widget'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isOverlayActive ? _updateOverlayContent : null,
              child: const Text('Update Overlay Content'),
            ),
            const SizedBox(height: 30),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructions:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text('1. Tap "Show Floating Widget" to create overlay'),
                    Text('2. Grant "Display over other apps" permission when prompted'),
                    Text('3. The floating widget will appear and can be dragged around'),
                    Text('4. The widget remains visible even when using other apps'),
                    Text('5. Use "Hide Floating Widget" to remove the overlay'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Overlay Widget that appears as floating window
class OverlayWidget extends StatefulWidget {
  const OverlayWidget({Key? key}) : super(key: key);

  @override
  State<OverlayWidget> createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<OverlayWidget> {
  static const MethodChannel _channel = MethodChannel('com.example.overlay/overlay_channel');
  
  String _displayText = 'Floating Widget';
  Color _bgColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _channel.setMethodCallHandler(_handleOverlayMethodCall);
  }

  Future<dynamic> _handleOverlayMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'updateContent':
        final args = call.arguments as Map;
        setState(() {
          _displayText = args['text'] ?? _displayText;
          _bgColor = Color(args['color'] ?? Colors.blue.value);
        });
        break;
    }
  }

  Future<void> _closeOverlay() async {
    try {
      await _channel.invokeMethod('closeOverlay');
    } on PlatformException catch (e) {
      print("Failed to close overlay: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 150,
        height: 100,
        decoration: BoxDecoration(
          color: _bgColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.widgets,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _displayText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: _closeOverlay,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 14,
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
