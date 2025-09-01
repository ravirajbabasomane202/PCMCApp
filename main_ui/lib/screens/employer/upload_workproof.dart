// lib/screens/employer/upload_workproof.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/file_service.dart';
import '../../services/grievance_service.dart';  // Assume upload method

class UploadWorkproof extends StatefulWidget {
  const UploadWorkproof({super.key});

  @override
  State<UploadWorkproof> createState() => _UploadWorkproofState();
}

class _UploadWorkproofState extends State<UploadWorkproof> {
  File? file;
  String notes = '';

  Future<void> _pickFile() async {
  final files = await FileService.pickFiles();
  if (files.isNotEmpty) {
    final platformFile = files.first; // PlatformFile
    setState(() {
      file = File(platformFile.path!); // Convert using path
    });
  }
}


  void _upload() async {
    if (file != null) {
      // await GrievanceService.uploadWorkproof(file!, notes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Workproof')),
      body: Column(
        children: [
          ElevatedButton(onPressed: _pickFile, child: const Text('Pick File')),
          TextFormField(onChanged: (v) => notes = v, decoration: const InputDecoration(labelText: 'Notes')),
          ElevatedButton(onPressed: _upload, child: const Text('Upload')),
        ],
      ),
    );
  }
}