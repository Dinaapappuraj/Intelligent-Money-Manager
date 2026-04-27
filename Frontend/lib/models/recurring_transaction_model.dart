import 'package:cloud_firestore/cloud_firestore.dart';
import './category_model.dart';
import './income_source_model.dart';

class RecurringTransaction {
  final String id;
  final String title;
  final double amount;
  final bool isExpense;
  final String frequency;
  final DateTime nextDate;
  final DateTime? endDate;
  final bool neverEnds;
  final ExpenseCategory? category;
  final IncomeSource? incomeSource;

  RecurringTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.isExpense,
    required this.frequency,
    required this.nextDate,
    this.endDate,
    this.neverEnds = false,
    this.category,
    this.incomeSource,
  }) : assert(isExpense ? category != null : incomeSource != null);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'isExpense': isExpense,
      'frequency': frequency,
      // --- THE FIX: Convert DateTime to a JSON-compatible string ---
      'nextDate': nextDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'neverEnds': neverEnds,
      'category': category?.toJson(),
      'incomeSource': incomeSource?.toJson(),
    };
  }

  factory RecurringTransaction.fromFirestore(DocumentSnapshot doc, Map<String, dynamic> data) {
    return RecurringTransaction(
      id: doc.id,
      title: data['title'] ?? 'No Title',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      isExpense: data['isExpense'] ?? true,
      frequency: data['frequency'] ?? 'Monthly',
      // --- THE FIX: Parse the string back to a DateTime ---
      nextDate: data['nextDate'] != null ? DateTime.parse(data['nextDate']) : DateTime.now(),
      endDate: data['endDate'] != null ? DateTime.parse(data['endDate']) : null,
      neverEnds: data['neverEnds'] ?? false,
      category: data['category'] != null ? ExpenseCategory.fromJson(data['category']) : null,
      incomeSource: data['incomeSource'] != null ? IncomeSource.fromJson(data['incomeSource']) : null,
    );
  }
}

