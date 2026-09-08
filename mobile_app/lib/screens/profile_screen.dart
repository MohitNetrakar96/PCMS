import 'login_screen.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/banker_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _apiUrlController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  static final List<Map<String, String>> presetAvatars = [
    {
      'name': 'Senior Banker',
      'url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop',
    },
    {
      'name': 'Branch Agent',
      'url': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&auto=format&fit=crop',
    },
    {
      'name': 'Chief Cashier',
      'url': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&auto=format&fit=crop',
    },
    {
      'name': 'Executive Lead',
      'url': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=200&auto=format&fit=crop',
    },
    {
      'name': 'Officer Maya',
      'url': 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=200&auto=format&fit=crop',
    },
    {
      'name': 'Agent Dev',
      'url': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&auto=format&fit=crop',
    },
    {
      'name': 'Regional Head',
      'url': 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=200&auto=format&fit=crop',
    },
    {
      'name': 'Vault Officer',
      'url': 'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=200&auto=format&fit=crop',
    },
  ];

  @override
  void initState() {
    super.initState();
    _apiUrlController.text = ApiService.baseUrl;
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveApiUrl() async {
    setState(() => _isSaving = true);
    final url = _apiUrlController.text.trim();
    if (url.isNotEmpty) {
      ApiService.setBaseUrl(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('API Gateway successfully routed to: ' + url),
            backgroundColor: const Color(0xFF76A787),
          ),
        );
      }
    }
    setState(() => _isSaving = false);
  }

  Future<void> _pickImage(ImageSource source, StateSetter setModalState, TextEditingController photoCtrl, Function(String) onImagePicked) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 80,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        final base64String = 'data:image/jpeg;base64,' + base64Encode(bytes);
        setModalState(() {
          photoCtrl.text = base64String;
          onImagePicked(base64String);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: ' + e.toString());
    }
  }

  void _showEditProfileModal(BuildContext context, AuthProvider auth) {
    final nameCtrl = TextEditingController(text: auth.name);
    final phoneCtrl = TextEditingController(text: auth.phone ?? '');
    final areaCtrl = TextEditingController(text: auth.area ?? '');
    final routeCtrl = TextEditingController(text: auth.route ?? '');
    final addressCtrl = TextEditingController(text: auth.address ?? '');
    final photoCtrl = TextEditingController(text: auth.photoUrl ?? '');

    String selectedPhoto = auth.photoUrl ?? '';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9E2F3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE9E2F3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.badge, color: Color(0xFF55356E), size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Edit Agent Profile & Photo',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF191308),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Selected Avatar Preview
                  Center(
                    child: Column(
                      children: [
                        BankerAvatar(
                          photoUrl: selectedPhoto,
                          name: nameCtrl.text.isNotEmpty ? nameCtrl.text : auth.name,
                          radius: 44,
                          showBadge: true,
                          badgeIcon: Icons.camera_alt,
                          onTap: () => _pickImage(ImageSource.gallery, setModalState, photoCtrl, (val) => selectedPhoto = val),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tap avatar to choose from device files',
                          style: TextStyle(fontSize: 11, color: Color(0xFF55356E), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pick Image From Device Files or Camera
                  const Text(
                    'UPLOAD PHOTO FROM DEVICE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF55356E),
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery, setModalState, photoCtrl, (val) => selectedPhoto = val),
                          icon: const Icon(Icons.folder_open, size: 18, color: Color(0xFF55356E)),
                          label: const Text('Choose from Files', style: TextStyle(color: Color(0xFF55356E), fontWeight: FontWeight.bold, fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF55356E), width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera, setModalState, photoCtrl, (val) => selectedPhoto = val),
                          icon: const Icon(Icons.photo_camera, size: 18, color: Color(0xFF76A787)),
                          label: const Text('Take Photo', style: TextStyle(color: Color(0xFF191308), fontWeight: FontWeight.bold, fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF76A787), width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Preset Avatars Row
                  const Text(
                    'OR CHOOSE BANKER AVATAR PRESET',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF55356E),
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 78,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: presetAvatars.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final avatar = presetAvatars[index];
                        final isSelected = selectedPhoto == avatar['url'];
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedPhoto = avatar['url']!;
                              photoCtrl.text = avatar['url']!;
                            });
                          },
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2.5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF55356E) : const Color(0xFFE9E2F3),
                                    width: isSelected ? 3 : 1.5,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundImage: NetworkImage(avatar['url']!),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                avatar['name']!,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? const Color(0xFF55356E) : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Custom Photo URL
                  TextField(
                    controller: photoCtrl,
                    style: const TextStyle(fontSize: 12),
                    onChanged: (val) {
                      setModalState(() {
                        selectedPhoto = val.trim();
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Or Paste Custom Image URL / Data Link',
                      labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF55356E)),
                      prefixIcon: const Icon(Icons.link, size: 18, color: Color(0xFF55356E)),
                      filled: true,
                      fillColor: const Color(0xFFF7F4FA),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE9E2F3)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Full Name
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Agent Full Name',
                      prefixIcon: const Icon(Icons.person, color: Color(0xFF55356E), size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF7F4FA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Phone
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Mobile Phone Number',
                      prefixIcon: const Icon(Icons.phone, color: Color(0xFF55356E), size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF7F4FA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Route & Area
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: routeCtrl,
                          decoration: InputDecoration(
                            labelText: 'Assigned Route',
                            hintText: 'e.g. Route-14',
                            prefixIcon: const Icon(Icons.alt_route, color: Color(0xFF55356E), size: 18),
                            filled: true,
                            fillColor: const Color(0xFFF7F4FA),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: areaCtrl,
                          decoration: InputDecoration(
                            labelText: 'Territory / Area',
                            hintText: 'e.g. South Bazaar',
                            prefixIcon: const Icon(Icons.location_city, color: Color(0xFF55356E), size: 18),
                            filled: true,
                            fillColor: const Color(0xFFF7F4FA),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Address
                  TextField(
                    controller: addressCtrl,
                    decoration: InputDecoration(
                      labelText: 'Branch / Office Address',
                      prefixIcon: const Icon(Icons.home_work, color: Color(0xFF55356E), size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF7F4FA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setModalState(() => isSubmitting = true);
                              final success = await auth.updateProfile(
                                name: nameCtrl.text.trim(),
                                phone: phoneCtrl.text.trim(),
                                photoUrl: selectedPhoto.isNotEmpty ? selectedPhoto : null,
                                route: routeCtrl.text.trim(),
                                area: areaCtrl.text.trim(),
                                address: addressCtrl.text.trim(),
                              );
                              setModalState(() => isSubmitting = false);

                              if (context.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Profile and Photo updated successfully!'
                                          : (auth.errorMessage ?? 'Failed to update profile.'),
                                    ),
                                    backgroundColor: success ? const Color(0xFF76A787) : Colors.red,
                                  ),
                                );
                              }
                            },
                      icon: isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_as, color: Color(0xFFD6F5FF)),
                      label: Text(
                        isSubmitting ? 'Saving Profile...' : 'Save Banker Profile & Photo',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF55356E),
                        foregroundColor: const Color(0xFFD6F5FF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Profile Medallion Header
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF55356E),
                Color(0xFF381F4C),
                Color(0xFF191308),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF55356E).withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: const Color(0xFFD6F5FF).withOpacity(0.3), width: 1.2),
          ),
          child: Column(
            children: [
              BankerAvatar(
                photoUrl: auth.photoUrl,
                name: auth.name,
                radius: 46,
                showBadge: true,
                badgeIcon: Icons.camera_alt,
                onTap: () => _showEditProfileModal(context, auth),
              ),
              const SizedBox(height: 14),
              Text(
                auth.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                auth.email,
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFFD6F5FF).withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF76A787).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF76A787), width: 1),
                    ),
                    child: Text(
                      'SOVEREIGN ROLE: ' + auth.role.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFFD6F5FF),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showEditProfileModal(context, auth),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit Dossier & Profile Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD6F5FF).withOpacity(0.18),
                  foregroundColor: const Color(0xFFD6F5FF),
                  side: const BorderSide(color: Color(0xFFD6F5FF), width: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Agent Dossier & Credentials Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE9E2F3), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9E2F3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.badge, color: Color(0xFF55356E), size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Banker Dossier & Credentials',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF191308)),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_note, color: Color(0xFF55356E), size: 22),
                    onPressed: () => _showEditProfileModal(context, auth),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDossierRow(Icons.pin, 'Employee ID', auth.employeeId ?? 'CAG-301'),
              const Divider(height: 16, color: Color(0xFFE9E2F3)),
              _buildDossierRow(Icons.phone, 'Mobile Contact', auth.phone?.isNotEmpty == true ? auth.phone! : '+91 98765 43210 (Default)'),
              const Divider(height: 16, color: Color(0xFFE9E2F3)),
              _buildDossierRow(Icons.alt_route, 'Assigned Route', auth.route?.isNotEmpty == true ? auth.route! : 'Route-12 (Central Commercial)'),
              const Divider(height: 16, color: Color(0xFFE9E2F3)),
              _buildDossierRow(Icons.location_city, 'Operational Area', auth.area?.isNotEmpty == true ? auth.area! : 'Sector 4 Market Corridor'),
              const Divider(height: 16, color: Color(0xFFE9E2F3)),
              _buildDossierRow(Icons.home_work, 'Field Office', auth.address?.isNotEmpty == true ? auth.address! : 'Main Branch, Pigmy Chamber #4'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // About BankFlow & Pigmy Heritage Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE9E2F3), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9E2F3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance, color: Color(0xFF55356E), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'About BankFlow & Pigmy Heritage',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF191308)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Rooted in the timeless tradition of Pigmy Daily Micro-Thrift Banking (established 1924), BankFlow combines century-old cooperative trust with quantum-grade 256-bit encryption. We empower local merchants, artisans, and families to accumulate wealth one doorstep deposit at a time.',
                style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF191308)),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildParchmentBadge(Icons.lock, '100% VAULT BACKED'),
                  _buildParchmentBadge(Icons.trending_up, 'DAILY 5.5% YIELD'),
                  _buildParchmentBadge(Icons.verified_user, 'RBI COMPLIANT'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Help Desk & Sovereign Concierge
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE9E2F3), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9E2F3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.support_agent, color: Color(0xFF55356E), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Help Desk & Sovereign Concierge',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF191308)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildHelpRow(
                icon: Icons.phone_in_talk,
                title: 'Direct Branch Concierge Helpline',
                subtitle: 'Priority telephone line to Chief Vault Officer: 1800-BANK-FLOW',
              ),
              const Divider(height: 20, color: Color(0xFFE9E2F3)),
              _buildHelpRow(
                icon: Icons.assignment_turned_in,
                title: 'Dispute & Ledger Resolution',
                subtitle: '24-hour SLA reconciliation guarantee for doorstep deposits',
              ),
              const Divider(height: 20, color: Color(0xFFE9E2F3)),
              _buildHelpRow(
                icon: Icons.fingerprint,
                title: 'Passbook Verification & KYC',
                subtitle: 'Biometric re-authentication at any accredited branch',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Core Banking API Gateway Diagnostics
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE9E2F3), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Core Banking API Gateway',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF191308)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _apiUrlController,
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF7F4FA),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE9E2F3)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveApiUrl,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF55356E),
                    foregroundColor: const Color(0xFFD6F5FF),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Update & Test Gateway Ping', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        OutlinedButton.icon(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF191308))),
                  ],
                ),
                content: const Text(
                  'Are you sure you want to end your banking session and log out?',
                  style: TextStyle(color: Color(0xFF55356E), fontSize: 13),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );

            if (confirm == true && context.mounted) {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            }
          },
          icon: const Icon(Icons.logout, color: Colors.red),
          label: const Text('Sign Out of Banking Session', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.redAccent),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'BankFlow PCMS Sovereign Edition v2.5 • ISO 27001 Certified',
            style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildDossierRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF55356E)),
        const SizedBox(width: 10),
        Text(
          label + ': ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF191308).withOpacity(0.7),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF191308),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParchmentBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE9E2F3).withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF55356E).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF55356E)),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF55356E))),
        ],
      ),
    );
  }

  Widget _buildHelpRow({required IconData icon, required String title, required String subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF55356E)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF191308))),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: const Color(0xFF191308).withOpacity(0.7), fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}
