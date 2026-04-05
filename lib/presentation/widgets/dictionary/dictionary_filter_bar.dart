import 'package:flutter/material.dart';
import 'package:til1m/presentation/blocs/blocs.dart';
import 'package:til1m/presentation/widgets/widgets.dart';

class DictionaryFilterBar extends StatelessWidget {
  const DictionaryFilterBar({required this.state, super.key});

  final DictionaryLoaded state;

  static const double height = 88;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatusRow(statusFilter: state.statusFilter),
        LevelAndSortRow(levelFilter: state.levelFilter, sort: state.sort),
      ],
    );
  }
}
