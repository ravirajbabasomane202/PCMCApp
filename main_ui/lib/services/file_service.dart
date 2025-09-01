// lib/services/file_service.dart
import 'package:file_picker/file_picker.dart';

class FileService {
  static Future<List<PlatformFile>> pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg'],
    );
    if (result != null) {
      return result.files;
    }
    return [];
  }
}