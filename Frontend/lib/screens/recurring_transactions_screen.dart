import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/recurring_transaction_model.dart';
import '../services/firestore_service.dart';
import 'add_recurring_screen.dart';

class RecurringTransactionsScreen extends StatelessWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: Text('Recurring Transactions', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<RecurringTransaction>>(
        stream: firestoreService.getRecurringTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No recurring transactions set up.', style: GoogleFonts.poppins()));
          }
          final recurring = snapshot.data!;
          final income = recurring.where((t) => !t.isExpense).toList();
          final expenses = recurring.where((t) => t.isExpense).toList();

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              if (income.isNotEmpty) ...[
                _buildSectionHeader('Income'),
                ...income.map((t) => _buildRecurringTile(t, currencyFormat, context)),
                const SizedBox(height: 20),
              ],
              if (expenses.isNotEmpty) ...[
                _buildSectionHeader('Expenses'),
                ...expenses.map((t) => _buildRecurringTile(t, currencyFormat, context)),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // --- THE FIX ---
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => Provider.value(
              value: firestoreService,
              child: const AddRecurringScreen(),
            ),
            fullscreenDialog: true,
          ));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade700));
  }

  Widget _buildRecurringTile(RecurringTransaction t, NumberFormat f, BuildContext context) {
    final color = t.isExpense ? Colors.redAccent : Colors.green;
    final sign = t.isExpense ? '-' : '+';

    // --- THE FIX: Build a richer subtitle ---
    String subtitle = 'Next on: ${DateFormat.yMMMd().format(t.nextDate)}';
    if (!t.neverEnds && t.endDate != null) {
      subtitle += '  •  Ends on: ${DateFormat.yMMMd().format(t.endDate!)}';
    }


    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(t.isExpense ? t.category!.icon : t.incomeSource!.icon, color: color),
        ),
        title: Text(t.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle), // Use the new subtitle
        trailing: Text(
          '$sign ${f.format(t.amount)}',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}