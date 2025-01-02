import 'screens/screen_dashboard.dart';
import 'screens/screen_transactions.dart';
import 'screens/screen_reports.dart';
import 'screens/screen_settings.dart';
import 'package:incredible_budgeting_app_fixed/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Advanced Budgeting App with Functional Dashboard and Fixed Transaction Categories

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = openDatabase(
    join(await getDatabasesPath(), 'budgeting_app.db'),
    onCreate: (db, version) async {
      await db.execute(
        'CREATE TABLE transactions(id INTEGER PRIMARY KEY, title TEXT, amount REAL, type TEXT, category TEXT, date TEXT)',
      );
      await db.execute(
        'CREATE TABLE categories(id INTEGER PRIMARY KEY, name TEXT, type TEXT)',
      );
      // Insert default categories
      await db.insert('categories', {'name': 'Food', 'type': 'expense'});
      await db.insert('categories', {'name': 'Rent', 'type': 'expense'});
      await db.insert('categories', {'name': 'Utilities', 'type': 'expense'});
      await db.insert('categories', {'name': 'Salary', 'type': 'income'});
      await db.insert('categories', {'name': 'Investments', 'type': 'income'});
    },
    version: 1,
  );


  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: BudgetingApp(database: database),
    ),
  );
}

class BudgetingApp extends StatelessWidget {
  final Future<Database> database;

  const BudgetingApp({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Budgeting App',
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        brightness:  Brightness.light,
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      darkTheme: ThemeData(
      brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      home: HomeScreen(database: database),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Future<Database> database;

  const HomeScreen({super.key, required this.database});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(database: widget.database),
      TransactionsScreen(database: widget.database),
      ReportsScreen(database: widget.database),
      SettingsScreen(database: widget.database),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.list), label: 'Transactions'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Reports'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}


