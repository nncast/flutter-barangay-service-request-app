import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/session.dart';
import '../../core/ui_helpers.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const String _hallEmail = 'DubinanEast.BarangayHall@santiagocity.gov.ph';

  static String _orNotSet(String? value) => (value == null || value.trim().isEmpty) ? 'Not set' : value;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                children: [
                  InitialsAvatar(initials: user?.initials ?? 'U', radius: 44),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'User',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kCharcoal, letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 8),
                  Tag(label: user?.role.toUpperCase() ?? 'RESIDENT', color: kCharcoal),
                ],
              ),
            ),
            const Divider(height: 1),
            // Profile Info
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Personal Information'),
                  const SizedBox(height: 16),
                  _infoTile(Icons.email, 'Email', user?.email ?? 'Not set'),
                  _infoTile(Icons.phone, 'Phone', _orNotSet(user?.phone)),
                  _infoTile(Icons.home, 'Address', _orNotSet(user?.address)),
                  const Divider(height: 32),
                  const SectionTitle('Account Settings'),
                  const SizedBox(height: 16),
                  _actionTile(Icons.help_outline, 'Help & Support', () {
                    _showHelpSupportDialog(context);
                  }),
                  _actionTile(Icons.info_outline, 'About', () {
                    _showAboutDialog(context);
                  }),
                  const Divider(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => confirmLogout(context),
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
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
          IconBox(icon, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: kGray)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kCharcoal)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: IconBox(icon, size: 40),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: kCharcoal)),
      trailing: const Icon(Icons.chevron_right, color: kGray),
      onTap: onTap,
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
                    color: kCharcoal.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    size: 48,
                    color: kCharcoal,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 4),
            const Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: kGray,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'A service request system for barangay residents to submit and track requests efficiently.',
              style: TextStyle(
                fontSize: 13,
                color: kCharcoal,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // License Information
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.code, size: 16, color: kCharcoal),
                      SizedBox(width: 8),
                      Text(
                        'License',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: kCharcoal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'MIT License',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kCharcoal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Copyright © 2026 Barangay Service System',
                    style: TextStyle(
                      fontSize: 11,
                      color: kGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files to use, copy, modify, merge, publish, and distribute copies of the Software.',
                    style: TextStyle(
                      fontSize: 11,
                      color: kGray,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The software is provided "as is", without warranty of any kind.',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: kGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Developer Credits
                  const Row(
                    children: [
                      Icon(Icons.people, size: 16, color: kCharcoal),
                      SizedBox(width: 8),
                      Text(
                        'Developers',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: kCharcoal,
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(12)),
      child: Text(
        name,
        style: const TextStyle(
          fontSize: 10,
          color: kCharcoal,
        ),
      ),
    );
  }

  void _showHelpSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: kCharcoal),
            SizedBox(width: 8),
            Text('Help & Support'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How can we help you?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kCharcoal),
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
            const Divider(),
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
            const Divider(),
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
      leading: Icon(icon, color: kCharcoal, size: 28),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, color: kCharcoal)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: kGray)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: kGray),
      onTap: onTap,
    );
  }

  void _showContactInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Barangay Hall'),
        content: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.location_on, color: kCharcoal),
              title: const Text('Address'),
              subtitle: const Text('Dubinan East Barangay Multi-purpose Hall, CM Recto St, Santiago City', style: TextStyle(color: kGray)),
              onTap: () {
                final url = Uri.parse('https://www.google.com/maps/place/Dubinan+East+Barangay+Multi-purpose+Hall/@16.6891599,121.5401739,17z/data=!3m1!4b1!4m6!3m5!1s0x339006022a6053e3:0x56ebaaba7bd70229!8m2!3d16.6891599!4d121.5427488!16s%2Fg%2F1hjgkv_sh?entry=ttu&g_ep=EgoyMDI2MDUwMi4wIKXMDSoASAFQAw%3D%3D');
                _launchUrl(url);
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: kCharcoal),
              title: const Text('Phone'),
              subtitle: const Text('(02) 1234-5678'),
              onTap: () {
                _launchUrl(Uri.parse('tel:0212345678'));
              },
            ),
            ListTile(
              leading: const Icon(Icons.email, color: kCharcoal),
              title: const Text('Email'),
              subtitle: const Text(_hallEmail),
              onTap: () {
                _launchUrl(Uri(scheme: 'mailto', path: _hallEmail));
              },
            ),
            const ListTile(
              leading: Icon(Icons.access_time, color: kCharcoal),
              title: Text('Office Hours'),
              subtitle: Text('Monday - Friday: 8:00 AM - 5:00 PM'),
            ),
          ],
        ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
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
        title: const Text('Frequently Asked Questions'),
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
        color: kSurface,
        borderRadius: BorderRadius.circular(10),
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
                  color: kCharcoal,
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: kCharcoal,
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
                  color: kOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'A',
                    style: TextStyle(
                      color: kCharcoal,
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
                  style: const TextStyle(
                    fontSize: 13,
                    color: kGray,
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

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report an Issue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please describe the issue you are experiencing:'),
            const SizedBox(height: 16),
            TextField(
              controller: issueController,
              decoration: const InputDecoration(hintText: 'Describe the issue...'),
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final issue = issueController.text.trim();
              if (issue.isEmpty) return;
              Navigator.pop(ctx);
              final opened = await _launchUrl(Uri(
                scheme: 'mailto',
                path: _hallEmail,
                query: 'subject=${Uri.encodeComponent('App Issue Report')}&body=${Uri.encodeComponent(issue)}',
              ));
              if (context.mounted) {
                showMessage(
                  context,
                  opened
                      ? 'Your email app has opened with the report. Send it to finish.'
                      : 'No email app found. Please email $_hallEmail directly.',
                  success: opened,
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  // launchUrl is called directly: canLaunchUrl wrongly reports false on
  // Android 11+ unless every scheme is declared in the manifest.
  Future<bool> _launchUrl(Uri url) async {
    try {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching URL: $e');
      return false;
    }
  }
}