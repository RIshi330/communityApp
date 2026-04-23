import 'package:flutter/material.dart';
import '../database/database.dart';
import '../core/theme/app_theme.dart';

/* ================= MODEL ================= */

class WalletTransaction {
  final int id;
  final String description;
  final DateTime date;
  final double amount;
  final String nature;

  WalletTransaction({
    required this.id,
    required this.description,
    required this.date,
    required this.amount,
    required this.nature,
  });

  bool get isCredit => nature == 'CREDIT';
}

/* ================= SCREEN ================= */

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final Database db = Database();

  bool loading = true;
  double ewallet = 0;
  double ebanking = 0;
  List<WalletTransaction> transactions = [];

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  /* ================= LOAD WALLET ================= */

  Future<void> _loadWallet() async {
    setState(() => loading = true);

    final res = await db.getData({
      "action": "get_wallet",
    });

    if (res != null && res['status'] == 200 && res['data'] != null) {
      final balances = res['data']['balances'];
      final txns = res['data']['transactions'] as List? ?? [];

      setState(() {
        ewallet = double.tryParse(balances['ewallet'].toString()) ?? 0;
        ebanking =
            double.tryParse(balances['available_ebanking'].toString()) ?? 0;

        transactions = txns.map((t) {
          return WalletTransaction(
            id: t['id'],
            description: t['description'] ?? '',
            date: DateTime.tryParse(t['date'] ?? '') ?? DateTime.now(),
            amount: double.tryParse(t['amount'].toString()) ?? 0,
            nature: t['nature'] ?? '',
          );
        }).toList();

        loading = false;
      });
    } else {
      loading = false;
      _showSnack("Failed to load wallet");
    }
  }

  /* ================= ADD MONEY ================= */

  Future<void> _addMoney(String amount) async {
    final res = await db.getData({
      "action": "add_money",
      "amount": amount,
      "description": "Wallet top-up",
      "addTo": "ewallet",
    });

    if (res['status'] == 200) {
      _showSnack("Money added successfully");
      _loadWallet();
    } else {
      _showSnack(res['message'] ?? "Failed to add money");
    }
  }

  /* ================= WITHDRAW ================= */

  Future<void> _withdraw(String amount, String description) async {
    final res = await db.getData({
      "action": "withdraw_request",
      "amount": amount,
      "description": description,
      "receiveTo": "bank",
    });

    if (res['status'] == 200) {
      _showSnack("Withdrawal request submitted");
      _loadWallet();
    } else {
      _showSnack(res['message'] ?? "Withdrawal failed");
    }
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Wallet", style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: "add",
            onPressed: _openAddMoneySheet,
            icon: const Icon(Icons.add),
            label: const Text("Add Money"),
            backgroundColor: AppTheme.primaryColor,
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: "withdraw",
            onPressed: _openWithdrawSheet,
            icon: const Icon(Icons.account_balance),
            label: const Text("Withdraw"),
            backgroundColor: Colors.orange,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWallet,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _walletSummary(),
                  const SizedBox(height: 24),
                  const Text(
                    "Transaction History",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (transactions.isEmpty)
                    const Center(child: Text("No transactions found")),
                  ...transactions.map(_transactionTile).toList(),
                ],
              ),
            ),
    );
  }

  /* ================= WIDGETS ================= */

  Widget _walletSummary() => Row(
        children: [
          _summaryCard(
            "e-Wallet",
            "₹${ewallet.toStringAsFixed(0)}",
            Icons.account_balance_wallet,
          ),
          const SizedBox(width: 12),
          _summaryCard(
            "e-Banking",
            "₹${ebanking.toStringAsFixed(0)}",
            Icons.account_balance,
          ),
        ],
      );

  Widget _summaryCard(String title, String value, IconData icon) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.teal.shade50,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.teal),
              const SizedBox(height: 12),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(title, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );

  Widget _transactionTile(WalletTransaction t) => Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor:
                t.isCredit ? Colors.green.shade100 : Colors.red.shade100,
            child: Icon(
              t.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: t.isCredit ? Colors.green : Colors.red,
            ),
          ),
          title: Text(
            t.description.isEmpty ? "Wallet Transaction" : t.description,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
              "TXN#${t.id}\n${_formatDate(t.date)}"),
          trailing: Text(
            "${t.isCredit ? '+' : '-'}₹${t.amount.toStringAsFixed(0)}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: t.isCredit ? Colors.green : Colors.red,
            ),
          ),
          isThreeLine: true,
        ),
      );

  String _formatDate(DateTime d) =>
      "${d.day}/${d.month}/${d.year} • ${d.hour}:${d.minute.toString().padLeft(2, '0')}";

  /* ================= BOTTOM SHEETS ================= */

  void _openAddMoneySheet() {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Add Money",
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: "Amount"),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _addMoney(controller.text);
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  void _openWithdrawSheet() {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Withdraw Money",
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: "Amount"),
            ),
            TextField(
              controller: descCtrl,
              decoration:
                  const InputDecoration(labelText: "Description"),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _withdraw(amountCtrl.text, descCtrl.text);
              },
              child: const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }

  /* ================= HELPERS ================= */

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}



















/*import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database/database.dart';
import '../../app_constants.dart';

/* ================= MODEL ================= */

class WalletTransaction {
  final String title;
  final String txnId;
  final DateTime date;
  final double amount;
  final bool isCredit;

  WalletTransaction({
    required this.title,
    required this.txnId,
    required this.date,
    required this.amount,
    required this.isCredit,
  });
}

/* ================= SCREEN ================= */

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final Database db = Database();

  bool loading = true;
  double eWalletBalance = 0;
  double eBankingBalance = 0;
  List<WalletTransaction> transactions = [];

  @override
  void initState() {
    super.initState();
    loadWallet();
  }

  /* ================= FETCH WALLET ================= */

  Future<void> loadWallet() async {
    final res = await db.getData({
      "module": "payment",
      "submodule": "utils",
      "functions":
          "ewallet,ebanking,income,expenditure,pending_request,transaction_history",
    });

    print("WALLET RESPONSE => $res");

    if (res['status'] == 200 && res['data'] != null) {
      final data = res['data'];

      setState(() {
        eWalletBalance = double.tryParse(
                data['ewallet']?['available']?.toString() ?? "0") ??
            0;

        eBankingBalance = double.tryParse(
                data['ebanking']?['available']?.toString() ?? "0") ??
            0;

        final historyWrapper = data['transaction_history'];

        if (historyWrapper != null &&
            historyWrapper['status'] == 200 &&
            historyWrapper['data'] is List) {
          transactions =
              (historyWrapper['data'] as List).map((t) {
            return WalletTransaction(
              title: t['description'] ?? 'Wallet Transaction',
              txnId: t['id']?.toString() ?? '-',
              date: DateTime.tryParse(t['date'] ?? '') ??
                  DateTime.now(),
              amount: double.tryParse(
                      t['amount']?.toString() ?? "0") ??
                  0,
              isCredit: t['nature'] == 'CREDIT',
            );
          }).toList();
        } else {
          transactions = [];
        }

        loading = false;
      });
    } else {
      loading = false;
    }
  }

  /* ================= GENERATE PAYMENT LINK ================= */

  Future<void> generatePaymentLink(String amount) async {
    final res = await db.getData({
      "module": "payment",
      "submodule": "utils",
      "functions": "generate_link",
      "marketplace": marketplaceId,
      "service_charge": amount,
      "item_id": "1",
      "client": "1",
    });

    print("GENERATE LINK RESPONSE => $res");

    if (res['status'] == 200 && res.containsKey('payment_link')) {
      await launchUrl(
        Uri.parse(res['payment_link']),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xfff5f7fa),
      appBar: AppBar(
        title: const Text("Wallet"),
        backgroundColor: const Color(0xFF014D4E),
      ),

      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: "add",
            backgroundColor: const Color(0xFF014D4E),
            onPressed: () => _addMoney(context),
            icon: const Icon(Icons.add),
            label: const Text("Add Money"),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: "withdraw",
            backgroundColor: Colors.orange,
            onPressed: () => _withdraw(context),
            icon: const Icon(Icons.account_balance),
            label: const Text("Withdraw"),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: loadWallet,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _walletSummary(),
              const SizedBox(height: 24),
              const Text(
                "Transaction History",
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (transactions.isEmpty)
                const Center(child: Text("No transactions found")),
              ...transactions.map(_transactionCard).toList(),
            ],
          ),
        ),
      ),
    );
  }

  /* ================= SUMMARY ================= */

  Widget _walletSummary() => SizedBox(
        height: 120,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _summaryCard(
              "e-Wallet Available",
              "₹${eWalletBalance.toStringAsFixed(0)}",
              Icons.account_balance_wallet,
            ),
            _summaryCard(
              "e-Banking Available",
              "₹${eBankingBalance.toStringAsFixed(0)}",
              Icons.account_balance,
            ),
          ],
        ),
      );

  Widget _summaryCard(String title, String value, IconData icon) =>
      Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.teal.shade50,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.teal),
            const Spacer(),
            Text(value,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            Text(title,
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );

  /* ================= TRANSACTION CARD ================= */

  Widget _transactionCard(WalletTransaction t) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor:
                t.isCredit ? Colors.green.shade100 : Colors.red.shade100,
            child: Icon(
              t.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: t.isCredit ? Colors.green : Colors.red,
            ),
          ),
          title: Text(
            t.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
              "ID: ${t.txnId}\n${_formatDate(t.date)}"),
          trailing: Text(
            "${t.isCredit ? '+' : '-'}₹${t.amount.toStringAsFixed(0)}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: t.isCredit ? Colors.green : Colors.red,
            ),
          ),
          isThreeLine: true,
        ),
      );

  String _formatDate(DateTime d) =>
      "${d.day}/${d.month}/${d.year} • ${d.hour}:${d.minute.toString().padLeft(2, '0')}";

  /* ================= ADD MONEY ================= */

  void _addMoney(BuildContext context) {
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Add Money",
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: "Amount"),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await generatePaymentLink(
                    amountController.text);
              },
              child: const Text("Proceed to Pay"),
            ),
          ],
        ),
      ),
    );
  }

  /* ================= WITHDRAW (BACKEND-DRIVEN) ================= */

  void _withdraw(BuildContext context) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Withdraw Money",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: "Amount"),
            ),
            TextField(
              controller: descriptionController,
              decoration:
                  const InputDecoration(labelText: "Description"),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final res = await db.getData({
                  "module": "payment",
                  "submodule": "utils",
                  "functions": "withdraw_request",
                  "amount": amountController.text,
                  "description":
                      descriptionController.text,
                  "transfer_to": "1",
                });

                print("WITHDRAW RESPONSE => $res");

                final withdraw =
                    res['data']?['withdraw_request'];

                Navigator.pop(context);

                if (withdraw != null &&
                    withdraw['status'] == 200) {
                  loadWallet();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            "Withdrawal request submitted")),
                  );
                } else {
                  final error =
                      withdraw?['error'] ??
                          "Withdrawal failed";
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error)),
                  );
                }
              },
              child: const Text("Submit Withdrawal"),
            ),
          ],
        ),
      ),
    );
  }
}
*/