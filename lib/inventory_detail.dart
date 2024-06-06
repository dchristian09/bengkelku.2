import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class InventoryDetailScreen extends StatefulWidget {
  final int itemId;
  final String token;
  final String bengkelId;
  final String userRole;

  const InventoryDetailScreen({Key? key, required this.itemId, required this.token, required this.bengkelId, required this.userRole}) : super(key: key);

  @override
  _InventoryDetailScreenState createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends State<InventoryDetailScreen> {
  final List<BarangMasuk> _listBarangMasuk = [];
  final _jumlahBarangController = TextEditingController();
  final _hargaModalController = TextEditingController();
  
  String _namaBarang = '';
  String _kodeBarang = '';
  String _hargaJualBarang = '';
  String totalJumlah = '';

  @override
  void initState() {
    super.initState();
    _fetchInventoryDetail();
    _fetchBarangMasuk();
  }

  Future<void> _fetchInventoryDetail() async {
    try {
      final response = await http.get(
        Uri.parse('https://bengkel-ku.com/public/api/barang/${widget.itemId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        final dynamic barangData = data['barang'];
        setState(() {
          _namaBarang = barangData['nama_barang'];
          _kodeBarang = barangData['kode_barang'];
          _hargaJualBarang = barangData['harga_jual'].toString();
        });
      } else {
        print('Failed to fetch inventory detail: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching inventory detail: $error');
    }
  }

  Future<void> _fetchBarangMasuk() async {
    try {
      final response = await http.get(
        Uri.parse('https://bengkel-ku.com/public/api/barang_masuk/${widget.itemId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        final List<dynamic> barangMasukList = data['barang_masuk'];

        setState(() {
          _listBarangMasuk.clear();
          for (final barangMasuk in barangMasukList) {
            _listBarangMasuk.add(
              BarangMasuk(
                id: barangMasuk['id'],
                jumlah: barangMasuk['kuantitas_barang'],
                hargaModal: barangMasuk['harga_modal'].toDouble(),
                tanggalMasuk: DateTime.parse(barangMasuk['created_at']),
              ),
            );
          }
        });
      } else {
        print('Failed to fetch barang masuk: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching barang masuk: $error');
    }
  }

  _editBarang(BuildContext context) {
    TextEditingController _nameController = TextEditingController();
    TextEditingController _codeController = TextEditingController();
    TextEditingController _hargaJualController = TextEditingController();

    _nameController.text = _namaBarang;
    _codeController.text = _kodeBarang;
    _hargaJualController.text = _hargaJualBarang.toString();

    String nameError = "";
    String kodeError = "";
    String hargaJualError = "";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Edit Barang'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Barang',
                      errorText: nameError.isNotEmpty ? nameError : null,
                    ),
                  ),
                  TextField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: 'Kode Barang',
                      errorText: kodeError.isNotEmpty ? kodeError : null
                    ),
                  ),
                  TextField(
                    controller: _hargaJualController,
                    decoration: InputDecoration(
                      labelText: 'Harga Jual Barang',
                      errorText: hargaJualError.isNotEmpty ? hargaJualError : null
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_nameController.text.isEmpty || _codeController.text.isEmpty || _hargaJualController.text.isEmpty){
                        if (_nameController.text.isEmpty) {
                          setState(() {
                            nameError = 'Harga barang tidak boleh kosong';
                          });
                        }else{
                          setState(() {
                            nameError = '';
                          });
                        }
                        if (_codeController.text.isEmpty) {
                          setState(() {
                            kodeError = 'Jumlah barang tidak boleh kosong';
                          });
                        }else{
                          setState(() {
                            kodeError = '';
                          });
                        }
                        if (_hargaJualController.text.isEmpty) {
                          setState(() {
                            hargaJualError = 'Harga jual barang tidak boleh kosong';
                          });
                        }else{
                          setState(() {
                            hargaJualError = '';
                          });
                        }
                        return;
                      }

                    final response = await http.put(
                      Uri.parse('https://bengkel-ku.com/public/api/barang/${widget.itemId}'),
                      headers: {'Authorization': 'Bearer ${widget.token}'},
                      body: {
                        'bengkel_id': widget.bengkelId,
                        'nama_barang': _nameController.text,
                        'kode_barang': _codeController.text,
                        'harga_jual': _hargaJualController.text
                      },
                    );
                    if (response.statusCode == 200) {
                      await _fetchInventoryDetail();
                      print('Barang updated successfully.');
                      Navigator.pop(context);
                    } else if (response.statusCode == 422) {
                      setState(() {
                        nameError = "Nama barang sudah terpakai";
                      });
                    } else {
                      print('Failed to update barang: ${response.statusCode}');
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    int total = 0;
    for (var barangMasuk in _listBarangMasuk) {
      total += barangMasuk.jumlah;
    }
    totalJumlah = total.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Detail Screen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _deleteItem();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nama Barang: $_namaBarang'),
            Text('Kode Barang: $_kodeBarang'),
            Text('Harga Jual Barang: $_hargaJualBarang'),
            const SizedBox(height: 10),
            Text('Total Jumlah: $totalJumlah'),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _listBarangMasuk.length,
                itemBuilder: (context, index) {
                  final barangMasuk = _listBarangMasuk[index];
                  final tanggalMasuk = DateFormat('yyyy-MM-dd').format(barangMasuk.tanggalMasuk);

                  return ListTile(
                    title: Text('Jumlah: ${barangMasuk.jumlah}'),
                    subtitle: Text('Harga Modal: ${barangMasuk.hargaModal}\nTanggal Masuk: $tanggalMasuk'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if(widget.userRole != "kasir")
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            _editBarangMasuk(barangMasuk);
                          },
                        ),
                        if(widget.userRole != "kasir")
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            _hapusBarangMasuk(barangMasuk);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _editBarang(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _tambahBarangDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Tambah Barang'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _tambahBarangDialog(BuildContext context) {
    String jumlahBarangError = "";
    String hargaModalError= "";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Tambah Jumlah'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _jumlahBarangController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Jumlah Barang',
                      errorText: jumlahBarangError.isNotEmpty ? jumlahBarangError : null,
                    ),
                  ),
                  TextFormField(
                    controller: _hargaModalController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Harga Modal Barang',
                      errorText: hargaModalError.isNotEmpty ? hargaModalError : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      if (_jumlahBarangController.text.isEmpty || _hargaModalController.text.isEmpty){
                        if (_jumlahBarangController.text.isEmpty) {
                          setState(() {
                            jumlahBarangError = 'Harga barang tidak boleh kosong';
                          });
                        }else{
                          setState(() {
                            jumlahBarangError = '';
                          });
                        }
                        if (_hargaModalController.text.isEmpty) {
                          setState(() {
                            hargaModalError = 'Jumlah barang tidak boleh kosong';
                          });
                        }else{
                          setState(() {
                            hargaModalError = '';
                          });
                        }
                        return;
                      }
                      Navigator.pop(context);
                        _addBarangMasuk();
                    },
                    child: const Text('Tambah'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _jumlahBarangController.clear();
                      _hargaModalController.clear();
                    },
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }





  Future<void> _addBarangMasuk() async {
    try {
      if (_jumlahBarangController.text.isNotEmpty && _hargaModalController.text.isNotEmpty) {
        final jumlah = int.parse(_jumlahBarangController.text);
        final hargaModal = double.parse(_hargaModalController.text);

        final response = await http.post(
          Uri.parse('https://bengkel-ku.com/public/api/barang_masuk/store'),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer ${widget.token}',
          },
          body: jsonEncode(<String, dynamic>{
            'barang_id': widget.itemId,
            'kuantitas_barang': jumlah,
            'harga_modal': hargaModal,
          }),
        );

        if (response.statusCode == 201) {
          final List<dynamic> responseData = json.decode(response.body);
          if (responseData.isNotEmpty && responseData[0].containsKey('id')){
            final newBarangMasuk = BarangMasuk(
              id: responseData[0]['id'],
              jumlah: responseData[0]['kuantitas_barang'],
              hargaModal: responseData[0]['harga_modal'] is int
                ? responseData[0]['harga_modal'].toDouble()
                :double.parse(responseData[0]['harga_modal']),
              tanggalMasuk: DateTime.parse(responseData[0]['created_at']),
            );
            setState(() {
              _listBarangMasuk.add(newBarangMasuk);
              _jumlahBarangController.text = "";
              _hargaModalController.text = "";
            });
          }else {
            print('Error: Response body does not contain the "id" field');
          }
        } else {
          print('Failed to add barang masuk: ${response.statusCode}');
        }
      } else {
        print('fields empty');
      }
    } catch (error) {
      print('Error adding barang masuk: $error');
    }
  }

  Future<void> _deleteItem() async {
    try {
      final response = await http.delete(
        Uri.parse('https://bengkel-ku.com/public/api/barang/${widget.itemId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        Navigator.pop(context, true);
      } else {
        print('Failed to delete item: ${response.statusCode}');
      }
    } catch (error) {
      print('Error deleting item: $error');
    }
  }

  void _editBarangMasuk(BarangMasuk barangMasuk) {
    // setState(() {
    //   _jumlahBarangController.text = barangMasuk.jumlah.toString();
    //   _hargaModalController.text = barangMasuk.hargaModal.toString();
    // });
    String jumlahBarangError = "";
    String hargaModalError= "";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState){
            return AlertDialog(
              title: Text('Edit Barang Masuk'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _jumlahBarangController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Jumlah Barang',
                      errorText: jumlahBarangError.isNotEmpty ? jumlahBarangError : null,
                    ),
                  ),
                  TextFormField(
                    controller: _hargaModalController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Harga Modal Barang',
                          errorText: hargaModalError.isNotEmpty ? hargaModalError : null,
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      if (_jumlahBarangController.text.isEmpty || _hargaModalController.text.isEmpty){
                        if (_jumlahBarangController.text.isEmpty) {
                          setState(() {
                            jumlahBarangError = 'Harga barang tidak boleh kosong';
                          });
                        }else{
                          setState(() {
                            jumlahBarangError = '';
                          });
                        }
                        if (_hargaModalController.text.isEmpty) {
                          setState(() {
                            hargaModalError = 'Jumlah barang tidak boleh kosong';
                          });
                        }else{
                          setState(() {
                            hargaModalError = '';
                          });
                        }
                        return;
                      }
                      _simpanPerubahan(barangMasuk);
                      Navigator.pop(context);
                    },
                    child: Text('Simpan Perubahan'),
                  ),
                ],
              ),
            );
        });
      },
    );
  }

  Future<void> _hapusBarangMasuk(BarangMasuk barangMasuk) async {
    try {
      final response = await http.delete(
        Uri.parse('https://bengkel-ku.com/public/api/barang_masuk/${barangMasuk.id}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _listBarangMasuk.remove(barangMasuk);
        });
      } else {
        print('Failed to delete barang masuk: ${response.statusCode}');
      }
    } catch (error) {
      print('Error deleting barang masuk: $error');
    }
  }

  Future<void> _simpanPerubahan(BarangMasuk barangMasuk) async {
    try {
      if (_jumlahBarangController.text.isNotEmpty && _hargaModalController.text.isNotEmpty) {
        final jumlah = int.parse(_jumlahBarangController.text);
        final hargaModal = double.parse(_hargaModalController.text);
        
        final Map<String, dynamic> data = {
          'kuantitas_barang': jumlah,
          'harga_modal': hargaModal,
        };

        final response = await http.put(
          Uri.parse('https://bengkel-ku.com/public/api/barang_masuk/${barangMasuk.id}'),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
            'Content-Type': 'application/json',
          },
          body: json.encode(data),
        );

        if (response.statusCode == 200) {
          setState(() {
            barangMasuk.jumlah = jumlah;
            barangMasuk.hargaModal = hargaModal;
          });
        } else {
          print('Failed to update barang masuk: ${response.statusCode}');
        }
      } else {
        print("Textfields empty");
      }
    } catch (error) {
      print('Error updating barang masuk: $error');
    }
  }

  @override
  void dispose() {
    _jumlahBarangController.dispose();
    _hargaModalController.dispose();
    super.dispose();
  }
}

class BarangMasuk {
  final int id;
  int jumlah;
  double hargaModal;
  final DateTime tanggalMasuk;

  BarangMasuk({required this.id, required this.jumlah, required this.hargaModal, required this.tanggalMasuk});
}
