import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color white = Color(0xFFFFFFFF);
  static const Color creamGold = Color(0xFFFAD793);
  static const Color burntOrange = Color(0xFFBE5633);
  static const Color darkBrown = Color(0xFF46291D);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: burntOrange,
        foregroundColor: white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              color: burntOrange.withOpacity(0.05),
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: burntOrange.withOpacity(0.2),
                    child: Text(
                      user?.initials ?? 'U',
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: burntOrange),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'User',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkBrown),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: burntOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user?.role.toUpperCase() ?? 'RESIDENT',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: burntOrange),
                    ),
                  ),
                ],
              ),
            ),
            // Profile Info
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkBrown),
                  ),
                  const SizedBox(height: 16),
                  _infoTile(Icons.email, 'Email', user?.email ?? 'Not set'),
                  _infoTile(Icons.phone, 'Phone', user?.phone ?? 'Not set'),
                  _infoTile(Icons.home, 'Address', user?.address ?? 'Not set'),
                  const Divider(height: 32, color: darkBrown),
                  Text(
                    'Account Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkBrown),
                  ),
                  const SizedBox(height: 16),
                  _actionTile(Icons.help_outline, 'Help & Support', () {
                    _showHelpSupportDialog(context);
                  }),
                  _actionTile(Icons.info_outline, 'About', () {
                    _showAboutDialog(context);
                  }),
                  const Divider(height: 32, color: darkBrown),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text('Logout', style: TextStyle(color: darkBrown)),
                            content: Text('Are you sure you want to logout?', style: TextStyle(color: darkBrown)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                style: TextButton.styleFrom(foregroundColor: darkBrown),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: TextButton.styleFrom(foregroundColor: burntOrange),
                                child: const Text('Logout'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          await auth.logout();
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(context, '/');
                          }
                        }
                      },
                      icon: Icon(Icons.logout, color: burntOrange),
                      label: Text('Logout', style: TextStyle(color: burntOrange)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: burntOrange),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: burntOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: burntOrange),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: darkBrown.withOpacity(0.6))),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 14, color: darkBrown)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: burntOrange),
      title: Text(title, style: TextStyle(color: darkBrown)),
      trailing: Icon(Icons.chevron_right, color: darkBrown.withOpacity(0.5)),
      onTap: onTap,
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Column(
          children: [
            // BSR Logo Image
            Image.asset(
              'assets/images/BSR_Logo_1.png',
              height: 60,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: burntOrange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance,
                    size: 48,
                    color: burntOrange,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 4),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: darkBrown.withOpacity(0.6),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(color: darkBrown),
            const SizedBox(height: 12),
            Text(
              'A service request system for barangay residents to submit and track requests efficiently.',
              style: TextStyle(
                fontSize: 13,
                color: darkBrown,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // License Information
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: burntOrange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: burntOrange.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.code, size: 16, color: burntOrange),
                      const SizedBox(width: 8),
                      Text(
                        'License',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: darkBrown,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'MIT License',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: burntOrange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Copyright © 2026 Barangay Service System',
                    style: TextStyle(
                      fontSize: 11,
                      color: darkBrown.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files to use, copy, modify, merge, publish, and distribute copies of the Software.',
                    style: TextStyle(
                      fontSize: 11,
                      color: darkBrown.withOpacity(0.6),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The software is provided "as is", without warranty of any kind.',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: darkBrown.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Developer Credits
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: burntOrange),
                      const SizedBox(width: 8),
                      Text(
                        'Developers',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: darkBrown,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildDeveloperChip('Bernabe, K.S.'),
                      _buildDeveloperChip('Castillo, J.A.F.'),
                      _buildDeveloperChip('Cauilan, C.A.T.'),
                      _buildDeveloperChip('Espinocilla, E.S.Jr.'),
                      _buildDeveloperChip('Gacrama, A.I.M.'),
                      _buildDeveloperChip('Liquete, J.P.R.'),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: burntOrange,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: burntOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 10,
          color: burntOrange,
        ),
      ),
    );
  }

  void _showHelpSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.help_outline, color: burntOrange),
            const SizedBox(width: 8),
            Text('Help & Support', style: TextStyle(color: darkBrown)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How can we help you?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkBrown),
            ),
            const SizedBox(height: 16),
            _helpOption(
              context,
              icon: Icons.contact_support,
              title: 'Contact Barangay Hall',
              subtitle: 'Visit or call us during office hours',
              onTap: () {
                Navigator.pop(ctx);
                _showContactInfoDialog(context);
              },
            ),
            const Divider(color: darkBrown),
            _helpOption(
              context,
              icon: Icons.question_answer,
              title: 'FAQs',
              subtitle: 'Frequently asked questions',
              onTap: () {
                Navigator.pop(ctx);
                _showFaqDialog(context);
              },
            ),
            const Divider(color: darkBrown),
            _helpOption(
              context,
              icon: Icons.report_problem,
              title: 'Report an Issue',
              subtitle: 'Having trouble with the app?',
              onTap: () {
                Navigator.pop(ctx);
                _showReportIssueDialog(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: burntOrange,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _helpOption(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: burntOrange, size: 28),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: darkBrown)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: darkBrown.withOpacity(0.7))),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: darkBrown.withOpacity(0.5)),
      onTap: onTap,
    );
  }

  void _showContactInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Barangay Hall', style: TextStyle(color: darkBrown)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Icon(Icons.location_on, color: burntOrange),
              title: Text('Address', style: TextStyle(color: darkBrown)),
              subtitle: Text('Dubinan East Barangay Multi-purpose Hall, CM Recto St, Santiago City', style: TextStyle(color: darkBrown.withOpacity(0.7))),
              onTap: () {
                final url = Uri.parse('https://www.google.com/maps/place/Dubinan+East+Barangay+Multi-purpose+Hall/@16.6891599,121.5401739,17z/data=!3m1!4b1!4m6!3m5!1s0x339006022a6053e3:0x56ebaaba7bd70229!8m2!3d16.6891599!4d121.5427488!16s%2Fg%2F1hjgkv_sh?entry=ttu&g_ep=EgoyMDI2MDUwMi4wIKXMDSoASAFQAw%3D%3D');
                _launchUrl(url);
              },
            ),
            ListTile(
              leading: Icon(Icons.phone, color: burntOrange),
              title: Text('Phone', style: TextStyle(color: darkBrown)),
              subtitle: const Text('(02) 1234-5678'),
              onTap: () {
                _launchUrl(Uri.parse('tel:0212345678'));
              },
            ),
            ListTile(
              leading: Icon(Icons.email, color: burntOrange),
              title: Text('Email', style: TextStyle(color: darkBrown)),
              subtitle: const Text('Santiago.DubinanEast@barangay.gov.ph'),
              onTap: () {
                _launchUrl(Uri.parse('mailto:DubinanEast.BarangayHall@santiagocity.gov.ph'));
              },
            ),
            ListTile(
              leading: Icon(Icons.access_time, color: burntOrange),
              title: Text('Office Hours', style: TextStyle(color: darkBrown)),
              subtitle: const Text('Monday - Friday: 8:00 AM - 5:00 PM'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: burntOrange,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFaqDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Frequently Asked Questions', style: TextStyle(color: darkBrown)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _faqItem(
                  'How do I submit a request?',
                  'Tap the "Submit New Request" button on the home screen, select a category, fill in the details, and submit.',
                ),
                const SizedBox(height: 16),
                _faqItem(
                  'How can I track my request?',
                  'Go to "My Requests" tab to see all your requests and their current status.',
                ),
                const SizedBox(height: 16),
                _faqItem(
                  'How long does it take to process?',
                  'Processing time varies by request type. Most requests are processed within 3-5 business days.',
                ),
                const SizedBox(height: 16),
                _faqItem(
                  'Can I cancel a request?',
                  'Yes, you can cancel pending requests by viewing the request details and tapping the Cancel button.',
                ),
                const SizedBox(height: 16),
                _faqItem(
                  'How will I receive updates?',
                  'You will receive notifications in the app when your request status changes.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: burntOrange,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _faqItem(String question, String answer) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: darkBrown.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: burntOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Q',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: darkBrown,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'A',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  answer,
                  style: TextStyle(
                    fontSize: 13,
                    color: darkBrown.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReportIssueDialog(BuildContext context) {
    final issueController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Report an Issue', style: TextStyle(color: darkBrown)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please describe the issue you are experiencing:', style: TextStyle(color: darkBrown)),
            const SizedBox(height: 16),
            TextField(
              controller: issueController,
              decoration: InputDecoration(
                hintText: 'Describe the issue...',
                hintStyle: TextStyle(color: darkBrown.withOpacity(0.5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: darkBrown),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: darkBrown.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: burntOrange, width: 2),
                ),
              ),
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: burntOrange,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final issue = issueController.text.trim();
              if (issue.isNotEmpty) {
                final emailUri = Uri.parse(
                  'mailto:support@barangay.gov.ph?subject=App Issue Report&body=${Uri.encodeComponent(issue)}',
                );
                _launchUrl(emailUri);
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Thank you for your report. We will look into it.'),
                  backgroundColor: burntOrange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: burntOrange,
              foregroundColor: white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(Uri url) async {
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }
}