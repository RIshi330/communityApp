import 'package:flutter/material.dart';

class PromotionSchedulerScreen extends StatefulWidget {
  const PromotionSchedulerScreen({super.key});

  @override
  State<PromotionSchedulerScreen> createState() =>
      _PromotionSchedulerScreenState();
}

class _PromotionSchedulerScreenState extends State<PromotionSchedulerScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String _selectedAudience = 'All Members';
  String _selectedDuration = '7 Days';
  String _selectedType = 'Post Boost';
  DateTime? _startDate;
  bool _isScheduling = false;

  final List<String> _audiences = [
    'All Members',
    'Followers Only',
    'Custom Audience',
    'New Users',
  ];

  final List<String> _durations = [
    '1 Day',
    '3 Days',
    '7 Days',
    '14 Days',
    '30 Days',
  ];

  final List<Map<String, dynamic>> _promoTypes = [
    {'label': 'Post Boost', 'icon': Icons.rocket_launch_outlined, 'color': const Color(0xff8F7CFF)},
    {'label': 'Story Ad', 'icon': Icons.auto_stories_outlined, 'color': Colors.orange},
    {'label': 'Banner Ad', 'icon': Icons.image_outlined, 'color': Colors.blue},
    {'label': 'Sponsored', 'icon': Icons.campaign_outlined, 'color': Colors.green},
  ];

  // Scheduled promotions list
  final List<Map<String, dynamic>> _scheduledPromos = [
    {
      'title': 'Summer Sale Campaign',
      'type': 'Post Boost',
      'status': 'Live',
      'budget': '₹2,000',
      'reach': '12.4K',
      'startDate': 'Feb 18',
      'endDate': 'Feb 25',
      'color': Colors.green,
    },
    {
      'title': 'New Member Welcome',
      'type': 'Story Ad',
      'status': 'Scheduled',
      'budget': '₹1,500',
      'reach': '—',
      'startDate': 'Feb 22',
      'endDate': 'Feb 29',
      'color': Colors.orange,
    },
    {
      'title': 'Product Launch',
      'type': 'Banner Ad',
      'status': 'Ended',
      'budget': '₹3,000',
      'reach': '28.7K',
      'startDate': 'Feb 10',
      'endDate': 'Feb 17',
      'color': Colors.grey,
    },
  ];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xff8F7CFF)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _schedulePromotion() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter promotion title'), backgroundColor: Color(0xff8F7CFF)),
      );
      return;
    }
    setState(() => _isScheduling = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isScheduling = false;
      _scheduledPromos.insert(0, {
        'title': _titleController.text.trim(),
        'type': _selectedType,
        'status': 'Scheduled',
        'budget': '₹${_budgetController.text.isEmpty ? "0" : _budgetController.text}',
        'reach': '—',
        'startDate': _startDate != null ? '${_startDate!.day} Feb' : 'Today',
        'endDate': '—',
        'color': Colors.orange,
      });
      _titleController.clear();
      _budgetController.clear();
      _descController.clear();
      _startDate = null;
    });
    Navigator.pop(context); // close bottom sheet
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Promotion scheduled!'), backgroundColor: Color(0xff8F7CFF)),
    );
  }

  void _openScheduleSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(margin: const EdgeInsets.symmetric(vertical: 10), width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFD1D5DB), borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Schedule Promotion', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Promo Type selector
                      const Text('Promotion Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 10),
                      Row(
                        children: _promoTypes.map((type) {
                          final isSelected = _selectedType == type['label'];
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setSheet(() => _selectedType = type['label']),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? (type['color'] as Color).withOpacity(0.15) : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: isSelected ? type['color'] as Color : Colors.transparent, width: 2),
                                ),
                                child: Column(
                                  children: [
                                    Icon(type['icon'] as IconData, color: isSelected ? type['color'] as Color : const Color(0xFF6B7280), size: 20),
                                    const SizedBox(height: 4),
                                    Text(type['label'] as String, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isSelected ? type['color'] as Color : const Color(0xFF6B7280)), textAlign: TextAlign.center),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),

                      // Title
                      const Text('Promotion Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Summer Sale Campaign',
                          filled: true, fillColor: const Color(0xFFF9FAFB),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xff8F7CFF), width: 2)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Description
                      const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Describe your promotion...',
                          filled: true, fillColor: const Color(0xFFF9FAFB),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xff8F7CFF), width: 2)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Budget + Duration row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Budget (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _budgetController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: '1000',
                                    prefixText: '₹ ',
                                    filled: true, fillColor: const Color(0xFFF9FAFB),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xff8F7CFF), width: 2)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Duration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFE5E7EB)),
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedDuration,
                                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14), border: InputBorder.none),
                                    items: _durations.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 14)))).toList(),
                                    onChanged: (v) => setSheet(() => _selectedDuration = v!),
                                    dropdownColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Audience
                      const Text('Target Audience', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE5E7EB))),
                        child: DropdownButtonFormField<String>(
                          value: _selectedAudience,
                          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14), border: InputBorder.none, prefixIcon: Icon(Icons.people_outline, color: Color(0xff8F7CFF))),
                          items: _audiences.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                          onChanged: (v) => setSheet(() => _selectedAudience = v!),
                          dropdownColor: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Start Date
                      const Text('Start Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE5E7EB))),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, color: Color(0xff8F7CFF), size: 18),
                              const SizedBox(width: 10),
                              Text(
                                _startDate == null ? 'Select start date' : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                                style: TextStyle(color: _startDate == null ? const Color(0xFF9CA3AF) : Colors.black, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Schedule button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isScheduling ? null : _schedulePromotion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff8F7CFF),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _isScheduling
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Schedule Promotion', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff8F7CFF),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Promotion Scheduler', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Summary cards
            Row(
              children: [
                _summaryCard('Live', '2', Icons.play_circle_outline, Colors.green, const Color(0xFFE8F5E9)),
                const SizedBox(width: 10),
                _summaryCard('Scheduled', '1', Icons.schedule, Colors.orange, const Color(0xFFFFF3E0)),
                const SizedBox(width: 10),
                _summaryCard('Total Reach', '41K', Icons.people_outline, const Color(0xff8F7CFF), const Color(0xFFE8E5FF)),
              ],
            ),

            const SizedBox(height: 24),

            // Scheduled Promotions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Scheduled Promotions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _openScheduleSheet,
                  icon: const Icon(Icons.add, size: 16, color: Color(0xff8F7CFF)),
                  label: const Text('New', style: TextStyle(color: Color(0xff8F7CFF), fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            ..._scheduledPromos.map((promo) => _promoCard(promo)),

            const SizedBox(height: 30),
          ],
        ),
      ),

      // FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openScheduleSheet,
        backgroundColor: const Color(0xff8F7CFF),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Schedule', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          ],
        ),
      ),
    );
  }

  Widget _promoCard(Map<String, dynamic> promo) {
    final color = promo['color'] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(promo['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(promo['status'] as String, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.campaign_outlined, size: 14, color: Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Text(promo['type'] as String, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              const SizedBox(width: 16),
              const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Text('${promo['startDate']} → ${promo['endDate']}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 10),
          Row(
            children: [
              _promoStat('Budget', promo['budget'] as String, Icons.currency_rupee),
              const SizedBox(width: 24),
              _promoStat('Reach', promo['reach'] as String, Icons.people_outline),
            ],
          ),
        ],
      ),
    );
  }

  Widget _promoStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xff8F7CFF)),
        const SizedBox(width: 4),
        Text('$label: ', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _budgetController.dispose();
    _descController.dispose();
    super.dispose();
  }
}