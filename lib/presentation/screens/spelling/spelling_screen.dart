import 'package:flutter/material.dart';

class SpellingScreen extends StatelessWidget {
  const SpellingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Написание')),
      body: const Center(child: Text('Написание — в разработке')),
    );
  }
}
