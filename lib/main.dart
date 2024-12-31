<<<<<<< HEAD
// Advanced Budgeting App with Functional Dashboard and Fixed Transaction Categories

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';

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

  runApp(BudgetingApp(database: database));
}

class BudgetingApp extends StatelessWidget {
  final Future<Database> database;

  const BudgetingApp({Key? key, required this.database}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Budgeting App',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      home: HomeScreen(database: database),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Future<Database> database;

  const HomeScreen({Key? key, required this.database}) : super(key: key);

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

class DashboardScreen extends StatefulWidget {
  final Future<Database> database;

  const DashboardScreen({Key? key, required this.database}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _totalIncome = 0;
  double _totalExpenses = 0;
  List<Map<String, dynamic>> _expenseBreakdown = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    final db = await widget.database;

    // Fetch total income
    final incomeResult = await db.rawQuery(
        'SELECT SUM(amount) as total FROM transactions WHERE type = ?', ['income']);
    _totalIncome = (incomeResult.first['total'] as num?)?.toDouble() ?? 0;

    // Fetch total expenses
    final expenseResult = await db.rawQuery(
        'SELECT SUM(amount) as total FROM transactions WHERE type = ?', ['expense']);
    _totalExpenses = (expenseResult.first['total'] as num?)?.toDouble() ?? 0;

    // Fetch expense breakdown by category
    final breakdownResult = await db.rawQuery(
        'SELECT category, SUM(amount) as total FROM transactions WHERE type = ? GROUP BY category',
        ['expense']);
    setState(() {
      _expenseBreakdown = breakdownResult;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentMonth = DateFormat('MMMM').format(DateTime.now()); // Get the current month

    return Scaffold(
      appBar: AppBar(
        title: Text('Budget for $currentMonth'), // Display the month dynamically
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Budget Overview',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSummaryCard('Income', _totalIncome, Colors.green),
                _buildSummaryCard('Expenses', _totalExpenses, Colors.red),
                _buildSummaryCard('Savings', _totalIncome - _totalExpenses, Colors.teal),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Expense Breakdown for $currentMonth', // Include month in breakdown title
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _expenseBreakdown.isEmpty
                ? const Text('No data available')
                : SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _expenseBreakdown
                      .map((data) => PieChartSectionData(
                    color: Colors.primaries[
                    data['category'].hashCode % Colors.primaries.length],
                    value: (data['total'] as num).toDouble(),
                    title: data['category'],
                    radius: 50,
                  ))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double value, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${value.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}


  Widget _buildSummaryCard(String title, double value, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${value.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }


class TransactionsScreen extends StatefulWidget {
  final Future<Database> database;

  const TransactionsScreen({Key? key, required this.database}) : super(key: key);

  @override
  _TransactionsScreenState createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    final db = await widget.database;
    final transactions = await db.query('transactions', orderBy: 'date DESC');
    setState(() {
      _transactions = transactions;
    });
  }

  Future<void> _deleteTransaction(int id) async {
    final db = await widget.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    _fetchTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        centerTitle: true,
      ),
      body: _transactions.isEmpty
          ? const Center(
        child: Text('No transactions available'),
      )
          : ListView.builder(
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final transaction = _transactions[index];
          return ListTile(
            leading: Icon(
              transaction['type'] == 'income'
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              color: transaction['type'] == 'income' ? Colors.green : Colors.red,
            ),
            title: Text(transaction['title']),
            subtitle: Text(
              '${transaction['category']} - ${DateFormat('yyyy-MM-dd').format(DateTime.parse(transaction['date']))}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$${transaction['amount'].toStringAsFixed(2)}',
                  style: TextStyle(
                    color: transaction['type'] == 'income' ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteTransaction(transaction['id']),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionScreen(database: widget.database),
            ),
          );
          _fetchTransactions();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddTransactionScreen extends StatefulWidget {
  final Future<Database> database;

  const AddTransactionScreen({Key? key, required this.database}) : super(key: key);

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _type = 'expense';
  String? _selectedCategory;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories(); // Load categories when screen loads
  }

  Future<void> _fetchCategories() async {
    final db = await widget.database;
    final categories = await db.query('categories', where: 'type = ?', whereArgs: [_type]);
    setState(() {
      _categories = categories.map((e) => e['name'] as String).toList();
      _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            DropdownButton<String>(
              value: _type,
              items: const [
                DropdownMenuItem(
                  value: 'expense',
                  child: Text('Expense'),
                ),
                DropdownMenuItem(
                  value: 'income',
                  child: Text('Income'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _type = value!;
                  _fetchCategories();
                });
              },
            ),
            DropdownButton<String?>(
              value: _selectedCategory,
              hint: const Text('Select Category'),
              items: _categories.isEmpty
                  ? [
                const DropdownMenuItem(
                  value: null,
                  child: Text('No Categories Available'),
                ),
              ]
                  : _categories
                  .map((category) => DropdownMenuItem(
                value: category,
                child: Text(category),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_titleController.text.isEmpty ||
                    _amountController.text.isEmpty ||
                    _selectedCategory == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields.')),
                  );
                  return;
                }

                final db = await widget.database;
                final formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
                await db.insert(
                  'transactions',
                  {
                    'title': _titleController.text,
                    'amount': double.parse(_amountController.text),
                    'type': _type,
                    'category': _selectedCategory,
                    'date': formattedDate,
                  },
                );
                Navigator.pop(context);
              },
              child: const Text('Add Transaction'),
            ),
          ],
        ),
      ),
    );
  }
}

class ReportsScreen extends StatelessWidget {
  final Future<Database> database;

  const ReportsScreen({Key? key, required this.database}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Reports Placeholder'));
  }
}

class SettingsScreen extends StatelessWidget {
  final Future<Database> database;

  const SettingsScreen({Key? key, required this.database}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Settings Placeholder'));
  }
}
=======
// Advanced Budgeting App with Functional Dashboard and Fixed Transaction Categories

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';

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

  runApp(BudgetingApp(database: database));
}

class BudgetingApp extends StatelessWidget {
  final Future<Database> database;

  const BudgetingApp({Key? key, required this.database}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Budgeting App',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      home: HomeScreen(database: database),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Future<Database> database;

  const HomeScreen({Key? key, required this.database}) : super(key: key);

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

class DashboardScreen extends StatefulWidget {
  final Future<Database> database;

  const DashboardScreen({Key? key, required this.database}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _totalIncome = 0;
  double _totalExpenses = 0;
  List<Map<String, dynamic>> _expenseBreakdown = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    final db = await widget.database;

    // Fetch total income
    final incomeResult = await db.rawQuery(
        'SELECT SUM(amount) as total FROM transactions WHERE type = ?', ['income']);
    _totalIncome = (incomeResult.first['total'] as num?)?.toDouble() ?? 0;

    // Fetch total expenses
    final expenseResult = await db.rawQuery(
        'SELECT SUM(amount) as total FROM transactions WHERE type = ?', ['expense']);
    _totalExpenses = (expenseResult.first['total'] as num?)?.toDouble() ?? 0;

    // Fetch expense breakdown by category
    final breakdownResult = await db.rawQuery(
        'SELECT category, SUM(amount) as total FROM transactions WHERE type = ? GROUP BY category',
        ['expense']);
    setState(() {
      _expenseBreakdown = breakdownResult;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentMonth = DateFormat('MMMM').format(DateTime.now()); // Get the current month

    return Scaffold(
      appBar: AppBar(
        title: Text('Budget for $currentMonth'), // Display the month dynamically
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Budget Overview',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSummaryCard('Income', _totalIncome, Colors.green),
                _buildSummaryCard('Expenses', _totalExpenses, Colors.red),
                _buildSummaryCard('Savings', _totalIncome - _totalExpenses, Colors.teal),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Expense Breakdown for $currentMonth', // Include month in breakdown title
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _expenseBreakdown.isEmpty
                ? const Text('No data available')
                : SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _expenseBreakdown
                      .map((data) => PieChartSectionData(
                    color: Colors.primaries[
                    data['category'].hashCode % Colors.primaries.length],
                    value: (data['total'] as num).toDouble(),
                    title: data['category'],
                    radius: 50,
                  ))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double value, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${value.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}


  Widget _buildSummaryCard(String title, double value, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${value.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }


class TransactionsScreen extends StatefulWidget {
  final Future<Database> database;

  const TransactionsScreen({Key? key, required this.database}) : super(key: key);

  @override
  _TransactionsScreenState createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    final db = await widget.database;
    final transactions = await db.query('transactions', orderBy: 'date DESC');
    setState(() {
      _transactions = transactions;
    });
  }

  Future<void> _deleteTransaction(int id) async {
    final db = await widget.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    _fetchTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        centerTitle: true,
      ),
      body: _transactions.isEmpty
          ? const Center(
        child: Text('No transactions available'),
      )
          : ListView.builder(
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final transaction = _transactions[index];
          return ListTile(
            leading: Icon(
              transaction['type'] == 'income'
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              color: transaction['type'] == 'income' ? Colors.green : Colors.red,
            ),
            title: Text(transaction['title']),
            subtitle: Text(
              '${transaction['category']} - ${DateFormat('yyyy-MM-dd').format(DateTime.parse(transaction['date']))}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$${transaction['amount'].toStringAsFixed(2)}',
                  style: TextStyle(
                    color: transaction['type'] == 'income' ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteTransaction(transaction['id']),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionScreen(database: widget.database),
            ),
          );
          _fetchTransactions();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddTransactionScreen extends StatefulWidget {
  final Future<Database> database;

  const AddTransactionScreen({Key? key, required this.database}) : super(key: key);

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _type = 'expense';
  String? _selectedCategory;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories(); // Load categories when screen loads
  }

  Future<void> _fetchCategories() async {
    final db = await widget.database;
    final categories = await db.query('categories', where: 'type = ?', whereArgs: [_type]);
    setState(() {
      _categories = categories.map((e) => e['name'] as String).toList();
      _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            DropdownButton<String>(
              value: _type,
              items: const [
                DropdownMenuItem(
                  value: 'expense',
                  child: Text('Expense'),
                ),
                DropdownMenuItem(
                  value: 'income',
                  child: Text('Income'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _type = value!;
                  _fetchCategories();
                });
              },
            ),
            DropdownButton<String?>(
              value: _selectedCategory,
              hint: const Text('Select Category'),
              items: _categories.isEmpty
                  ? [
                const DropdownMenuItem(
                  value: null,
                  child: Text('No Categories Available'),
                ),
              ]
                  : _categories
                  .map((category) => DropdownMenuItem(
                value: category,
                child: Text(category),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_titleController.text.isEmpty ||
                    _amountController.text.isEmpty ||
                    _selectedCategory == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields.')),
                  );
                  return;
                }

                final db = await widget.database;
                final formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
                await db.insert(
                  'transactions',
                  {
                    'title': _titleController.text,
                    'amount': double.parse(_amountController.text),
                    'type': _type,
                    'category': _selectedCategory,
                    'date': formattedDate,
                  },
                );
                Navigator.pop(context);
              },
              child: const Text('Add Transaction'),
            ),
          ],
        ),
      ),
    );
  }
}

class ReportsScreen extends StatelessWidget {
  final Future<Database> database;

  const ReportsScreen({Key? key, required this.database}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Reports Placeholder'));
  }
}

class SettingsScreen extends StatelessWidget {
  final Future<Database> database;

  const SettingsScreen({Key? key, required this.database}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Settings Placeholder'));
  }
}

git test
>>>>>>> 7fe2c7f (GitTest)
