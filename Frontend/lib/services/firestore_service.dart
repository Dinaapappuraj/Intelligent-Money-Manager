import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter/foundation.dart';

import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../models/recurring_transaction_model.dart';
import './encryption_service.dart';

class FirestoreService {
  final String userId;
  final EncryptionService _encryptionService;

  late final CollectionReference _transactionsCollection;
  late final CollectionReference _budgetsCollection;
  late final CollectionReference _recurringCollection;

  FirestoreService({required this.userId, required EncryptionService encryptionService})
      : _encryptionService = encryptionService {
    _transactionsCollection = FirebaseFirestore.instance.collection('users').doc(userId).collection('transactions');
    _budgetsCollection = FirebaseFirestore.instance.collection('users').doc(userId).collection('budgets');
    _recurringCollection = FirebaseFirestore.instance.collection('users').doc(userId).collection('recurring');
  }

  // --- Transaction Methods ---
  Future<void> addTransaction(Transaction transaction) async {
    try {
      final jsonString = json.encode(transaction.toJson());
      final encryptedData = await _encryptionService.encryptData(jsonString);

      if (encryptedData != null) {
        // We store the date unencrypted for sorting purposes.
        await _transactionsCollection.add({
          'data': encryptedData,
          'date': Timestamp.fromDate(transaction.date),
          'isExpense': transaction.isExpense,
        });
      }
    } catch (e) {
      debugPrint("Error adding transaction: $e");
    }
  }

  // --- THE FIX ---
  // Fully implemented decryption logic.
  Stream<List<Transaction>> getTransactions() {
    return _transactionsCollection.orderBy('date', descending: true).snapshots().asyncMap((snapshot) async {
      final transactions = <Transaction>[];
      for (final doc in snapshot.docs) {
        final docData = doc.data() as Map<String, dynamic>?;

        if (docData != null && docData.containsKey('data')) {
          final encryptedPayload = docData['data'] as String?;
          if (encryptedPayload != null) {
            final decryptedString = await _encryptionService.decryptData(encryptedPayload);
            if (decryptedString != null) {
              final dataMap = json.decode(decryptedString) as Map<String, dynamic>;
              transactions.add(Transaction.fromFirestore(doc, dataMap));
            } else {
              // If decryption fails (e.g., wrong key), show a locked item.
              // This call now correctly matches the updated factory constructor.
              transactions.add(Transaction.fromEncrypted(doc));
            }
          }
        }
      }
      return transactions;
    });
  }

  // --- Budget Methods ---
  Future<void> addOrUpdateBudget(Budget budget) async {
    try {
      // Budgets are not encrypted.
      await _budgetsCollection.doc(budget.id).set(budget.toJson());
    } catch (e) {
      debugPrint("Error adding budget: $e");
    }
  }

  Stream<List<Budget>> getBudgets() {
    return _budgetsCollection.snapshots().map((snapshot) {
      try {
        return snapshot.docs.map((doc) => Budget.fromFirestore(doc)).toList();
      } catch (e) {
        debugPrint("Error parsing budgets: $e");
        return [];
      }
    });
  }

  // --- Recurring Transaction Methods ---
  Future<void> addRecurringTransaction(RecurringTransaction recurring) async {
    try {
      final jsonString = json.encode(recurring.toJson());
      final encryptedData = await _encryptionService.encryptData(jsonString);

      if (encryptedData != null) {
        await _recurringCollection.add({
          'data': encryptedData,
          'nextDate': Timestamp.fromDate(recurring.nextDate),
        });
      }
    } catch (e) {
      debugPrint("Error adding recurring transaction: $e");
    }
  }

  // --- THE FIX ---
  // Fully implemented decryption logic for recurring transactions.
  Stream<List<RecurringTransaction>> getRecurringTransactions() {
    return _recurringCollection.orderBy('nextDate').snapshots().asyncMap((snapshot) async {
      final recurring = <RecurringTransaction>[];
      for (final doc in snapshot.docs) {
        final docData = doc.data() as Map<String, dynamic>?;
        if (docData != null && docData.containsKey('data')) {
          final encryptedPayload = docData['data'] as String?;
          if (encryptedPayload != null) {
            final decryptedString = await _encryptionService.decryptData(encryptedPayload);
            if (decryptedString != null) {
              final dataMap = json.decode(decryptedString) as Map<String, dynamic>;
              recurring.add(RecurringTransaction.fromFirestore(doc, dataMap));
            }
            // As requested, we don't show a placeholder for recurring items,
            // we just skip if decryption fails.
          }
        }
      }
      return recurring;
    });
  }
}
