import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'revisipermohonan.dart'; // Make sure to import the new screen

class StatusScreen extends StatelessWidget {
  final String nip;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  StatusScreen({required this.nip});

  Future<void> _showRejectionReason(BuildContext context, String requestId) async {
    final rejectionDoc = await FirebaseFirestore.instance
        .collection('penolakan')
        .where('requestId', isEqualTo: requestId)
        .get();

    if (rejectionDoc.docs.isNotEmpty) {
      final reason = rejectionDoc.docs.first['alasan'];

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Alasan Penolakan"),
            content: Text(reason),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak ada alasan penolakan yang ditemukan')),
      );
    }
  }

  Future<void> _downloadFile(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  void _navigateToRevisi(BuildContext context, String requestId, String documentType) {
    // Navigate to the RevisiPermohonanScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RevisiPermohonanScreen(
          nip: nip,
          requestId: requestId,
          documentType: documentType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Status Pengajuan'),
        backgroundColor: Color.fromRGBO(66, 129, 139, 1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Text(
                'STATUS PENGAJUAN',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'PENGAJUAN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(66, 129, 139, 1),
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('request')
                    .where('nip', isEqualTo: nip)
                    .orderBy('date', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'TIDAK ADA PENGAJUAN TERBARU',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(66, 129, 139, 1),
                        ),
                      ),
                    );
                  }

                  final submissions = snapshot.data!.docs.map((doc) {
                    final timestamp = doc['date'] as Timestamp;
                    final formattedDate = _dateFormat.format(timestamp.toDate());

                    return {
                      'title': doc['tipedok'],
                      'status': doc['status'],
                      'date': formattedDate,
                      'requestId': doc.id,
                      'respon': doc['respon'] ?? '', // Add file URL
                    };
                  }).toList();

                  return ListView(
                    children: submissions.map((submission) {
                      return Container(
                        margin: EdgeInsets.only(bottom: 10),
                        padding: EdgeInsets.all(16),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              submission['title']!,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color.fromRGBO(66, 129, 139, 1),
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Status : ${submission['status']}',
                              style: TextStyle(
                                fontSize: 16,
                                color: submission['status'] == 'Ditolak'
                                    ? Colors.red
                                    : (submission['status'] == 'Disetujui'
                                        ? Colors.green
                                        : (submission['status'] == 'Perlu Direvisi'
                                            ? Colors.brown
                                            : Colors.yellow[800])),
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Date : ${submission['date']}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 10),
                            if (submission['status'] == 'Disetujui' && submission['respon']!.isNotEmpty)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => _downloadFile(submission['respon']!),
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.grey.shade400,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15.0),
                                    ),
                                  ),
                                  child: Text(
                                    'Download disini',
                                    style: TextStyle(
                                      color: Color.fromRGBO(66, 129, 139, 1),
                                    ),
                                  ),
                                ),
                              ),
                            if (submission['status'] == 'Ditolak')
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => _showRejectionReason(context, submission['requestId']!),
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.grey.shade400,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15.0),
                                    ),
                                  ),
                                  child: Text(
                                    'Lihat Detail',
                                    style: TextStyle(
                                      color: Color.fromRGBO(66, 129, 139, 1),
                                    ),
                                  ),
                                ),
                              ),
                            if (submission['status'] == 'Perlu Direvisi')
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => _navigateToRevisi(context, submission['requestId']!, submission['title']!),
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.grey.shade400,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15.0),
                                    ),
                                  ),
                                  child: Text(
                                    'Revisi Sekarang',
                                    style: TextStyle(
                                      color: Color.fromRGBO(66, 129, 139, 1),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
