import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ai_service.dart';

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  bool loading = true;
  Map<String, double> predictions = {};

  final AiService aiService = AiService();

  @override
  void initState() {
    super.initState();
    fetchPrediction();
  }

  Future<void> fetchPrediction() async {
    setState(() => loading = true);

    final result = await aiService.predictExpenses();

    setState(() {
      predictions = result ?? {};
      loading = false;
    });
  }

  double get totalPredicted {
    double total = 0;
    for (var value in predictions.values) {
      total += value;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //title: const Text("Expense Prediction"),
        title: Text('Expense Prediction', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),

        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : predictions.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            "No prediction data available.\nAdd more expense transactions first.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: fetchPrediction,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      size: 44,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Next Month Estimated Expense",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "₹ ${totalPredicted.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Category-wise Prediction",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            ...predictions.entries.map((entry) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.category),
                  title: Text(entry.key),
                  trailing: Text(
                    "₹ ${entry.value.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton.icon(
                onPressed: fetchPrediction,
                icon: const Icon(Icons.refresh),
                label: const Text("Refresh Prediction"),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}