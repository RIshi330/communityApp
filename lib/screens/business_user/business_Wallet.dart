import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'business_bottom_navigation.dart';

class BusinessWallet extends StatefulWidget {
  const BusinessWallet({super.key});

  @override
  State<BusinessWallet> createState() => _BusinessWalletState();
}

class _BusinessWalletState extends State<BusinessWallet> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Wallet")),
      body: const Center(
        child: Text("Wallet Screen"),
      ),
    );
  }
}
