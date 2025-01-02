import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import 'screen_edit_transactions.dart';

class TransactionsScreen extends StatefulWidget {
  final Future<Database> database;
  const TransactionsScreen({super.key, required this.database});

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
          return InkWell(
            onTap: () async {
              // Navigate to EditTransactionScreen with the selected transaction
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditTransactionScreen(transaction: transaction,
                  onSave: (){
                    setState((){
                      _fetchTransactions();
                    });
                  }),
                ),
              );
              if (result == 'updated') {
                // Refresh the transaction list
                _fetchTransactions();
              }
            },
            child: ListTile(
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
            ),
          );
        },
      ),

        floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddTransactionScreen(database: widget.database),
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

  const AddTransactionScreen({super.key, required this.database});

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _type = 'expense';
  String? _selectedCategory;
  List<String> _categories = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final db = await widget.database;
    final categories =
    await db.query('categories', where: 'type = ?', whereArgs: [_type]);
    setState(() {
      _categories = categories.map((e) => e['name'] as String).toList();
      _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
    });
  }

  Future<void> _addCategory(String categoryName) async {
    final db = await widget.database;
    await db.insert('categories', {'name': categoryName, 'type': _type});
    _fetchCategories(); // Refresh categories after adding a new one
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
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
    const SizedBox(height: 20),
    TextField(
    controller: _amountController,
    decoration: const InputDecoration(labelText: 'Amount'),
    keyboardType: TextInputType.number,
    ),
      const SizedBox(height: 20),
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
    _fetchCategories(); // Refresh categories when type changes
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
    TextButton(
    onPressed: () async {
    final newCategory = await showDialog<String>(
    context: context,
    builder: (BuildContext dialogContext) {
    final categoryController = TextEditingController();
    return AlertDialog(
    title: const Text('Add New Category'),
    content: TextField(
    controller: categoryController,
    decoration:
    const InputDecoration(labelText: 'Category Name'),
    ),
    actions: [
    TextButton(
    onPressed: () => Navigator.pop(dialogContext),
    child: const Text('Cancel'),
    ),
    TextButton(
    onPressed: () => Navigator.pop(
    dialogContext, categoryController.text),
    child: const Text('Add'),
    ),
    ],
    );
    },
    );
    if (newCategory != null && newCategory.isNotEmpty) {
    await _addCategory(newCategory);
    }
    },
    child: const Text('Add New Category'),
    ),
    ListTile(
    title: Text(
    'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
    ),
    trailing: const Icon(Icons.calendar_today),
    onTap: () => _selectDate(context),
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
    final formattedDate =
    DateFormat('yyyy-MM-dd').format(_selectedDate);
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
    ], // Closing the Column's children array
    ), // Closing the Column widget
    ), // Closing the Padding widget
    ); // Closing the Scaffold widget
  }
}