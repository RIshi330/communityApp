// import 'dart:io';
//
// import 'package:commity_app1/services/auth_service.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:image_picker/image_picker.dart';
//
// import '../Database/Database.dart';
// import 'commity_Manage.dart';
// import 'invite_member_screen.dart' as invite_screen;
//
// class CreateCommunityScreen extends StatefulWidget {
//   final bool openCommunityHomeOnCreate;
//
//   const CreateCommunityScreen({
//     super.key,
//     this.openCommunityHomeOnCreate = false,
//   });
//
//   @override
//   State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
// }
//
// class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
//   // Form Controllers
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _descriptionController = TextEditingController();
//   final TextEditingController _geographyController = TextEditingController();
//
//   // Images
//   File? _logoImage;
//   File? _bannerImage;
//   final ImagePicker _picker = ImagePicker();
//
//   // Community Info
//   String _joiningRule = 'Free to Join';
//   String _communityMode = 'Online';
//
//   // Tags
//   List<String> _communityTags = ['Technology', 'Startup'];
//   List<String> _demographyTags = [];
//   List<String> _professionalTags = [];
//
//   // Geography
//   String _geographyType = 'Global';
//
//   // Loading state
//   bool _isCreating = false;
//
//   // Options
//   final List<String> _joiningRules = [
//     'Free to Join',
//     'Join Post Approval',
//     'Pay to Join',
//   ];
//
//   final List<String> _communityModes = ['Online', 'Onsite', 'Hybrid'];
//
//   final List<String> _geographyOptions = [
//     'Pin Code',
//     'City',
//     'State',
//     'Country',
//     'Global',
//   ];
//
//   final List<String> _demographyOptions = [
//     'Men',
//     'Women',
//     'Kids',
//     'Senior Citizens',
//     'Others',
//   ];
//
//   String _extractCommunityId(Map response) {
//     String pick(dynamic v) {
//       if (v == null) return '';
//       final s = v.toString().trim();
//       if (s.isEmpty || s.toLowerCase() == 'null' || s == '0') return '';
//       return s;
//     }
//
//     final topLevelKeys = [
//       'community_id',
//       'id',
//       'group_id',
//       'communityId',
//       'insert_id',
//     ];
//     for (final key in topLevelKeys) {
//       final val = pick(response[key]);
//       if (val.isNotEmpty) return val;
//     }
//
//     final data = response['data'];
//     if (data is Map) {
//       for (final key in topLevelKeys) {
//         final val = pick(data[key]);
//         if (val.isNotEmpty) return val;
//       }
//     } else if (data is List && data.isNotEmpty && data.first is Map) {
//       final first = data.first as Map;
//       for (final key in topLevelKeys) {
//         final val = pick(first[key]);
//         if (val.isNotEmpty) return val;
//       }
//     }
//
//     return '';
//   }
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     _descriptionController.dispose();
//     _geographyController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _pickImage(bool isLogo) async {
//     try {
//       final XFile? image = await _picker.pickImage(
//         source: ImageSource.gallery,
//         imageQuality: 80,
//       );
//
//       if (image != null) {
//         setState(() {
//           if (isLogo) {
//             _logoImage = File(image.path);
//           } else {
//             _bannerImage = File(image.path);
//           }
//         });
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error picking image: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
//
//   void _addTag(List<String> tagList, String tag) {
//     if (tag.isNotEmpty && !tagList.contains(tag)) {
//       setState(() {
//         tagList.add(tag);
//       });
//     }
//   }
//
//   void _removeTag(List<String> tagList, String tag) {
//     setState(() {
//       tagList.remove(tag);
//     });
//   }
//
//   void _showAddTagDialog(List<String> tagList, String title) {
//     final controller = TextEditingController();
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Add $title'),
//         content: TextField(
//           controller: controller,
//           decoration: const InputDecoration(
//             hintText: 'Enter tag name',
//             border: OutlineInputBorder(),
//           ),
//           autofocus: true,
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               _addTag(tagList, controller.text.trim());
//               Navigator.pop(context);
//             },
//             child: const Text('Add'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   /// Check if the API response indicates success
//   bool _isSuccessResponse(Map response) {
//     // Check various success indicators
//     if (response['success'] == true) return true;
//     if (response['status'] == 200) return true;
//     if (response['status'] == 'success') return true;
//     // If we got data back and no explicit error, treat as success
//     if (response.containsKey('data') &&
//         response['status'] != 300 &&
//         response['error'] == null)
//       return true;
//     // If we got a community_id or insert_id back, it was created
//     if (response['community_id'] != null ||
//         response['insert_id'] != null ||
//         response['id'] != null)
//       return true;
//     return false;
//   }
//
//   Future<void> _createCommunity() async {
//     if (_nameController.text.trim().isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please enter a community name'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }
//
//     if (_descriptionController.text.trim().isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please enter a community description'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }
//
//     setState(() => _isCreating = true);
//
//     try {
//       final database = Database();
//
//       final vendorId = await AuthService.getVendorIdString();
//
//       // Prepare request body for create_community API
//       final requestBody = {
//         'action': 'create_community',
//         'community_title': _nameController.text.trim(),
//         'description': _descriptionController.text.trim(),
//         'community_type': 'community',
//         'visibility': 'public',
//         'joining_rule': _joiningRule.toLowerCase().replaceAll(' ', '_'),
//         'joining_fee': _joiningRule == 'Pay to Join' ? '499' : '0',
//         'logo': _logoImage?.path ?? '',
//         'cover_image': _bannerImage?.path ?? '',
//         'tags': _communityTags.join(','),
//         'vendor_id': vendorId,
//       };
//
//       // Call create_community API
//       final response = await database.getData(requestBody);
//
//       if (!mounted) return;
//
//       if (_isSuccessResponse(response)) {
//         // Community created successfully
//         final communityId = _extractCommunityId(response);
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Community created successfully! 🎉'),
//             backgroundColor: Colors.green,
//             duration: Duration(seconds: 2),
//           ),
//         );
//
//         if (widget.openCommunityHomeOnCreate) {
//           // Replace current screen to return 'true' to GroupsScreen while showing AdminView
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder: (_) => CommunityPrivateAdminView(
//                 groupName: _nameController.text.trim(),
//                 privacy: 'Public',
//               ),
//             ),
//             result: true,
//           );
//         } else {
//           // Replace current screen to return 'true' to GroupsScreen while showing Invite screen
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder: (_) => invite_screen.InviteMembersScreen(
//                 groupName: _nameController.text.trim(),
//                 privacy: 'Public',
//                 communityId: communityId,
//               ),
//             ),
//             result: true,
//           );
//         }
//       } else {
//         // Handle API error
//         final errorMessage =
//             response['message']?.toString() ??
//             response['error']?.toString() ??
//             'Failed to create community';
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
//         );
//
//         print("❌ Create Community Error: $errorMessage");
//         print("❌ Full response: $response");
//       }
//     } catch (e) {
//       if (!mounted) return;
//
//       // Handle network or other errors
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Network error: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//
//       print("❌ Create Community Exception: $e");
//     } finally {
//       if (mounted) {
//         setState(() => _isCreating = false);
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.close, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           'Create Community',
//           style: TextStyle(
//             color: Colors.black,
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         centerTitle: true,
//         bottom: const PreferredSize(
//           preferredSize: Size.fromHeight(1),
//           child: Divider(height: 1, color: Color(0xFFE5E7EB)),
//         ),
//       ),
//       body: _isCreating
//           ? const Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   CircularProgressIndicator(
//                     strokeWidth: 2,
//                     valueColor: AlwaysStoppedAnimation<Color>(
//                       Color(0xFF8F7CFF),
//                     ),
//                   ),
//                   SizedBox(height: 16),
//                   Text(
//                     'Creating Community...',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                       color: Colors.black87,
//                     ),
//                   ),
//                 ],
//               ),
//             )
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Community Info Section
//                   _buildSectionHeader('Community Info'),
//                   const SizedBox(height: 16),
//
//                   _buildTextField(
//                     controller: _nameController,
//                     label: 'Community Name',
//                     hintText: 'Enter your community name',
//                   ),
//                   const SizedBox(height: 16),
//
//                   _buildMultilineTextField(
//                     controller: _descriptionController,
//                     label: 'Description',
//                     hintText: 'Describe your community...',
//                     maxLines: 4,
//                   ),
//                   const SizedBox(height: 20),
//
//                   // Logo & Banner Upload
//                   _buildImageUploadSection(),
//                   const SizedBox(height: 24),
//
//                   // Joining Rule Section
//                   _buildSectionHeader('Joining Rule'),
//                   const SizedBox(height: 16),
//                   _buildRadioGroup(
//                     options: _joiningRules,
//                     selected: _joiningRule,
//                     onChanged: (value) => setState(() => _joiningRule = value!),
//                   ),
//                   const SizedBox(height: 24),
//
//                   // Community Mode Section
//                   _buildSectionHeader('Community Mode'),
//                   const SizedBox(height: 16),
//                   _buildRadioGroup(
//                     options: _communityModes,
//                     selected: _communityMode,
//                     onChanged: (value) =>
//                         setState(() => _communityMode = value!),
//                   ),
//                   const SizedBox(height: 24),
//
//                   // Tags Section
//                   _buildSectionHeader('Tags'),
//                   const SizedBox(height: 16),
//                   _buildTagsSection(
//                     tags: _communityTags,
//                     title: 'Community Tags',
//                     onAdd: () =>
//                         _showAddTagDialog(_communityTags, 'Community Tag'),
//                   ),
//                   const SizedBox(height: 24),
//
//                   // Members Info Section
//                   _buildSectionHeader('Members Info'),
//                   const SizedBox(height: 16),
//
//                   // Demography Tags
//                   _buildSubSectionHeader('Demography'),
//                   const SizedBox(height: 12),
//                   _buildChipSelector(
//                     options: _demographyOptions,
//                     selectedTags: _demographyTags,
//                     title: 'Demography',
//                   ),
//                   const SizedBox(height: 20),
//
//                   // Geography
//                   _buildSubSectionHeader('Geography'),
//                   const SizedBox(height: 12),
//                   _buildGeographySection(),
//                   const SizedBox(height: 20),
//
//                   // Professional Tags
//                   _buildSubSectionHeader('Professional'),
//                   const SizedBox(height: 12),
//                   _buildTagsSection(
//                     tags: _professionalTags,
//                     title: 'Professional Tags',
//                     onAdd: () => _showAddTagDialog(
//                       _professionalTags,
//                       'Professional Tag',
//                     ),
//                   ),
//                   const SizedBox(height: 32),
//
//                   // Create Button
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: _createCommunity,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF8F7CFF),
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         elevation: 0,
//                       ),
//                       child: const Text(
//                         'Create Community',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 32),
//                 ],
//               ),
//             ),
//     );
//   }
//
//   Widget _buildSectionHeader(String title) {
//     return Text(
//       title,
//       style: const TextStyle(
//         fontSize: 20,
//         fontWeight: FontWeight.bold,
//         color: Colors.black,
//       ),
//     );
//   }
//
//   Widget _buildSubSectionHeader(String title) {
//     return Text(
//       title,
//       style: const TextStyle(
//         fontSize: 16,
//         fontWeight: FontWeight.w600,
//         color: Colors.black87,
//       ),
//     );
//   }
//
//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required String hintText,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//             color: Colors.black87,
//           ),
//         ),
//         const SizedBox(height: 8),
//         TextField(
//           controller: controller,
//           style: const TextStyle(fontSize: 16),
//           decoration: InputDecoration(
//             hintText: hintText,
//             hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
//             filled: true,
//             fillColor: Colors.grey.shade50,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: const BorderSide(color: Color(0xFF8F7CFF), width: 2),
//             ),
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 12,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildMultilineTextField({
//     required TextEditingController controller,
//     required String label,
//     required String hintText,
//     int maxLines = 3,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//             color: Colors.black87,
//           ),
//         ),
//         const SizedBox(height: 8),
//         TextField(
//           controller: controller,
//           maxLines: maxLines,
//           style: const TextStyle(fontSize: 16),
//           decoration: InputDecoration(
//             hintText: hintText,
//             hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
//             filled: true,
//             fillColor: Colors.grey.shade50,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: const BorderSide(color: Color(0xFF8F7CFF), width: 2),
//             ),
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 12,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildImageUploadSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Logo & Banner',
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w600,
//             color: Colors.black87,
//           ),
//         ),
//         const SizedBox(height: 16),
//         Row(
//           children: [
//             // Logo Upload
//             Expanded(
//               child: _buildImageUploadCard(
//                 title: 'Community Logo',
//                 image: _logoImage,
//                 onTap: () => _pickImage(true),
//                 width: 80,
//                 height: 80,
//               ),
//             ),
//             const SizedBox(width: 16),
//             // Banner Upload
//             Expanded(
//               child: _buildImageUploadCard(
//                 title: 'Community Banner',
//                 image: _bannerImage,
//                 onTap: () => _pickImage(false),
//                 width: double.infinity,
//                 height: 120,
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   Widget _buildImageUploadCard({
//     required String title,
//     required File? image,
//     required VoidCallback onTap,
//     required double width,
//     required double height,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: width,
//         height: height,
//         decoration: BoxDecoration(
//           color: Colors.grey.shade100,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: Colors.grey.shade300),
//         ),
//         child: image != null
//             ? ClipRRect(
//                 borderRadius: BorderRadius.circular(12),
//                 child: Image.file(
//                   image!,
//                   width: width,
//                   height: height,
//                   fit: BoxFit.cover,
//                 ),
//               )
//             : Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.cloud_upload_outlined,
//                     size: 32,
//                     color: Colors.grey.shade600,
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     title,
//                     style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
//                     textAlign: TextAlign.center,
//                   ),
//                 ],
//               ),
//       ),
//     );
//   }
//
//   Widget _buildRadioGroup({
//     required List<String> options,
//     required String selected,
//     required Function(String?) onChanged,
//   }) {
//     return Column(
//       children: options.map((option) {
//         return RadioListTile<String>(
//           title: Text(
//             option,
//             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//           ),
//           value: option,
//           groupValue: selected,
//           onChanged: onChanged,
//           activeColor: const Color(0xFF8F7CFF),
//           contentPadding: EdgeInsets.zero,
//         );
//       }).toList(),
//     );
//   }
//
//   Widget _buildTagsSection({
//     required List<String> tags,
//     required String title,
//     required VoidCallback onAdd,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.black87,
//               ),
//             ),
//             TextButton.icon(
//               onPressed: onAdd,
//               icon: const Icon(Icons.add, size: 16),
//               label: const Text('Add Tag', style: TextStyle(fontSize: 12)),
//               style: TextButton.styleFrom(
//                 foregroundColor: const Color(0xFF8F7CFF),
//                 padding: EdgeInsets.zero,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 12),
//         Wrap(
//           spacing: 8,
//           runSpacing: 8,
//           children: tags
//               .map((tag) => _buildChip(tag, () => _removeTag(tags, tag)))
//               .toList(),
//         ),
//         if (tags.isEmpty)
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.grey.shade50,
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Text(
//               'No tags added. Click "Add Tag" to add tags.',
//               style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
//             ),
//           ),
//       ],
//     );
//   }
//
//   Widget _buildChip(String label, VoidCallback onDelete) {
//     return Chip(
//       label: Text(label),
//       deleteIcon: const Icon(Icons.close, size: 16),
//       onDeleted: onDelete,
//       backgroundColor: const Color(0xFFE8E5FF),
//       deleteIconColor: const Color(0xFF8F7CFF),
//       labelStyle: const TextStyle(
//         color: Color(0xFF8F7CFF),
//         fontWeight: FontWeight.w500,
//       ),
//     );
//   }
//
//   Widget _buildChipSelector({
//     required List<String> options,
//     required List<String> selectedTags,
//     required String title,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           title,
//           style: const TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//             color: Colors.black87,
//           ),
//         ),
//         const SizedBox(height: 12),
//         Wrap(
//           spacing: 8,
//           runSpacing: 8,
//           children: options.map((option) {
//             final isSelected = selectedTags.contains(option);
//             return FilterChip(
//               label: Text(option),
//               selected: isSelected,
//               onSelected: (selected) {
//                 setState(() {
//                   if (selected) {
//                     selectedTags.add(option);
//                   } else {
//                     selectedTags.remove(option);
//                   }
//                 });
//               },
//               backgroundColor: Colors.grey.shade100,
//               selectedColor: const Color(0xFFE8E5FF),
//               checkmarkColor: const Color(0xFF8F7CFF),
//               labelStyle: TextStyle(
//                 color: isSelected ? const Color(0xFF8F7CFF) : Colors.black87,
//                 fontWeight: FontWeight.w500,
//               ),
//             );
//           }).toList(),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildGeographySection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Geography Type Selector
//         DropdownButtonFormField<String>(
//           value: _geographyType,
//           decoration: InputDecoration(
//             labelText: 'Geography Type',
//             border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: const BorderSide(color: Color(0xFF8F7CFF), width: 2),
//             ),
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 12,
//             ),
//           ),
//           items: _geographyOptions.map((option) {
//             return DropdownMenuItem<String>(value: option, child: Text(option));
//           }).toList(),
//           onChanged: (value) {
//             setState(() {
//               _geographyType = value!;
//               _geographyController.clear();
//             });
//           },
//         ),
//
//         if (_geographyType != 'Global') ...[
//           const SizedBox(height: 16),
//           TextField(
//             controller: _geographyController,
//             style: const TextStyle(fontSize: 16),
//             decoration: InputDecoration(
//               hintText: 'Enter ${_geographyType.toLowerCase()}',
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: const BorderSide(
//                   color: Color(0xFF8F7CFF),
//                   width: 2,
//                 ),
//               ),
//               contentPadding: const EdgeInsets.symmetric(
//                 horizontal: 16,
//                 vertical: 12,
//               ),
//             ),
//           ),
//         ],
//       ],
//     );
//   }
// }
//
// // Invite Members Screen with Skip Option
// class InviteMembersScreen extends StatefulWidget {
//   final String communityName;
//   final String joiningRule;
//   final String communityId;
//
//   const InviteMembersScreen({
//     super.key,
//     required this.communityName,
//     required this.joiningRule,
//     required this.communityId,
//   });
//
//   @override
//   State<InviteMembersScreen> createState() => _InviteMembersScreenState();
// }
//
// class _InviteMembersScreenState extends State<InviteMembersScreen> {
//   bool _isLoading = false;
//   bool _isGeneratingLink = false;
//   final Database _database = Database();
//
//   Future<void> _generateInviteLink({int validityDays = 10}) async {
//     if (widget.communityId.isEmpty) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Community ID missing. Please recreate community.'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }
//
//     setState(() => _isGeneratingLink = true);
//     try {
//       final response = await _database.getData({
//         'action': 'share_invite_link',
//         'community_id': widget.communityId,
//         'validity_days': validityDays.toString(),
//       });
//
//       if (!mounted) return;
//
//       final success = response['success'] == true || response['status'] == 200;
//       if (!success) {
//         final msg =
//             response['message']?.toString() ?? 'Failed to generate invite link';
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(msg), backgroundColor: Colors.red),
//         );
//         return;
//       }
//
//       final data = (response['data'] is Map)
//           ? response['data'] as Map
//           : <String, dynamic>{};
//       final inviteLink = (data['invite_link'] ?? response['invite_link'] ?? '')
//           .toString();
//
//       if (inviteLink.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Invite link not returned by server'),
//             backgroundColor: Colors.red,
//           ),
//         );
//         return;
//       }
//
//       await showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text('Invite Link Generated'),
//           content: SelectableText(inviteLink),
//           actions: [
//             TextButton(
//               onPressed: () async {
//                 await Clipboard.setData(ClipboardData(text: inviteLink));
//                 if (context.mounted) {
//                   Navigator.pop(context);
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Invite link copied')),
//                   );
//                 }
//               },
//               child: const Text('Copy Link'),
//             ),
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Close'),
//             ),
//           ],
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error generating invite: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       if (mounted) {
//         setState(() => _isGeneratingLink = false);
//       }
//     }
//   }
//
//   Future<void> _skipInvitation() async {
//     setState(() => _isLoading = true);
//
//     // Simulate navigation delay
//     await Future.delayed(const Duration(seconds: 1));
//
//     if (mounted) {
//       // Navigate to Community Groups screen
//       Navigator.pushReplacementNamed(context, '/community_groups');
//     }
//
//     setState(() => _isLoading = false);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.close, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           'Invite Members',
//           style: TextStyle(
//             color: Colors.black,
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         centerTitle: true,
//         actions: [
//           TextButton(
//             onPressed: _isLoading ? null : _skipInvitation,
//             child: _isLoading
//                 ? const SizedBox(
//                     width: 16,
//                     height: 16,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       valueColor: AlwaysStoppedAnimation<Color>(
//                         Color(0xFF8F7CFF),
//                       ),
//                     ),
//                   )
//                 : const Text(
//                     'Skip',
//                     style: TextStyle(
//                       color: Color(0xFF8F7CFF),
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//           ),
//         ],
//         bottom: const PreferredSize(
//           preferredSize: Size.fromHeight(1),
//           child: Divider(height: 1, color: Color(0xFFE5E7EB)),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             // Community Info Card
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: const Color(0xFFE8E5FF),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     widget.communityName,
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Joining Rule: ${widget.joiningRule}',
//                     style: const TextStyle(fontSize: 14, color: Colors.black87),
//                   ),
//                 ],
//               ),
//             ),
//
//             const SizedBox(height: 24),
//
//             // Invite Options
//             const Text(
//               'Invite members to your community',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.black,
//               ),
//             ),
//
//             const SizedBox(height: 16),
//
//             // Invite Options List
//             _inviteOption(
//               icon: Icons.link,
//               title: 'Invite with Link',
//               subtitle: 'Share invitation link with others',
//               onTap: () {
//                 _generateInviteLink();
//               },
//             ),
//
//             _inviteOption(
//               icon: Icons.email_outlined,
//               title: 'Invite via Email',
//               subtitle: 'Send email invitations',
//               onTap: () {
//                 _generateInviteLink();
//               },
//             ),
//
//             _inviteOption(
//               icon: Icons.contacts_outlined,
//               title: 'Invite from Contacts',
//               subtitle: 'Select from your contacts',
//               onTap: () {
//                 _generateInviteLink();
//               },
//             ),
//
//             if (_isGeneratingLink)
//               const Padding(
//                 padding: EdgeInsets.only(top: 8),
//                 child: LinearProgressIndicator(minHeight: 2),
//               ),
//
//             const Spacer(),
//
//             // Skip Button
//             SizedBox(
//               width: double.infinity,
//               child: OutlinedButton(
//                 onPressed: _isLoading ? null : _skipInvitation,
//                 style: OutlinedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   side: const BorderSide(color: Color(0xFF8F7CFF)),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: _isLoading
//                     ? const SizedBox(
//                         width: 16,
//                         height: 16,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           valueColor: AlwaysStoppedAnimation<Color>(
//                             Color(0xFF8F7CFF),
//                           ),
//                         ),
//                       )
//                     : const Text(
//                         'Skip for Now',
//                         style: TextStyle(
//                           color: Color(0xFF8F7CFF),
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _inviteOption({
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required VoidCallback onTap,
//   }) {
//     return ListTile(
//       contentPadding: EdgeInsets.zero,
//       leading: CircleAvatar(
//         backgroundColor: const Color(0xFFE8E5FF),
//         child: Icon(icon, color: const Color(0xFF8F7CFF)),
//       ),
//       title: Text(
//         title,
//         style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
//       ),
//       subtitle: Text(
//         subtitle,
//         style: const TextStyle(color: Colors.grey, fontSize: 14),
//       ),
//       onTap: onTap,
//     );
//   }
// }
import 'dart:io';

import 'package:commity_app1/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../Database/Database.dart';
import 'commity_Manage.dart';
import 'invite_member_screen.dart' as invite_screen;

// ─────────────────────────────────────────────────────────────────────────
// Design tokens
// ─────────────────────────────────────────────────────────────────────────
class _Tokens {
  static const Color primary = Color(0xFF7C5CFF);
  static const Color primaryDark = Color(0xFF6A47F2);
  static const Color primarySoft = Color(0xFFF1ECFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color bg = Color(0xFFF7F7FB);
  static const Color border = Color(0xFFE8E8F0);
  static const Color textPrimary = Color(0xFF15141F);
  static const Color textSecondary = Color(0xFF6F6E81);
  static const Color textMuted = Color(0xFF9D9CAE);
  static const Color danger = Color(0xFFEF4444);
  static const Color success = Color(0xFF12B76A);

  static const double radiusLg = 18;
  static const double radiusMd = 14;
  static const double radiusSm = 10;
}

class CreateCommunityScreen extends StatefulWidget {
  final bool openCommunityHomeOnCreate;

  const CreateCommunityScreen({
    super.key,
    this.openCommunityHomeOnCreate = false,
  });

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  // Form Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _geographyController = TextEditingController();

  // Images
  File? _logoImage;
  File? _bannerImage;
  final ImagePicker _picker = ImagePicker();

  // Community Info
  String _joiningRule = 'Free to Join';
  String _communityMode = 'Online';

  // Tags
  List<String> _communityTags = ['Technology', 'Startup'];
  List<String> _demographyTags = [];
  List<String> _professionalTags = [];

  // Geography
  String _geographyType = 'Global';

  // Loading state
  bool _isCreating = false;

  // Options
  final List<String> _joiningRules = [
    'Free to Join',
    'Join Post Approval',
    'Pay to Join',
  ];

  final List<String> _communityModes = ['Online', 'Onsite', 'Hybrid'];

  final List<String> _geographyOptions = [
    'Pin Code',
    'City',
    'State',
    'Country',
    'Global',
  ];

  final List<String> _demographyOptions = [
    'Men',
    'Women',
    'Kids',
    'Senior Citizens',
    'Others',
  ];

  String _extractCommunityId(Map response) {
    String pick(dynamic v) {
      if (v == null) return '';
      final s = v.toString().trim();
      if (s.isEmpty || s.toLowerCase() == 'null' || s == '0') return '';
      return s;
    }

    final topLevelKeys = [
      'community_id',
      'id',
      'group_id',
      'communityId',
      'insert_id',
    ];
    for (final key in topLevelKeys) {
      final val = pick(response[key]);
      if (val.isNotEmpty) return val;
    }

    final data = response['data'];
    if (data is Map) {
      for (final key in topLevelKeys) {
        final val = pick(data[key]);
        if (val.isNotEmpty) return val;
      }
    } else if (data is List && data.isNotEmpty && data.first is Map) {
      final first = data.first as Map;
      for (final key in topLevelKeys) {
        final val = pick(first[key]);
        if (val.isNotEmpty) return val;
      }
    }

    return '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _geographyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isLogo) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          if (isLogo) {
            _logoImage = File(image.path);
          } else {
            _bannerImage = File(image.path);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: _Tokens.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_Tokens.radiusSm),
          ),
        ),
      );
    }
  }

  void _addTag(List<String> tagList, String tag) {
    if (tag.isNotEmpty && !tagList.contains(tag)) {
      setState(() {
        tagList.add(tag);
      });
    }
  }

  void _removeTag(List<String> tagList, String tag) {
    setState(() {
      tagList.remove(tag);
    });
  }

  void _showAddTagDialog(List<String> tagList, String title) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _Tokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_Tokens.radiusLg),
        ),
        title: Text(
          'Add $title',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: _Tokens.textPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter tag name',
            hintStyle: const TextStyle(color: _Tokens.textMuted),
            filled: true,
            fillColor: _Tokens.bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_Tokens.radiusSm),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_Tokens.radiusSm),
              borderSide: const BorderSide(color: _Tokens.primary, width: 1.5),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: _Tokens.textSecondary,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _addTag(tagList, controller.text.trim());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _Tokens.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_Tokens.radiusSm),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  /// Check if the API response indicates success
  bool _isSuccessResponse(Map response) {
    if (response['success'] == true) return true;
    if (response['status'] == 200) return true;
    if (response['status'] == 'success') return true;
    if (response.containsKey('data') &&
        response['status'] != 300 &&
        response['error'] == null)
      return true;
    if (response['community_id'] != null ||
        response['insert_id'] != null ||
        response['id'] != null)
      return true;
    return false;
  }

  Future<void> _createCommunity() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnack('Please enter a community name', isError: true);
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _showSnack('Please enter a community description', isError: true);
      return;
    }

    setState(() => _isCreating = true);

    try {
      final database = Database();

      final vendorId = await AuthService.getVendorIdString();

      final requestBody = {
        'action': 'create_community',
        'community_title': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'community_type': 'community',
        'visibility': 'public',
        'joining_rule': _joiningRule.toLowerCase().replaceAll(' ', '_'),
        'joining_fee': _joiningRule == 'Pay to Join' ? '499' : '0',
        'logo': _logoImage?.path ?? '',
        'cover_image': _bannerImage?.path ?? '',
        'tags': _communityTags.join(','),
        'vendor_id': vendorId,
      };

      final response = await database.getData(requestBody);

      if (!mounted) return;

      if (_isSuccessResponse(response)) {
        final communityId = _extractCommunityId(response);

        _showSnack('Community created successfully 🎉', isError: false);

        if (widget.openCommunityHomeOnCreate) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CommunityPrivateAdminView(
                groupName: _nameController.text.trim(),
                privacy: 'Public',
              ),
            ),
            result: true,
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => invite_screen.InviteMembersScreen(
                groupName: _nameController.text.trim(),
                privacy: 'Public',
                communityId: communityId,
              ),
            ),
            result: true,
          );
        }
      } else {
        final errorMessage =
            response['message']?.toString() ??
                response['error']?.toString() ??
                'Failed to create community';

        _showSnack(errorMessage, isError: true);

        print("❌ Create Community Error: $errorMessage");
        print("❌ Full response: $response");
      }
    } catch (e) {
      if (!mounted) return;

      _showSnack('Network error: ${e.toString()}', isError: true);

      print("❌ Create Community Exception: $e");
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? _Tokens.danger : _Tokens.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_Tokens.radiusSm),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Tokens.bg,
      appBar: AppBar(
        backgroundColor: _Tokens.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _Tokens.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _Tokens.border),
            ),
            child: const Icon(Icons.close, color: _Tokens.textPrimary, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Community',
          style: TextStyle(
            color: _Tokens.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
      ),
      body: _isCreating
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _Tokens.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(_Tokens.primary),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Creating your community…',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _Tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'This will only take a moment',
              style: TextStyle(
                fontSize: 13,
                color: _Tokens.textMuted,
              ),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Community Info Section
            _sectionCard(
              eyebrow: 'Basics',
              title: 'Community info',
              subtitle: 'Tell people what this community is about.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: 'Community name',
                    hintText: 'e.g. Bengaluru Founders Network',
                  ),
                  const SizedBox(height: 16),
                  _buildMultilineTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hintText:
                    'Share what members can expect — topics, vibe, and goals.',
                    maxLines: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Logo & Banner Upload
            _sectionCard(
              eyebrow: 'Branding',
              title: 'Logo & banner',
              subtitle: 'Add visuals so your community stands out.',
              child: _buildImageUploadSection(),
            ),
            const SizedBox(height: 16),

            // Joining Rule + Mode
            _sectionCard(
              eyebrow: 'Access',
              title: 'Joining rule',
              subtitle: 'Decide how new members can join.',
              child: _buildOptionGroup(
                options: _joiningRules,
                selected: _joiningRule,
                icons: const [
                  Icons.lock_open_rounded,
                  Icons.verified_user_outlined,
                  Icons.payments_outlined,
                ],
                onChanged: (value) => setState(() => _joiningRule = value),
              ),
            ),
            const SizedBox(height: 16),

            _sectionCard(
              eyebrow: 'Format',
              title: 'Community mode',
              subtitle: 'How will members mostly interact?',
              child: _buildOptionGroup(
                options: _communityModes,
                selected: _communityMode,
                icons: const [
                  Icons.wifi_rounded,
                  Icons.location_on_outlined,
                  Icons.hub_outlined,
                ],
                onChanged: (value) =>
                    setState(() => _communityMode = value),
              ),
            ),
            const SizedBox(height: 16),

            // Tags Section
            _sectionCard(
              eyebrow: 'Discovery',
              title: 'Tags',
              subtitle: 'Help people find your community.',
              child: _buildTagsSection(
                tags: _communityTags,
                placeholder: 'No tags yet — add a few to get discovered.',
                onAdd: () =>
                    _showAddTagDialog(_communityTags, 'Community Tag'),
              ),
            ),
            const SizedBox(height: 16),

            // Members Info Section
            _sectionCard(
              eyebrow: 'Audience',
              title: 'Members info',
              subtitle: 'Set who this community is for.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSubLabel('Demography'),
                  const SizedBox(height: 10),
                  _buildChipSelector(
                    options: _demographyOptions,
                    selectedTags: _demographyTags,
                  ),
                  const SizedBox(height: 22),
                  _buildSubLabel('Geography'),
                  const SizedBox(height: 10),
                  _buildGeographySection(),
                  const SizedBox(height: 22),
                  _buildSubLabel('Professional'),
                  const SizedBox(height: 10),
                  _buildTagsSection(
                    tags: _professionalTags,
                    placeholder:
                    'No professional tags yet — add roles or industries.',
                    onAdd: () => _showAddTagDialog(
                      _professionalTags,
                      'Professional Tag',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Create Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _createCommunity,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _Tokens.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_Tokens.radiusMd),
                  ),
                ).copyWith(
                  overlayColor: WidgetStateProperty.all(
                    _Tokens.primaryDark.withOpacity(0.1),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Create community',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'You can edit these details anytime from settings.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: _Tokens.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────
  // Layout helpers
  // ───────────────────────────────────────────────────────────────────────

  Widget _sectionCard({
    required String eyebrow,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _Tokens.surface,
        borderRadius: BorderRadius.circular(_Tokens.radiusLg),
        border: Border.all(color: _Tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _Tokens.primary,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _Tokens.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: _Tokens.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildSubLabel(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: _Tokens.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _Tokens.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 15, color: _Tokens.textPrimary),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: _Tokens.textMuted, fontSize: 14),
            filled: true,
            fillColor: _Tokens.bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_Tokens.radiusMd),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_Tokens.radiusMd),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_Tokens.radiusMd),
              borderSide: const BorderSide(color: _Tokens.primary, width: 1.5),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildMultilineTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    int maxLines = 3,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _Tokens.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 15, color: _Tokens.textPrimary),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: _Tokens.textMuted, fontSize: 14),
            filled: true,
            fillColor: _Tokens.bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_Tokens.radiusMd),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_Tokens.radiusMd),
              borderSide: const BorderSide(color: _Tokens.primary, width: 1.5),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImageUploadCard(
          title: 'Logo',
          subtitle: 'Square works best',
          icon: Icons.add_a_photo_outlined,
          image: _logoImage,
          onTap: () => _pickImage(true),
          width: 96,
          height: 96,
          shape: BoxShape.circle,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildImageUploadCard(
            title: 'Banner',
            subtitle: 'Wide image, 3:1 ratio',
            icon: Icons.image_outlined,
            image: _bannerImage,
            onTap: () => _pickImage(false),
            width: double.infinity,
            height: 96,
            shape: BoxShape.rectangle,
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required File? image,
    required VoidCallback onTap,
    required double width,
    required double height,
    required BoxShape shape,
  }) {
    final radius = shape == BoxShape.circle
        ? BorderRadius.circular(height)
        : BorderRadius.circular(_Tokens.radiusMd);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: _Tokens.bg,
              shape: shape,
              borderRadius: shape == BoxShape.circle ? null : radius,
              border: Border.all(
                color: _Tokens.border,
                style: image == null ? BorderStyle.solid : BorderStyle.none,
              ),
            ),
            child: image != null
                ? ClipRRect(
              borderRadius: radius,
              child: Image.file(
                image,
                width: width,
                height: height,
                fit: BoxFit.cover,
              ),
            )
                : Center(
              child: Icon(
                icon,
                size: 26,
                color: _Tokens.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _Tokens.textPrimary,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11.5,
              color: _Tokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  /// Modern card-style single-select group, replaces RadioListTile rows.
  Widget _buildOptionGroup({
    required List<String> options,
    required String selected,
    required List<IconData> icons,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      children: List.generate(options.length, (i) {
        final option = options[i];
        final isSelected = option == selected;
        return Padding(
          padding: EdgeInsets.only(bottom: i == options.length - 1 ? 0 : 10),
          child: InkWell(
            onTap: () => onChanged(option),
            borderRadius: BorderRadius.circular(_Tokens.radiusMd),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: isSelected ? _Tokens.primarySoft : _Tokens.bg,
                borderRadius: BorderRadius.circular(_Tokens.radiusMd),
                border: Border.all(
                  color: isSelected ? _Tokens.primary : Colors.transparent,
                  width: 1.4,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icons.length > i ? icons[i] : Icons.circle_outlined,
                    size: 19,
                    color: isSelected ? _Tokens.primary : _Tokens.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? _Tokens.textPrimary
                            : _Tokens.textSecondary,
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? _Tokens.primary : _Tokens.border,
                        width: 1.6,
                      ),
                      color: isSelected ? _Tokens.primary : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 13, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTagsSection({
    required List<String> tags,
    required String placeholder,
    required VoidCallback onAdd,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...tags.map((tag) => _buildChip(tag, () => _removeTag(tags, tag))),
            _buildAddTagButton(onAdd),
          ],
        ),
        if (tags.isEmpty) ...[
          const SizedBox(height: 10),
          Text(
            placeholder,
            style: const TextStyle(color: _Tokens.textMuted, fontSize: 12.5),
          ),
        ],
      ],
    );
  }

  Widget _buildAddTagButton(VoidCallback onAdd) {
    return InkWell(
      onTap: onAdd,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: _Tokens.bg,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: _Tokens.border, style: BorderStyle.solid),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 15, color: _Tokens.primary),
            SizedBox(width: 4),
            Text(
              'Add tag',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _Tokens.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, VoidCallback onDelete) {
    return Container(
      padding: const EdgeInsets.only(left: 14, right: 8, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: _Tokens.primarySoft,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _Tokens.primaryDark,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(50),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.close, size: 14, color: _Tokens.primaryDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipSelector({
    required List<String> options,
    required List<String> selectedTags,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selectedTags.contains(option);
        return InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedTags.remove(option);
              } else {
                selectedTags.add(option);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? _Tokens.primarySoft : _Tokens.bg,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: isSelected ? _Tokens.primary : _Tokens.border,
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(Icons.check, size: 14, color: _Tokens.primary),
                  const SizedBox(width: 5),
                ],
                Text(
                  option,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                    isSelected ? _Tokens.primaryDark : _Tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGeographySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: _Tokens.bg,
            borderRadius: BorderRadius.circular(_Tokens.radiusMd),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              value: _geographyType,
              icon: const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.expand_more_rounded,
                    color: _Tokens.textSecondary),
              ),
              dropdownColor: _Tokens.surface,
              borderRadius: BorderRadius.circular(_Tokens.radiusMd),
              style: const TextStyle(fontSize: 14.5, color: _Tokens.textPrimary),
              decoration: InputDecoration(
                labelText: 'Geography type',
                labelStyle:
                const TextStyle(color: _Tokens.textSecondary, fontSize: 13),
                filled: true,
                fillColor: _Tokens.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_Tokens.radiusMd),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_Tokens.radiusMd),
                  borderSide:
                  const BorderSide(color: _Tokens.primary, width: 1.5),
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              items: _geographyOptions.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _geographyType = value!;
                  _geographyController.clear();
                });
              },
            ),
          ),
        ),
        if (_geographyType != 'Global') ...[
          const SizedBox(height: 12),
          TextField(
            controller: _geographyController,
            style: const TextStyle(fontSize: 14.5, color: _Tokens.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter ${_geographyType.toLowerCase()}',
              hintStyle: const TextStyle(color: _Tokens.textMuted, fontSize: 14),
              filled: true,
              fillColor: _Tokens.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_Tokens.radiusMd),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_Tokens.radiusMd),
                borderSide: const BorderSide(color: _Tokens.primary, width: 1.5),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Invite Members Screen with Skip Option
// ─────────────────────────────────────────────────────────────────────────
class InviteMembersScreen extends StatefulWidget {
  final String communityName;
  final String joiningRule;
  final String communityId;

  const InviteMembersScreen({
    super.key,
    required this.communityName,
    required this.joiningRule,
    required this.communityId,
  });

  @override
  State<InviteMembersScreen> createState() => _InviteMembersScreenState();
}

class _InviteMembersScreenState extends State<InviteMembersScreen> {
  bool _isLoading = false;
  bool _isGeneratingLink = false;
  final Database _database = Database();

  Future<void> _generateInviteLink({int validityDays = 10}) async {
    if (widget.communityId.isEmpty) {
      if (!mounted) return;
      _showSnack('Community ID missing. Please recreate community.',
          isError: true);
      return;
    }

    setState(() => _isGeneratingLink = true);
    try {
      final response = await _database.getData({
        'action': 'share_invite_link',
        'community_id': widget.communityId,
        'validity_days': validityDays.toString(),
      });

      if (!mounted) return;

      final success = response['success'] == true || response['status'] == 200;
      if (!success) {
        final msg =
            response['message']?.toString() ?? 'Failed to generate invite link';
        _showSnack(msg, isError: true);
        return;
      }

      final data = (response['data'] is Map)
          ? response['data'] as Map
          : <String, dynamic>{};
      final inviteLink = (data['invite_link'] ?? response['invite_link'] ?? '')
          .toString();

      if (inviteLink.isEmpty) {
        _showSnack('Invite link not returned by server', isError: true);
        return;
      }

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: _Tokens.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_Tokens.radiusLg),
          ),
          title: const Text(
            'Invite link generated',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _Tokens.textPrimary,
              fontSize: 17,
            ),
          ),
          content: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _Tokens.bg,
              borderRadius: BorderRadius.circular(_Tokens.radiusSm),
            ),
            child: SelectableText(
              inviteLink,
              style: const TextStyle(fontSize: 13.5, color: _Tokens.textPrimary),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: _Tokens.textSecondary,
              ),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: inviteLink));
                if (context.mounted) {
                  Navigator.pop(context);
                  _showSnack('Invite link copied', isError: false);
                }
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Copy link'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _Tokens.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_Tokens.radiusSm),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error generating invite: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isGeneratingLink = false);
      }
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? _Tokens.danger : _Tokens.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_Tokens.radiusSm),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _skipInvitation() async {
    setState(() => _isLoading = true);

    // Simulate navigation delay
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/community_groups');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Tokens.bg,
      appBar: AppBar(
        backgroundColor: _Tokens.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _Tokens.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _Tokens.border),
            ),
            child: const Icon(Icons.close, color: _Tokens.textPrimary, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Invite Members',
          style: TextStyle(
            color: _Tokens.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isLoading ? null : _skipInvitation,
              style: TextButton.styleFrom(
                foregroundColor: _Tokens.primary,
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_Tokens.primary),
                ),
              )
                  : const Text(
                'Skip',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          children: [
            // Community Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_Tokens.primary, _Tokens.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(_Tokens.radiusLg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.groups_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.communityName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Joining rule: ${widget.joiningRule}',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Invite members',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _Tokens.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Grow your community by inviting people to join.',
                style: TextStyle(fontSize: 13, color: _Tokens.textSecondary),
              ),
            ),

            const SizedBox(height: 16),

            // Invite Options List
            _inviteOption(
              icon: Icons.link_rounded,
              title: 'Invite with link',
              subtitle: 'Share an invitation link with others',
              onTap: _generateInviteLink,
            ),
            const SizedBox(height: 10),
            _inviteOption(
              icon: Icons.email_outlined,
              title: 'Invite via email',
              subtitle: 'Send email invitations',
              onTap: _generateInviteLink,
            ),
            const SizedBox(height: 10),
            _inviteOption(
              icon: Icons.contacts_outlined,
              title: 'Invite from contacts',
              subtitle: 'Select from your contacts',
              onTap: _generateInviteLink,
            ),

            if (_isGeneratingLink) ...[
              const SizedBox(height: 16),
              const ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(4)),
                child: LinearProgressIndicator(
                  minHeight: 4,
                  color: _Tokens.primary,
                  backgroundColor: _Tokens.primarySoft,
                ),
              ),
            ],

            const Spacer(),

            // Skip Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _skipInvitation,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _Tokens.border, width: 1.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_Tokens.radiusMd),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(_Tokens.primary),
                  ),
                )
                    : const Text(
                  'Skip for now',
                  style: TextStyle(
                    color: _Tokens.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inviteOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _Tokens.surface,
      borderRadius: BorderRadius.circular(_Tokens.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_Tokens.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_Tokens.radiusMd),
            border: Border.all(color: _Tokens.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _Tokens.primarySoft,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: _Tokens.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: _Tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _Tokens.textMuted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: _Tokens.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}