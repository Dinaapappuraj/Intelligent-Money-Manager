import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import './category_model.dart';
import './income_source_model.dart';

class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final bool isExpense;
  final ExpenseCategory? category;
  final IncomeSource? incomeSource;

  // This is the main, public constructor with the assertion.
  // It ensures all REAL transactions are valid.
  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.isExpense,
    this.category,
    this.incomeSource,
  }) : assert(isExpense ? category != null : incomeSource != null);

  // --- THE FIX ---
  // A new private constructor WITHOUT the assertion.
  // This is ONLY used for creating the special "encrypted" placeholder.
  Transaction._encrypted({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.isExpense,
    this.category,
    this.incomeSource,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'isExpense': isExpense,
      'category': category?.toJson(),
      'incomeSource': incomeSource?.toJson(),
    };
  }

  factory Transaction.fromFirestore(DocumentSnapshot doc, Map<String, dynamic> data) {
    return Transaction(
      id: doc.id,
      title: data['title'] ?? 'No Title',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      date: data['date'] != null ? DateTime.parse(data['date']) : DateTime.now(),
      isExpense: data['isExpense'] ?? true,
      category: data['category'] != null ? ExpenseCategory.fromJson(data['category']) : null,
      incomeSource: data['incomeSource'] != null ? IncomeSource.fromJson(data['incomeSource']) : null,
    );
  }

  // --- THE FIX ---
  // The factory now uses the private `_encrypted` constructor,
  // which safely bypasses the assertion.
  factory Transaction.fromEncrypted(DocumentSnapshot doc) {
    final docData = doc.data() as Map<String, dynamic>;
    return Transaction._encrypted(
      id: doc.id,
      title: 'Encrypted Data',
      amount: 0.0,
      date: (docData['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isExpense: docData['isExpense'] ?? true,
      // We provide a category with a lock icon for both income and expense placeholders.
      // This ensures the UI has an icon to display and won't crash.
      category: ExpenseCategory(name: 'Locked', icon: Icons.lock),
      incomeSource: null, // This is now safe because the assertion is bypassed.
    );
  }
}

