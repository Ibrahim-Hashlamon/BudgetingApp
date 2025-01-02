import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';


class ReportsScreen extends StatelessWidget {
  final Future<Database> database;

  const ReportsScreen({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
  return const Center(child: Text('Reports Placeholder'));
  }}