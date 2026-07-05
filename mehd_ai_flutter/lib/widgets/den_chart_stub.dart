import 'package:flutter/material.dart';

class DenChart extends StatefulWidget {
  final String symbol;
  final String interval;
  final double basePrice;
  final bool isAutoMode;
  final String activeTool;
  final List<Map<String, dynamic>> commands;
  final Function(Map) onEvent;

  const DenChart({
    required this.symbol,
    this.interval = '1m',
    required this.basePrice,
    required this.isAutoMode,
    this.activeTool = 'none',
    this.commands = const [],
    required this.onEvent,
    super.key,
  });

  @override
  State<DenChart> createState() => DenChartState();
}

class DenChartState extends State<DenChart> {
  void clearDrawings() {}

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('DenChart requires Web'));
  }
}
