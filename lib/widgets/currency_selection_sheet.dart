// lib/widgets/currency_selection_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../models/currency.dart';
import '../services/user_state.dart'; // Import UserState
import '../screens/vip_upsell_screen.dart'; // Import VipUpsellScreen

class CurrencySelectionSheet extends StatefulWidget {
  final Function(Currency) onCurrencySelected;

  const CurrencySelectionSheet({super.key, required this.onCurrencySelected});

  @override
  State<CurrencySelectionSheet> createState() => _CurrencySelectionSheetState();
}

class _CurrencySelectionSheetState extends State<CurrencySelectionSheet> {
  // --- MODIFIED: Get currency list from UserState ---
  late List<Currency> _availableCurrencies;
  late List<Currency> _filteredCurrencies;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Get the correct list based on user status when the sheet opens
    // We use listen: false here because this is in initState
    _availableCurrencies = Provider.of<UserState>(context, listen: false).availableCurrencies;
    _filteredCurrencies = _availableCurrencies;
    _searchController.addListener(_filterCurrencies);
  }

  void _filterCurrencies() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCurrencies = _availableCurrencies.where((currency) { // Filter from the correct base list
        return currency.name.toLowerCase().contains(query) || currency.code.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCurrencies);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- NEW: Access UserState to check for VIP status ---
    // We use listen: false here as well, as the list is loaded in initState
    // and this build method is just for layout.
    final userState = Provider.of<UserState>(context, listen: false);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // --- Handle bar ---
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              // --- Search Field ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search currency by name or code...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
                  ),
                ),
              ),
              // --- NEW: Conditionally show Upgrade CTA ---
              // Show if the user is NOT VIP and NOT Admin
              if (!userState.isVip && !userState.isAdmin) _buildUpgradeBanner(context),
              // --- List ---
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _filteredCurrencies.length,
                  itemBuilder: (context, index) {
                    final currency = _filteredCurrencies[index];
                    return ListTile(
                      title: Text(currency.name),
                      trailing: Text(currency.code),
                      onTap: () {
                        widget.onCurrencySelected(currency);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

   // --- NEW: Helper Widget for Upgrade Banner ---
   Widget _buildUpgradeBanner(BuildContext context) {
     return InkWell(
        onTap: () {
          Navigator.pop(context); // Close the sheet first
          Navigator.push(context, MaterialPageRoute(builder: (_) => const VipUpsellScreen()));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          color: Colors.amber.shade100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: Colors.amber.shade800, size: 20),
              const SizedBox(width: 10),
              Text(
                "Upgrade to VIP for All Currencies!",
                style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 10),
               Icon(Icons.arrow_forward_ios, color: Colors.amber.shade800, size: 16),
            ],
          ),
        ),
      );
   }
}
