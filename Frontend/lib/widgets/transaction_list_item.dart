import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/transaction_model.dart';

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;

  const TransactionListItem({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final color = transaction.isExpense ? Colors.redAccent.shade400 : Colors.green.shade600;
    final sign = transaction.isExpense ? '-' : '+';

    // --- THE FIX ---
    // This logic is now robust and handles the "Encrypted" placeholder case safely.
    final IconData iconData;
    // First, check if this is our special placeholder.
    if (transaction.title == 'Encrypted Data' && transaction.category?.name == 'Locked') {
      iconData = transaction.category!.icon; // Use the lock icon
    }
    // Otherwise, proceed with the original logic for normal transactions.
    else if (transaction.isExpense) {
      iconData = transaction.category!.icon;
    } else {
      iconData = transaction.incomeSource!.icon;
    }


    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(iconData, color: color, size: 24),
        ),
        title: Text(
          transaction.title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          DateFormat.yMMMd().format(transaction.date),
          style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13),
        ),
        trailing: Text(
          '$sign ${currencyFormat.format(transaction.amount)}',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
