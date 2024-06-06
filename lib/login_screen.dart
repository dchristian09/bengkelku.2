import 'dart:convert';

import 'mechanic_detail.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'bottom_navigation_bar.dart';
import 'register_screen.dart';

void main() {
  runApp(const LoginScreen());
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Form',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Login Form'),
        ),
        body: const LoginForm(),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    try {
      final response = await http.post(
        Uri.parse('https://bengkel-ku.com/public/api/login'),
        body: {
          'username': _usernameController.text.trim(),
          'password': _passwordController.text.trim(),
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final String token = responseData['token'];
        final String bengkelId = responseData['user']['bengkel_id'].toString();
        final String userId = responseData['user']['id'].toString();
        final String userRole = responseData['user']['role'].toString();
        int mechanicId = responseData['user']['mechanic_id'] ?? 0;

        if (userRole != "mechanic")
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BottomNavigationBarWidget(token: token, bengkelId: bengkelId, userId: userId, userRole: userRole)),
        );
        if (userRole == "mechanic")
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MechanicDetailScreen(token: token, mechanicId: mechanicId, userRole: userRole,)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username atau password tidak valid')),
        );
      }
    } catch (error) {
      print('Error logging in: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20.0),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 20.0),
          ElevatedButton(
            onPressed: () {
                if (_usernameController.text.isEmpty ||
                    _passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields')),
                  );
                } else {
                  _login();
                }
              },
            
            child: const Text('Login'),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterScreen()),
              );
            },
            child: const Text('Belum punya akun? Register Disini'),
          ),
        ],
      ),
    );
  }
}
