import 'package:easy_localization/easy_localization.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/good_category.dart';
import '../../providers/navigation_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'location_picker_screen.dart';

class AddGoodScreen extends StatefulWidget {
  const AddGoodScreen({super.key});

  @override
  State<AddGoodScreen> createState() => _AddGoodScreenState();
}

class _AddGoodScreenState extends State<AddGoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  // Controllers
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _messageController = TextEditingController();
  final _priceController = TextEditingController(text: '0');

  // State
  List<GoodCategory> _categories = [];
  GoodCategory? _selectedCategory;
  DateTime? _selectedExpiry;
  Uint8List? _selectedImageBytes;
  String _selectedImageName = '';
  bool _isLoadingCategories = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _messageController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _apiService.fetchCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          _isLoadingCategories = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primaryGreen),
              title: Text('choose_from_gallery').tr(),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.primaryGreen),
              title: Text('take_a_photo').tr(),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    final file = await _picker.pickImage(source: source, imageQuality: 75, maxWidth: 1024);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _selectedImageBytes = bytes;
      _selectedImageName = file.name;
    });
  }

  Future<void> _pickLocation() async {
    final address = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );
    if (address != null && mounted) {
      setState(() => _locationController.text = address);
    }
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primaryGreen),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedExpiry = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showSnack('Please select a category.', isError: true);
      return;
    }
    if (_selectedExpiry == null) {
      _showSnack('Please pick an expiry date.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    final int currentUserId = context.read<AuthProvider>().currentUserId ?? 0;

    final (error, goodId) = await _apiService.createGood(
      userId: currentUserId,
      categoryId: _selectedCategory!.id,
      goodName: _nameController.text.trim(),
      datetimeExpiry: _selectedExpiry!,
      pickLocation: _locationController.text.trim(),
      messageForPicker: _messageController.text.trim(),
      goodPrice: double.tryParse(_priceController.text) ?? 0.0,
    );

    if (!mounted) return;

    if (error != null) {
      setState(() => _isSubmitting = false);
      _showSnack(error, isError: true);
      return;
    }

    // Upload image if one was selected
    if (_selectedImageBytes != null && goodId != null) {
      await _apiService.uploadGoodPicture(
        goodId: goodId,
        imageBytes: _selectedImageBytes!,
        filename: _selectedImageName,
      );
    }

    setState(() => _isSubmitting = false);

    _showSnack('good_published_successfully'.tr());

    // Reset form
    _formKey.currentState!.reset();
    setState(() {
      _selectedCategory = null;
      _selectedExpiry = null;
      _selectedImageBytes = null;
      _selectedImageName = '';
      _priceController.text = '0';
      _locationController.clear();
      _messageController.clear();
    });

    // Navigate to My Good List tab (index 3)
    if (mounted) {
      context.read<NavigationProvider>().goToTab(3);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : AppTheme.primaryGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  String _formatDate(DateTime dt) {
    return DateFormat('dd MMMM yyyy', context.locale.toString()).format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('share_a_good').tr(),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: _isLoadingCategories
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Good Picture ───────────────────────────────────
                      _buildLabel('good_picture'.tr()),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.primaryGreen.withValues(alpha: 0.4),
                              width: 2,
                            ),
                            image: _selectedImageBytes != null
                                ? DecorationImage(
                                    image: MemoryImage(_selectedImageBytes!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _selectedImageBytes == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate_outlined,
                                        size: 52,
                                        color: AppTheme.primaryGreen.withValues(alpha: 0.6)),
                                    const SizedBox(height: 8),
                                    Text(
                                      'tap_to_add_photo'.tr(),
                                      style: TextStyle(
                                          color: Colors.grey.shade500, fontSize: 13),
                                    ),
                                  ],
                                )
                              : Align(
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        _selectedImageBytes = null;
                                        _selectedImageName = '';
                                      }),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close,
                                            color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Good Name ──────────────────────────────────────
                      _buildLabel('good_name_req'.tr()),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: _dec(
                          hint: 'hint_good_name'.tr(),
                          icon: Icons.inventory_2_outlined,
                        ),
                        validator: (v) => v!.trim().isEmpty ? 'name_is_required'.tr() : null,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),

                      // ── Category ───────────────────────────────────────
                      _buildLabel('category_req'.tr()),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<GoodCategory>(
                        value: _selectedCategory,
                        decoration: _dec(
                          hint: 'select_a_category'.tr(),
                          icon: Icons.category_outlined,
                        ),
                        items: _categories
                            .map((cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat.name),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedCategory = val),
                        validator: (v) => v == null ? 'please_select_a_category'.tr() : null,
                      ),
                      const SizedBox(height: 16),

                      // ── Expiry Date ────────────────────────────────────
                      _buildLabel('good_expiry_date_req'.tr()),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickExpiryDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  color: _selectedExpiry != null
                                      ? AppTheme.primaryGreen
                                      : Colors.grey.shade500),
                              const SizedBox(width: 12),
                              Text(
                                _selectedExpiry != null
                                    ? _formatDate(_selectedExpiry!)
                                    : 'select_expiry_date'.tr(),
                                style: TextStyle(
                                  fontSize: 15,
                                  color: _selectedExpiry != null
                                      ? AppTheme.textPrimary
                                      : Colors.grey.shade500,
                                ),
                              ),
                              const Spacer(),
                              Icon(Icons.chevron_right,
                                  color: Colors.grey.shade400),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Location ───────────────────────────────────────
                      _buildLabel('pickup_location_req'.tr()),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _locationController,
                              readOnly: false,
                              maxLines: 2,
                              minLines: 1,
                              decoration: _dec(
                                hint: 'hint_pickup_location'.tr(),
                                icon: Icons.location_on_outlined,
                              ),
                              validator: (v) =>
                                  v!.trim().isEmpty ? 'location_is_required'.tr() : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: _pickLocation,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.map_outlined,
                                  color: Colors.white, size: 22),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Message for Picker ─────────────────────────────
                      _buildLabel('message_for_picker'.tr()),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _messageController,
                        maxLines: 3,
                        decoration: _dec(
                          hint: 'hint_message_picker'.tr(),
                          icon: Icons.chat_bubble_outline,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Price ──────────────────────────────────────────
                      _buildLabel('price_free'.tr()),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _dec(
                          hint: '0',
                          icon: Icons.attach_money_outlined,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          if (double.tryParse(v) == null) return 'enter_valid_number'.tr();
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // ── Publish Button ─────────────────────────────────
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.volunteer_activism,
                                        color: Colors.white),
                                    SizedBox(width: 10),
                                    Text(
                                      'publish_good'.tr(),
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
        letterSpacing: 0.4,
      ),
    );
  }

  InputDecoration _dec({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Icon(icon, color: AppTheme.primaryGreen, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}
