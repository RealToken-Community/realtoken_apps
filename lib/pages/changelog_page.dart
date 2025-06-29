import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;

class ChangelogPage extends StatefulWidget {
  const ChangelogPage({super.key});

  @override
  _ChangelogPageState createState() => _ChangelogPageState();
}

class _ChangelogPageState extends State<ChangelogPage> {
  String _markdownData = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMarkdown();
  }

  Future<void> _fetchMarkdown() async {
    const url =
        'https://raw.githubusercontent.com/RealToken-Community/realtoken_apps/refs/heads/main/CHANGELOG.md';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          _markdownData = response.body;
          _isLoading = false;
        });
      } else {
        setState(() {
          _markdownData =
              'Erreur lors du chargement du contenu (code: ${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _markdownData = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Changelog'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Markdown(
              data: _markdownData,
              padding: const EdgeInsets.all(16.0),
            ),
    );
  }
}
