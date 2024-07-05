import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'login_screen.dart';

class SuperAdminHomeScreen extends StatelessWidget {
  void _logout(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  Future<String> _getUserName(String nip) async {
    String userName = '';
    List<String> collections = ['pegawai', 'admin', 'superadmin'];

    for (String collection in collections) {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection(collection)
          .where('nip', isEqualTo: nip)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        userName = querySnapshot.docs.first['name'];
        break;
      }
    }

    return userName.isNotEmpty ? userName : 'Unknown User';
  }

  Future<void> _downloadData(BuildContext context) async {
    final QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('request').get();
    final List<QueryDocumentSnapshot> docs = querySnapshot.docs;

    // Request permissions
    await Permission.storage.request();

    // Get the directory where the existing Excel file is located
    Directory? directory = await getExternalStorageDirectory();

    if (directory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to access storage')),
      );
      return;
    }

    // Copy the Excel file to the application documents directory if it doesn't exist
    String inputPath = '${directory.path}/RequestList.xlsx';
    File excelFile = File(inputPath);
    if (!await excelFile.exists()) {
      final byteData = await rootBundle.load('assets/RequestList.xlsx');
      final buffer = byteData.buffer;
      await excelFile.writeAsBytes(
        buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
      );
    }

    var bytes = File(inputPath).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);

    Sheet sheetObject = excel['Sheet1'];

    // Set header row background color to blue
    CellStyle headerStyle = CellStyle(
      backgroundColorHex: "#0000FF",
      fontColorHex: "#FFFFFF",
      bold: true,
      fontSize: 12,
    );

    // Assuming the first row is the header
    var headerRow = sheetObject.row(0);
    for (var cell in headerRow) {
      cell?.cellStyle = headerStyle;
    }

    // Fill the sheet with data from Firestore
    int rowIndex = 1; // Start writing from the second row (index 1)
    for (var doc in docs) {
      String nip = doc['nip'];
      String userName = await _getUserName(nip);
      String jenisDokumen = doc['tipedok'];
      String status = doc['status'];
      String date = DateFormat('yyyy-MM-dd HH:mm:ss').format((doc['date'] as Timestamp).toDate());

      sheetObject.appendRow([nip, userName, jenisDokumen, status, date]);
      rowIndex++;
    }

    String outputPath = '${directory.path}/RequestList_Filled.xlsx';
    File(outputPath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(excel.encode()!);

    // Open the file
    OpenFile.open(outputPath);

    // Notify user of the file location
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('File saved to $outputPath')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: Color.fromRGBO(66, 129, 139, 1),
      //   actions: [
      //     // Removed the download icon button from the AppBar
      //   ],
      // ),
      body: Column(
        children: [
          Stack(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
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
                    SizedBox(height: 20),
                    Image.asset(
                      'assets/images/docuserv.png',
                      width: 300,
                      height: 150,
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 95,
                right: 30,
                child: PopupMenuButton<String>(
                  onSelected: (String result) {
                    if (result == 'logout') {
                      _logout(context);
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.logout, color: Colors.red),
                          SizedBox(width: 10),
                          Text('Logout'),
                        ],
                      ),
                    ),
                  ],
                  child: CircleAvatar(
                    backgroundColor: Colors.grey.shade300,
                    child: Icon(Icons.person, color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Center(
            child: Text(
              'Daftar Pengajuan Permohonan Dokumen oleh Pegawai',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color.fromRGBO(66, 129, 139, 1),
              ),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _downloadData(context),
            icon: Icon(Icons.download),
            label: Text('Download Data'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromRGBO(66, 129, 139, 1),
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('request')
                    .orderBy('date', descending: true) // Order by date in descending order
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final requests = snapshot.data!.docs;
                  final DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

                  return ListView(
                    children: requests.map((doc) {
                      return FutureBuilder<String>(
                        future: _getUserName(doc['nip']),
                        builder: (context, userNameSnapshot) {
                          if (!userNameSnapshot.hasData) {
                            return Container();
                          }

                          Color statusColor;
                          switch (doc['status']) {
                            case 'Ditolak':
                              statusColor = Colors.red;
                              break;
                            case 'Disetujui':
                              statusColor = Colors.green;
                              break;
                            default:
                              statusColor = Colors.yellow[800]!;
                              break;
                          }

                          return Container(
                            margin: EdgeInsets.only(bottom: 10),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  userNameSnapshot.data!, // Display user name
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromRGBO(66, 129, 139, 1),
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Jenis Dokumen : ${doc['tipedok']}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color.fromRGBO(66, 129, 139, 1),
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Status : ${doc['status']}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: statusColor,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Date : ${dateFormat.format((doc['date'] as Timestamp).toDate())}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
