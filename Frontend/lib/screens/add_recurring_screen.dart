import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/recurring_transaction_model.dart';
import '../models/category_model.dart';
import '../models/income_source_model.dart';
import '../services/firestore_service.dart'; // THE CHANGE

class AddRecurringScreen extends StatefulWidget {
  const AddRecurringScreen({super.key});

  @override
  State<AddRecurringScreen> createState() => _AddRecurringScreenState();
}

class _AddRecurringScreenState extends State<AddRecurringScreen> {
  // All state logic is identical to the mock
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  bool _isExpense = true;
  String _frequency = 'Monthly';
  DateTime _nextDate = DateTime.now();
  DateTime? _endDate;
  bool _neverEnds = true;

  ExpenseCategory? _selectedCategory;
  IncomeSource? _selectedIncomeSource;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStartDate) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _nextDate : (_endDate ?? _nextDate),
      firstDate: _nextDate, // End date cannot be before the start date
      lastDate: DateTime(2050),
    );
    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _nextDate = pickedDate;
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }

  void _submitData() {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      if (amount <= 0) return;

      final newRecurring = RecurringTransaction(
        id: const Uuid().v4(),
        title: _titleController.text,
        amount: amount,
        isExpense: _isExpense,
        frequency: _frequency,
        nextDate: _nextDate,
        neverEnds: _neverEnds,
        endDate: _neverEnds ? null : _endDate,
        category: _isExpense ? _selectedCategory : null,
        incomeSource: !_isExpense ? _selectedIncomeSource : null,
      );

      // THE CHANGE: Use the real FirestoreService
      Provider.of<FirestoreService>(context, listen: false)
          .addRecurringTransaction(newRecurring);

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Recurring', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildTypeToggle(),
            const SizedBox(height: 20),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount', prefixIcon: Icon(Icons.attach_money)),
              validator: (v) => v!.isEmpty ? 'Please enter an amount' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title (e.g., Netflix, Salary)'),
              validator: (v) => v!.isEmpty ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 20),
            _isExpense
                ? _buildCategoryDropdown()
                : _buildIncomeSourceDropdown(),
            const SizedBox(height: 20),
            _buildFrequencyDropdown(),
            const SizedBox(height: 20),
            _buildDatePicker('Next Payment Date', _nextDate, () => _pickDate(true)),
            const SizedBox(height: 10),
            _buildNeverEndsSwitch(),
            if (!_neverEnds)
              _buildDatePicker('End Date', _endDate ?? _nextDate, () => _pickDate(false)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _submitData,
              child: const Text('Save Recurring Transaction'),
            ),
          ],
        ),
      ),
    );
  }

  // --- THE FIX: Implementing the missing UI widgets ---
  Widget _buildTypeToggle() {
    return Center(
      child: ToggleButtons(
        isSelected: [_isExpense, !_isExpense],
        onPressed: (index) {
          setState(() {
            _isExpense = index == 0;
          });
        },
        borderRadius: BorderRadius.circular(8),
        constraints: BoxConstraints(minWidth: 100, minHeight: 40),
        children: const [
          Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Expense')),
          Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Income')),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<ExpenseCategory>(
      value: _selectedCategory,
      hint: const Text('Select Category'),
      items: defaultCategories.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
      onChanged: (v) => setState(() => _selectedCategory = v),
      validator: (v) => v == null ? 'Please select a category' : null,
    );
  }

  Widget _buildIncomeSourceDropdown() {
    return DropdownButtonFormField<IncomeSource>(
      value: _selectedIncomeSource,
      hint: const Text('Select Income Source'),
      items: defaultIncomeSources.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
      onChanged: (v) => setState(() => _selectedIncomeSource = v),
      validator: (v) => v == null ? 'Please select a source' : null,
    );
  }
  // --- END OF FIX ---

  Widget _buildFrequencyDropdown() {
    return DropdownButtonFormField<String>(
      value: _frequency,
      hint: const Text('Select Frequency'),
      items: ['Daily', 'Weekly', 'Monthly', 'Yearly']
          .map((f) => DropdownMenuItem(value: f, child: Text(f)))
          .toList(),
      onChanged: (v) => setState(() => _frequency = v!),
    );
  }

  Widget _buildDatePicker(String label, DateTime date, VoidCallback handler) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 16)),
        TextButton(
          onPressed: handler,
          child: Text(DateFormat.yMMMd().format(date), style: const TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildNeverEndsSwitch() {
    return SwitchListTile(
      title: Text('This transaction never ends', style: GoogleFonts.poppins()),
      value: _neverEnds,
      onChanged: (value) {
        setState(() {
          _neverEnds = value;
          if (value) {
            _endDate = null;
          } else {
            // Default end date to one year from next date
            _endDate = DateTime(_nextDate.year + 1, _nextDate.month, _nextDate.day);
          }
        });
      },
    );
  }
}

