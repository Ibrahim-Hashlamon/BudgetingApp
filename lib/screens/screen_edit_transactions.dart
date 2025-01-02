import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class EditTransactionScreen extends StatefulWidget {
  final Map<String, dynamic> transaction;
  final Future<Database> database;
  final Function onSave;

  const EditTransactionScreen({
    Key? key,
    required this.transaction,
    required this.database,
    required this.onSave,
  }) : super(key: key);

  @override
  _EditTransactionScreenState createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late String _type;
  late String? _category;
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.transaction['title']);
    _amountController = TextEditingController(
        text: widget.transaction['amount'].toString());
    _type = widget.transaction['type'];
    _category = widget.transaction['category'];
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final db = await widget.database;
    final categories = await db.query(
      'categories',
      where: 'type = ?',
      whereArgs: [_type],
    );

    setState(() {
      _categories = categories;
      if (_categories.isNotEmpty &&
          !_categories.any((c) => c['name'] == _category)) {
        _category = _categories.first['name'];
      }
    });
  }

  Future<void> _saveTransaction() async {
    final db = await widget.database;
    await db.update(
      'transactions',
      {
        'title': _titleController.text,
        'amount': double.parse(_amountController.text),
        'type': _type,
        'category': _category,
      },
      where: 'id = ?',
      whereArgs: [widget.transaction['id']],
    );
    widget.onSave(); // Refresh the transactions list
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveTransaction,
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
