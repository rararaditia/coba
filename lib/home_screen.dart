import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'request_screen.dart';
import 'status_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final String nip;

  HomeScreen({required this.nip});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<String> _userNameFuture;

  @override
  void initState() {
    super.initState();
    _userNameFuture = _getUserName();
  }

  Future<String> _getUserName() async {
    String userName = '';
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('pegawai')
        .where('nip', isEqualTo: widget.nip)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      userName = querySnapshot.docs.first['name'];
    } else {
      querySnapshot = await FirebaseFirestore.instance
          .collection('admin')
          .where('nip', isEqualTo: widget.nip)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        userName = querySnapshot.docs.first['name'];
      } else {
        querySnapshot = await FirebaseFirestore.instance
            .collection('superadmin')
            .where('nip', isEqualTo: widget.nip)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          userName = querySnapshot.docs.first['name'];
        }
      }
    }
    return userName;
  }

  void _logout(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  Future<void> _navigateToRequestScreen(BuildContext context, String documentType) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('request')
        .where('nip', isEqualTo: widget.nip)
        .where('tipedok', isEqualTo: documentType)
        .where('status', isEqualTo: 'Dalam Proses')
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Peringatan"),
            content: Text(
                "Anda sudah memiliki permohonan dengan tipe dokumen yang sama yang sedang diproses. Harap tunggu sampai permohonan sebelumnya selesai diproses."),
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
    } else {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              RequestScreen(documentType: documentType, nip: widget.nip),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var begin = Offset(1.0, 0.0);
            var end = Offset.zero;
            var curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      );
    }
  }

  void _navigateToStatusScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatusScreen(nip: widget.nip), // Pass the nip to StatusScreen
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(66, 129, 139, 1),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30.0),
                      bottomRight: Radius.circular(30.0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(height: 45),
                      FutureBuilder<String>(
                        future: _userNameFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Hello, ${snapshot.data}!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 25),
                                Text(
                                  'Welcome to',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                      SizedBox(height: 35),
                    ],
                  ),
                ),
                Positioned(
                  top: 60,
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
                Positioned(
                  top: 60,
                  left: 20,
                  child: Transform.translate(
                    offset: Offset(-45.0, 45.0),
                    child: Image.asset(
                      'assets/images/docuserv.png',
                      width: 250,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: <Widget>[
                  SizedBox(height: 30),
                  Text(
                    'Dokumen Apa Yang Anda Butuhkan?',
                    style: TextStyle(
                      color: Color.fromRGBO(66, 129, 139, 1),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _navigateToRequestScreen(context, 'Slip Gaji');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        padding: EdgeInsets.symmetric(vertical: 5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/1.png',
                            width: 70,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'SLIP GAJI',
                            style: TextStyle(
                              fontSize: 18,
                              color: Color.fromRGBO(66, 129, 139, 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _navigateToRequestScreen(context, 'Paklaring');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        padding: EdgeInsets.symmetric(vertical: 5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/2.png',
                            width: 70,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'PAKLARING',
                            style: TextStyle(
                              fontSize: 18,
                              color: Color.fromRGBO(66, 129, 139, 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _navigateToRequestScreen(context, 'Kartu BPJS');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        padding: EdgeInsets.symmetric(vertical: 5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/3.png',
                            width: 70,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'KARTU BPJS',
                            style: TextStyle(
                              fontSize: 18,
                              color: Color.fromRGBO(66, 129, 139, 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 90),
                  Text(
                    'Cek Status Pengajuan Dokumen Anda Disini!',
                    style: TextStyle(
                      color: Color.fromRGBO(66, 129, 139, 1),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _navigateToStatusScreen(context); // Navigate to StatusScreen with nip
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        padding: EdgeInsets.symmetric(vertical: 5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/4.png',
                            width: 55,
                            height: 75,
                            fit: BoxFit.cover,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'STATUS',
                            style: TextStyle(
                              fontSize: 18,
                              color: Color.fromRGBO(66, 129, 139, 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
