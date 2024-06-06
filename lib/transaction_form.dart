import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class TransactionFormPage extends StatefulWidget {
  final String token;
  final String bengkelId;
  final String userId;
  final int itemId;

  const TransactionFormPage({Key? key, required this.token, required this.bengkelId, required this.userId, required this.itemId}) : super(key: key);

  @override
  _TransactionFormPageState createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends State<TransactionFormPage> {
  final TextEditingController _platNomorController = TextEditingController();
  final TextEditingController _hargaJasaController = TextEditingController();
  final TextEditingController _jumlahBarangController = TextEditingController();
  String? statusTransaksi;
  double _totalBiaya = 0;
  List<Map<String, dynamic>> _barangDitambahkan = [];
  List<Map<String, String>> _namaBarang = [];
  Map<String, String>? _barangTerpilih;
  Map<String, int> _barangIds = {};
  Map<int, int> _hargaBarang = {};
  final List<String> _mechanicNames = [];
  final Map<int, String> _mechanicIdMap = {};
  int? _selectedMechanicId;
  late Map<String, dynamic> _transactionData = {};
  Set<int> _deletedDetailIds = {};

  @override
  void initState() {
    super.initState();
    _loadBarangList();
    _loadMechanicList();
    _fetchTransactionDetail();
  }

  Future<void> _fetchTransactionDetail() async {
    try {
      final response = await http.get(
        Uri.parse('https://bengkel-ku.com/public/api/transaction/${widget.itemId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        setState(() {
          _transactionData = data['transaction'];
        });
        await _fetchDetailTransaksi();
        setState(() {
          _platNomorController.text = _transactionData['plat_nomor'];
          _hargaJasaController.text = _transactionData['harga_jasa'].toString();
          statusTransaksi = _transactionData['status_transaksi'];
        });
        if (_transactionData.containsKey('detail_transaksi')) {
          _barangDitambahkan.addAll(List<Map<String, dynamic>>.from(_transactionData['detail_transaksi']));
        }
        print(_barangDitambahkan);
        _hitungTotal();
      } else {
        print('Failed to fetch transaction detail: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching transaction detail: $error');
    }
  }

  Future<void> _fetchDetailTransaksi() async {
    try {
      final response = await http.get(
        Uri.parse('https://bengkel-ku.com/public/api/detail_transaksi?transaksi_id=${widget.itemId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        setState(() {
          _transactionData['detail_transaksi'] = data['detail_transaksis'];
        });
      } else {
        print('Failed to fetch detail_transaksi: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching detail_transaksi: $error');
    }
  }

  Future<void> _loadBarangList() async {
    try {
      final response = await http.get(
        Uri.parse('https://bengkel-ku.com/public/api/barang?bengkel_id=${widget.bengkelId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data != null && data['barangs'] != null) {
          final List<dynamic> barangs = data['barangs'];
          print(barangs);
          setState(() {
            _namaBarang = barangs.map((barangs) => {
              'kode_barang': barangs['kode_barang'] as String,
              'nama_barang': barangs['nama_barang'] as String,
            }).toList();
            _barangTerpilih = _namaBarang.isNotEmpty ? _namaBarang.first : null;
            _barangIds = { for (var barang in barangs) barang['nama_barang'] as String : barang['id'] as int };
            _hargaBarang = { for (var barang in barangs) barang['id'] as int : barang['harga_jual'] as int  };
          });
        } else {
          print('Error: Unexpected data format or null data. Response body: ${response.body}');
        }
      } else {
        print('Failed to fetch barang list: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching barang list: $error');
    }
  }

  Future<void> _loadMechanicList() async {
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
            _mechanicNames.clear();
            _mechanicIdMap.clear();
            for (var mechanic in mechanics) {
              int id = mechanic['id'];
              String name = mechanic['nama'];
              _mechanicNames.add(name);
              _mechanicIdMap[id] = name;
            }
            if (_mechanicNames.isNotEmpty) {
              _selectedMechanicId = _mechanicIdMap.keys.first;
            }
          });
        } else {
          print('Error: Unexpected data format or null data. Response body: ${response.body}');
        }
      } else {
        print('Failed to fetch mechanics list: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching mechanics list: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Transaksi'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _platNomorController,
              decoration: const InputDecoration(labelText: 'Nomor Plat Kendaraan'),
            ),
            DropdownButtonFormField<int>(
              value: _selectedMechanicId,
              onChanged: (newValue) {
                setState(() {
                  _selectedMechanicId = newValue;
                });
              },
              items: _mechanicIdMap.entries.map<DropdownMenuItem<int>>((entry) {
                int mechanicId = entry.key;
                String mechanicName = entry.value;
                return DropdownMenuItem<int>(
                  value: mechanicId,
                  child: Text(mechanicName),
                );
              }).toList(),
              decoration: const InputDecoration(labelText: 'Nama Mekanik'),
            ),
            TextField(
              controller: _hargaJasaController,
              decoration: const InputDecoration(labelText: 'Harga Jasa'),
              keyboardType: TextInputType.number,
              onChanged: (_) => _hitungTotal(),
            ),
            const SizedBox(height: 20),
            const Text('Daftar Barang yang Ditambahkan:'),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _barangDitambahkan.length,
                itemBuilder: (context, index) {
                  final barang = _barangDitambahkan[index];
                  return ListTile(
                    title: Text('${barang['kode_barang']}-${barang['nama_barang']}' ?? ''),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Harga Barang: ${_getHargaBarang(barang['barang_id'])}'),
                        Text('Jumlah: ${barang['jumlah_barang'] ?? ''}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            _editDetailTransaction(index);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            _deleteDetailTransaction(index);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Total Biaya: Rp.${_formatTotalBiaya()}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.itemId == -1)
              ElevatedButton(
                onPressed: (){
                  if (_platNomorController.text.isNotEmpty && _selectedMechanicId!= null){
                    if(_hargaJasaController.text.isEmpty){
                      _hargaJasaController.text = "0";
                    }
                    _saveTransaction();
                  }else{
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Harap isi plat nomor dan mekanik')),
                    );
                  }
                },
                child: const Text('Submit'),
              ),
            if (widget.itemId != -1)
              ElevatedButton(
                onPressed: () {
                  if (_platNomorController.text.isNotEmpty && _selectedMechanicId!= null){
                    if(_hargaJasaController.text.isEmpty){
                      _hargaJasaController.text = "0";
                    }
                    _updateTransaction(widget.itemId);
                  }else{
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Harap isi plat nomor dan mekanik')),
                    );
                  }
                },
                child: const Text('Save'),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _tambahBarangDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _tambahBarangDialog() {

    String jumlahError = "";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState){
            return AlertDialog(
              title: const Text('Tambah Barang'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Map<String, String>>(
                    value: _barangTerpilih,
                    items: _namaBarang.map((barang) {
                      return DropdownMenuItem(
                        value: barang,
                        child: Text('${barang['kode_barang']} - ${barang['nama_barang']}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _barangTerpilih = value;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Nama Barang',
                    ),
                  ),

                  const SizedBox(height: 20),
                  TextField(
                    controller: _jumlahBarangController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Jumlah Barang',
                      errorText: jumlahError.isNotEmpty ? jumlahError : null
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    if (_barangTerpilih != null &&
                        _jumlahBarangController.text.isNotEmpty) {
                      setState(() {
                        final nama = _barangTerpilih!['nama_barang']!;
                        final kode = _barangTerpilih!['kode_barang']!;
                        final jumlah = int.tryParse(_jumlahBarangController.text) ?? 0;
                        final barangId = _getBarangId(nama);
                        final hargaBarang = _getHargaBarang(barangId!);
                        _barangDitambahkan.add({'nama_barang': nama, 'kode_barang': kode, 'barang_id': barangId, 'harga_jual': hargaBarang, 'jumlah_barang': jumlah, 'keuntungan_bersih': 0});
                        _hitungTotal();
                      });
                      _jumlahBarangController.clear();
                      Navigator.pop(context);
                    }else{
                      if (_jumlahBarangController.text.isEmpty){
                        if (_jumlahBarangController.text.isEmpty) {
                          setState(() {
                            jumlahError = 'Jumlah barang tidak boleh kosong';
                          });
                        }else{
                          setState(() {
                            jumlahError = '';
                          });
                        }
                        return;
                      }
                    }
                  },
                  child: const Text('Tambah'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  int? _getBarangId(String namaBarang) {
    return _barangIds[namaBarang];
  }
  int? _getHargaBarang(int barangId) {
    return _hargaBarang[barangId];
  }

  void _hitungTotal() {
    double hargaJasa = double.tryParse(_hargaJasaController.text) ?? 0;
    double totalBiayaBarang = _barangDitambahkan.fold(0, (prev, barang) {
      final harga = _getHargaBarang(barang['barang_id']) ?? 0;
      final jumlah = barang['jumlah_barang'] ?? 0;
      return prev + (harga * jumlah);
    });
    setState(() {
      _totalBiaya = hargaJasa + totalBiayaBarang;
    });
  }

  String _formatTotalBiaya() {
    return NumberFormat("#,##0", "en_US").format(_totalBiaya);
  }

  Future<bool> _checkStockAvailability() async {
  try {
    int totalRequestedQuantity = 0;
    Map<int, int> barangStockMap = {};

    for (var detailTransaksi in _transactionData['detail_transaksi']) {
      int barangId = detailTransaksi['barang_id'];
      int requestedQuantity = detailTransaksi['jumlah_barang'];
      totalRequestedQuantity += requestedQuantity;

      final response = await http.get(
        Uri.parse('https://bengkel-ku.com/public/api/barang_masuk/$barangId'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        List<dynamic> barangMasukList = data['barang_masuk'];

        int totalStock = barangMasukList.fold(
            0,
            (total, barangMasuk) =>
                total +
                (barangMasuk['kuantitas_barang'] as int));
        barangStockMap[barangId] = totalStock; 
      } else {
        print('Failed to fetch barang_masuk for barang $barangId: ${response.statusCode}');
      }
    }

    for (var entry in barangStockMap.entries) {
      int requestedQuantity = _transactionData['detail_transaksi']
          .firstWhere((detail) => detail['barang_id'] == entry.key)['jumlah_barang'];
      if (requestedQuantity > entry.value) {
        print('Insufficient stock for barang ${entry.key}');
        return false;
      }
    }
    return true;
  } catch (error) {
    print('Error checking stock availability: $error');
    return false;
  }
}

  Future<void> _updateTransaction(int transactionId) async {
  try {
    final Map<String, dynamic> transactionData = {
      'plat_nomor': _platNomorController.text,
      'harga_jasa': double.tryParse(_hargaJasaController.text) ?? 0,
      'total_transaksi': _totalBiaya.toString(),
      'status_transaksi': statusTransaksi,
      'user_id': widget.userId,
      'mechanic_id': _selectedMechanicId,
      'bengkel_id': widget.bengkelId,
    };

    final response = await http.put(
      Uri.parse('https://bengkel-ku.com/public/api/transaction/$transactionId'),
      headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      body: json.encode(transactionData),
    );

    if (response.statusCode == 200) {
      print('Transaction updated successfully!');

      for (final barang in _barangDitambahkan) {
        final Map<String, dynamic> detailTransaksiData = {
          'transaksi_id': transactionId,
          'barang_id': barang['barang_id'].toString(),
          'jumlah_barang': barang['jumlah_barang'].toString(),
          'keuntungan_bersih': barang['keuntungan_bersih'].toString(),
        };

        if (barang['id'] != null) {
          final detailResponse = await http.put(
            Uri.parse('https://bengkel-ku.com/public/api/detail_transaksi/${barang['id']}'),
            headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
            body: json.encode(detailTransaksiData),
          );

          if (detailResponse.statusCode == 200) {
            print('Success Update Detail Transaksi');
          } else {
            print('Failed to update detail transaksi for barang: ${barang['nama_barang']}');
          }
        } else {
          final detailResponse = await http.post(
            Uri.parse('https://bengkel-ku.com/public/api/detail_transaksi/store'),
            headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
            body: json.encode(detailTransaksiData),
          );

          if (detailResponse.statusCode == 201) {
            print('Success Add Detail Transaksi');
          } else {
            print('Failed to add detail transaksi for barang: ${barang['nama_barang']}');
          }
        }
      }

      for (final deletedDetailId in _deletedDetailIds) {
        final deleteResponse = await http.delete(
          Uri.parse('https://bengkel-ku.com/public/api/detail_transaksi/$deletedDetailId'),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        );

        if (deleteResponse.statusCode == 200) {
          print('Deleted detail transaksi with ID: $deletedDetailId');
        } else {
          print('Failed to delete detail transaksi with ID: $deletedDetailId');
        }
      }
      _deletedDetailIds.clear();
      Navigator.pop(context, true); 
    } else {
      print('Failed to update transaction: ${response.statusCode}');
    }
  } catch (error) {
    print('Error updating transaction: $error');
  }
}


  void _editDetailTransaction(int index) {

    String jumlahError= "";

    showDialog(
      context: context,
      builder: (context) {

        final barang = _barangDitambahkan[index];
        final TextEditingController jumlahController = TextEditingController(text: barang['jumlah_barang'].toString());
      
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState){
            return AlertDialog(
              title: Text('Edit Detail Barang - ${barang['nama_barang']}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  TextField(
                    controller: jumlahController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Jumlah Barang', errorText: jumlahError.isNotEmpty ? jumlahError : null),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    if (jumlahController.text.isEmpty){
                      if (jumlahController.text.isEmpty) {
                        setState(() {
                          jumlahError = 'Jumlah barang tidak boleh kosong';
                        });
                      }else{
                        setState(() {
                          jumlahError = '';
                        });
                      }
                      return;
                    }
                    setState(() {
                      barang['jumlah_barang'] = int.tryParse(jumlahController.text) ?? 0;
                      _hitungTotal();
                    });
                    Navigator.pop(context);
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

  void _deleteDetailTransaction(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus Barang'),
          content: const Text('Apakah Anda yakin ingin menghapus barang ini dari transaksi?'),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  final barang = _barangDitambahkan[index];
                  if (barang.containsKey('id')) {
                    _deletedDetailIds.add(barang['id']);
                  }
                  _barangDitambahkan.removeAt(index);
                  _hitungTotal();
                });
                Navigator.pop(context);
              },
              child: const Text('Ya'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Tidak'),
            ),
          ],
        );
      },
    );
  }

  void _saveTransaction() async {
    print("total biaya"+_totalBiaya.toString());
    try {
      await _checkStockAvailability();
      final Map<String, dynamic> transactionData = {
        'plat_nomor': _platNomorController.text,
        'harga_jasa': double.tryParse(_hargaJasaController.text) ?? 0,
        'total_transaksi': _totalBiaya,
        'status_transaksi': 'belum lunas',
        'user_id': widget.userId,
        'mechanic_id': _selectedMechanicId,
        'bengkel_id': widget.bengkelId,
      };

      final response = await http.post(
        Uri.parse('https://bengkel-ku.com/public/api/transaction/store'),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
        body: json.encode(transactionData),
      );

      if (response.statusCode == 201) {
        final dynamic data = json.decode(response.body);
        final int transactionId = data['transaction']['id'];

        for (final barang in _barangDitambahkan) {
          final Map<String, dynamic> detailTransaksiData = {
            'transaksi_id': transactionId,
            'barang_id': barang['barang_id'].toString(),
            'jumlah_barang': barang['jumlah_barang'].toString(),
            'keuntungan_bersih': barang['keuntungan_bersih'].toString(),
          };

          final detailResponse = await http.post(
            Uri.parse('https://bengkel-ku.com/public/api/detail_transaksi/store'),
            headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
            body: json.encode(detailTransaksiData),
          );

          if (detailResponse.statusCode == 201) {
            print('Added detail transaksi successfully for barang: ${barang['nama_barang']}');
          } else {
            print('Failed to add detail transaksi for barang: ${barang['nama_barang']}');
          }
        }

        Navigator.pop(context, true);
      } else {
        print('Failed to save transaction: ${response.statusCode}');
      }
    } catch (error) {
      print('Error saving transaction: $error');
    }
  }
}
