import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

@immutable
final class WordExample extends Equatable {
  const WordExample({
    required this.exampleEn,
    this.exampleRu,
    this.exampleKy,
    this.orderIndex = 0,
  });

  final String exampleEn;
  final String? exampleRu;
  final String? exampleKy;
  final int orderIndex;

  @override
  List<Object?> get props => [exampleEn, exampleRu, exampleKy, orderIndex];
}
