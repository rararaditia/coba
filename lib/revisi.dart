import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RevisiDokumenScreen extends StatelessWidget {
  final String nip;
  final String requestId;

  RevisiDokumenScreen({required this.nip, required this.requestId});

  final TextEditingController _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _submitRevisi(String requestId, String notes, BuildContext context) async {
    if (_formKey.currentState?.validate() ?? false) {
      // Save revision notes to the 'revisi' collection
      await FirebaseFirestore.instance.collection('revisi').add({
        'requestId': requestId,
        'alasan': notes,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update the status of the request to 'Perlu Direvisi'
      await FirebaseFirestore.instance.collection('request').doc(requestId).update({
        'status': 'Perlu Direvisi',
      });

      // Show confirmation dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Konfirmasi"),
            content: Text("Catatan Revisi Berhasil Dikirim"),
            actions: <Widget>[
              TextButton(
                child: Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Close the screen after submitting
                },
              ),
            ],
          );
        },
      );
    }
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: Text(
                        'REVISI DOKUMEN',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    SizedBox(height: 20),
                    Text(
                      'Revisi Notes',
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
                      child: TextFormField(
                        controller: _notesController,
                        maxLines: 6,
                        decoration: InputDecoration.collapsed(
                          hintText: "Masukkan catatan revisi...",
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Catatan Revisi harus diisi';
                          }
                          return null;
                        },
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          _submitRevisi(requestId, _notesController.text, context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                        ),
                        child: Text(
                          'Submit Revisi',
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
          ),
        ],
      ),
    );
  }
}
