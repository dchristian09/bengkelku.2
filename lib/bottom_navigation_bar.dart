import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'inventory_screen.dart';
import 'mechanic_screen.dart';
import 'profile_screen.dart';

class BottomNavigationBarWidget extends StatefulWidget {
  final String token;
  final String bengkelId;
  final String userId;
  final String userRole;

  const BottomNavigationBarWidget({super.key, required this.token, required this.bengkelId, required this.userId, required this.userRole});

  @override
  _BottomNavigationBarWidgetState createState() => _BottomNavigationBarWidgetState();
}

class _BottomNavigationBarWidgetState extends State<BottomNavigationBarWidget> {
  int _selectedIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(token: widget.token, bengkelId: widget.bengkelId, userId: widget.userId, userRole: widget.userRole,),
      InventoryScreen(token: widget.token, bengkelId: widget.bengkelId, userRole: widget.userRole),
      if(widget.userRole != "kasir")
      MechanicScreen(token: widget.token, bengkelId: widget.bengkelId, userRole: widget.userRole),
      ProfileScreen(token: widget.token, bengkelId: widget.bengkelId, userId: widget.userId, userRole: widget.userRole),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
            backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Inventory',
            backgroundColor: Colors.black,
          ),
          if(widget.userRole != "kasir")
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Mechanic',
            backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
            backgroundColor: Colors.black,
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
