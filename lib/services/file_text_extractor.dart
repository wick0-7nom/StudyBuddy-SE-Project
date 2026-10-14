import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class FileTextExtractor {
  static Future<String?> pickAndExtractText() async {
    try {
      // 🌐 FileType.any দিয়ে সব ফরম্যাটের ফাইল সিলেক্ট করার অপশন দেওয়া হলো
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.single.path == null) return null;

      File file = File(result.files.single.path!);
      String extension = result.files.single.extension?.toLowerCase() ?? '';

      // 1. PDF Files (.pdf)
      if (extension == 'pdf') {
        final PdfDocument document = PdfDocument(inputBytes: await file.readAsBytes());
        String text = PdfTextExtractor(document).extractText();
        document.dispose();
        return text;
      }

      // 2. All Image Formats (JPG, PNG, WEBP, BMP) - OCR
      else if (['jpg', 'jpeg', 'png', 'webp', 'bmp'].contains(extension)) {
        final inputImage = InputImage.fromFile(file);
        final textRecognizer = TextRecognizer();
        final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
        await textRecognizer.close();
        return recognizedText.text;
      }

      // 3. MS Word Documents (.docx)
      else if (extension == 'docx') {
        final bytes = await file.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);
        for (final archiveFile in archive) {
          if (archiveFile.name == 'word/document.xml') {
            final content = utf8.decode(archiveFile.content as List<int>);
            return content
                .replaceAll(RegExp(r'<[^>]*>'), ' ')
                .replaceAll(RegExp(r'\s+'), ' ')
                .trim();
          }
        }
      }

      // 4. MS PowerPoint Presentations (.pptx)
      else if (extension == 'pptx') {
        final bytes = await file.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);
        StringBuffer slideTexts = StringBuffer();

        for (final archiveFile in archive) {
          if (archiveFile.name.startsWith('ppt/slides/slide') && archiveFile.name.endsWith('.xml')) {
            final content = utf8.decode(archiveFile.content as List<int>);
            String slideText = content
                .replaceAll(RegExp(r'<[^>]*>'), ' ')
                .replaceAll(RegExp(r'\s+'), ' ')
                .trim();
            slideTexts.writeln(slideText);
          }
        }
        return slideTexts.toString();
      }

      // 5. Plain Text, Code, CSV, Markdown, Logs, JSON, HTML
      else {
        try {
          return await file.readAsString();
        } catch (e) {
          print('Binary or unsupported text stream: $e');
          return null;
        }
      }
    } catch (e) {
      print('Error extracting text: $e');
      return null;
    }
  }
}