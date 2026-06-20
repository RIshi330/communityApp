// import 'dart:convert';
// import 'package:commity_app1/app_constants.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
//
// // ─────────────────────────────────────────────
// //  API SERVICE WITH DEBUGGING
// // ─────────────────────────────────────────────
//
// class CampaignApiService {
//   String _baseUrl = "${baseUrl}new_apis/submit_content_api.php";
//   static Future<ApiResult> submitCampaign({
//
//     required int marketplaceId,
//     required int requestId,
//     required int orderId,
//     required String description,
//     required String location,
//     required int budget,
//     required String availability,
//     required int minQty,
//     required int maxQty,
//     required int status,
//     required String comment,
//     required List<String> attachments,
//     String? sessionCookie,
//   }) async {
//     // final uri = Uri.parse(_baseUrl);
//
//     try {
//       // final uri = Uri.parse(_baseUrl);
//
//       final Map<String, dynamic> body = {
//         'action': 'submit_opp_response',
//         'marketplace_id': marketplaceId,
//         'request_id': requestId,
//         'order_id': orderId,
//         'description': description,
//         'location': location,
//         'budget': budget,
//         'availability': availability,
//         'min_qty': minQty,
//         'max_qty': maxQty,
//         'status': status,
//         'comment': comment,
//         'attachments': attachments,
//       };
//
//       // DEBUG: Log request
//       print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
//       print('🔍 API REQUEST:');
//       // print('📍 URL: $uri');
//       print('📦 Body: ${jsonEncode(body)}');
//       print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
//
//       final headers = <String, String>{
//         'Content-Type': 'application/json',
//         'Accept': 'application/json',
//         if (sessionCookie != null) 'Cookie': sessionCookie,
//       };
//
//       final response = await http
//           .post(uri, headers: headers, body: jsonEncode(body))
//           .timeout(const Duration(seconds: 30));
//
//       // DEBUG: Log response
//       print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
//       print('📥 API RESPONSE:');
//       print('📊 Status: ${response.statusCode}');
//       print('📄 Body: ${response.body}');
//       print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
//
//       if (response.statusCode == 200) {
//         if (response.body.isEmpty) {
//           return ApiResult.failure('Server returned empty response');
//         }
//
//         try {
//           final decoded = jsonDecode(response.body) as Map<String, dynamic>;
//
//           final bool success =
//           (decoded['status'] as bool? ??
//               decoded['success'] as bool? ??
//               false);
//           final String message =
//               decoded['message'] as String? ?? 'Unknown error';
//
//           if (success) {
//             return ApiResult.success(
//               message: message,
//               responseId: decoded['response_id'] as int?,
//             );
//           } else {
//             return ApiResult.failure(message);
//           }
//         } on FormatException catch (e) {
//           print('❌ JSON Parse Error: $e');
//           return ApiResult.failure('Invalid response format: $e');
//         }
//       } else if (response.statusCode == 401) {
//         return ApiResult.failure('Session expired. Please log in again.');
//       } else {
//         return ApiResult.failure(
//             'Server error (${response.statusCode}): ${response.body}'
//         );
//       }
//     } on http.ClientException catch (e) {
//       print('❌ Network Error: $e');
//       return ApiResult.failure('Network error: Could not connect to server');
//     } on FormatException catch (e) {
//       print('❌ Format Error: $e');
//       return ApiResult.failure('Invalid response format from server');
//     } on Exception catch (e) {
//       print('❌ Unexpected Error: $e');
//       return ApiResult.failure('Unexpected error: $e');
//     }
//   }
// }
//
// class ApiResult {
//   final bool success;
//   final String message;
//   final int? responseId;
//
//   const ApiResult._({
//     required this.success,
//     required this.message,
//     this.responseId,
//   });
//
//   factory ApiResult.success({required String message, int? responseId}) =>
//       ApiResult._(success: true, message: message, responseId: responseId);
//
//   factory ApiResult.failure(String message) =>
//       ApiResult._(success: false, message: message);
// }
//
// // ─────────────────────────────────────────────
// //  MAIN PAGE WIDGET
// // ─────────────────────────────────────────────
//
// class SubmitCampaignContentPage extends StatelessWidget {
//   const SubmitCampaignContentPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Serene Commerce',
//       debugShowCheckedModeBanner: false,
//       theme: _buildTheme(),
//       home: const _CampaignContentForm(),
//     );
//   }
//
//   ThemeData _buildTheme() {
//     return ThemeData(
//       colorScheme: const ColorScheme.light(
//         primary: Color(0xFF7C5CFF),
//         secondary: Color(0xFF516161),
//         tertiary: Color(0xFF595A5B),
//         error: Color(0xFFBA1A1A),
//         surface: Color(0xFFFCF9F8),
//         surfaceBright: Color(0xFFFCF9F8),
//         surfaceDim: Color(0xFFDCD9D9),
//         surfaceContainer: Color(0xFFF0EDED),
//         surfaceContainerHigh: Color(0xFFEAE7E7),
//         surfaceContainerHighest: Color(0xFFE5E2E1),
//         surfaceContainerLow: Color(0xFFF6F3F2),
//         surfaceContainerLowest: Color(0xFFFFFFFF),
//         onSurface: Color(0xFF1C1B1B),
//         onSurfaceVariant: Color(0xFF3E4949),
//         outline: Color(0xFF6E7979),
//         outlineVariant: Color(0xFFBDC9C8),
//         primaryContainer: Color(0xFF7C5CFF),
//         onPrimaryContainer: Color(0xFFFFFFFF),
//         secondaryContainer: Color(0xFFD4E6E5),
//         onSecondaryContainer: Color(0xFF576867),
//         tertiaryContainer: Color(0xFF717373),
//         onTertiaryContainer: Color(0xFFF9F9F9),
//       ),
//       fontFamily: 'Inter',
//       textTheme: const TextTheme(
//         displayLarge: TextStyle(
//             fontSize: 40,
//             fontWeight: FontWeight.w700,
//             letterSpacing: -0.02,
//             height: 1.2),
//         titleLarge: TextStyle(
//             fontSize: 32,
//             fontWeight: FontWeight.w600,
//             letterSpacing: -0.01,
//             height: 1.3),
//         titleMedium: TextStyle(
//             fontSize: 24, fontWeight: FontWeight.w600, height: 1.4),
//         bodyLarge:
//         TextStyle(fontSize: 18, fontWeight: FontWeight.w400, height: 1.6),
//         bodyMedium:
//         TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.6),
//         bodySmall:
//         TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5),
//         labelLarge: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w500,
//             letterSpacing: 0.01,
//             height: 1),
//         labelSmall: TextStyle(
//             fontSize: 12,
//             fontWeight: FontWeight.w600,
//             letterSpacing: 0.05,
//             height: 1),
//       ),
//       scaffoldBackgroundColor: const Color(0xFFFCF9F8),
//       appBarTheme: const AppBarTheme(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         centerTitle: false,
//         titleTextStyle: TextStyle(
//             fontSize: 24,
//             fontWeight: FontWeight.w600,
//             color: Color(0xFF7C5CFF)),
//         iconTheme: IconThemeData(color: Color(0xFF7C5CFF)),
//       ),
//       inputDecorationTheme: InputDecorationTheme(
//         filled: true,
//         fillColor: const Color(0xFFF6F3F2),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide.none,
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide.none,
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: Color(0xFF7C5CFF), width: 2),
//         ),
//         errorBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide:
//           const BorderSide(color: Color(0xFFBA1A1A), width: 1.5),
//         ),
//         focusedErrorBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide:
//           const BorderSide(color: Color(0xFFBA1A1A), width: 2),
//         ),
//         contentPadding:
//         const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
//       ),
//       elevatedButtonTheme: ElevatedButtonThemeData(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: const Color(0xFF7C5CFF),
//           foregroundColor: Colors.white,
//           shape:
//           RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           padding:
//           const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//           textStyle: const TextStyle(
//               fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.01),
//         ),
//       ),
//       outlinedButtonTheme: OutlinedButtonThemeData(
//         style: OutlinedButton.styleFrom(
//           foregroundColor: const Color(0xFF7C5CFF),
//           side: const BorderSide(color: Color(0xFF7C5CFF)),
//           shape:
//           RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           padding:
//           const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//           textStyle: const TextStyle(
//               fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.01),
//         ),
//       ),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────
// //  FORM STATE
// // ─────────────────────────────────────────────
//
// class _CampaignContentForm extends StatefulWidget {
//   const _CampaignContentForm();
//
//   @override
//   State<_CampaignContentForm> createState() => _CampaignContentFormState();
// }
//
// class _CampaignContentFormState extends State<_CampaignContentForm> {
//   final _formKey = GlobalKey<FormState>();
//
//   // Controllers for text fields
//   final _titleController = TextEditingController();
//   final _descriptionController = TextEditingController();
//   final _websiteController = TextEditingController();
//   final _instructionsController = TextEditingController();
//
//   String? _selectedProduct;
//   String? _selectedCta;
//
//   bool _isUploadHovered = false;
//   bool _isSubmitting = false;
//   bool _isTestingApi = false;
//
//   final List<String> _uploadedFiles = [];
//
//   // ── Hardcoded demo order data (replace with real data from your order screen)
//   final int _marketplaceId = 1;
//   final int _requestId = 0;
//   final int _orderId = 123;
//   final String _orderStatus = 'ACTIVE';
//   final String _orderPackage = 'Startup Promotion • 7 Posts • 3 Days';
//
//   final List<String> _products = [
//     'Home Decor Collection',
//     'Eco-Friendly Essentials',
//     'Minimalist Tech Gear',
//   ];
//
//   final List<String> _ctaOptions = [
//     'Apply Now',
//     'Shop Now',
//     'Learn More',
//     'Get Started',
//   ];
//
//   // API Test Results
//   String _apiTestResult = '';
//   Color _apiTestColor = Colors.grey;
//
//   @override
//   void dispose() {
//     _titleController.dispose();
//     _descriptionController.dispose();
//     _websiteController.dispose();
//     _instructionsController.dispose();
//     super.dispose();
//   }
//
//   // ─── Helpers ───────────────────────────────
//
//   void _showSnack(String msg, {bool error = false}) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(msg),
//         backgroundColor: error ? const Color(0xFFBA1A1A) : null,
//         behavior: SnackBarBehavior.floating,
//         duration: const Duration(seconds: 5),
//       ),
//     );
//   }
//
//   bool get _isFormValid =>
//       _titleController.text.trim().isNotEmpty &&
//           _descriptionController.text.trim().isNotEmpty &&
//           _selectedProduct != null &&
//           _selectedCta != null;
//
//   // ─── Actions ───────────────────────────────
//
//   void _addContent() {
//     setState(() {
//       _uploadedFiles.add('content_${_uploadedFiles.length + 1}.jpg');
//     });
//     _showSnack('File added (demo). Integrate image_picker for real uploads.');
//   }
//
//   void _saveDraft() {
//     _showSnack('Draft saved successfully!');
//   }
//
//   // ─── API Test Function ──────────────────────
//
//   Future<void> _testApiConnection() async {
//     setState(() {
//       _isTestingApi = true;
//       _apiTestResult = 'Testing API connection...';
//       _apiTestColor = Colors.orange;
//     });
//
//     try {
//       final result = await CampaignApiService.submitCampaign(
//         marketplaceId: _marketplaceId,
//         requestId: _requestId,
//         orderId: _orderId,
//         description: 'Test description from Flutter app',
//         location: 'Test location',
//         budget: 100,
//         availability: 'Immediate',
//         minQty: 1,
//         maxQty: 10,
//         status: 1,
//         comment: 'Test comment',
//         attachments: ['test_file.jpg'],
//       );
//
//       if (!mounted) return;
//
//       setState(() {
//         _isTestingApi = false;
//         if (result.success) {
//           _apiTestResult = '✅ SUCCESS: ${result.message}\nResponse ID: ${result.responseId ?? 'N/A'}';
//           _apiTestColor = Colors.green;
//           _showSnack('✅ API Connection Successful!');
//         } else {
//           _apiTestResult = '❌ FAILED: ${result.message}';
//           _apiTestColor = Colors.red;
//           _showSnack('❌ API Error: ${result.message}', error: true);
//         }
//       });
//     } catch (e) {
//       if (!mounted) return;
//       setState(() {
//         _isTestingApi = false;
//         _apiTestResult = '❌ ERROR: $e';
//         _apiTestColor = Colors.red;
//       });
//       _showSnack('❌ Connection Failed: $e', error: true);
//     }
//   }
//
//   Future<void> _submitForReview() async {
//     // 1. Validate form
//     if (!(_formKey.currentState?.validate() ?? false)) return;
//     if (_selectedProduct == null || _selectedCta == null) {
//       _showSnack('Please select a product and call-to-action.', error: true);
//       return;
//     }
//
//     setState(() => _isSubmitting = true);
//
//     // 2. Call API
//     final result = await CampaignApiService.submitCampaign(
//       marketplaceId: _marketplaceId,
//       requestId: _requestId,
//       orderId: _orderId,
//       description: _descriptionController.text.trim(),
//       location: '', // extend form if you need this field
//       budget: 0, // extend form if you need this field
//       availability: '', // extend form if you need this field
//       minQty: 0, // extend form if you need this field
//       maxQty: 0, // extend form if you need this field
//       status: 1,
//       comment: _instructionsController.text.trim(),
//       attachments: List<String>.from(_uploadedFiles),
//     );
//
//     if (!mounted) return;
//     setState(() => _isSubmitting = false);
//
//     if (result.success) {
//       _showSnack(
//           '${result.message} (ID: ${result.responseId ?? '–'})');
//       // Optionally pop or navigate after successful submit:
//       // Navigator.of(context).pop();
//     } else {
//       _showSnack(result.message, error: true);
//     }
//   }
//
//   // ─────────────────────────────────────────────
//   //  BUILD
//   // ─────────────────────────────────────────────
//
//   @override
//   Widget build(BuildContext context) {
//     final cs = Theme.of(context).colorScheme;
//
//     return Scaffold(
//       body: Form(
//         key: _formKey,
//         child: Stack(
//           children: [
//             CustomScrollView(
//               slivers: [
//                 // ── App Bar ──
//                 SliverAppBar(
//                   pinned: true,
//                   elevation: 0,
//                   backgroundColor: cs.surface.withOpacity(0.9),
//                   foregroundColor: cs.primary,
//                   leading: IconButton(
//                     icon: const Icon(Icons.arrow_back),
//                     onPressed: () => Navigator.of(context).maybePop(),
//                   ),
//                   title: const Text(
//                     'Submit Campaign Content',
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
//                   ),
//                   actions: [
//                     IconButton(
//                       icon: const Icon(Icons.more_vert),
//                       onPressed: () {},
//                     ),
//                   ],
//                 ),
//
//                 // ── Body ──
//                 SliverPadding(
//                   padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
//                   sliver: SliverList(
//                     delegate: SliverChildListDelegate([
//                       const SizedBox(height: 8),
//                       _OrderInfoCard(
//                         orderId: 'ORD$_orderId',
//                         status: _orderStatus,
//                         package: _orderPackage,
//                       ),
//                       const SizedBox(height: 24),
//                     //  _buildApiTestCard(cs), // API Test Card
//                     //  const SizedBox(height: 24),
//                       _buildCampaignDetailsCard(cs),
//                       const SizedBox(height: 24),
//                       _buildUploadContentCard(cs),
//                       const SizedBox(height: 24),
//                       _buildCtaLinksCard(cs),
//                       const SizedBox(height: 24),
//                       _buildInstructionsCard(cs),
//                       const SizedBox(height: 24),
//                       _buildPreviewSection(cs),
//                       // Space for the bottom bar
//                       const SizedBox(height: 90),
//                     ]),
//                   ),
//                 ),
//               ],
//             ),
//
//             // ── Sticky Bottom Bar ──
//             Positioned(
//               bottom: 0,
//               left: 0,
//               right: 0,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                     horizontal: 16, vertical: 16),
//                 decoration: BoxDecoration(
//                   color: cs.surface.withOpacity(0.95),
//                   border:
//                   Border(top: BorderSide(color: cs.surfaceContainerHigh)),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.05),
//                       offset: const Offset(0, -4),
//                       blurRadius: 20,
//                     ),
//                   ],
//                 ),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: OutlinedButton(
//                         onPressed: _isSubmitting ? null : _saveDraft,
//                         style: OutlinedButton.styleFrom(
//                           padding:
//                           const EdgeInsets.symmetric(vertical: 14),
//                           shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12)),
//                         ),
//                         child: const Text('Save Draft'),
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       flex: 2,
//                       child: ElevatedButton(
//                         onPressed: _isSubmitting ? null : _submitForReview,
//                         style: ElevatedButton.styleFrom(
//                           padding:
//                           const EdgeInsets.symmetric(vertical: 14),
//                           backgroundColor: cs.primaryContainer,
//                           foregroundColor: cs.onPrimaryContainer,
//                           elevation: 4,
//                           shadowColor:
//                           cs.primaryContainer.withOpacity(0.2),
//                           shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12)),
//                         ),
//                         child: _isSubmitting
//                             ? const SizedBox(
//                           height: 20,
//                           width: 20,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             color: Colors.white,
//                           ),
//                         )
//                             : const Text('Submit for Review'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ─────────────────────────────────────────────
//   //  SECTION BUILDERS
//   // ─────────────────────────────────────────────
//
//
//   Widget _buildCampaignDetailsCard(ColorScheme cs) {
//     return _SectionCard(
//       label: 'CAMPAIGN DETAILS',
//       colorScheme: cs,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _FieldLabel('Campaign Title', cs),
//           const SizedBox(height: 4),
//           TextFormField(
//             controller: _titleController,
//             decoration:
//             const InputDecoration(hintText: 'Enter campaign title'),
//             validator: (v) =>
//             (v == null || v.trim().isEmpty) ? 'Title is required' : null,
//             textInputAction: TextInputAction.next,
//           ),
//           const SizedBox(height: 16),
//           _FieldLabel('Description', cs),
//           const SizedBox(height: 4),
//           TextFormField(
//             controller: _descriptionController,
//             maxLines: 4,
//             decoration: const InputDecoration(
//               hintText: 'Describe your campaign goals and style',
//               alignLabelWithHint: true,
//             ),
//             validator: (v) => (v == null || v.trim().isEmpty)
//                 ? 'Description is required'
//                 : null,
//             textInputAction: TextInputAction.next,
//           ),
//           const SizedBox(height: 16),
//           _FieldLabel('Product', cs),
//           const SizedBox(height: 4),
//           DropdownButtonFormField<String>(
//             value: _selectedProduct,
//             decoration:
//             const InputDecoration(suffixIcon: Icon(Icons.expand_more)),
//             hint: const Text('Select Product'),
//             items: _products
//                 .map((p) => DropdownMenuItem(value: p, child: Text(p)))
//                 .toList(),
//             validator: (v) =>
//             v == null ? 'Please select a product' : null,
//             onChanged: (v) => setState(() => _selectedProduct = v),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildUploadContentCard(ColorScheme cs) {
//     return _SectionCard(
//       label: 'UPLOAD CONTENT',
//       colorScheme: cs,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           MouseRegion(
//             onEnter: (_) => setState(() => _isUploadHovered = true),
//             onExit: (_) => setState(() => _isUploadHovered = false),
//             child: GestureDetector(
//               onTap: _addContent,
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 200),
//                 height: 160,
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                   border: Border.all(
//                     color: _isUploadHovered
//                         ? cs.primaryContainer
//                         : cs.outlineVariant,
//                     width: 2,
//                   ),
//                   borderRadius: BorderRadius.circular(12),
//                   color: _isUploadHovered
//                       ? cs.secondaryContainer.withOpacity(0.15)
//                       : cs.surfaceContainerLow,
//                 ),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Container(
//                       width: 48,
//                       height: 48,
//                       decoration: BoxDecoration(
//                         color: cs.primaryContainer.withOpacity(0.12),
//                         shape: BoxShape.circle,
//                       ),
//                       child: Icon(Icons.add_a_photo,
//                           color: cs.primaryContainer, size: 26),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       '+ Add Content',
//                       style: Theme.of(context).textTheme.labelLarge?.copyWith(
//                         color: cs.primaryContainer,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'MP4, JPG or PNG up to 50 MB',
//                       style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                         color: cs.outline,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           if (_uploadedFiles.isNotEmpty) ...[
//             const SizedBox(height: 16),
//             ..._uploadedFiles.map(
//                   (file) => Padding(
//                 padding: const EdgeInsets.only(bottom: 8),
//                 child: Row(
//                   children: [
//                     Icon(Icons.insert_drive_file,
//                         size: 20, color: cs.primary),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Text(file,
//                           style: Theme.of(context).textTheme.bodySmall),
//                     ),
//                     IconButton(
//                       icon: Icon(Icons.close,
//                           size: 18, color: cs.onSurfaceVariant),
//                       tooltip: 'Remove file',
//                       onPressed: () =>
//                           setState(() => _uploadedFiles.remove(file)),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
//
//   Widget _buildCtaLinksCard(ColorScheme cs) {
//     return _SectionCard(
//       label: 'CTA & LINKS',
//       colorScheme: cs,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _FieldLabel('Call to Action', cs),
//           const SizedBox(height: 4),
//           DropdownButtonFormField<String>(
//             value: _selectedCta,
//             decoration:
//             const InputDecoration(suffixIcon: Icon(Icons.expand_more)),
//             hint: const Text('Select CTA'),
//             items: _ctaOptions
//                 .map((c) => DropdownMenuItem(value: c, child: Text(c)))
//                 .toList(),
//             validator: (v) =>
//             v == null ? 'Please select a call to action' : null,
//             onChanged: (v) => setState(() => _selectedCta = v),
//           ),
//           const SizedBox(height: 16),
//           _FieldLabel('Website / Landing Page', cs),
//           const SizedBox(height: 4),
//           TextFormField(
//             controller: _websiteController,
//             keyboardType: TextInputType.url,
//             decoration: InputDecoration(
//               prefixIcon: Icon(Icons.link, color: cs.outline),
//               hintText: 'https://yourwebsite.com',
//             ),
//             validator: (v) {
//               if (v == null || v.trim().isEmpty) return null; // optional
//               final uri = Uri.tryParse(v.trim());
//               if (uri == null || !uri.hasScheme) {
//                 return 'Enter a valid URL starting with https://';
//               }
//               return null;
//             },
//             textInputAction: TextInputAction.next,
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildInstructionsCard(ColorScheme cs) {
//     return _SectionCard(
//       label: 'INSTRUCTIONS FOR ADMIN',
//       colorScheme: cs,
//       child: TextFormField(
//         controller: _instructionsController,
//         maxLines: 3,
//         decoration: const InputDecoration(
//           hintText: 'Any specific request or instruction for our team...',
//           alignLabelWithHint: true,
//         ),
//         textInputAction: TextInputAction.done,
//       ),
//     );
//   }
//
//   Widget _buildPreviewSection(ColorScheme cs) {
//     return _SectionCard(
//       label: 'LIVE PREVIEW',
//       colorScheme: cs,
//       color: cs.surfaceContainerLow,
//       child: Center(
//         child: Container(
//           width: 280,
//           decoration: BoxDecoration(
//             color: cs.surfaceContainerLowest,
//             borderRadius: BorderRadius.circular(16),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.10),
//                 blurRadius: 10,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//             border: Border.all(color: cs.surfaceContainerHighest),
//           ),
//           child: Column(
//             children: [
//               // Preview image placeholder
//               Stack(
//                 children: [
//                   ClipRRect(
//                     borderRadius: const BorderRadius.vertical(
//                         top: Radius.circular(16)),
//                     child: Image.network(
//                       'https://lh3.googleusercontent.com/aida-public/AB6AXuAuK7_8kFEWcHK0Q4IIwZZkDf3R0Ra1fZhsK83kXM5jcJVp7PYVBmFEAi6cWIHLzMXy6a7-IHPkejwEAJT4lT3u6NYFfyuoysa8to3NMVMmmj0cHD1pfJdy3UhLSJyv7vamWsY-4WVfGB6TSuL2AOTW5BIuUhdiyQk4o1bSS3yy6GWh6OtRK0ncisFA8xvjjzKXOF3a2e_pc5VzsTFIOVWp0zimA76HLCsIlhL35Cs0D02xF6zAGsLy',
//                       height: 200,
//                       width: double.infinity,
//                       fit: BoxFit.cover,
//                       errorBuilder: (_, __, ___) => Container(
//                         height: 200,
//                         color: cs.surfaceContainerHigh,
//                         child: Icon(Icons.image,
//                             size: 48, color: cs.outlineVariant),
//                       ),
//                     ),
//                   ),
//                   Positioned.fill(
//                     child: Center(
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 12, vertical: 6),
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.90),
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: const Text(
//                           'PREVIEW IMAGE',
//                           style: TextStyle(
//                               fontSize: 10, fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//
//               // Preview content skeleton + CTA
//               Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   children: [
//                     // Title placeholder
//                     Text(
//                       _titleController.text.isNotEmpty
//                           ? _titleController.text
//                           : 'Campaign Title',
//                       style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                         fontWeight: FontWeight.w600,
//                         color: cs.onSurface,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 6),
//                     // Desc placeholder lines
//                     Container(
//                       height: 10,
//                       width: double.infinity,
//                       decoration: BoxDecoration(
//                         color: cs.secondaryContainer.withOpacity(0.3),
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Container(
//                       height: 10,
//                       width: 160,
//                       decoration: BoxDecoration(
//                         color: cs.secondaryContainer.withOpacity(0.3),
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     // CTA button preview
//                     ElevatedButton.icon(
//                       onPressed: null,
//                       icon: const Icon(Icons.open_in_new, size: 16),
//                       label: Text(_selectedCta ?? 'Apply Now'),
//                       style: ElevatedButton.styleFrom(
//                         minimumSize: const Size(double.infinity, 40),
//                         backgroundColor: cs.primaryContainer,
//                         foregroundColor: cs.onPrimaryContainer,
//                         disabledBackgroundColor: cs.primaryContainer,
//                         disabledForegroundColor: cs.onPrimaryContainer,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────
// //  REUSABLE WIDGETS
// // ─────────────────────────────────────────────
//
// class _SectionCard extends StatelessWidget {
//   final String label;
//   final Widget child;
//   final ColorScheme colorScheme;
//   final Color? color;
//
//   const _SectionCard({
//     required this.label,
//     required this.child,
//     required this.colorScheme,
//     this.color,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 0,
//       shape:
//       RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       color: color ?? colorScheme.surfaceContainerLowest,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               label,
//               style: Theme.of(context).textTheme.labelSmall?.copyWith(
//                 color: colorScheme.secondary,
//                 letterSpacing: 0.05,
//               ),
//             ),
//             const SizedBox(height: 16),
//             child,
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class _OrderInfoCard extends StatelessWidget {
//   final String orderId;
//   final String status;
//   final String package;
//
//   const _OrderInfoCard({
//     required this.orderId,
//     required this.status,
//     required this.package,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final cs = Theme.of(context).colorScheme;
//
//     return Card(
//       elevation: 0,
//       shape:
//       RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       color: cs.surfaceContainerLowest,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'ORDER INFO',
//               style: Theme.of(context).textTheme.labelSmall?.copyWith(
//                 color: cs.secondary,
//                 letterSpacing: 0.05,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 RichText(
//                   text: TextSpan(
//                     text: 'Order ID: ',
//                     style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                       color: cs.onSurface,
//                       fontWeight: FontWeight.w600,
//                     ),
//                     children: [
//                       TextSpan(
//                         text: orderId,
//                         style: TextStyle(color: cs.primary),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 8, vertical: 3),
//                   decoration: BoxDecoration(
//                     color: cs.secondaryContainer,
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     status,
//                     style: const TextStyle(
//                       fontSize: 10,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF576867),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 4),
//             Text(
//               'Package: $package',
//               style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                 color: cs.onSurfaceVariant,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class _FieldLabel extends StatelessWidget {
//   final String text;
//   final ColorScheme cs;
//
//   const _FieldLabel(this.text, this.cs);
//
//   @override
//   Widget build(BuildContext context) {
//     return Text(
//       text,
//       style: Theme.of(context).textTheme.bodySmall?.copyWith(
//         fontWeight: FontWeight.w600,
//         color: cs.onSurfaceVariant,
//       ),
//     );
//   }
// }