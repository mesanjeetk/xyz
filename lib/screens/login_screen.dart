import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text("Login"),
            ),
            TextButton(
              onPressed: () => context.go('/register'),
              child: const Text("Go to Register"),
            ),
          ],
        ),
      ),
    );
  }
}
