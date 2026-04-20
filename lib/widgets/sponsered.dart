// sponsoredcard.dart

import 'package:flutter/material.dart';
import '../theme.dart';

class SponsoredAdCard extends StatelessWidget {
  const SponsoredAdCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.softLavender,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        leading: const Icon(Icons.campaign),
        title: const Text("Sponsored"),
        subtitle: const Text("Promote your brand here"),
        trailing: ElevatedButton(
          onPressed: () {},
          child: const Text("Explore"),
        ),
      ),
    );
  }
}
