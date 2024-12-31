import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';


class ReportsScreen extends StatelessWidget {
  final Future<Database> database;

  const ReportsScreen({Key? key, required this.database}) : super(key: key);

  @override
  Widget build(BuildContext context) {
  return const Center(child: Text('Reports Placeholder'));
  }}