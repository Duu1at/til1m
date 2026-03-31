import 'package:flutter/material.dart';

class WordDetailScreen extends StatelessWidget {
  final String wordId;

  const WordDetailScreen({super.key, required this.wordId});

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
