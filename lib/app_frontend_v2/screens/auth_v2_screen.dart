import 'package:flutter/material.dart';

class AuthV2Screen extends StatelessWidget {
  const AuthV2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Dravik Sign In',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                const TextField(
                  decoration: InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 10),
                const TextField(
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Sign In'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
