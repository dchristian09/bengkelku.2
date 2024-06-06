import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class InventoryFormPage extends StatefulWidget {
  final String token;
  final String bengkelId;

  const InventoryFormPage({super.key, required this.token, required this.bengkelId});

  @override
  _InventoryFormPageState createState() => _InventoryFormPageState();
}

class _InventoryFormPageState extends State<InventoryFormPage> {
  final TextEditingController _namaBarangController = TextEditingController();
  final TextEditingController _kodeBarangController = TextEditingController();
  final TextEditingController _hargaJualBarangController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _namaBarangController.dispose();
    _kodeBarangController.dispose();
    _hargaJualBarangController.dispose();
    super.dispose();
  }

  Future<void> _simpanBarang() async {
    try {
      final response = await http.post(
        Uri.parse('https://bengkel-ku.com/public/api/barang/store'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
        body: {
          'nama_barang': _namaBarangController.text,
          'kode_barang': _kodeBarangController.text,
          'bengkel_id': widget.bengkelId,
          'harga_jual':_hargaJualBarangController.text,
        },
      );

      if (response.statusCode == 201) {
        print('Inventory saved successfully!');
        Navigator.pop(context, true); 
      } else if (response.statusCode == 422){
        print('Same inventory name exist: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama Barang Sudah Terpakai')),
      );
      }else{
        print('Failed to save inventory: ${response.body}');
      }
    } catch (error) {
      print('Error submitting form: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Inventaris'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _namaBarangController,
              decoration: const InputDecoration(
                labelText: 'Nama Barang',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _kodeBarangController,
              decoration: const InputDecoration(
                labelText: 'Kode Barang',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _hargaJualBarangController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Harga Jual Barang',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_namaBarangController.text.isNotEmpty && _hargaJualBarangController.text.isNotEmpty && _kodeBarangController.text.isNotEmpty){
                  _simpanBarang();
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
}
