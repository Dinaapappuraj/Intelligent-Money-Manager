import 'package:flutter/material.dart';

class NextMonthPredictionPage extends StatelessWidget {
  final List<double> monthlyExpenses;
  // Example: [8500, 9200, 9800, 10400]

  const NextMonthPredictionPage({
    Key? key,
    required this.monthlyExpenses,
  }) : super(key: key);

  double predictNextMonth() {
    if (monthlyExpenses.isEmpty) return 0;

    double avg =
        monthlyExpenses.reduce((a, b) => a + b) / monthlyExpenses.length;

    double trend = 0;
    if (monthlyExpenses.length > 1) {
      trend = monthlyExpenses.last -
          monthlyExpenses[monthlyExpenses.length - 2];
    }

    return avg + trend;
  }

  @override
  Widget build(BuildContext context) {
    final prediction = predictNextMonth();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Next Month Prediction"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Expense Prediction",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      "Estimated Spending",
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "₹ ${prediction.toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Based on your previous expenses",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Previous Months",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: monthlyExpenses.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.calendar_month),
                    title: Text("Month ${index + 1}"),
                    trailing:
                    Text("₹ ${monthlyExpenses[index].toStringAsFixed(2)}"),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
