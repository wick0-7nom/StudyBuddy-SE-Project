import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../services/file_text_extractor.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  String _extractedText = '';
  String _aiOutput = '';
  bool _isLoading = false;

  // সামারি টাইপ বেছে নেওয়ার ভ্যারিয়েবল ('lda' অথবা 'ai')
  String _summaryType = 'lda';

  // 🎨 আপনার অ্যাপের থিম কালার (স্ক্রিনশট অনুযায়ী)
  final Color appBgColor = const Color(0xFF121212);
  final Color creamAccentColor = const Color(0xFFEBE4D5);
  final Color themeDarkText = const Color(0xFF1E1E1E);

  Future<void> _processFile({required String type}) async {
    if (_extractedText.isEmpty) {
      final text = await FileTextExtractor.pickAndExtractText();
      if (text != null && text.trim().isNotEmpty) {
        _extractedText = text;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No readable text found or no file selected.')),
          );
        }
        return;
      }
    }

    setState(() => _isLoading = true);

    String? result;
    if (type == 'lda') {
      result = await AIService.generateLdaSummary(_extractedText);
    } else if (type == 'ai') {
      result = await AIService.generateAiSummary(_extractedText);
    } else if (type == 'quiz') {
      result = await AIService.generateQuiz(_extractedText);
    }

    setState(() {
      _aiOutput = result ?? 'Error generating content.';
      _isLoading = false;
    });
  }

  void _changeFile() {
    setState(() {
      _extractedText = '';
      _aiOutput = '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File cleared. Select a new file now.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // কুইজ বাটন শুধুমাত্র Gemini (ai) সিলেক্ট থাকলে কাজ করবে
    bool isQuizEnabled = _summaryType == 'ai';

    return Scaffold(
      backgroundColor: appBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('✨ AI Study Assistant', style: TextStyle(color: Colors.white, fontSize: 18)),
        centerTitle: true,
        actions: [
          if (_extractedText.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Change File',
              onPressed: _changeFile,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Column(
          children: [
            // 🔘 Option Selection Row (Overflow Fixed & Icon Fixed)
            Row(
              children: [
                const Text("Option: ", style: TextStyle(color: Colors.white70, fontSize: 15)),
                const SizedBox(width: 8),

                // 1st Option: LDA
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _summaryType = 'lda'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      decoration: BoxDecoration(
                        color: _summaryType == 'lda' ? creamAccentColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _summaryType == 'lda' ? creamAccentColor : Colors.white24,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_summaryType == 'lda') ...[
                            Icon(Icons.check, color: themeDarkText, size: 18), // বৃত্ত ছাড়া চেক আইকন
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                            child: Text(
                              "LDA Keywords",
                              style: TextStyle(
                                color: _summaryType == 'lda' ? themeDarkText : Colors.white70,
                                fontWeight: _summaryType == 'lda' ? FontWeight.bold : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // 2nd Option: Gemini AI
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _summaryType = 'ai'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      decoration: BoxDecoration(
                        color: _summaryType == 'ai' ? creamAccentColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _summaryType == 'ai' ? creamAccentColor : Colors.white24,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_summaryType == 'ai') ...[
                            Icon(Icons.check, color: themeDarkText, size: 18), // বৃত্ত ছাড়া চেক আইকন
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                            child: Text(
                              "Gemini AI",
                              style: TextStyle(
                                color: _summaryType == 'ai' ? themeDarkText : Colors.white70,
                                fontWeight: _summaryType == 'ai' ? FontWeight.bold : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 🔘 Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _processFile(type: _summaryType),
                    icon: const Icon(Icons.description, size: 18),
                    label: Text(_summaryType == 'lda' ? 'LDA Summary' : 'AI Summary', style: const TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: creamAccentColor,
                      foregroundColor: themeDarkText,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_isLoading || !isQuizEnabled) ? null : () => _processFile(type: 'quiz'),
                    icon: const Icon(Icons.quiz, size: 18),
                    label: const Text('Generate Quiz', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: creamAccentColor,
                      foregroundColor: themeDarkText,
                      disabledBackgroundColor: const Color(0xFF2A2A2A),
                      disabledForegroundColor: Colors.white30,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),

            // 💡 Hint Message
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: !isQuizEnabled ? 30 : 0,
              curve: Curves.easeInOut,
              alignment: Alignment.center,
              margin: const EdgeInsets.only(top: 8),
              child: !isQuizEnabled
                  ? const Text("* Quiz generation is only available with Gemini AI",
                  style: TextStyle(color: Colors.white54, fontSize: 12))
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 16),

            // 📄 Output View (Transparent Glass Box)
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: _isLoading
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: creamAccentColor),
                    const SizedBox(height: 16),
                    const Text("Processing Document...", style: TextStyle(color: Colors.white70)),
                  ],
                )
                    : SingleChildScrollView(
                  child: _aiOutput.isEmpty
                      ? const Center(
                    child: Text(
                      'Upload any file to generate Summary or Quiz!',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  )
                      : SelectableText(
                    _aiOutput,
                    style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}