import 'package:bengkelku/transaction_detail.dart';
import 'package:bengkelku/transaction_form.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  final String token;
  final String bengkelId;
  final String userId;
  final String userRole;
  

  const HomeScreen({super.key, required this.token, required this.bengkelId, required this.userId, required this.userRole});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _showCalendar = false;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchTransactions(_selectedDate);
    print(_transactions);
  }

  Future<void> _fetchTransactions(DateTime selectedDate) async {
  try {
    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    final response = await http.get(
      Uri.parse('https://bengkel-ku.com/public/api/transaction?date=$formattedDate&bengkel_id=${widget.bengkelId}'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (response.statusCode == 200) {
      final dynamic data = json.decode(response.body);
      if (data is Map<String, dynamic> && data.containsKey('transactions')) {
        final List<dynamic> transactions = data['transactions'];
        setState(() {
          _transactions = transactions;
        });
        print(_transactions);
      } else {
        print('Error: Expected a Map<String, dynamic> with key "transactions" but received: $data');
      }
    } else {
      print('Failed to fetch transactions: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  } catch (error) {
    print('Error fetching transactions: $error');
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Home Screen',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        setState(() {
                          _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                        });
                        _fetchTransactions(_selectedDate);
                      },
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showCalendar = true;
                        });
                      },
                      child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () {
                        setState(() {
                          _selectedDate = _selectedDate.add(const Duration(days: 1));
                        });
                        _fetchTransactions(_selectedDate);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _transactions.isEmpty
                ? const Center(
                    child: Text(
                      'No transactions for this date',
                      style: TextStyle(fontSize: 16.0),
                    ),
                  )
                : ListView.builder(
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _transactions[index];
                      return GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TransactionDetailScreen(
                                itemId: transaction['id'],
                                token: widget.token,
                                bengkelId: widget.bengkelId,
                                userId: widget.userId,
                                userRole: widget.userRole,
                                
                              ),
                            ),
                          );
                          if (result == true) {
                            _fetchTransactions(_selectedDate);
                          }
                        },
                        child: ListTile(
                          title: Text(
                            transaction['plat_nomor'] ?? 'No Plat Nomor',
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transaction['status_transaksi'] ?? 'Status Unavailable',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          if (_showCalendar)
            TableCalendar(
              focusedDay: _selectedDate,
              firstDay: DateTime.utc(2022, 1, 1),
              lastDay: DateTime.utc(2025, 12, 31),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDate = selectedDay;
                  _showCalendar = false; 
                });
                _fetchTransactions(selectedDay);
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TransactionFormPage(token: widget.token, bengkelId: widget.bengkelId, userId: widget.userId, itemId: -1,)),
          );
          if (result == true) {
            _fetchTransactions(_selectedDate);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
