import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app_constants.dart';

// API Configuration
class ApiConfig {
  // Replace with your actual live domain
  static const String walletEndpoint = '/api/wallet.php';

  static String get walletUrl => '${baseUrl}new_apis/wallet_API.php';
}

class AppTheme {
  static const Color primary = Color(0xFF7C83FD);
  static const Color primarySoft = Color(0xFFF1F2FF);
  static const Color surface = Color(0xFFF9F9FF);
  static const Color border = Color(0xFFE6E6F0);
  static const Color textMain = Color(0xFF1F2937);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      fontFamily: 'Manrope',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textMain),
        titleTextStyle: TextStyle(
          color: textMain,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }
}

class Wallet extends StatefulWidget {
  const Wallet({super.key});

  @override
  State<Wallet> createState() => _Wallet();
}

class _Wallet extends State<Wallet> {
  bool _isLoading = true;
  String? _errorMessage;

  // Wallet data
  Map<String, dynamic> _balances = {
    'total_ebanking': 0,
    'available_ebanking': 0,
    'pending_requests': 0,
    'ewallet': 0,
  };

  List<dynamic> _transactions = [];
  int _currentPage = 1;
  int _totalPages = 1;
  String _selectedTransactionType = 'all';

  // Authentication token
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchData();
  }

  Future<void> _loadTokenAndFetchData() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');

    if (_authToken == null) {
      setState(() {
        _errorMessage = 'Please login to continue';
        _isLoading = false;
      });
      return;
    }

    await fetchWalletData();
  }

  Future<void> fetchWalletData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final url = Uri.parse('${ApiConfig.walletUrl}?type=$_selectedTransactionType&page=$_currentPage');

      print('Fetching from URL: $url'); // For debugging

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          setState(() {
            _balances = data['data']['balances'];
            _transactions = data['data']['transactions']['data'];
            _totalPages = data['data']['transactions']['last_page'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Failed to load data';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        _handleLogout();
      } else {
        setState(() {
          _errorMessage = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _errorMessage = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> addMoneyToWallet(double amount, String description, String addTo) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await http.post(
        Uri.parse(ApiConfig.walletUrl),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'action': 'add_money',
          'amount': amount,
          'description': description,
          'addTo': addTo, // 'ewallet' or 'ebanking'
        }),
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Payment initiated successfully'),
              backgroundColor: AppTheme.success,
            ),
          );

          // If there's a redirect URL, handle payment
          if (data['redirect_url'] != null && data['redirect_url'].isNotEmpty) {
            _openPaymentGateway(data['redirect_url']);
          }

          // Refresh wallet data
          await fetchWalletData();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Payment failed'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> requestWithdrawal(double amount, String description, String receiveTo) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await http.post(
        Uri.parse(ApiConfig.walletUrl),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'action': 'withdraw_request',
          'amount': amount,
          'description': description,
          'receiveTo': receiveTo, // 'ewallet' or 'bank'
        }),
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message']),
              backgroundColor: AppTheme.success,
            ),
          );
          // Refresh wallet data
          await fetchWalletData();
          if (mounted) {
            Navigator.pop(context); // Close modal
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Withdrawal failed'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openPaymentGateway(String url) {
    // Show payment dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Payment Gateway'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.payment, size: 50, color: AppTheme.primary),
            const SizedBox(height: 16),
            const Text('Redirecting to payment gateway...'),
            const SizedBox(height: 8),
            Text(
              'Please complete the payment',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // You can implement URL launcher here
              // launchUrl(Uri.parse(url));
            },
            child: const Text('Open Browser'),
          ),
        ],
      ),
    );
  }

  void _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please login again.'),
          backgroundColor: AppTheme.error,
        ),
      );

      // Navigate to login screen
      // Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _showAddMoneyModal() {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedAddTo = 'ebanking';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              const Text('Add Money', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Text('Add funds to your wallet.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              const SizedBox(height: 24),
              const Text('Enter Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  hintText: '0.00',
                  filled: true,
                  fillColor: AppTheme.primarySoft.withOpacity(0.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Enter description (min 5 characters)',
                  filled: true,
                  fillColor: AppTheme.primarySoft.withOpacity(0.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Add To', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildAddToOption('E-Banking', 'ebanking', selectedAddTo == 'ebanking', (value) {
                      setModalState(() {
                        selectedAddTo = 'ebanking';
                      });
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAddToOption('E-Wallet', 'ewallet', selectedAddTo == 'ewallet', (value) {
                      setModalState(() {
                        selectedAddTo = 'ewallet';
                      });
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(amountController.text);
                    final description = descriptionController.text.trim();

                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid amount')),
                      );
                      return;
                    }

                    if (description.length < 5) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Description must be at least 5 characters')),
                      );
                      return;
                    }

                    Navigator.pop(context);
                    addMoneyToWallet(amount, description, selectedAddTo);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Proceed to Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddToOption(String label, String value, bool isSelected, Function(String) onSelected) {
    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primarySoft : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border),
        ),
        child: Column(
          children: [
            Icon(value == 'ebanking' ? Icons.account_balance : Icons.wallet,
                color: isSelected ? AppTheme.primary : AppTheme.textMuted),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? AppTheme.primary : AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  void _showWithdrawModal(BuildContext context) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedReceiveTo = 'bank';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              const Text('Withdraw Funds', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Text('Funds will be credited to your selected account.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              const SizedBox(height: 24),
              const Text('Enter Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  hintText: '0.00',
                  filled: true,
                  fillColor: AppTheme.primarySoft.withOpacity(0.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 8),
              Text('Maximum available: ₹${_balances['available_ebanking']}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              const SizedBox(height: 16),
              const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Enter description (min 5 characters)',
                  filled: true,
                  fillColor: AppTheme.primarySoft.withOpacity(0.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Receive To', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildReceiveToOption('Bank Transfer', 'bank', selectedReceiveTo == 'bank', (value) {
                      setModalState(() {
                        selectedReceiveTo = 'bank';
                      });
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildReceiveToOption('E-Wallet', 'ewallet', selectedReceiveTo == 'ewallet', (value) {
                      setModalState(() {
                        selectedReceiveTo = 'ewallet';
                      });
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(amountController.text);
                    final description = descriptionController.text.trim();

                    if (amount == null || amount < 2000) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Minimum withdrawal amount is ₹2000')),
                      );
                      return;
                    }

                    if (amount > _balances['available_ebanking']) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Insufficient balance')),
                      );
                      return;
                    }

                    if (description.length < 5) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Description must be at least 5 characters')),
                      );
                      return;
                    }

                    requestWithdrawal(amount, description, selectedReceiveTo);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Submit Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiveToOption(String label, String value, bool isSelected, Function(String) onSelected) {
    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primarySoft : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border),
        ),
        child: Column(
          children: [
            Icon(value == 'bank' ? Icons.account_balance_outlined : Icons.wallet_outlined,
                color: isSelected ? AppTheme.primary : AppTheme.textMuted),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? AppTheme.primary : AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet', style: TextStyle(fontSize: 25)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchWalletData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: AppTheme.error)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchWalletData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Stats Row
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(child: _buildMiniStatCard('Total Revenue', '₹${_balances['total_ebanking']}', '+12%', AppTheme.success, Icons.payments_outlined)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildMiniStatCard('Total Expenses', '₹${_balances['total_ebanking'] - _balances['available_ebanking']}', '-5%', AppTheme.error, Icons.account_balance_wallet_outlined)),
                ],
              ),
            ),

            // E-Wallet Overview Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Icon(Icons.wallet_outlined, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text('E-Wallet Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Detailed Balances Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildBalanceCard('TOTAL E-BANKING', '₹${_balances['total_ebanking']}')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildBalanceCard('AVAILABLE E-BANKING', '₹${_balances['available_ebanking']}', isHighlighted: true)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildBalanceCard('E-WALLET BALANCE', '₹${_balances['ewallet']}')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildBalanceCard('PENDING WITHDRAWAL', '₹${_balances['pending_requests']}', showDot: _balances['pending_requests'] > 0)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Transaction History Header with Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Transaction History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      DropdownButton<String>(
                        value: _selectedTransactionType,
                        icon: const Icon(Icons.filter_list, size: 20),
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All')),
                          DropdownMenuItem(value: 'ebanking', child: Text('E-Banking')),
                          DropdownMenuItem(value: 'ewallet', child: Text('E-Wallet')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedTransactionType = value;
                              _currentPage = 1;
                            });
                            fetchWalletData();
                          }
                        },
                      ),
                      IconButton(onPressed: fetchWalletData, icon: const Icon(Icons.refresh, size: 20)),
                    ],
                  ),
                ],
              ),
            ),

            // Transaction List
            _transactions.isEmpty
                ? const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No transactions found')),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                final transaction = _transactions[index];
                final isCredit = transaction['type'] == 'CREDIT';
                final amountPrefix = isCredit ? '+' : '-';

                return _buildTransactionTile(
                  transaction['description'],
                  transaction['transaction_id'],
                  _formatDate(transaction['date']),
                  '$amountPrefix₹${transaction['amount']}',
                  transaction['status'],
                  transaction['status'] == 'COMPLETED' ? AppTheme.success :
                  transaction['status'] == 'PENDING' ? AppTheme.warning : AppTheme.error,
                  isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                );
              },
            ),

            // Pagination
            if (_totalPages > 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _currentPage > 1 ? () {
                        setState(() {
                          _currentPage--;
                        });
                        fetchWalletData();
                      } : null,
                    ),
                    Text('Page $_currentPage of $_totalPages'),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _currentPage < _totalPages ? () {
                        setState(() {
                          _currentPage++;
                        });
                        fetchWalletData();
                      } : null,
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'addMoney',
            onPressed: _showAddMoneyModal,
            backgroundColor: AppTheme.success,
            mini: true,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'withdraw',
            onPressed: () => _showWithdrawModal(context),
            backgroundColor: AppTheme.primary,
            child: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateTime) {
    try {
      final date = DateTime.parse(dateTime);
      return '${date.day}/${date.month}/${date.year} • ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }

  Widget _buildMiniStatCard(String title, String value, String trend, Color trendColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppTheme.primarySoft, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 16, color: AppTheme.primary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: trendColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(trend, style: TextStyle(color: trendColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(String label, String value, {bool isHighlighted = false, bool showDot = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted ? AppTheme.primary : AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isHighlighted ? AppTheme.primary : AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 9, color: isHighlighted ? Colors.white70 : AppTheme.textMuted, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isHighlighted ? Colors.white : AppTheme.textMain)),
              if (showDot) ...[
                const SizedBox(width: 4),
                const Icon(Icons.circle, size: 6, color: AppTheme.warning),
              ]
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(String title, String id, String time, String amount, String status, Color statusColor, IconData icon) {
    bool isCredit = amount.startsWith('+');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: isCredit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 18, color: isCredit ? Colors.green : Colors.red),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('$id • $time', style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isCredit ? Colors.green : Colors.red)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}