import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/income_source_model.dart';
import '../services/firestore_service.dart'; // THE CHANGE

class AddExpenseScreen extends StatefulWidget {
  final String? prefilledTitle;
  final double? prefilledAmount;

  const AddExpenseScreen({
    super.key,
    this.prefilledTitle,
    this.prefilledAmount,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  // All state logic is identical to the mock
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isExpense = true;
  ExpenseCategory? _selectedCategory;
  IncomeSource? _selectedIncomeSource;

  // --- THE FIX: Pre-fill the controllers in initState ---
  @override
  void initState() {
    super.initState();
    if (widget.prefilledTitle != null) {
      _titleController.text = widget.prefilledTitle!;
    }
    if (widget.prefilledAmount != null) {
      _amountController.text = widget.prefilledAmount!.toStringAsFixed(2);
    }
  }


  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }


  Future<void> _submitData() async {
    print("BUTTON CLICKED");

    if (!_formKey.currentState!.validate()) {
      print("FORM NOT VALID");
      return;
    }

    try {
      final amount = double.tryParse(_amountController.text) ?? 0.0;

      print("Amount: $amount");
      print("Title: ${_titleController.text}");
      print("Category: $_selectedCategory");

      final newTransaction = Transaction(
        id: const Uuid().v4(),
        title: _titleController.text,
        amount: amount,
        date: _selectedDate,
        isExpense: _isExpense,
        category: _selectedCategory,
        incomeSource: _selectedIncomeSource,
      );

      print("Calling Firestore...");

      await Provider.of<FirestoreService>(context, listen: false)
          .addTransaction(newTransaction);

      print("SUCCESS");

      Navigator.of(context).pop();

    } catch (e) {
      print("ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        // Make space for the keyboard
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isExpense ? 'Add Expense' : 'Add Income',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildTypeToggle(),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Amount', prefixIcon: const Icon(Icons.currency_rupee)),
                validator: (v) => v!.isEmpty ? 'Please enter an amount' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Note / Title', prefixIcon: const Icon(Icons.edit)),
                validator: (v) => v!.isEmpty ? 'Please enter a note' : null,
              ),
              const SizedBox(height: 20),
              _isExpense
                  ? _buildCategoryDropdown()
                  : _buildIncomeSourceDropdown(),
              const SizedBox(height: 20),
              _buildDatePicker(),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submitData,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Save Transaction',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return ToggleButtons(
      isSelected: [_isExpense, !_isExpense],
      onPressed: (index) {
        setState(() {
          _isExpense = index == 0;
        });
      },
      borderRadius: BorderRadius.circular(8),
      fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
      selectedColor: Theme.of(context).primaryColor,
      children: const [
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Expense')),
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Income')),
      ],
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

  Widget _buildDatePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(DateFormat.yMMMd().format(_selectedDate)),
        TextButton(onPressed: _presentDatePicker, child: const Text('Choose Date')),
      ],
    );
  }
}