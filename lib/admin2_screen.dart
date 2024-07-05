import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'review_screen.dart';
import 'login_screen.dart';
import 'package:intl/intl.dart';

class Admin2Screen extends StatelessWidget {
  void _logout(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  String formatDate(Timestamp timestamp) {
    final DateTime date = timestamp.toDate();
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(date);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          Text(
            'DAFTAR PENGAJUAN DOKUMEN PAKLARING',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color.fromRGBO(66, 129, 139, 1),
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('request')
                  .where('tipedok', isEqualTo: 'Paklaring')
                  .where('status', isEqualTo: 'Dalam Proses')
                  .snapshots(), // Add this line to filter requests
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Tidak ada Pengajuan'));
                }

                final requests = snapshot.data!.docs;

                return ListView(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  children: requests.map((doc) {
                    return FutureBuilder<String>(
                      future: _getUserName(doc['nip']),
                      builder: (context, userNameSnapshot) {
                        if (userNameSnapshot.connectionState == ConnectionState.waiting) {
                          return Container(
                            margin: EdgeInsets.only(bottom: 10),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (userNameSnapshot.hasError) {
                          return Container(
                            margin: EdgeInsets.only(bottom: 10),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            child: Center(child: Text('Error retrieving user name')),
                          );
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
                                'Date: ${formatDate(doc['date'] as Timestamp)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ReviewScreen(
                                          nip: doc['nip'],
                                          keperluan: doc['keperluan'],
                                          doktambahan: doc['doktambahan'] ?? '',
                                          requestId: doc.id,
                                        ),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.grey.shade400,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15.0),
                                    ),
                                  ),
                                  child: Text(
                                    'Cek Detail',
                                    style: TextStyle(
                                      color: Color.fromRGBO(66, 129, 139, 1),
                                    ),
                                  ),
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
        ],
      ),
    );
  }
}
