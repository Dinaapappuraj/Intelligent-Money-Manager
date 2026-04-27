import 'package:cloud_firestore/cloud_firestore.dart';
import './category_model.dart';

class Budget {
  final String id;
  final ExpenseCategory category;
  final double amount;

  Budget({
    required this.id,
    required this.category,
    required this.amount,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category.toJson(),
      'amount': amount,
    };
  }

  // Create from Firestore document
  factory Budget.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Budget(
      id: doc.id,
      category: ExpenseCategory.fromJson(data['category'] ?? {}),
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

