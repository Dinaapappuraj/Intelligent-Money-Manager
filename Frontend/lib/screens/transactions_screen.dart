import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/transaction_model.dart';
import '../services/firestore_service.dart'; // THE CHANGE
import '../widgets/transaction_list_item.dart';

enum TransactionFilter { all, income, expense }

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  TransactionFilter _currentFilter = TransactionFilter.all;

  @override
  Widget build(BuildContext context) {
    // THE CHANGE: Use the real FirestoreService
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('All Transactions', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Transaction>>(
        // THE CHANGE: Consume the real stream
        stream: firestoreService.getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No transactions found.'));
          }

          final allTransactions = snapshot.data!;
          final filteredTransactions = _filterTransactions(allTransactions);

          return Column(
            children: [
              _buildFilterChips(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) {
                    return TransactionListItem(transaction: filteredTransactions[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    switch (_currentFilter) {
      case TransactionFilter.income:
        return transactions.where((t) => !t.isExpense).toList();
      case TransactionFilter.expense:
        return transactions.where((t) => t.isExpense).toList();
      case TransactionFilter.all:
      default:
        return transactions;
    }
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _currentFilter == TransactionFilter.all,
            onSelected: (selected) {
              if (selected) setState(() => _currentFilter = TransactionFilter.all);
            },
          ),
          FilterChip(
            label: const Text('Income'),
            selected: _currentFilter == TransactionFilter.income,
            onSelected: (selected) {
              if (selected) setState(() => _currentFilter = TransactionFilter.income);
            },
          ),
          FilterChip(
            label: const Text('Expenses'),
            selected: _currentFilter == TransactionFilter.expense,
            onSelected: (selected) {
              if (selected) setState(() => _currentFilter = TransactionFilter.expense);
            },
          ),
        ],
      ),
    );
  }
}

