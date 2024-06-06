import 'dart:convert';
import 'dart:math';

import 'package:bengkelku/transaction_form.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class TransactionDetailScreen extends StatefulWidget {
  final int itemId;
  final String token;
  final String bengkelId;
  final String userId;
  final String userRole;

  const TransactionDetailScreen({
    Key? key,
    required this.itemId,
    required this.token,
    required this.userId,
    required this.bengkelId,
    required this.userRole
  }) : super(key: key);

  @override
  _TransactionDetailScreenState createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late Map<String, dynamic> _transactionData = {};
  String namaMekanik = "";
  int totalUntungBersih = 0;
  double? totalTransaksi = 0;
  @override
  void initState() {
    super.initState();
    _fetchTransactionDetail();
  }

  String _formatTotalUntungBersih(int value) {
    return NumberFormat("#,##0", "en_US").format(value);
  }
  String _formatTotalTransaksi(double? value) {
    return NumberFormat("#,##0", "en_US").format(value);
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
        print(_transactionData);
        
        double? nullableIntValue = double.tryParse(_transactionData['total_transaksi'].toString().trim());
        totalTransaksi = nullableIntValue;

        await _fetchDetailTransaksi();
        await _fetchDetailMekanik();
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
        Uri.parse(
            'https://bengkel-ku.com/public/api/detail_transaksi?transaksi_id=${widget.itemId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        setState(() {
          _transactionData['detail_transaksi'] = data['detail_transaksis'];
        });
        for (var detailTransaksi in _transactionData['detail_transaksi']){
          totalUntungBersih += detailTransaksi['keuntungan_bersih'] as int;
        }
        print('testing-${_transactionData}');
        
      } else {
        print('Failed to fetch detail_transaksi: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching detail_transaksi: $error');
    }
  }

  Future<void> _fetchDetailMekanik() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://bengkel-ku.com/public/api/mechanic/${_transactionData['mechanic_id']}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic data = json.decode(response.body);
        setState(() {
          namaMekanik = data['mechanic']['nama'].toString();
        });
      } else {
        setState(() {
          namaMekanik = "Mekanik Terhapus";
        });
      }
    } catch (error) {
      print('Error fetching detail_mechanic: $error');
    }
  }

  Future<void> _setPendapatanMekanik() async {
  try {

    final responseMechanic = await http.get(
      Uri.parse(
          'https://bengkel-ku.com/public/api/mechanic/${_transactionData['mechanic_id']}'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (responseMechanic.statusCode == 200) {
      Map<String, dynamic> mechanicData = json.decode(responseMechanic.body);
      double totalPendapatan = 0;
      if (mechanicData['mechanic']['pendapatan'] != null) {
        totalPendapatan =
            (mechanicData['mechanic']['pendapatan'] as int).toDouble();
      }
      totalPendapatan +=
          (_transactionData['harga_jasa'] as int).toDouble();

      final responseUpdateMechanic = await http.put(
        Uri.parse(
            'https://bengkel-ku.com/public/api/mechanicPendapatan/${_transactionData['mechanic_id']}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
        body: {
          'pendapatan': totalPendapatan.toString(),
        },
      );

      if (responseUpdateMechanic.statusCode == 200 ||
          responseUpdateMechanic.statusCode == 201) {
        print("success mark transaction as paid");

      } else {
        print(
            'Failed to update mechanic pendapatan: ${responseUpdateMechanic.statusCode}');
      }
    } else {
      print(
          'Failed to fetch mechanic data: ${responseMechanic.statusCode}');
    }
  } catch (error) {
    print('Error marking transaction as paid: $error');
  }
}

  Future<void> _setKeuntunganBersih(int detailTransaksiId, int keuntunganBersih) async {
    try {
        final response = await http.put(
          Uri.parse(
              'https://bengkel-ku.com/public/api/detail_transaksis/$detailTransaksiId'),
          headers: {'Authorization': 'Bearer ${widget.token}'},
          body: {'keuntungan_bersih': keuntunganBersih.toString()},
        );

        if (response.statusCode != 200) {
          print(
              'Failed to update keuntungan_bersih: ${response.statusCode}');
        }
      
    } catch (error) {
      print('Error calculating and setting keuntungan_bersih: $error');
    }
  }


  Future<void> _reduceStock() async {
    try {
      int totalRequestedQuantity = 0;
      Map<int, int> barangStockMap = {};
      int totalKeuntunganBersih = 0;

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

          int totalStock = barangMasukList.fold(0,(total, barangMasuk) => total + (barangMasuk['kuantitas_barang'] as int));
          barangStockMap[barangId] = totalStock;
        } else {
          print(
              'Failed to fetch barang_masuk for barang $barangId: ${response.statusCode}');
        }
      }

      bool stockAvailable = true;
      for (var entry in barangStockMap.entries) {
        int requestedQuantity = _transactionData['detail_transaksi']
            .firstWhere((detail) => detail['barang_id'] == entry.key)['jumlah_barang'];
        if (requestedQuantity > entry.value) {
          print('Insufficient stock for barang ${entry.key}');
          stockAvailable = false;
          break;
        }
      }

      if (!stockAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Stok Barang Tidak Cukup")),
        );
        return;
      }

      for (var detailTransaksi in _transactionData['detail_transaksi']) {
        print('masuk');
        print(_transactionData);
        int detailTransaksiId = detailTransaksi['id'];
        int remainingQuantity = detailTransaksi['jumlah_barang'];
        int barangId = detailTransaksi['barang_id'];
        List<dynamic> barangMasukList = await _fetchBarangMasukList(barangId);
        int hargaJual = await _fetchBarangDetail(barangId);
        print(barangMasukList);
        for (var barangMasuk in barangMasukList) {
          if (remainingQuantity > 0) {
            int availableStock = barangMasuk['kuantitas_barang'];
            int hargaModal = barangMasuk['harga_modal'];
            int quantityToReduce = min(remainingQuantity, availableStock);
            await _updateBarangMasuk(barangMasuk['id'], quantityToReduce);
              remainingQuantity -= quantityToReduce;
              totalKeuntunganBersih = totalKeuntunganBersih + ((hargaJual-hargaModal)*quantityToReduce);

          } else {
            break;
          }
        }
        await _setKeuntunganBersih(detailTransaksiId, totalKeuntunganBersih);
        setState(() {
          totalKeuntunganBersih = 0;
        });
      }
      await _markTransactionPaid();
      await _setPendapatanMekanik();
    } catch (error) {
      print('Error reducing stock: $error');
    }
  }

  Future<List<dynamic>> _fetchBarangMasukList(int barangId) async {
    final response = await http.get(
      Uri.parse('https://bengkel-ku.com/public/api/barang_masuk/$barangId'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (response.statusCode == 200) {
      final dynamic data = json.decode(response.body);
      return data['barang_masuk'];
    } else {
      print(
          'Failed to fetch barang_masuk for barang $barangId: ${response.statusCode}');
      return [];
    }
  }

  Future<int> _fetchBarangDetail (int barangId) async {
    final response = await http.get(
      Uri.parse('https://bengkel-ku.com/public/api/barang/$barangId'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (response.statusCode == 200) {
      final dynamic data = json.decode(response.body);
      return data['barang']['harga_jual'];
    } else {
      print(
          'Failed to fetch barang detail for barang $barangId: ${response.statusCode}');
      return 0;
    }
  }

  Future<void> _updateBarangMasuk(int barangMasukId, int quantityToReduce) async {
    final response = await http.put(
      Uri.parse('https://bengkel-ku.com/public/api/barang_masuk/$barangMasukId/reduce-stock'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
      body: {'quantity': quantityToReduce.toString()},
    );

    if (response.statusCode != 200) {
      print('Failed to reduce stock for barang masuk $barangMasukId: ${response.statusCode}');
    }
  }

  Future<void> _markTransactionPaid() async {
    final responseMarkPaid = await http.put(
      Uri.parse('https://bengkel-ku.com/public/api/transaction/${widget.itemId}'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
      body: {
        'user_id': _transactionData['user_id'].toString(),
        'mechanic_id': _transactionData['mechanic_id'].toString(),
        'plat_nomor': _transactionData['plat_nomor'].toString(),
        'harga_jasa': _transactionData['harga_jasa'].toString(),
        'total_transaksi': _transactionData['total_transaksi'].toString(),
        'bengkel_id': _transactionData['bengkel_id'].toString(),
        'status_transaksi': 'lunas',
      },
    );

    if (responseMarkPaid.statusCode == 200) {
      Navigator.pop(context, true);
    } else {
      print(
          'Failed to mark transaction as paid: ${responseMarkPaid.statusCode}');
    }
  }

  Future<void> _deleteItem() async {
    try {
      final response = await http.delete(
        Uri.parse('https://bengkel-ku.com/public/api/transaction/${widget.itemId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        Navigator.pop(context, true);
      } else {
        print('Failed to delete item: ${response.statusCode}');
      }
    } catch (error) {
      print('Error deleting item: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Detail Screen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _deleteItem();
            },
          ),
        ],
      ),
      body: _transactionData.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nomor Plat Kendaraan: ${_transactionData['plat_nomor']}'),
                  Text('Nama Mekanik: $namaMekanik'),
                  Text('Harga Jasa: Rp.${_transactionData['harga_jasa']}'),
                  const SizedBox(height: 20),
                  const Text('Daftar Barang yang Ditambahkan:'),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _transactionData['detail_transaksi'] != null
                          ? _transactionData['detail_transaksi'].length
                          : 0,
                      itemBuilder: (context, index) {
                        final detailTransaksi =
                            _transactionData['detail_transaksi'][index];
                        return ListTile(
                          title: Text(detailTransaksi['kode_barang'] != null && detailTransaksi['nama_barang'] != null
                            ? '${detailTransaksi['kode_barang'].toString()}-${detailTransaksi['nama_barang'].toString()}'
                            : detailTransaksi['kode_barang'] != null
                              ? detailTransaksi['kode_barang'].toString()
                              : 'Barang Telah Dihapus'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FutureBuilder<int>(
                                future: _fetchBarangDetail(detailTransaksi['barang_id']),
                                builder: (context, snapshot) {
                                  return Text('Harga Jual: ${snapshot.data}');
                                },
                              ),
                              Text('Jumlah: ${detailTransaksi['jumlah_barang']}'),
                              if (_transactionData['status_transaksi'] == "lunas" && widget.userRole != "kasir")
                              Text('Keuntungan Bersih: ${detailTransaksi['keuntungan_bersih']}'),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Total Biaya: Rp.${_formatTotalTransaksi(totalTransaksi)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.userRole != "kasir")
                  Text(
                    'Total Keuntungan Bersih: Rp.${_formatTotalUntungBersih(totalUntungBersih)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (_transactionData['status_transaksi'] == 'belum lunas')
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, true);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) =>
                                  TransactionFormPage(token: widget.token,
                                      bengkelId: widget.bengkelId,
                                      userId: widget.userId,
                                      itemId: widget.itemId)),
                            );
                          },
                          style: ButtonStyle(
                            padding: MaterialStateProperty.all(
                                const EdgeInsets.symmetric(vertical: 16)),
                          ),
                          child: const Text('Edit'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (_transactionData['status_transaksi'] == 'belum lunas')
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _reduceStock,
                            style: ButtonStyle(
                              padding: MaterialStateProperty.all(
                                  const EdgeInsets.symmetric(vertical: 16)),
                            ),
                            child: const Text('Paid'),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
