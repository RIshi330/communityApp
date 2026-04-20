import 'package:flutter/material.dart';

class PromotionEngineScreen extends StatefulWidget {
  const PromotionEngineScreen({super.key});

  @override
  State<PromotionEngineScreen> createState() => _PromotionEngineScreenState();
}

class _PromotionEngineScreenState extends State<PromotionEngineScreen> {
  bool autoBoostEnabled = true;
  bool smartTargetingEnabled = false;
  bool peakTimeEnabled = true;
  String selectedBidStrategy = 'Auto Bid';

  final List<Map<String, dynamic>> _activeEngines = [
    {'name': 'Auto Post Booster', 'status': true, 'reach': '8.2K', 'spend': '₹450'},
    {'name': 'Peak Time Scheduler', 'status': true, 'reach': '5.1K', 'spend': '₹210'},
    {'name': 'Smart Retargeting', 'status': false, 'reach': '—', 'spend': '₹0'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff8F7CFF),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Promotion Engine', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Stats row
            Row(
              children: [
                _statBox('Total Spend', '₹660', Icons.currency_rupee, Colors.blue, const Color(0xFFE3F2FD)),
                const SizedBox(width: 10),
                _statBox('Total Reach', '13.3K', Icons.people_outline, const Color(0xff8F7CFF), const Color(0xFFE8E5FF)),
                const SizedBox(width: 10),
                _statBox('Active', '2', Icons.play_circle_outline, Colors.green, const Color(0xFFE8F5E9)),
              ],
            ),

            const SizedBox(height: 24),

            // Engine toggles
            const Text('Engine Settings', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            _toggleCard(
              title: 'Auto Post Boost',
              subtitle: 'Automatically boost high-performing posts',
              icon: Icons.rocket_launch_outlined,
              iconColor: const Color(0xff8F7CFF),
              value: autoBoostEnabled,
              onChanged: (v) => setState(() => autoBoostEnabled = v),
            ),
            _toggleCard(
              title: 'Smart Targeting',
              subtitle: 'Use AI to find best audience automatically',
              icon: Icons.psychology_outlined,
              iconColor: Colors.orange,
              value: smartTargetingEnabled,
              onChanged: (v) => setState(() => smartTargetingEnabled = v),
            ),
            _toggleCard(
              title: 'Peak Time Delivery',
              subtitle: 'Show ads when members are most active',
              icon: Icons.access_time_outlined,
              iconColor: Colors.green,
              value: peakTimeEnabled,
              onChanged: (v) => setState(() => peakTimeEnabled = v),
            ),

            const SizedBox(height: 20),

            // Bid strategy
            const Text('Bid Strategy', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: ['Auto Bid', 'Manual Bid', 'Target CPA'].map((strategy) {
                final isSelected = selectedBidStrategy == strategy;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedBidStrategy = strategy),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xff8F7CFF) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(strategy, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : const Color(0xFF6B7280))),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Active engines
            const Text('Active Engines', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._activeEngines.map((engine) => _engineCard(engine)),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String label, String value, IconData icon, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
        ]),
      ),
    );
  }

  Widget _toggleCard({required String title, required String subtitle, required IconData icon, required Color iconColor, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: iconColor, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          ])),
          Switch(value: value, onChanged: onChanged, activeColor: const Color(0xff8F7CFF)),
        ],
      ),
    );
  }

  Widget _engineCard(Map<String, dynamic> engine) {
    final isActive = engine['status'] as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(color: isActive ? Colors.green : Colors.grey, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(engine['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
          Text('Reach: ${engine['reach']}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(width: 12),
          Text(engine['spend'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xff8F7CFF))),
        ],
      ),
    );
  }
}