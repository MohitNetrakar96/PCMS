import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../auth/screens/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 32,
                      backgroundColor: AppPalette.primaryContainer,
                      foregroundColor: AppPalette.onPrimaryContainer,
                      child: Text('RA', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rahul Ahire', style: AppTextStyles.titleMedium),
                        const SizedBox(height: 4),
                        Text('Employee ID: PCM-2847', style: AppTextStyles.caption.copyWith(color: AppPalette.textSecondary)),
                        Text('Branch: Mumbai Central', style: AppTextStyles.caption.copyWith(color: AppPalette.textSecondary)),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatPill('Collected', '14', 'Today'),
                    _buildStatPill('Amount', '₹87,200', 'Today'),
                    _buildStatPill('Rate', '98%', 'Success'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: SectionHeader(title: 'Settings'),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            children: [
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildListTile(
                      context: context,
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Manage alerts',
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildListTile(
                      context: context,
                      icon: Icons.language_outlined,
                      title: 'Language',
                      subtitle: 'English',
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildListTile(
                      context: context,
                      icon: Icons.pin_outlined,
                      title: 'Change PIN',
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildListTile(
                      context: context,
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Support',
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildListTile(
                      context: context,
                      icon: Icons.info_outline_rounded,
                      title: 'About PCMS',
                      subtitle: 'v1.0.0',
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.logout_rounded, color: AppPalette.error),
                      title: const Text('Logout', style: TextStyle(color: AppPalette.error, fontWeight: FontWeight.w500)),
                      onTap: () {
                        _showLogoutDialog(context);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatPill(String title, String value, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppPalette.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.titleSmall.copyWith(color: AppPalette.onPrimaryContainer)),
          Text('$subtitle $title', style: AppTextStyles.caption.copyWith(color: AppPalette.onPrimaryContainer, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppPalette.textSecondary),
      title: Text(title, style: AppTextStyles.bodyMedium),
      subtitle: subtitle != null ? Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppPalette.textSecondary)) : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: AppPalette.outlineVariant),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coming soon')),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Logout', style: TextStyle(color: AppPalette.error)),
          ),
        ],
      ),
    );
  }
}
