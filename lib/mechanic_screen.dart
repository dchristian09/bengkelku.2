import 'package:bengkelku/mechanic_detail.dart';
import 'package:bengkelku/mechanic_form.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MechanicScreen extends StatefulWidget {
  final String token;
  final String bengkelId;
  final String userRole;

  const MechanicScreen({super.key, required this.token, required this.bengkelId, required this.userRole});

  @override
  _MechanicScreenState createState() => _MechanicScreenState();
}

class _MechanicScreenState extends State<MechanicScreen> {
  List<Map<String, dynamic>> _mechanicList = [];

  @override
  void initState() {
    super.initState();
    print('Token received in MechanicScreen: ${widget.token}');
    _fetchMechanicList();
  }

  Future<void> _fetchMechanicList() async {
    try {
      final response = await http.get(
        Uri.parse('https://bengkel-ku.com/public/api/mechanic?bengkel_id=${widget.bengkelId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data != null && data['mechanic'] != null) {
          final List<dynamic> mechanics = data['mechanic'];
          setState(() {
            _mechanicList = List<Map<String, dynamic>>.from(mechanics);
          });
        } else {
          print('Error: Unexpected data format or null data. Response body: ${response.body}');
        }
      } else {
        print('Failed to fetch mechanic list: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching mechanic list: $error');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            color: Colors.blue,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  'Mechanic Screen',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _mechanicList.length,
              itemBuilder: (context, index) {
                final mechanic = _mechanicList[index];
                return GestureDetector(
                  onTap: () async{
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MechanicDetailScreen(mechanicId: mechanic['id'], token: widget.token, userRole: widget.userRole)), 
                    );
                    if (result == true) {
                        _fetchMechanicList();
                    }
                  },
                  child: ListTile(
                    title: Text(mechanic['nama'] ?? ''),
                    subtitle: Text('Mekanik ${index+1}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MechanicFormPage(token: widget.token, bengkelId: widget.bengkelId,)),
          );
          if (result == true) {
            _fetchMechanicList();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

