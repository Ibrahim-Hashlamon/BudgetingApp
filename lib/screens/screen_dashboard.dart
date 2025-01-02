import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';


class DashboardScreen extends StatefulWidget {
  final Future<Database> database;

  const DashboardScreen({super.key, required this.database});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _totalIncome = 0;
  double _totalExpenses = 0;
  List<Map<String, dynamic>> _expenseBreakdown = [];
  List<Map<String, dynamic>> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _fetchRecentTransactions();
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

  Future<void> _fetchRecentTransactions() async {
    final db = await widget.database;

    // Fetch the two most recent transactions
    final recentTransactions = await db.query(
      'transactions',
      orderBy: 'date DESC',
      limit: 2,
    );

    setState(() {
      _recentTransactions = recentTransactions;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentMonth = DateFormat('MMMM').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text('Budget for $currentMonth'),
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
            const SizedBox(height: 40),
            const Text(
              'Expense Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            const SizedBox(height: 68),
            const Text(
              'Recent Transactions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _recentTransactions.isEmpty
                ? const Text('No recent transactions available')
                : Column(
              children: _recentTransactions.map((transaction) {
                return ListTile(
                  title: Text(transaction['title']),
                  subtitle: Text(
                      '${transaction['category']} - ${DateFormat('yyyy-MM-dd').format(DateTime.parse(transaction['date']))}'),
                  trailing: Text(
                    '\$${transaction['amount'].toStringAsFixed(2)}',
                    style: TextStyle(
                      color: transaction['type'] == 'income'
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
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


Widget _buildSummaryCard2(String title, double value, Color color) {
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



Widget _buildSummaryCard3(String title, double value, Color color) {
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