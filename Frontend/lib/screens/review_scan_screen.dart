import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/ai_service.dart';
import '../services/firestore_service.dart'; // ✅ ADDED
import 'add_expense_screen.dart';

class ReviewScanScreen extends StatefulWidget {
  final String imagePath;
  const ReviewScanScreen({super.key, required this.imagePath});

  @override
  State<ReviewScanScreen> createState() => _ReviewScanScreenState();
}

class _ReviewScanScreenState extends State<ReviewScanScreen> {
  late Future<Map<String, dynamic>?> _extractionFuture;

  @override
  void initState() {
    super.initState();
    final aiService = Provider.of<AiService>(context, listen: false);
    _extractionFuture =
        aiService.extractDataFromImage(File(widget.imagePath));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Review Scanned Data',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _extractionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Analyzing your receipt..."),
                ],
              ),
            );
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data == null) {
            return const Center(
              child: Text(
                'An unknown error occurred. Please try again.',
              ),
            );
          }

          final extractedData = snapshot.data!;

          // Handle backend error message
          if (extractedData.containsKey('error')) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  extractedData['error'],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
              ),
            );
          }

          // ✅ FIX: Wrap with Provider to pass FirestoreService
          return Provider.value(
            value: Provider.of<FirestoreService>(context, listen: false),
            child: AddExpenseScreen(
              prefilledTitle: extractedData['merchant'] as String?,
              prefilledAmount:
              (extractedData['amount'] as num?)?.toDouble(),
            ),
          );
        },
      ),
    );
  }
}