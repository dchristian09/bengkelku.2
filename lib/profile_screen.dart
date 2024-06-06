import 'dart:convert';
import 'package:bengkelku/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  final String token;
  final String bengkelId;
  final String userId;
  final String userRole;

  const ProfileScreen(
      {Key? key,
      required this.token,
      required this.bengkelId,
      required this.userId,
      required this.userRole})
      : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String username = "";
  late String namaBengkel = "";
  late String alamat = "";
  late String totalPendapatan = "";
  String message = "";
  int keuntunganBersih = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchBengkelData();
    _fetchKeuntunganBersih();
  }

  Future<void> _fetchUserData() async {
    try {
      final response = await http.get(
        Uri.parse('https://bengkel-ku.com/public/api/user/${widget.userId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        final dynamic userData = data['user'];

        setState(() {
          username = userData['username'];
        });
      } else {
        print('Failed to fetch user data: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching user data: $error');
    }
  }

  Future<void> _fetchBengkelData() async {
    try {
      final response = await http.get(
        Uri.parse('https://bengkel-ku.com/public/api/bengkel/${widget.bengkelId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        final dynamic bengkelData = data['bengkel'];

        setState(() {
          namaBengkel = bengkelData['nama_bengkel'];
          alamat = bengkelData['alamat'];
        });
      } else {
        print('Failed to fetch bengkel data: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching bengkel data: $error');
    }
  }

  Future<void> _fetchKeuntunganBersih() async {
    try {
      final response = await http.get(
        Uri.parse('https://bengkel-ku.com/public/api/keuntungan_bersih/${widget.bengkelId}?date=${DateTime.now().toString().substring(0, 10)}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        setState(() {
          keuntunganBersih = data['net_profit'] as int;
        });
      } else {
        print('Failed to fetch keuntungan bersih data: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching keuntungan bersih data: $error');
    }
  }

  void _addCashier(BuildContext context) {
    TextEditingController _usernameController = TextEditingController();
    TextEditingController _passwordController = TextEditingController();

    String usernameError = "";
    String passwordError = "";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState){
            return AlertDialog(
              title: const Text('Tambah Kasir'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(labelText: 'Username', errorText: usernameError.isNotEmpty ? usernameError : null),
                  ),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(labelText: 'Password', errorText: passwordError.isNotEmpty ? passwordError : null),
                    obscureText: true,
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty){
                      if (_usernameController.text.isEmpty) {
                        setState(() {
                          usernameError = 'Harga barang tidak boleh kosong';
                        });
                      }else{
                        setState(() {
                          usernameError = '';
                        });
                      }
                      if (_passwordController.text.isEmpty) {
                        setState(() {
                          passwordError = 'Jumlah barang tidak boleh kosong';
                        });
                      }else{
                        setState(() {
                          passwordError = '';
                        });
                      }
                      return;
                    }
                    final response = await http.post(
                      Uri.parse('https://bengkel-ku.com/public/api/user/store'),
                      headers: {'Authorization': 'Bearer ${widget.token}'},
                      body: {
                        'username': _usernameController.text,
                        'password': _passwordController.text,
                        'role': 'kasir',
                        'bengkel_id': widget.bengkelId,
                      },
                    );
                    if (response.statusCode == 200) {
                      print('New cashier added successfully.');
                    } else {
                      print('Failed to add new cashier: ${response.statusCode}');
                    }
                    Navigator.of(context).pop();
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          }
        );
        
      },
    );
  }

  void _editBengkel(BuildContext context) {
    TextEditingController _namaController = TextEditingController();
    TextEditingController _alamatController = TextEditingController();

    String namaError = "";
    String alamatError= "";

    setState(() {
      _namaController.text = namaBengkel;
      _alamatController.text = alamat;
    });

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState){
            return AlertDialog(
              title: Text("Edit Bengkel"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _namaController,
                    decoration: InputDecoration(
                      labelText: 'Nama Bengkel', 
                      errorText: namaError.isNotEmpty ? namaError : null,
                    ),
                  ),
                  TextFormField(
                    controller: _alamatController,
                    decoration: InputDecoration(
                      labelText: 'Alamat Bengkel', 
                      errorText: alamatError.isNotEmpty ? alamatError : null,
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_namaController.text.isEmpty || _alamatController.text.isEmpty){
                      if (_namaController.text.isEmpty) {
                        setState(() {
                          namaError = 'Harga barang tidak boleh kosong';
                        });
                      }else{
                        setState(() {
                          namaError = '';
                        });
                      }
                      if (_alamatController.text.isEmpty) {
                        setState(() {
                          alamatError = 'Jumlah barang tidak boleh kosong';
                        });
                      }else{
                        setState(() {
                          alamatError = '';
                        });
                      }
                      return;
                    }
                    final response = await http.put(
                      Uri.parse('https://bengkel-ku.com/public/api/bengkel/${widget.bengkelId}'),
                      headers: {'Authorization': 'Bearer ${widget.token}'},
                      body: {
                        'nama_bengkel': _namaController.text,
                        'alamat': _alamatController.text,
                      },
                    );
                    if (response.statusCode == 200) {
                      await _fetchBengkelData();
                      print('Bengkel address updated successfully.');
                    } else {
                      print('Failed to update bengkel address: ${response.statusCode}');
                    }
                    Navigator.of(context).pop();
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          }
        ); 
      },
    );
  }

  String _formatKeuntunganBersih() {
    return NumberFormat("#,##0", "en_US").format(keuntunganBersih);
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
                  'Profile Screen',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Username: $username',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                'Nama Bengkel: $namaBengkel',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                'Alamat: $alamat',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              if(widget.userRole != "kasir")
              Text(
                'Keuntungan Bersih Hari Ini: Rp${_formatKeuntunganBersih()}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 30),
              if(widget.userRole != "kasir")
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _addCashier(context);
                      },
                      child: const Text('Tambah Kasir'),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _editBengkel(context);
                      },
                      child: const Text('Edit Bengkel'),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    child: const Text('Keluar'),
                  ),
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}