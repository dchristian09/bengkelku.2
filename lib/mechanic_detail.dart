import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MechanicDetailScreen extends StatefulWidget {
  final String token;
  final int mechanicId;
  final String userRole;

  const MechanicDetailScreen({Key? key, required this.token, required this.mechanicId, required this.userRole}) : super(key: key);

  @override
  _MechanicDetailScreenState createState() => _MechanicDetailScreenState();
}

class _MechanicDetailScreenState extends State<MechanicDetailScreen> {
  late String mechanicName = '';
  late List<dynamic> transactions = [];
  late double totalHargaJasa = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchMechanicDetails();
  }

  Future<void> _fetchMechanicDetails() async {
    try {
      final response = await http.get(
        Uri.parse('https://bengkel-ku.com/public/api/mechanic/${widget.mechanicId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        setState(() {
          mechanicName = data['mechanic']['nama'];
        });
        _fetchMechanicTransactions();
      } else {
        print('Failed to fetch mechanic details: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching mechanic details: $error');
    }
  }

  Future<void> _fetchMechanicTransactions() async {
    try {
      final response = await http.get(
        Uri.parse('https://bengkel-ku.com/public/api/transactions?mechanic_id=${widget.mechanicId}&date=${DateTime.now().toString().substring(0, 10)}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        setState(() {
          transactions = data['transactions'];
          totalHargaJasa = transactions.fold(0, (sum, transaction) => sum + double.parse(transaction['harga_jasa'].toString()));
        });
      } else {
        print('Failed to fetch mechanic transactions: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching mechanic transactions: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mechanic Detail'),
        actions: [
          if(widget.userRole != "mechanic")
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _deleteItem();
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Mechanic Name: $mechanicName',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Total Pendapatan Hari Ini: $totalHargaJasa',
              style: TextStyle(fontSize: 18),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return ListTile(
                  title: Text('Plat Nomor: ${transaction['plat_nomor']}'),
                  subtitle: Text('Harga Jasa: ${transaction['harga_jasa']}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem() async {
    try {
      final response = await http.delete(
        Uri.parse('https://bengkel-ku.com/public/api/mechanic/${widget.mechanicId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        Navigator.pop(context, true);
      } else {
        print('Failed to delete mechanic: ${response.statusCode}');
      }
    } catch (error) {
      print('Error deleting item: $error');
    }
  }
}
