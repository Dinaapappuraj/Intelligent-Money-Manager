import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/firestore_service.dart';
import '../services/ai_service.dart';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';
import 'prediction_page.dart';
import 'budgets_screen.dart';
import 'settings_screen.dart';
import 'add_transaction_modal.dart';

final GlobalKey<_MainScreenState> mainScreenKey =
GlobalKey<_MainScreenState>();

class MainScreen extends StatefulWidget {
  MainScreen() : super(key: mainScreenKey);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void changeTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _widgetOptions = <Widget>[
    const DashboardScreen(),
    const TransactionsScreen(),
    const PredictionPage(),
    const BudgetsScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showAddTransactionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MultiProvider(
        providers: [
          Provider.value(
            value: Provider.of<FirestoreService>(
              context,
              listen: false,
            ),
          ),
          Provider.value(
            value: Provider.of<AiService>(
              context,
              listen: false,
            ),
          ),
        ],
        child: const AddTransactionModal(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),

      // ✅ FAB at bottom-right
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8, right: 4),
        child: FloatingActionButton(
          onPressed: _showAddTransactionModal,
          heroTag: 'add_transaction_fab_real',
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),

      // ✅ Position updated
      floatingActionButtonLocation:
      FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavItem(icon: Icons.dashboard_rounded, index: 0),
            _buildNavItem(icon: Icons.list_alt_rounded, index: 1),
            _buildNavItem(
                icon: Icons.trending_up_rounded, index: 2),
            _buildNavItem(icon: Icons.pie_chart_rounded, index: 3),
            _buildNavItem(icon: Icons.settings_rounded, index: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return IconButton(
      icon: Icon(
        icon,
        color: isSelected
            ? Theme.of(context).primaryColor
            : Colors.grey.shade600,
      ),
      onPressed: () => _onItemTapped(index),
    );
  }
}