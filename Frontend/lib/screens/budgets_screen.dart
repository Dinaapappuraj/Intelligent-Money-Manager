import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';
import 'add_budget_screen.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: Text('Budgets', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Budget>>(
        stream: firestoreService.getBudgets(),
        builder: (context, budgetSnapshot) {
          if (!budgetSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final budgets = budgetSnapshot.data!;
          return StreamBuilder<List<Transaction>>(
            stream: firestoreService.getTransactions(),
            builder: (context, transactionSnapshot) {
              if (!transactionSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final transactions = transactionSnapshot.data!;
              final totalBudget = budgets.fold(0.0, (sum, b) => sum + b.amount);
              final totalSpent = transactions.where((t) => t.isExpense).fold(0.0, (sum, t) => sum + t.amount);

              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildTotalBudgetSummary(context, totalSpent, totalBudget, currencyFormat),
                  const SizedBox(height: 24),
                  ...budgets.map((budget) {
                    final spentOnCategory = transactions
                        .where((t) => t.isExpense && t.category?.name == budget.category.name)
                        .fold(0.0, (sum, item) => sum + item.amount);
                    return _buildBudgetListItem(context, budget, spentOnCategory, currencyFormat);
                  }),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16), // 🔥 increase this value if needed
        child: FloatingActionButton(
          heroTag: 'budgets_add_fab_real',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => Provider.value(
                  value: firestoreService,
                  child: const AddBudgetScreen(),
                ),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
    //floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
  }

  Widget _buildTotalBudgetSummary(BuildContext context, double totalSpent, double totalBudget, NumberFormat currencyFormat) {
    final percentage = totalBudget > 0 ? (totalSpent / totalBudget) : 0.0;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('September Spending', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18, color: Theme.of(context).primaryColorDark)),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              width: 100,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: percentage,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                  ),
                  Center(child: Text('${(percentage * 100).toStringAsFixed(0)}%', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColorDark))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('${currencyFormat.format(totalSpent)} of ${currencyFormat.format(totalBudget)}', style: GoogleFonts.poppins(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetListItem(BuildContext context, Budget budget, double spent, NumberFormat currencyFormat) {
    final percentage = budget.amount > 0 ? (spent / budget.amount) : 0.0;
    final remaining = budget.amount - spent;
    final progressColor = percentage > 0.8 ? Colors.redAccent : (percentage > 0.5 ? Colors.orangeAccent : Colors.green);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(budget.category.icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Text(budget.category.name, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 10,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Spent: ${currencyFormat.format(spent)}', style: GoogleFonts.poppins(color: Colors.grey.shade700)),
                Text('Remaining: ${currencyFormat.format(remaining)}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
