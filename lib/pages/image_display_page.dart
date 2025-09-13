import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ImageDisplayPage extends StatelessWidget {
  const ImageDisplayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Display'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('clinicDetails').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No images found.'));
          }

          final clinicDetails = snapshot.data!.docs;

          return ListView.builder(
            itemCount: clinicDetails.length,
            itemBuilder: (context, index) {
              final data = clinicDetails[index].data() as Map<String, dynamic>;
              final certifications = data['certifications'] as List<dynamic>?;
              final licenses = data['licenses'] as List<dynamic>?;

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (certifications != null && certifications.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Certifications:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ...certifications.map((cert) {
                        final imageUrl = cert['documentUrl'] as String?;
                        return imageUrl != null
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Image.network(imageUrl, height: 150),
                              )
                            : const SizedBox.shrink();
                      }).toList(),
                    ],
                    if (licenses != null && licenses.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Licenses:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ...licenses.map((license) {
                        final imageUrl = license['licensePictureUrl'] as String?;
                        return imageUrl != null
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Image.network(imageUrl, height: 150),
                              )
                            : const SizedBox.shrink();
                      }).toList(),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
