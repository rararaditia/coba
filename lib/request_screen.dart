import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class RequestScreen extends StatefulWidget {
  final String documentType;
  final String nip;

  RequestScreen({required this.documentType, required this.nip});

  @override
  _RequestScreenState createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  String? selectedFile;
  bool isChecked = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        selectedFile = result.files.single.path;
      });
    }
  }

  Future<String> _uploadFile(String filePath) async {
    final fileName = filePath.split('/').last;
    final storageRef = FirebaseStorage.instance.ref().child('doktambahan/$fileName');
    final uploadTask = storageRef.putFile(File(filePath));
    await uploadTask.whenComplete(() => {});
    return await storageRef.getDownloadURL();
  }

  void _submitRequest() async {
    if (_formKey.currentState!.validate() && isChecked) {
      String? fileUrl;
      if (selectedFile != null) {
        fileUrl = await _uploadFile(selectedFile!);
      }

      // Create a new request document with an auto-generated ID
      DocumentReference requestRef = FirebaseFirestore.instance.collection('request').doc();
      String requestId = requestRef.id;

      // Save request to Firestore
      await requestRef.set({
        'nip': widget.nip,
        'tipedok': widget.documentType,
        'keperluan': _descriptionController.text,
        'date': Timestamp.now(),
        'status': 'Dalam Proses',
        'doktambahan': fileUrl ?? '',
        'requestId': requestId,
        'respon': '', // Initialize the respon field
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Konfirmasi"),
            content: Text("Permintaan Anda telah diajukan, mohon tunggu respon dari kami"),
            actions: <Widget>[
              TextButton(
                child: Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeScreen(nip: widget.nip),
                    ),
                    (Route<dynamic> route) => false,
                  );
                },
              ),
            ],
          );
        },
      );
    } else if (!isChecked) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Peringatan"),
            content: Text("Anda harus mencentang pernyataan sebelum melanjutkan."),
            actions: <Widget>[
              TextButton(
                child: Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
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
        title: Text('${widget.documentType} Request'),
        backgroundColor: Color.fromRGBO(66, 129, 139, 1),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(height: 20),
                  // Center(
                  //   child: Text(
                  //     'MOHON ISI FORM INI',
                  //     style: TextStyle(
                  //       fontWeight: FontWeight.bold,
                  //       fontSize: 20,
                  //     ),
                  //   ),
                  // ),
                  // SizedBox(height: 30),
                  Text(
                    'KETERANGAN/KEPERLUAN',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(66, 129, 139, 1),
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Keterangan/Keperluan harus diisi';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: 40),
                  Text(
                    'DOKUMEN PENDUKUNG (Opsional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(66, 129, 139, 1),
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _pickFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                    ),
                    icon: Icon(Icons.attach_file, color: Color.fromRGBO(66, 129, 139, 1)),
                    label: Text(
                      selectedFile != null ? selectedFile!.split('/').last : 'SELECT FILE',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color.fromRGBO(66, 129, 139, 1),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Checkbox(
                        value: isChecked,
                        onChanged: (bool? value) {
                          setState(() {
                            isChecked = value!;
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          'Saya sudah mengisi data-data dengan benar jika terdapat kesalahan pada data tersebut, saya bersedia pengajuan ini tidak diterima atau ditolak',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 50),
                  Center(
                    child: ElevatedButton(
                      onPressed: _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                      ),
                      child: Text(
                        'Submit',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color.fromRGBO(66, 129, 139, 1),
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
