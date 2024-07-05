import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PengajuanDitolakScreen extends StatefulWidget {
  final String nip;
  final String requestId;

  PengajuanDitolakScreen({required this.nip, required this.requestId});

  @override
  _PengajuanDitolakScreenState createState() => _PengajuanDitolakScreenState();
}

class _PengajuanDitolakScreenState extends State<PengajuanDitolakScreen> {
  final TextEditingController _reasonController = TextEditingController();

  Future<void> _submitRejection() async {
    final reason = _reasonController.text.trim();

    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Masukkan keterangan penolakan terlebih dahulu')),
      );
      return;
    }

    // Update the request document
    await FirebaseFirestore.instance
        .collection('request')
        .doc(widget.requestId)
        .update({'status': 'Ditolak', 'reason': reason});

    // Add a new document to the penolakan collection
    await FirebaseFirestore.instance.collection('penolakan').add({
      'requestId': widget.requestId,
      'alasan': reason,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pengajuan Permintaan Dokumen Pegawai Berhasil Ditolak')),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Konfirmasi"),
          content: Text("Pengajuan Permintaan Dokumen Pegawai Berhasil Ditolak"),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(); // Go back to admin page
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(66, 129, 139, 1),
      ),
      body: Column(
        children: [
          Stack(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(66, 129, 139, 1),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(height: 0),
                    Image.asset(
                      'assets/images/docuserv.png',
                      width: 300,
                      height: 150,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Text(
                      'PENOLAKAN PENGAJUAN',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'KETERANGAN PENOLAKAN PENGAJUAN',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(66, 129, 139, 1),
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: TextField(
                      controller: _reasonController,
                      maxLines: 5,
                      decoration: InputDecoration.collapsed(hintText: "Masukkan alasan penolakan..."),
                    ),
                  ),
                  Spacer(),
                  Center(
                    child: ElevatedButton(
                      onPressed: _submitRejection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                      ),
                      child: Text(
                        'Submit',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
