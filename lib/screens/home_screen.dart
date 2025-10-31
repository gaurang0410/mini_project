// lib/screens/home_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/currency_list.dart'; // Keep this for default
import '../models/currency.dart';
import '../models/recent_search.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/user_state.dart';
import '../widgets/currency_selection_sheet.dart';
import 'login_screen.dart';
import 'vip_upsell_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final _amountController = TextEditingController();
  Currency _fromCurrency = currencies.firstWhere((c) => c.code == 'USD');
  Currency _toCurrency = currencies.firstWhere((c) => c.code == 'INR');
  bool _isLoading = false;
  String _conversionResult = "";
  Key _resultKey = UniqueKey();
  late Future<List<RecentSearch>> _recentSearchesFuture;
  bool _isFirstCurrencyLoad = true;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final available = Provider.of<UserState>(context).availableCurrencies;
    if (_isFirstCurrencyLoad || !available.any((c) => c.code == _fromCurrency.code) || !available.any((c) => c.code == _toCurrency.code)) {
      _fromCurrency = available.firstWhere((c) => c.code == 'USD', orElse: () => available.first);
      _toCurrency = available.firstWhere((c) => c.code == 'INR', orElse: () => available.length > 1 ? available[1] : available.first);
      _isFirstCurrencyLoad = false;
    }
  }

  void _loadRecentSearches() {
    setState(() {
      _recentSearchesFuture = DatabaseService.instance.getRecentSearches();
    });
  }

  void _showErrorSnackBar(String message, {bool isVipNotice = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isVipNotice ? Colors.amber.shade700 : Colors.red,
        action: isVipNotice
            ? SnackBarAction(
                label: "UPGRADE",
                textColor: Colors.white,
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const VipUpsellScreen()));
                },
              )
            : null,
      ),
    );
  }
  
  Future<void> _convertCurrency() async {
    if (_amountController.text.isEmpty) {
      _showErrorSnackBar("Please enter an amount.");
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() { _isLoading = true; _conversionResult = ""; });
    
    try {
      final double amount = double.parse(_amountController.text);
      final rate = await _apiService.getConversionRate(_fromCurrency.code, _toCurrency.code);
      final result = amount * rate;
      
      setState(() {
        _conversionResult = "${amount.toStringAsFixed(2)} ${_fromCurrency.code} = ${result.toStringAsFixed(2)} ${_toCurrency.code}";
        _resultKey = UniqueKey();
      });

      await _saveConversionToFirestore(amount, result);
      await _saveSearchToLocalDb();
    } catch (e) {
      print("--- [HOME SCREEN] AN ERROR OCCURRED: $e ---");
      _showErrorSnackBar("An error occurred during conversion.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSearchToLocalDb() async {
    final recentSearch = RecentSearch(fromCurrency: _fromCurrency, toCurrency: _toCurrency);
    await DatabaseService.instance.insertSearch(recentSearch);
    _loadRecentSearches();
  }

  Future<void> _deleteRecentSearch(int id) async {
    await DatabaseService.instance.deleteSearch(id);
    _loadRecentSearches();
  }
  
  Future<void> _saveConversionToFirestore(double amount, double result) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("--- [HOME SCREEN] User is guest, not saving to Firestore. ---");
      return;
    }
    
    await FirebaseFirestore.instance.collection('conversionHistory').add({
      'userId': user.uid, 'from': _fromCurrency.code, 'to': _toCurrency.code,
      'amount': amount, 'result': result, 'timestamp': FieldValue.serverTimestamp(),
    });
    print("--- [HOME SCREEN] Successfully saved to Firestore. ---");
  }

  void _selectCurrency(bool isFrom) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CurrencySelectionSheet(
        onCurrencySelected: (currency) {
          setState(() {
            if (isFrom) _fromCurrency = currency;
            else _toCurrency = currency;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isNewUiEnabled = Provider.of<UserState>(context).isNewUiEnabled;

    return Scaffold(
      backgroundColor: isNewUiEnabled ? Colors.grey.shade100 : Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Currency Converter'), centerTitle: true,
        elevation: 0, backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAmountCard(),
            const SizedBox(height: 20),
            _buildCurrencySelectionRow(),
            const SizedBox(height: 40),
            _buildConvertButton(),
            const SizedBox(height: 30),
            _buildResultDisplay(),
            const SizedBox(height: 20),
            _buildRecentSearches(),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: TextField(
          controller: _amountController,
          decoration: InputDecoration(
            labelText: 'Enter Amount to Convert',
            border: InputBorder.none,
            labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ),
    );
  }

  Widget _buildCurrencySelectionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(child: _buildCurrencySelector(true, _fromCurrency)),
        IconButton(
          icon: Icon(Icons.swap_horiz, size: 40, color: Theme.of(context).colorScheme.primary),
          onPressed: () => setState(() {
            final temp = _fromCurrency;
            _fromCurrency = _toCurrency;
            _toCurrency = temp;
          }),
        ),
        Expanded(child: _buildCurrencySelector(false, _toCurrency)),
      ],
    );
  }

  Widget _buildCurrencySelector(bool isFrom, Currency currency) {
    return InkWell(
      onTap: () => _selectCurrency(isFrom),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(isFrom ? 'FROM' : 'TO', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text(currency.code, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            SizedBox(
              width: 100,
              child: Text(currency.name, style: const TextStyle(color: Colors.grey, fontSize: 10), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConvertButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primary, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _convertCurrency,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
            : const Text('Convert', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildResultDisplay() {
    return Consumer<UserState>(
      builder: (context, userState, child) {
        final bool isGuest = userState.isGuest;
        
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
          child: _conversionResult.isNotEmpty
              ? Column(
                  key: _resultKey,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).colorScheme.secondary),
                      ),
                      child: Center(
                        child: Text(
                          _conversionResult,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    if (isGuest)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: InkWell(
                          onTap: () {
                             Navigator.pushNamed(context, '/login');
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200)
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.login, color: Colors.blue.shade700, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "Sign in to save your conversions online!",
                                    style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                  ],
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Recent Searches (Tap to use, Long-press to delete)", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        SizedBox(
          height: 80,
          child: FutureBuilder<List<RecentSearch>>(
            future: _recentSearchesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No recent searches yet."));
              }
              final searches = snapshot.data!;
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: searches.length,
                itemBuilder: (context, index) {
                  final search = searches[index];
                  return GestureDetector(
                    onTap: () {
                      final available = Provider.of<UserState>(context, listen: false).availableCurrencies;
                      if (available.any((c) => c.code == search.fromCurrency.code) &&
                          available.any((c) => c.code == search.toCurrency.code)) {
                        setState(() {
                          _fromCurrency = search.fromCurrency;
                          _toCurrency = search.toCurrency;
                        });
                      } else {
                        _showErrorSnackBar("This pair requires a VIP plan.", isVipNotice: true);
                      }
                    },
                    onLongPress: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Delete Search?"),
                          content: Text("Delete ${search.fromCurrency.code} to ${search.toCurrency.code} from history?"),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
                            TextButton(
                              onPressed: () {
                                _deleteRecentSearch(search.id!);
                                Navigator.of(context).pop();
                              },
                              child: const Text("Delete", style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.only(right: 10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("${search.fromCurrency.code} ➔ ${search.toCurrency.code}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 120,
                              child: Text("${search.fromCurrency.name} to ${search.toCurrency.name}", style: const TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}