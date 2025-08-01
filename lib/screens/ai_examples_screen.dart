import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// AI 예문 생성 전용 화면
class AiExamplesScreen extends StatefulWidget {
  final String term;
  const AiExamplesScreen({super.key, required this.term});

  @override
  State<AiExamplesScreen> createState() => _AiExamplesScreenState();
}

class _AiExamplesScreenState extends State<AiExamplesScreen> {
  final ApiService _api = ApiService();
  List<String>? _examples;
  bool _isLoading = false;

  Future<void> _generateExamples() async {
    setState(() {
      _isLoading = true;
      _examples = null;
    });
    try {
      final result = await _api.generateExamplesWithAI(widget.term);
      setState(() => _examples = result);
    } catch (e) {
      setState(() => _examples = ['Error: \$e']);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _generateExamples(); // 화면 진입 시 바로 예문 생성
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('"${widget.term}"에 대한 AI 예문'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(_isLoading ? '생성 중...' : '다시 생성'),
              onPressed: _isLoading ? null : _generateExamples,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),
            if (_examples != null) ...[
              const Text('AI가 생성한 예문:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _examples!.length,
                  itemBuilder: (context, index) {
                    final ex = _examples![index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('• \$ex'),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
