import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/transaction_model.dart';
import '../models/category_model.dart';

class ExpenseChart extends StatefulWidget {
  final List<Transaction> transactions;
  const ExpenseChart({super.key, required this.transactions});

  @override
  State<ExpenseChart> createState() => _ExpenseChartState();
}

class _ExpenseChartState extends State<ExpenseChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    // --- THE FIX ---
    // Filter out both non-expense transactions AND our special "Locked" placeholders.
    // This ensures the chart only processes real, decryptable expense data.
    final expenseTransactions = widget.transactions
        .where((tx) => tx.isExpense && tx.category?.name != 'Locked')
        .toList();

    if (expenseTransactions.isEmpty) {
      return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pie_chart_outline_rounded,
                  size: 60, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text('No expense data for chart.',
                  style: GoogleFonts.poppins(color: Colors.grey.shade600))
            ],
          ));
    }

    final spendingByCategory = <String, double>{};
    for (var tx in expenseTransactions) {
      if (tx.category != null) {
        spendingByCategory.update(
          tx.category!.name,
              (value) => value + tx.amount,
          ifAbsent: () => tx.amount,
        );
      }
    }

    final totalSpending =
    spendingByCategory.values.fold(0.0, (sum, item) => sum + item);
    final categoryEntries = spendingByCategory.entries.toList();

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  pieTouchResponse == null ||
                  pieTouchResponse.touchedSection == null) {
                touchedIndex = -1;
                return;
              }
              touchedIndex =
                  pieTouchResponse.touchedSection!.touchedSectionIndex;
            });
          },
        ),
        sections: List.generate(categoryEntries.length, (index) {
          final isTouched = index == touchedIndex;
          final fontSize = isTouched ? 18.0 : 14.0;
          final radius = isTouched ? 60.0 : 50.0;
          final entry = categoryEntries[index];
          final percentage = (entry.value / totalSpending) * 100;
          final category = defaultCategories.firstWhere(
                (cat) => cat.name == entry.key,
            orElse: () => defaultCategories.last,
          );

          return PieChartSectionData(
            color: Colors.primaries[
            defaultCategories.indexOf(category) % Colors.primaries.length],
            value: entry.value,
            title: '${percentage.toStringAsFixed(0)}%',
            radius: radius,
            titleStyle: GoogleFonts.poppins(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            badgeWidget: isTouched ? _buildBadge(category.name, entry.value) : null,
            badgePositionPercentageOffset: .98,
          );
        }),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 60,
      ),
    );
  }

  Widget _buildBadge(String categoryName, double amount) {
    final currencyFormat =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            categoryName,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            currencyFormat.format(amount),
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
