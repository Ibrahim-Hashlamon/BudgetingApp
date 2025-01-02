import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

class EditTransactionScreen extends StatefulWidget {
  final Map<String, dynamic> transaction;
  final Function onSave;

  const EditTransactionScreen({
    super.key,
    required this.transaction,
    required this.onSave,
  });

  @override
  _EditTransactionScreenState createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late String _type;
  late String? _category;
  List<Map<String, dynamic>> _categories = [];
  late Database _database;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.transaction['title']);
    _amountController = TextEditingController(
        text: widget.transaction['amount'].toString());
    _type = widget.transaction['type'];
    _category = widget.transaction['category'];
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    final databasePath = await getDatabasesPath();
    _database = await openDatabase(
      path.join(databasePath, 'budgeting_app.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            amount REAL,
            category TEXT,
            type TEXT,
            date TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            type TEXT
          )
        ''');
      },
    );
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final List<Map<String, dynamic>> categories = await _database.query(
      'categories',
      where: 'type = ?',
      whereArgs: [_type],
    );

    setState(() {
      _categories = categories;
      if (_categories.isNotEmpty &&
          !_categories.any((c) => c['name'] == _category)) {
        _category = _categories.first['name'];
      } else if (_categories.isEmpty) {
        _category = null;
      }
    });
  }

  Future<void> _addCategory(String name) async {
    await _database.insert('categories', {
      'name': name,
      'type': _type,
    });
    _fetchCategories();
  }

  Future<void> _saveTransaction() async {
    await _database.update(
      'transactions',
      {
        'title': _titleController.text,
        'amount': double.parse(_amountController.text),
        'category': _category,
        'type': _type,
        'date': widget.transaction['date'],
      },
      where: 'id = ?',
      whereArgs: [widget.transaction['id']],
    );
    widget.onSave();
    Navigator.pop(context);
  }

  void _openCategoryDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext dialogContext) => CategoryDialog(
        onAddCategory: (name) {
          _addCategory(name);
          Navigator.pop(dialogContext);
        },
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                items: _categories
                    .map((category) => category['name'])
                    .toSet()
                    .map((uniqueName) {
                  return DropdownMenuItem<String>(
                    value: uniqueName,
                    child: Text(uniqueName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _category = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Category',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _openCategoryDialog,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _type,
                items: const [
                  DropdownMenuItem(value: 'Income', child: Text('Income')),
                  DropdownMenuItem(value: 'Expense', child: Text('Expense')),
                ],
                onChanged: (value) {
                  setState(() {
                    _type = value!;
                    _fetchCategories();
                  });
                },
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveTransaction,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryDialog extends StatelessWidget {
  final Function(String) onAddCategory;

  const CategoryDialog({super.key, required this.onAddCategory});

  @override
  Widget build(BuildContext context) {
    TextEditingController categoryController = TextEditingController();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: categoryController,
            decoration: const InputDecoration(labelText: 'Category Name'),
          ),
          ElevatedButton(
            onPressed: () {
              if (categoryController.text.isNotEmpty) {
                onAddCategory(categoryController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add Category'),
          ),
        ],
      ),
    );
  }
}
