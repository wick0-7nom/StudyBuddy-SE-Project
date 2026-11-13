import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PDFHelper {
  static Future<String?> extractTextFromPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final File file = File(result.files.single.path!);
      final PdfDocument document = PdfDocument(inputBytes: await file.readAsBytes());

      String text = PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    }
    return null;
  }
}