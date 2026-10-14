import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class DriveUploadService {
  // 🔗 Google Apps Script Web App URL
  static const String scriptUrl = 'https://script.google.com/macros/s/AKfycbxAVVU086eP5G1hsvCPI4wk9M2IV9R15ozxgOvDpXK5zU6C2V15xDoTtnHjh2NY1hAnew/exec';

  static Future<Map<String, String>?> pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.single.path == null) {
        print('⚠️ No file selected.');
        return null;
      }

      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      final extension = result.files.single.extension?.toLowerCase() ?? '';

      print('📂 File Selected: $fileName (${await file.length()} bytes)');

      String mimeType = 'application/octet-stream';
      if (extension == 'pdf') mimeType = 'application/pdf';
      else if (extension == 'jpg' || extension == 'jpeg') mimeType = 'image/jpeg';
      else if (extension == 'png') mimeType = 'image/png';
      else if (extension == 'doc' || extension == 'docx') mimeType = 'application/msword';
      else if (extension == 'ppt' || extension == 'pptx') mimeType = 'application/vnd.ms-powerpoint';
      else if (extension == 'txt') mimeType = 'text/plain';

      final fileBytes = await file.readAsBytes();
      final base64File = base64Encode(fileBytes);

      print('🚀 Sending request to Google Apps Script...');

      // 🟢 Redirect ম্যানুয়ালি হ্যান্ডেল করার জন্য Client & Request তৈরি
      final client = http.Client();
      final request = http.Request('POST', Uri.parse(scriptUrl))
        ..followRedirects = false
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({
          'file': base64File,
          'filename': fileName,
          'mimetype': mimeType,
        });

      final streamedResponse = await client.send(request);
      var response = await http.Response.fromStream(streamedResponse);

      print('📡 Initial Response Status Code: ${response.statusCode}');

      // 🟢 Google Apps Script 302/301 Redirect দিলে নতুন Location থেকে JSON ডাটা নিয়ে আসা
      if (response.statusCode == 302 || response.statusCode == 301 || response.statusCode == 307) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          print('🔄 Following Redirect to: $redirectUrl');
          response = await client.get(Uri.parse(redirectUrl));
        }
      }

      print('📡 Final Response Status Code: ${response.statusCode}');
      print('📄 Final Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          print('✅ Upload Success! Link: ${data['fileUrl']}');
          return {
            'fileUrl': data['fileUrl'] as String,
            'fileName': fileName,
          };
        } else {
          print('❌ Apps Script Returned Error: ${data['message']}');
        }
      }
      return null;
    } catch (e, stackTrace) {
      print('💥 Exception during upload: $e');
      print('📌 StackTrace: $stackTrace');
      return null;
    }
  }
}