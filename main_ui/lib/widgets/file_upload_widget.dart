// lib/widgets/file_upload_widget.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';

import 'dart:io' as io;
import '../services/file_service.dart';


class FileUploadWidget extends StatefulWidget {
  final Function(List<PlatformFile>) onFilesSelected; // Updated type
  const FileUploadWidget({super.key, required this.onFilesSelected});

  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  List<PlatformFile> files = []; // Updated type

  Future<void> _pickFiles() async {
    final newFiles = await FileService.pickFiles();
    if (files.length + newFiles.length > 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Max 10 files')));
    } else {
      setState(() => files.addAll(newFiles));
      widget.onFilesSelected(files);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(onPressed: _pickFiles, child: const Text('Upload Files')),
        ...files.map((file) {
          final mimeType = lookupMimeType(file.name); // Use name
          if (mimeType?.startsWith('image/') ?? false) {
            if (kIsWeb) {
              return Image.memory(file.bytes!, height: 100); // Web: Use bytes
            } else {
              return Image.file(io.File(file.path!), height: 100); // Non-web: Use path
            }
          } else {
            return const Icon(Icons.picture_as_pdf, size: 100);
          }
        }),
      ],
    );
  }
}