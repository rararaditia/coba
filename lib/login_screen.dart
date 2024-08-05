import 'package:flutter/material.dart';

import 'admin1_screen.dart';
import 'admin2_screen.dart';
import 'admin3_screen.dart';
import 'home_screen.dart';
import 'super_admin_home_screen.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login(BuildContext context) async {
    String username = _usernameController.text;
    String password = _passwordController.text;

    // Fungsi untuk memeriksa kredensial di Firestore
    Future<DocumentSnapshot?> checkCredentials(String collection, String username, String password) async {
      var query = await FirebaseFirestore.instance
          .collection(collection)
          .where('username', isEqualTo: username)
          .where('password', isEqualTo: password)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first;
      }
      return null;
    }

    DocumentSnapshot? userDoc;
    String role = '';

    // Cek untuk pegawai
    userDoc = await checkCredentials('pegawai', username, password);
    if (userDoc != null) {
      role = 'pegawai';
    }

    // Cek untuk admin
    if (userDoc == null) {
      userDoc = await checkCredentials('admin', username, password);
      if (userDoc != null) {
        role = userDoc['role'];
      }
    }

    // Cek untuk superadmin
    if (userDoc == null) {
      userDoc = await checkCredentials('superadmin', username, password);
      if (userDoc != null) {
        role = 'superadmin';
      }
    }

    if (userDoc != null) {
      String nip = userDoc['nip'];

      // Redirect berdasarkan role
      if (role == 'pegawai') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(nip: nip)),
        );
      } else if (role == 'admin1') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Admin1Screen()),
        );
      } else if (role == 'admin2') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Admin2Screen()),
        );
      } else if (role == 'admin3') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Admin3Screen()),
        );
      } else if (role == 'superadmin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SuperAdminHomeScreen()),
        );
      }
    } else {
      // Invalid login
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Login Gagal'),
            content: Text('Username atau password salah.'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
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
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromRGBO(66, 129, 139, 1),
                  Color.fromRGBO(66, 129, 139, 0.6),
                ],
              ),
            ),
          ),
          Positioned(
            top: 15,
            left: 20,
            child: Image.asset(
              'assets/images/logo.png',
              width: 150,
              height: 150,
            ),
          ),
          Positioned(
            bottom: -40,
            left: -10,
            right: -5,
            child: Image.asset(
              'assets/images/wave.png',
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image.asset(
                    'assets/images/docuserv.png',
                    width: 380, // Adjust the width and height as needed
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 0), // Add spacing between images
                  Image.asset(
                    'assets/images/doc.png',
                    width: 300, // Adjust the width and height as needed
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 20), // Adjust spacing between the image and text fields
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Masukkan username anda',
                      labelText: 'Username',
                      hintStyle: TextStyle(
                        color: Colors.black.withOpacity(0.5), // Set opacity here
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Masukkan password anda',
                      labelText: 'Password',
                      hintStyle: TextStyle(
                        color: Colors.black.withOpacity(0.5), // Set opacity here
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () => _login(context),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      backgroundColor: Color.fromARGB(255, 183, 219, 219),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    child: Text(
                      'Login',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color.fromARGB(255, 15, 124, 143),
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
