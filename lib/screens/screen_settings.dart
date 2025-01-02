import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:incredible_budgeting_app_fixed/theme_provider.dart';
import 'package:sqflite/sqflite.dart';


class SettingsScreen extends StatelessWidget {
  final Future<Database> database;


  const SettingsScreen({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: const Text('Dark Mode'),
              trailing: Switch(
                value: themeProvider.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  themeProvider.toggleTheme();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}