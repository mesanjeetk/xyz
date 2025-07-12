import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.go('/login'),
          child: const Text("Go to Login"),
        ),
      ),
    );
  }
}
