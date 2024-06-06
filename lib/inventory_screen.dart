import 'package:flutter/material.dart';
import 'package:bengkelku/inventory_detail.dart';
import 'package:bengkelku/inventory_form.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class InventoryScreen extends StatefulWidget {
  final String token;
  final String bengkelId;
  final String userRole;

  const InventoryScreen({super.key, required this.token, required this.bengkelId, required this.userRole});

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Map<String, dynamic>> _inventoryList = [];

  @override
  void initState() {
    super.initState();
    _fetchInventoryList();
  }

  Future<void> _fetchInventoryList() async {
    try {
      final response = await http.get(
        Uri.parse('https://bengkel-ku.com/public/api/barang?bengkel_id=${widget.bengkelId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data != null && data['barangs'] != null) {
          final List<dynamic> barangs = data['barangs'];
          setState(() {
            _inventoryList = List<Map<String, dynamic>>.from(barangs);
          });
        } else {
          print('Error: Unexpected data format or null data. Response body: ${response.body}');
        }
      } else {
        print('Failed to fetch inventory list: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching inventory list: $error');
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
                  'Inventory Screen',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _inventoryList.length,
              itemBuilder: (context, index) {
                final inventory = _inventoryList[index];
                return ListTile(
                  title: Text(inventory['nama_barang'] ?? ''),
                  subtitle: Text(inventory['kode_barang'] ?? ''),
                  onTap: () async{
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => InventoryDetailScreen(itemId: inventory['id'], token: widget.token, bengkelId: widget.bengkelId, userRole: widget.userRole)),
                    );
                    if (result == true) {
                      _fetchInventoryList();
                    }
                  },
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
            MaterialPageRoute(builder: (context) => InventoryFormPage(token: widget.token, bengkelId: widget.bengkelId)),
          );
          if (result == true) {
            _fetchInventoryList();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
