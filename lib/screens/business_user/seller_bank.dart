import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../Database/Database.dart';

/* =========================================================
   MODEL  — field names match PHP SELECT response exactly
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
      accountHolder: json['account_name'] ?? '',   // DB col = account_name
      accountNumber: json['account_number'] ?? '',
      ifsc: json['ifsc'] ?? '',
      branch: json['branch_name'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      micr: json['MICR_code'] ?? '',               // DB col = MICR_code
      accountType: json['account_type'] ?? 'Savings',
      isDefault: json['default'] == "1" || json['default'] == 1,
    );
  }
}

/* =========================================================
   SCREEN
========================================================= */

class SellerBankAccountsScreen_ extends StatefulWidget {
  const SellerBankAccountsScreen_({super.key});

  @override
  State<SellerBankAccountsScreen_> createState() =>
      _SellerBankAccountsScreenState();
}

class _SellerBankAccountsScreenState extends State<SellerBankAccountsScreen_>
    with SingleTickerProviderStateMixin {
  final Database _db = Database();
  List<BankAccount> accounts = [];
  bool isLoading = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _fetchAccounts();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  /* =========================================================
     API CALLS — keys match your PHP backend EXACTLY
  ========================================================= */

  // PHP: if (isset($input['fetch_all']))
  Future<List<BankAccount>?> _apiFetchAll() async {
    try {
      final res = await _db.getData({'fetch_all': true});
      if (res['success'] == true && res['data'] != null) {
        return (res['data'] as List).map((e) => BankAccount.fromMap(e)).toList();
      }
      debugPrint('fetchAll failed: ${res['message']}');
      return null;
    } catch (e) {
      debugPrint('fetchAll error: $e');
      return null;
    }
  }

  // PHP: if (isset($input['IFSC']))
  Future<Map<String, dynamic>?> _apiLookupIfsc(String ifsc) async {
    try {
      final res = await _db.getData({'IFSC': ifsc.toUpperCase()});
      if (res['success'] == true && res['data'] != null) {
        return Map<String, dynamic>.from(res['data']);
      }
      debugPrint('IFSC lookup failed: ${res['message']}');
      return null;
    } catch (e) {
      debugPrint('IFSC error: $e');
      return null;
    }
  }

  // PHP: if (isset($input['API_Data']) || isset($input['User_Data']))
  //   isApiData=true  → flagKey='API_Data',      prefix='1'
  //   isApiData=false → flagKey='User_Data',     prefix='2'
  //   Fields sent: enter_acc{p}, name{p}, ifsc_code{p}, bank_name{p},
  //                branch_name{p}, branch_code{p}, city{p}, state{p},
  //                MICR{p}, acc_type{p}
  Future<bool> _apiAddBank({
    required String accountNumber,
    required String accountHolder,
    required String ifsc,
    required String bankName,
    required String branchName,
    required String city,
    required String state,
    String branchCode = '',
    String micr = '',
    String accountType = 'SAVINGS',
    bool isApiData = false,
  }) async {
    try {
      final String p = isApiData ? '1' : '2';
      final String flagKey = isApiData ? 'API_Data' : 'User_Data';
      final res = await _db.getData({
        flagKey: true,
        'enter_acc$p': accountNumber,
        'name$p': accountHolder,
        'ifsc_code$p': ifsc,
        'bank_name$p': bankName,
        'branch_name$p': branchName,
        'branch_code$p': branchCode,
        'city$p': city,
        'state$p': state,
        'MICR$p': micr,
        'acc_type$p': accountType,
      });
      debugPrint('addBank: ${res['success']} ${res['message']}');
      return res['success'] == true;
    } catch (e) {
      debugPrint('addBank error: $e');
      return false;
    }
  }

  // PHP: if (isset($input['Edit_API_Data']) || isset($input['Edit_User_Data']))
  //   The bank ID is the VALUE of the flag key (PHP: $id = realEscape($input['Edit_User_Data']))
  //   isApiData=true  → flagKey='Edit_API_Data', prefix='1'
  //   isApiData=false → flagKey='Edit_User_Data', prefix='2'
  Future<bool> _apiEditBank({
    required String id,
    required String accountNumber,
    required String accountHolder,
    required String ifsc,
    required String bankName,
    required String branchName,
    required String city,
    required String state,
    String branchCode = '',
    String micr = '',
    String accountType = 'SAVINGS',
    bool isApiData = false,
  }) async {
    try {
      final String p = isApiData ? '1' : '2';
      final String flagKey = isApiData ? 'Edit_API_Data' : 'Edit_User_Data';
      final res = await _db.getData({
        flagKey: id,            // ← ID is the VALUE, not a separate key
        'enter_acc$p': accountNumber,
        'name$p': accountHolder,
        'ifsc_code$p': ifsc,
        'bank_name$p': bankName,
        'branch_name$p': branchName,
        'branch_code$p': branchCode,
        'city$p': city,
        'state$p': state,
        'MICR$p': micr,
        'acc_type$p': accountType,
      });
      debugPrint('editBank: ${res['success']} ${res['message']}');
      return res['success'] == true;
    } catch (e) {
      debugPrint('editBank error: $e');
      return false;
    }
  }

  // PHP: if (isset($input['delete']))  — value is the bank id
  Future<bool> _apiDeleteBank(String id) async {
    try {
      final res = await _db.getData({'delete': id});
      debugPrint('deleteBank: ${res['success']} ${res['message']}');
      return res['success'] == true;
    } catch (e) {
      debugPrint('deleteBank error: $e');
      return false;
    }
  }

  // PHP: if (isset($input['default']))
  //   value = bank id,  status = '1' to set as default
  Future<bool> _apiSetDefault(String id) async {
    try {
      final res = await _db.getData({
        'default': id,    // PHP: $id = realEscape($input['default'])
        'status': '1',    // PHP: $status = realEscape($input['status'])
      });
      debugPrint('setDefault: ${res['success']} ${res['message']}');
      return res['success'] == true;
    } catch (e) {
      debugPrint('setDefault error: $e');
      return false;
    }
  }

  /* =========================================================
     SCREEN LOGIC
  ========================================================= */

  Future<void> _fetchAccounts() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    final data = await _apiFetchAll();
    if (!mounted) return;
    setState(() {
      accounts = data ?? [];
      isLoading = false;
    });
    _animCtrl.forward(from: 0);
  }

  Future<void> _deleteAccount(String id) async {
    final confirm = await _confirmDialog(
      title: 'Delete Account',
      message: 'Are you sure you want to delete this bank account? This cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirm != true) return;
    _showLoader();
    final ok = await _apiDeleteBank(id);
    if (mounted) Navigator.pop(context);
    if (ok) {
      _showSuccess('Account deleted successfully');
      setState(() => accounts.removeWhere((a) => a.id == id));
    } else {
      _showError('Failed to delete account');
    }
  }

  Future<void> _setDefaultAccount(String id) async {
    _showLoader();
    final ok = await _apiSetDefault(id);
    if (mounted) Navigator.pop(context);
    if (ok) {
      _showSuccess('Default account updated!');
      setState(() {
        for (final a in accounts) {
          a.isDefault = (a.id == id);
        }
      });
    } else {
      _showError('Failed to update default account');
    }
  }

  /* =========================================================
     HELPERS
  ========================================================= */

  void _showLoader() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Padding(
            padding: EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Processing...', style: TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white),
        const SizedBox(width: 10),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(12),
    ));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline, color: Colors.white),
        const SizedBox(width: 10),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(12),
    ));
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(
            isDestructive ? Icons.warning_amber_rounded : Icons.info_outline,
            color: isDestructive ? Colors.red.shade700 : AppTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ]),
        content: Text(message, style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? Colors.red.shade700 : AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  String _maskAccount(String number) {
    if (number.length <= 4) return number;
    return 'XXXX XXXX ${number.substring(number.length - 4)}';
  }

  /* =========================================================
     BUILD
  ========================================================= */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Bank Details',
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20),
        ),
      ),
      floatingActionButton: accounts.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: () => _openBankModal(),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('Add Account',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
      )
          : null,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchAccounts,
        child: accounts.isEmpty
            ? _buildEmptyState()
            : FadeTransition(
          opacity: _fadeAnim,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            itemCount: accounts.length + 1,
            itemBuilder: (_, i) {
              if (i == accounts.length) return _buildAddMoreBtn();
              return _bankCard(accounts[i]);
            },
          ),
        ),
      ),
    );
  }

  /* ─── Empty State ─── */

  Widget _buildEmptyState() {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 600),
        builder: (_, v, child) => Opacity(opacity: v, child: child),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: Colors.grey.shade100, shape: BoxShape.circle),
              child: Icon(Icons.account_balance_wallet_outlined,
                  size: 80, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),
            Text('No Bank Accounts',
                style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Text('Add your first bank account to receive payments',
                style: GoogleFonts.poppins(
                    fontSize: 14, color: Colors.grey.shade500)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: Text('Add Bank Account',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                elevation: 2,
              ),
              onPressed: () => _openBankModal(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMoreBtn() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: OutlinedButton.icon(
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Add New Bank Account'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          foregroundColor: AppTheme.primaryColor,
          side: BorderSide(color: AppTheme.primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: () => _openBankModal(),
      ),
    );
  }

  /* ─── Bank Card ─── */

  Widget _bankCard(BankAccount acc) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      builder: (_, v, child) =>
          Transform.scale(scale: v, child: Opacity(opacity: v, child: child)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: acc.isDefault
                ? [Colors.green.shade50, Colors.green.shade100]
                : [Colors.white, Colors.grey.shade50],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
          border: Border.all(
            color: acc.isDefault ? Colors.green.shade300 : Colors.grey.shade200,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onLongPress: () => _showBottomOptions(acc),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.account_balance,
                          color: AppTheme.primaryColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              acc.bankName.isNotEmpty
                                  ? acc.bankName
                                  : 'Bank Account',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  color: Colors.grey.shade800),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (acc.branch.isNotEmpty)
                              Text(acc.branch,
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade600)),
                          ]),
                    ),
                    if (acc.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.verified,
                              size: 14, color: Colors.green.shade700),
                          const SizedBox(width: 4),
                          Text('Default',
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700)),
                        ]),
                      ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      itemBuilder: (_) => [
                        _popItem('edit', Icons.edit_outlined, 'Edit',
                            Colors.blue.shade700),
                        if (!acc.isDefault)
                          _popItem('default', Icons.star_outline,
                              'Set as Default', Colors.orange),
                        _popItem('delete', Icons.delete_outline, 'Delete',
                            Colors.red),
                      ],
                      onSelected: (val) {
                        if (val == 'edit') _openBankModal(edit: acc);
                        if (val == 'delete' && acc.id != null)
                          _deleteAccount(acc.id!);
                        if (val == 'default' && acc.id != null)
                          _setDefaultAccount(acc.id!);
                      },
                    ),
                  ]),

                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.shade200, height: 1),
                  const SizedBox(height: 12),

                  _infoRow('Holder Name', acc.accountHolder),
                  _infoRow('Account Type', acc.accountType),
                  _infoRow('Account No.', _maskAccount(acc.accountNumber)),
                  _infoRow('IFSC Code', acc.ifsc),

                  const SizedBox(height: 12),

                  // Default switch
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: acc.isDefault
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.blue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
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
                              ? '✓ Default Payment Account'
                              : 'Set as default account',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: acc.isDefault
                                ? Colors.green.shade700
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _popItem(
      String val, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: val,
      child: Row(children: [
        Icon(icon, size: 19, color: color),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                color: val == 'delete' ? Colors.red : null,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 100,
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                  fontSize: 12)),
        ),
        Expanded(
          child: Text(value,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.grey.shade800)),
        ),
      ]),
    );
  }

  void _showBottomOptions(BankAccount acc) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: Colors.blue),
            title: const Text('Edit Account'),
            onTap: () {
              Navigator.pop(context);
              _openBankModal(edit: acc);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Delete Account',
                style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              if (acc.id != null) _deleteAccount(acc.id!);
            },
          ),
          if (!acc.isDefault)
            ListTile(
              leading: const Icon(Icons.star_outline, color: Colors.orange),
              title: const Text('Set as Default'),
              onTap: () {
                Navigator.pop(context);
                if (acc.id != null) _setDefaultAccount(acc.id!);
              },
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  /* =========================================================
     ADD / EDIT MODAL
  ========================================================= */

  void _openBankModal({BankAccount? edit}) {
    final accNoCtrl = TextEditingController(text: edit?.accountNumber);
    final reAccNoCtrl = TextEditingController(text: edit?.accountNumber);
    final holderCtrl = TextEditingController(text: edit?.accountHolder);
    final ifscCtrl = TextEditingController(text: edit?.ifsc);
    final bankCtrl = TextEditingController(text: edit?.bankName);
    final branchCtrl = TextEditingController(text: edit?.branch);
    final cityCtrl = TextEditingController(text: edit?.city);
    final stateCtrl = TextEditingController(text: edit?.state);
    final micrCtrl = TextEditingController(text: edit?.micr);

    String accType = edit?.accountType ?? 'Savings';
    bool useIfsc = true;
    bool isFetching = false;
    bool bankFetched = edit != null && edit.bankName.isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(builder: (ctx, setM) {
          Future<void> onSave() async {
            if (holderCtrl.text.trim().isEmpty) {
              _showError('Enter account holder name');
              return;
            }
            if (accNoCtrl.text.trim().isEmpty) {
              _showError('Enter account number');
              return;
            }
            if (edit == null &&
                accNoCtrl.text.trim() != reAccNoCtrl.text.trim()) {
              _showError('Account numbers do not match');
              return;
            }
            if (ifscCtrl.text.trim().length < 5) {
              _showError('Enter a valid IFSC code');
              return;
            }
            if (bankCtrl.text.trim().isEmpty) {
              _showError(
                  useIfsc ? 'Please fetch bank details first' : 'Enter bank name');
              return;
            }

            Navigator.pop(ctx);
            _showLoader();

            // isApiData=true  → PHP 'API_Data' key, prefix '1'
            // isApiData=false → PHP 'User_Data' key, prefix '2'
            final bool isApiData = useIfsc && bankFetched;

            bool ok;
            if (edit == null) {
              ok = await _apiAddBank(
                accountNumber: accNoCtrl.text.trim(),
                accountHolder: holderCtrl.text.trim(),
                ifsc: ifscCtrl.text.trim().toUpperCase(),
                bankName: bankCtrl.text.trim(),
                branchName: branchCtrl.text.trim(),
                city: cityCtrl.text.trim(),
                state: stateCtrl.text.trim(),
                micr: micrCtrl.text.trim(),
                accountType: accType.toUpperCase(),
                isApiData: isApiData,
              );
            } else {
              if (edit.id == null) {
                if (mounted) Navigator.pop(context);
                _showError('Cannot edit — account ID missing');
                return;
              }
              ok = await _apiEditBank(
                id: edit.id!,
                accountNumber: accNoCtrl.text.trim(),
                accountHolder: holderCtrl.text.trim(),
                ifsc: ifscCtrl.text.trim().toUpperCase(),
                bankName: bankCtrl.text.trim(),
                branchName: branchCtrl.text.trim(),
                city: cityCtrl.text.trim(),
                state: stateCtrl.text.trim(),
                micr: micrCtrl.text.trim(),
                accountType: accType.toUpperCase(),
                isApiData: isApiData,
              );
            }

            if (mounted) Navigator.pop(context);

            if (ok) {
              _showSuccess(edit == null
                  ? 'Bank account added successfully!'
                  : 'Bank account updated successfully!');
              await _fetchAccounts();
            } else {
              _showError(edit == null
                  ? 'Failed to add bank account'
                  : 'Failed to update bank account');
            }
          }

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 8,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  Text(
                    edit == null ? 'Add Bank Account' : 'Edit Bank Account',
                    style: GoogleFonts.poppins(
                        fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    edit == null
                        ? 'Enter your bank account details'
                        : 'Update your bank account information',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 20),

                  // IFSC / Manual toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      _toggleTab('Fetch via IFSC', useIfsc,
                          onTap: () => setM(() => useIfsc = true)),
                      _toggleTab('Manual Entry', !useIfsc,
                          onTap: () => setM(() => useIfsc = false)),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  _field('Account Number', accNoCtrl,
                      icon: Icons.credit_card,
                      isNumber: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ]),

                  if (edit == null)
                    _field('Re-enter Account Number', reAccNoCtrl,
                        icon: Icons.credit_card,
                        isNumber: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ]),

                  _field('Account Holder Name', holderCtrl,
                      icon: Icons.person_outline),

                  const SizedBox(height: 4),
                  Text('Account Type',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: _typeChip('Savings', accType == 'Savings',
                            onTap: () => setM(() => accType = 'Savings'))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _typeChip('Current', accType == 'Current',
                            onTap: () => setM(() => accType = 'Current'))),
                  ]),
                  const SizedBox(height: 16),

                  _field('IFSC Code', ifscCtrl,
                      icon: Icons.code,
                      hint: 'Enter 11-character IFSC code',
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[A-Za-z0-9]')),
                        LengthLimitingTextInputFormatter(11),
                      ]),

                  // Fetch button
                  if (useIfsc) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isFetching
                            ? null
                            : () async {
                          final code =
                          ifscCtrl.text.trim().toUpperCase();
                          if (code.length < 11) {
                            _showError(
                                'Enter a valid 11-character IFSC code');
                            return;
                          }
                          setM(() => isFetching = true);
                          final data = await _apiLookupIfsc(code);
                          setM(() => isFetching = false);
                          if (data != null) {
                            setM(() {
                              bankCtrl.text = data['BANK'] ?? '';
                              branchCtrl.text = data['BRANCH'] ?? '';
                              cityCtrl.text = data['CITY'] ?? '';
                              stateCtrl.text = data['STATE'] ?? '';
                              micrCtrl.text = data['MICR'] ?? '';
                              bankFetched = true;
                            });
                            _showSuccess('Bank details fetched successfully!');
                          } else {
                            _showError(
                                'Failed to fetch bank details. Check IFSC code.');
                          }
                        },
                        icon: isFetching
                            ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.cloud_download_outlined),
                        label: Text(
                            isFetching ? 'Fetching...' : 'Fetch Bank Details',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding:
                          const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Bank details (after fetch or in manual mode)
                  if (!useIfsc || bankFetched) ...[
                    if (bankFetched && useIfsc)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(children: [
                          Icon(Icons.check_circle,
                              size: 16, color: Colors.green.shade600),
                          const SizedBox(width: 6),
                          Text('Bank details fetched successfully',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500)),
                        ]),
                      ),
                    _field('Bank Name', bankCtrl,
                        icon: Icons.account_balance_outlined,
                        readOnly: useIfsc && bankFetched),
                    _field('Branch Name', branchCtrl,
                        icon: Icons.location_city_outlined,
                        readOnly: useIfsc && bankFetched),
                    _field('City', cityCtrl,
                        icon: Icons.location_on_outlined,
                        readOnly: useIfsc && bankFetched),
                    _field('State', stateCtrl,
                        icon: Icons.map_outlined,
                        readOnly: useIfsc && bankFetched),
                    _field('MICR Code', micrCtrl,
                        icon: Icons.qr_code,
                        readOnly: useIfsc && bankFetched),
                  ],

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      child: Text(
                        edit == null
                            ? 'Save Bank Account'
                            : 'Update Bank Account',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _toggleTab(String label, bool active,
      {required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: active ? Colors.white : Colors.grey.shade600)),
        ),
      ),
    );
  }

  Widget _typeChip(String label, bool selected,
      {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
            selected ? AppTheme.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Center(
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color:
                  selected ? Colors.white : Colors.grey.shade700)),
        ),
      ),
    );
  }

  Widget _field(
      String label,
      TextEditingController ctrl, {
        IconData? icon,
        String? hint,
        bool isNumber = false,
        bool readOnly = false,
        List<TextInputFormatter>? inputFormatters,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: ctrl,
        readOnly: readOnly,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        inputFormatters: inputFormatters,
        style: GoogleFonts.poppins(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon != null
              ? Icon(icon, size: 20, color: Colors.grey.shade600)
              : null,
          filled: true,
          fillColor:
          readOnly ? Colors.grey.shade100 : Colors.grey.shade50,
          border:
          OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
            BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
          labelStyle: GoogleFonts.poppins(
              fontSize: 13, color: Colors.grey.shade600),
        ),
      ),
    );
  }
}