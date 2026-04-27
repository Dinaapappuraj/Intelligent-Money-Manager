import 'package:flutter/material.dart';

class IncomeSource {
  final String name;
  final IconData icon;

  IncomeSource({required this.name, required this.icon});

  // Convert to Map for JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'iconCodePoint': icon.codePoint,
    };
  }

  // Create from Map (e.g., from Firestore)
  factory IncomeSource.fromJson(Map<String, dynamic> json) {
    return IncomeSource(
      name: json['name'] ?? 'Other',
      icon: IconData(json['iconCodePoint'] ?? Icons.money.codePoint, fontFamily: 'MaterialIcons'),
    );
  }
}

final List<IncomeSource> defaultIncomeSources = [
  IncomeSource(name: 'Salary', icon: Icons.business_center_rounded),
  IncomeSource(name: 'Freelance', icon: Icons.work_outline_rounded),
  // ... other sources
];

