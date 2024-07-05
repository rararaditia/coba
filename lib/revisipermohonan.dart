import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class RevisiPermohonanScreen extends StatefulWidget {
  final String documentType;
  final String nip;
  final String requestId;

  RevisiPermohonanScreen({
    required this.documentType,
    required this.nip,
    required this.requestId,
  });

  @override
  _RevisiPermohonanScreenState createState() => _RevisiPermohonanScreenState();
}

class _RevisiPermohonanScreenState extends State<RevisiPermohonanScreen> {
  String? selectedFile;
  bool isChecked = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _revisiNotesController = TextEditingController();

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

      // Update the request document with new data
      await FirebaseFirestore.instance.collection('request').doc(widget.requestId).update({
        'keperluan': _descriptionController.text,
        'status': 'Dalam Proses',
        'doktambahan': fileUrl ?? '',
        'respon': '', // Initialize the respon field if not present
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Konfirmasi"),
            content: Text("Permintaan Anda telah diajukan kembali, mohon tunggu respon dari kami"),
            actions: <Widget>[
              TextButton(
                child: Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Close the screen after submitting
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
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  void _fetchInitialData() async {
    DocumentSnapshot requestDoc = await FirebaseFirestore.instance.collection('request').doc(widget.requestId).get();
    setState(() {
      _descriptionController.text = requestDoc['keperluan'];
    });

    QuerySnapshot revisiSnapshot = await FirebaseFirestore.instance
        .collection('revisi')
        .where('requestId', isEqualTo: widget.requestId)
        // .orderBy('timestamp', descending: true)
        .get();

    if (revisiSnapshot.docs.isNotEmpty) {
      print("Revisi document found: ${revisiSnapshot.docs.first.data()}");
      setState(() {
        _revisiNotesController.text = revisiSnapshot.docs.first['alasan'];
      });
    } else {
      print("No revisi document found for requestId: ${widget.requestId}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.documentType} Revisi'),
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
                  SizedBox(height: 40),
                  Text(
                    'ALASAN REVISI DARI ADMIN',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(233, 2, 2, 1),
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
                      controller: _revisiNotesController,
                      maxLines: 5,
                      readOnly: true,
                      decoration: InputDecoration(
                        border: InputBorder.none,
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
