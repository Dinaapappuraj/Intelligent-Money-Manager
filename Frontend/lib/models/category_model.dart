import 'package:flutter/material.dart';

// Represents a spending category with a name and an icon
class ExpenseCategory {
  final String name;
  final IconData icon;

  ExpenseCategory({required this.name, required this.icon});

  // Convert an ExpenseCategory object into a map for JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      // We store the icon's unique code point, which is an integer
      'iconCodePoint': icon.codePoint,
    };
  }

  // Create an ExpenseCategory object from a map (e.g., from Firestore)
  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      name: json['name'] ?? 'Other',
      // We recreate the IconData from the stored code point
      icon: IconData(json['iconCodePoint'] ?? Icons.category.codePoint, fontFamily: 'MaterialIcons'),
    );
  }
}

// Pre-defined list of categories for the user to choose from
final List<ExpenseCategory> defaultCategories = [
  ExpenseCategory(name: 'Food', icon: Icons.fastfood_rounded),
  ExpenseCategory(name: 'Transport', icon: Icons.directions_bus_rounded),
  ExpenseCategory(name: 'Shopping', icon: Icons.shopping_bag_rounded),
  ExpenseCategory(name: 'Bills', icon: Icons.receipt_long_rounded),
  ExpenseCategory(name: 'Entertainment', icon: Icons.movie_rounded),
  ExpenseCategory(name: 'Health', icon: Icons.local_hospital_rounded),
  ExpenseCategory(name: 'Groceries', icon: Icons.local_grocery_store_rounded),
  ExpenseCategory(name: 'Education', icon: Icons.school_rounded),
  ExpenseCategory(name: 'Gifts', icon: Icons.card_giftcard_rounded),
  ExpenseCategory(name: 'Other', icon: Icons.more_horiz_rounded),
];

