import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MechanicFormPage extends StatefulWidget {
  final String token;
  final String bengkelId;

  const MechanicFormPage({super.key, required this.token, required this.bengkelId});

  @override
  _MechanicFormPageState createState() => _MechanicFormPageState();
}

class _MechanicFormPageState extends State<MechanicFormPage> {
  final TextEditingController _namaMekanikController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Mekanik'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _namaMekanikController,
              decoration: const InputDecoration(labelText: 'Nama Mekanik'),
            ),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                String namaMekanik = _namaMekanikController.text;
                String username = _usernameController.text;
                String password = _passwordController.text;
                if (_namaMekanikController.text.isNotEmpty && _usernameController.text.isNotEmpty && _passwordController.text.isNotEmpty){
                  print('masuk');
                  submitFormData(namaMekanik, username, password);
                }else{
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Harap isi semua bagian')),
                  );
                }  
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> submitFormData(String namaMekanik, String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('https://bengkel-ku.com/public/api/mechanic/store'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(<String, dynamic>{
          'username': username,
          'password': password,
          'role': 'mechanic',
          'bengkel_id': widget.bengkelId,
          'nama': namaMekanik,
          'pendapatan': 0,
        }),
      );

      if (response.statusCode == 201) {
        print('Form submitted successfully');
        Navigator.pop(context, true);
      } else if (response.statusCode == 302){
        print('Failed to submit form: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username telah digunakan')),
        );
      } else{
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrasi gagal')),
        );
      }
    } catch (error) {
      print('Error submitting form: $error');
    }
  }
}
