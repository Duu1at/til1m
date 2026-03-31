import 'package:flutter/material.dart';

class WordDetailScreen extends StatelessWidget {
  const WordDetailScreen({required this.wordId, super.key});

  final String wordId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Слово')),
      body: Center(
        child: Text('Word Detail: $wordId — в разработке'),
      ),
    );
  }
}
