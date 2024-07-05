import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubmitDokumenScreen extends StatefulWidget {
  final String nip;
  final String requestId;

  SubmitDokumenScreen({required this.nip, required this.requestId});

  @override
  _SubmitDokumenScreenState createState() => _SubmitDokumenScreenState();
}

class _SubmitDokumenScreenState extends State<SubmitDokumenScreen> {
  String? selectedFile;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        selectedFile = result.files.single.path;
      });
    }
  }

  Future<void> _submitFile() async {
    if (selectedFile != null) {
      final fileName = selectedFile!.split('/').last;
      final storageRef = FirebaseStorage.instance.ref().child('respon/$fileName');
      final uploadTask = storageRef.putFile(File(selectedFile!));
      await uploadTask.whenComplete(() => {});
      final fileUrl = await storageRef.getDownloadURL();

      // Update the status and fileUrl in Firestore
      await FirebaseFirestore.instance.collection('request').doc(widget.requestId).update({
        'status': 'Disetujui',
        'respon': fileUrl, // Update the respon field with the file URL
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dokumen berhasil diunggah')),
      );

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Konfirmasi"),
            content: Text("Dokumen berhasil dikirim"),
            actions: <Widget>[
              TextButton(
                child: Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Navigate back to the admin screen
                  Navigator.of(context).pop(); 
                },
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih dokumen terlebih dahulu')),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Text(
                      'SUBMIT DOKUMEN HASIL',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'INPUT DOKUMEN PERMINTAAN',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(66, 129, 139, 1),
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _pickFile,
                    icon: Icon(Icons.attach_file),
                    label: Text(selectedFile == null ? 'SELECT FILE' : selectedFile!.split('/').last),
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: _submitFile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
