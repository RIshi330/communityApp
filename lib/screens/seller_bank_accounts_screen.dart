import 'package:flutter/material.dart';
// ⚠️ Update these imports to match your actual project structure
import '../../core/theme/app_theme.dart';
import '../../Database/Database.dart';

/* =========================================================
   MODEL
========================================================= */

class BankAccount {
  String? id;
  String bankName;
  String accountHolder;
  String accountNumber;
  String ifsc;
  String branch;
  String city;
  String state;
  String micr;
  String accountType;
  bool isDefault;

  BankAccount({
    this.id,
    required this.bankName,
    required this.accountHolder,
    required this.accountNumber,
    required this.ifsc,
    required this.branch,
    required this.city,
    required this.state,
    required this.micr,
    required this.accountType,
    this.isDefault = false,
  });

  factory BankAccount.fromMap(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id']?.toString(),
      bankName: json['bank_name'] ?? '',
      accountHolder: json['account_name'] ?? '',
      accountNumber: json['account_number'] ?? '',
      ifsc: json['ifsc'] ?? '',
      branch: json['branch_name'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      micr: json['MICR_code'] ?? '',
      accountType: json['account_type'] ?? 'Savings',
      isDefault: json['default'] == "1",
    );
  }
}

/* =========================================================
   SCREEN
========================================================= */

class SellerBankAccountsScreen extends StatefulWidget {
  const SellerBankAccountsScreen({super.key});

  @override
  State<SellerBankAccountsScreen> createState() =>
      _SellerBankAccountsScreenState();
}

class _SellerBankAccountsScreenState extends State<SellerBankAccountsScreen> {
  final Database _db = Database();
  List<BankAccount> accounts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
  }

  /* =========================================================
     BANKING API METHODS
  ========================================================= */

  Future<List<BankAccount>?> fetchBankAccounts() async {
    try {
      debugPrint(" Fetching bank accounts...");
      
      final response = await _db.getData({
        'action': 'fetch_all',
      });

      debugPrint(" Bank accounts API response: ${response['success']}");
      
      if (response['success'] == true && response['data'] != null) {
        debugPrint(" Bank accounts fetched successfully");
        final List data = response['data'];
        return data.map((e) => BankAccount.fromMap(e)).toList();
      } else {
        debugPrint(" Failed to fetch bank accounts: ${response['message']}");
        return null;
      }
    } catch (e) {
      debugPrint(" Error fetching bank accounts: $e");
      return null;
    }
  }

  Future<bool> addBankAccount({
    required String accountNumber,
    required String accountHolder,
    required String ifsc,
    required String bankName,
    required String branchName,
    required String city,
    required String state,
    String? branchCode,
    String? micr,
    String? accountType,
    bool isApiData = false,
  }) async {
    try {
      debugPrint("🔄 Adding bank account...");
      
      final Map<String, dynamic> requestData = {
        'action': 'add_bank',
        'is_api': isApiData,
        'bank_data': {
          'account_holder': accountHolder,
          'account_number': accountNumber,
          'ifsc': ifsc,
          'bank_name': bankName,
          'branch_name': branchName,
          'branch_code': branchCode ?? '',
          'city': city,
          'state': state,
          'micr': micr ?? '',
          'account_type': accountType ?? 'SAVINGS',
        }
      };

      final response = await _db.getData(requestData);

      debugPrint("📡 Add bank account response: ${response['success']}");
      
      if (response['success'] == true) {
        debugPrint("✅ Bank account added successfully");
        return true;
      } else {
        debugPrint("❌ Failed to add bank account: ${response['message']}");
        return false;
      }
    } catch (e) {
      debugPrint("💥 Error adding bank account: $e");
      return false;
    }
  }

  Future<bool> updateBankAccount({
    required String id,
    required String accountNumber,
    required String accountHolder,
    required String ifsc,
    required String bankName,
    required String branchName,
    required String city,
    required String state,
    String? branchCode,
    String? micr,
    String? accountType,
    bool isApiData = false,
  }) async {
    try {
      debugPrint("🔄 Updating bank account...");
      
      final response = await _db.getData({
        'action': 'edit_bank',
        'is_api': isApiData,
        'bank_id': id,
        'bank_data': {
          'account_holder': accountHolder,
          'account_number': accountNumber,
          'ifsc': ifsc,
          'bank_name': bankName,
          'branch_name': branchName,
          'branch_code': branchCode ?? '',
          'city': city,
          'state': state,
          'micr': micr ?? '',
          'account_type': accountType ?? 'SAVINGS',
        }
      });

      debugPrint("📡 Update bank account response: ${response['success']}");
      
      if (response['success'] == true) {
        debugPrint("✅ Bank account updated successfully");
        return true;
      } else {
        debugPrint("❌ Failed to update bank account: ${response['message']}");
        return false;
      }
    } catch (e) {
      debugPrint("💥 Error updating bank account: $e");
      return false;
    }
  }

  Future<bool> deleteBankAccount(String id) async {
    try {
      debugPrint("🔄 Deleting bank account...");
      
      final response = await _db.getData({
        'action': 'delete_bank',
        'bank_id': id,
      });

      debugPrint("📡 Delete bank account response: ${response['success']}");
      
      if (response['success'] == true) {
        debugPrint("✅ Bank account deleted successfully");
        return true;
      } else {
        debugPrint("❌ Failed to delete bank account: ${response['message']}");
        return false;
      }
    } catch (e) {
      debugPrint("💥 Error deleting bank account: $e");
      return false;
    }
  }

  Future<bool> setDefaultBankAccount(String id, bool isDefault) async {
    try {
      debugPrint("🔄 Setting default bank account...");
      
      final response = await _db.getData({
        'action': 'set_default',
        'bank_id': id,
        'status': isDefault ? '1' : '0',
      });

      debugPrint("📡 Set default bank account response: ${response['success']}");
      
      if (response['success'] == true) {
        debugPrint("✅ Default bank account updated successfully");
        return true;
      } else {
        debugPrint("❌ Failed to set default bank account: ${response['message']}");
        return false;
      }
    } catch (e) {
      debugPrint("💥 Error setting default bank account: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> lookupIfsc(String ifsc) async {
    try {
      debugPrint("🔄 Looking up IFSC code: $ifsc");
      
      final response = await _db.getData({
        'action': 'ifsc_lookup',
        'ifsc': ifsc,
      });

      debugPrint("📡 IFSC lookup response: ${response['success']}");
      
      if (response['success'] == true && response['data'] != null) {
        debugPrint("✅ IFSC data fetched successfully");
        return Map<String, dynamic>.from(response['data']);
      } else {
        debugPrint("❌ Failed to lookup IFSC: ${response['message']}");
        return null;
      }
    } catch (e) {
      debugPrint("💥 Error looking up IFSC: $e");
      return null;
    }
  }

  Future<void> _fetchAccounts() async {
    if (!mounted) return;
    // Only show full loader on initial load or empty list
    if (accounts.isEmpty) setState(() => isLoading = true);

    try {
      final response = await fetchBankAccounts();

      if (mounted) {
        if (response != null) {
          setState(() {
            accounts = response;
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
            accounts = [];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        _showError("Something went wrong: $e");
      }
    }
  }

  /// 🔹 ADD ACCOUNT
  Future<void> _addAccount({
    required String holderName,
    required String accNumber,
    required String ifscCode,
    required String accType,
    required Function() onSuccess,
  }) async {
    _showLoader();

    try {
      final response = await _db.getData({
        "module": "bank",
        "submodule": "add",
        "holder_name": holderName,
        "account_number": accNumber,
        "ifsc": ifscCode,
        "account_type": accType.toUpperCase(),
      });

      if (mounted) Navigator.pop(context); // Close Loader

      if (response['status'] == 200) {
        _showSuccess("Account added successfully!");
        onSuccess();
      } else {
        _showError(response['message'] ?? response['error'] ?? "Failed to add account");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showError("Error adding account: $e");
    }
  }

  /// 🔹 EDIT ACCOUNT
  Future<void> _editAccount({
    required String id,
    required String holderName,
    required String accNumber,
    required String ifscCode,
    required String accType,
    required Function() onSuccess,
  }) async {
    _showLoader();

    try {
      final response = await _db.getData({
        "module": "bank",
        "submodule": "edit",
        "id": id,
        "holder_name": holderName,
        "account_number": accNumber,
        "ifsc": ifscCode,
        "account_type": accType.toUpperCase(),
      });

      if (mounted) Navigator.pop(context); // Close Loader

      if (response['status'] == 200) {
        _showSuccess("Account updated successfully!");
        onSuccess();
      } else {
        _showError(response['message'] ?? response['error'] ?? "Failed to update account");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showError("Error updating account: $e");
    }
  }

  /// 🔹 DELETE ACCOUNT
  Future<void> _deleteAccount(String accountId) async {
    // Confirm Dialog
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("Are you sure you want to delete this bank account?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _showLoader();

    try {
      final response = await _db.getData({
        "module": "bank",
        "submodule": "remove_account", // ⚠️ UPDATED: Matches your screenshot
        "id": accountId,
      });

      if (mounted) Navigator.pop(context); // Close Loader

      if (response['status'] == 200) {
        _showSuccess("Account deleted successfully");
        // Local Update (Immediate)
        setState(() {
          accounts.removeWhere((acc) => acc.id == accountId);
        });
        // Background Sync
        _fetchAccounts();
      } else {
        _showError(response['message'] ?? "Failed to delete account");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showError("Error deleting account: $e");
    }
  }

  /// 🔹 CHANGE DEFAULT
  Future<void> _setDefaultAccount(String accountId) async {
    _showLoader();

    try {
      final success = await setDefaultBankAccount(accountId, true);
      
      if (mounted) Navigator.pop(context); // Close Loader

      if (success) {
        _showSuccess("Default account updated!");
        
        // Local Update
        setState(() {
          for (var acc in accounts) {
            acc.isDefault = (acc.id == accountId);
          }
        });

        // Background Sync
        _fetchAccounts();
      } else {
        _showError("Failed to update default account");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showError("Error updating default: $e");
    }
  }

  /* =========================================================
     HELPER WIDGETS
  ========================================================= */

  void _showLoader() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Bank Details"),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(color: Colors.white),
      ),
      backgroundColor: const Color(0xfff5f7fa),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchAccounts,
              child: accounts.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        ...accounts.map(_bankCard).toList(),
                        const SizedBox(height: 20),
                        _buildAddButton(),
                      ],
                    ),
            ),
    );
  }

  Widget _buildAddButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.add),
      label: const Text("Add New Bank Account"),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      onPressed: _openAddBankModal,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_balance_wallet_outlined,
              size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          const Text("No bank accounts added yet.",
              style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: _buildAddButton(),
          ),
        ],
      ),
    );
  }

  /* =========================================================
     BANK CARD
  ========================================================= */

  Widget _bankCard(BankAccount acc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    acc.bankName.isNotEmpty ? acc.bankName : "Bank Account",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (acc.isDefault) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.verified, size: 20, color: Colors.green),
                ],
                const SizedBox(width: 4),
                // Actions Menu
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text("Edit"),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text("Delete", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                  onSelected: (val) {
                    if (val == 'edit') _openAddBankModal(edit: acc);
                    if (val == 'delete') {
                      if (acc.id != null) {
                        _deleteAccount(acc.id!);
                      } else {
                        _showError("Cannot delete account without ID");
                      }
                    }
                  },
                )
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _infoRow("Holder Name", acc.accountHolder),
            _infoRow("Account Type", acc.accountType),
            _infoRow("Account No.", acc.accountNumber),
            _infoRow("IFSC Code", acc.ifsc),
            if (acc.branch.isNotEmpty) _infoRow("Branch", acc.branch),
            
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: acc.isDefault
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Switch(
                    value: acc.isDefault,
                    activeColor: Colors.green,
                    onChanged: (val) {
                      if (!acc.isDefault && acc.id != null) {
                         _setDefaultAccount(acc.id!);
                      }
                    },
                  ),
                  Expanded(
                    child: Text(
                      acc.isDefault
                          ? "Default Payment Account"
                          : "Set as default",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: acc.isDefault ? Colors.green : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /* =========================================================
     ADD / EDIT MODAL
  ========================================================= */

  void _openAddBankModal({BankAccount? edit}) {
    final accountNumber = TextEditingController(text: edit?.accountNumber);
    final reAccountNumber = TextEditingController(text: edit?.accountNumber);
    final holder = TextEditingController(text: edit?.accountHolder);
    final ifsc = TextEditingController(text: edit?.ifsc);
    final bank = TextEditingController(text: edit?.bankName);
    final branch = TextEditingController(text: edit?.branch);
    final city = TextEditingController(text: edit?.city);
    final state = TextEditingController(text: edit?.state);
    final micr = TextEditingController(text: edit?.micr);
    
    String accountType = edit?.accountType ?? "Savings";
    bool manual = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(builder: (c, setM) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(c).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      edit == null ? "Enter Bank Details" : "Edit Bank Details",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),

                  // Toggle Fetch / Manual
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text("Fetch using IFSC"),
                        selected: !manual,
                        onSelected: (_) => setM(() => manual = false),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text("Enter Manually"),
                        selected: manual,
                        onSelected: (_) => setM(() => manual = true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Basic Fields
                  _field("Account Number", accountNumber, isNumber: true),
                  if (edit == null)
                    _field("Re-enter Account Number", reAccountNumber, isNumber: true),
                  _field("Account Holder Name", holder),

                  // Account Type Radio
                  Row(
                    children: [
                      Radio(
                          value: "Savings",
                          groupValue: accountType,
                          onChanged: (v) => setM(() => accountType = v!)),
                      const Text("Savings"),
                      Radio(
                          value: "Current",
                          groupValue: accountType,
                          onChanged: (v) => setM(() => accountType = v!)),
                      const Text("Current"),
                    ],
                  ),

                  _field("IFSC Code", ifsc),

                  // Fetch Button
                  if (!manual)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ElevatedButton(
                        onPressed: () {
                          // Mock Fetch Logic (Replace with API later)
                          setM(() {
                            bank.text = "Bank Fetched"; 
                            branch.text = "Branch Fetched";
                          });
                        },
                        child: const Text("Fetch Bank Details"),
                      ),
                    ),

                  // Bank Detail Fields
                  if (manual || bank.text.isNotEmpty) ...[
                    _field("Bank Name", bank),
                    _field("Branch Name", branch),
                    _field("City", city),
                    _field("State", state),
                    _field("MICR", micr),
                  ],

                  const SizedBox(height: 16),
                  
                  // SAVE BUTTON
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 45)),
                    onPressed: () async {
                      // 1. Validation
                      if (edit == null &&
                          accountNumber.text != reAccountNumber.text) {
                        _showError("Account numbers do not match");
                        return;
                      }
                      
                      if (ifsc.text.length < 5) {
                        _showError("Please enter valid IFSC");
                        return;
                      }

                      if (holder.text.isEmpty ||
                          accountNumber.text.isEmpty ||
                          ifsc.text.isEmpty) {
                        _showError("Please fill all mandatory fields");
                        return;
                      }

                      // 2. Logic: Add vs Edit
                      if (edit == null) {
                        // ADD - Use new API method
                        _showLoader();
                        
                        final success = await addBankAccount(
                          accountNumber: accountNumber.text,
                          accountHolder: holder.text,
                          ifsc: ifsc.text,
                          bankName: bank.text,
                          branchName: branch.text,
                          city: city.text,
                          state: state.text,
                          micr: micr.text,
                          accountType: accountType,
                          isApiData: false,
                        );
                        
                        if (mounted) Navigator.pop(context); // Close Loader
                        
                        if (success) {
                          _showSuccess("Bank account added successfully!");
                          Navigator.pop(context);
                          _fetchAccounts();
                        } else {
                          _showError("Failed to add bank account");
                        }
                      } else {
                        // EDIT - Use new API method
                        if (edit.id == null) {
                           _showError("Cannot edit account without ID");
                           return;
                        }
                        _showLoader();
                        
                        final success = await updateBankAccount(
                          id: edit.id!,
                          accountNumber: accountNumber.text,
                          accountHolder: holder.text,
                          ifsc: ifsc.text,
                          bankName: bank.text,
                          branchName: branch.text,
                          city: city.text,
                          state: state.text,
                          micr: micr.text,
                          accountType: accountType,
                          isApiData: false,
                        );
                        
                        if (mounted) Navigator.pop(context); // Close Loader
                        
                        if (success) {
                          _showSuccess("Bank account updated successfully!");
                          Navigator.pop(context);
                          _fetchAccounts();
                        } else {
                          _showError("Failed to update bank account");
                        }
                      }
                    },
                    child: const Text("Save Bank Account"),
                  )
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _field(String label, TextEditingController c, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }
}