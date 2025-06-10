// lib/screens/about_screen.dart
import 'package:flutter/material.dart';
import 'package:tasbeehlite/localization/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  final String locale;

  const AboutScreen({super.key, required this.locale});

  // URL launcher helpers
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $urlString');
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=${Uri.encodeComponent('About Tasbeeh Lite App')}',
    );
    if (!await launchUrl(emailLaunchUri)) {
      debugPrint('Could not launch email to $email');
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final TextDirection currentTextDirection = locale == 'ar' ? TextDirection.rtl : TextDirection.ltr;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('about_app')),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Directionality(
        textDirection: currentTextDirection,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [

              // App Icon and Name
              Column(
                children: [
                  Image.asset(
                    'assets/images/tasbeeh_lite_icon.png',
                    height: 100,
                    width: 100,
                    errorBuilder: (_, __, ___) => const Icon(Icons.apps, size: 80),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    localizations.translate('tasbeeh'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${localizations.translate('version')}: 1.0',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // About Description
              _buildSectionTitle(context, localizations.translate('about_app')),
              Text(
                localizations.translate('about_description'),
                style: const TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 20),

              // Fazilat
              _buildSectionTitle(context, localizations.translate('fazilat')),
              Text(
                localizations.translate('fazilat_text'),
                style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),

              const SizedBox(height: 30),

              // Contact Section
              _buildSectionTitle(context, localizations.translate('contact_us')),
              Text(localizations.translate('contact_us_description')),
              const SizedBox(height: 10),
              InkWell(
                onTap: () => _launchEmail(localizations.translate('contact_email')),
                child: Text(
                  localizations.translate('contact_email'),
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Developer Info
              _buildSectionTitle(context, localizations.translate('developer_info')),
              _buildDeveloperCard(context, localizations),

              const SizedBox(height: 30),

              // Social Links
              _buildSectionTitle(context, localizations.translate('follow_us')),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialButton(Icons.facebook, 'https://facebook.com/yourprofile'),
                  _buildSocialButton(Icons.video_library, 'https://youtube.com/yourchannel'),
                  _buildSocialButton(Icons.code, 'https://github.com/yourusername'),
                ],
              ),

              const SizedBox(height: 30),

              // Terms & Policies
              _buildSectionTitle(context, localizations.translate('terms_and_policy')),
              Text(localizations.translate('terms_policy_description')),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: [
                  ElevatedButton(
                    onPressed: () => _launchURL('https://yourwebsite.com/privacy'),
                    child: Text(localizations.translate('privacy_policy')),
                  ),
                  ElevatedButton(
                    onPressed: () => _launchURL('https://yourwebsite.com/terms'),
                    child: Text(localizations.translate('terms_conditions')),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Open Source Licenses
              _buildSectionTitle(context, localizations.translate('open_source_licenses')),
              Text(localizations.translate('open_source_description')),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _launchURL('https://yourwebsite.com/licenses'),
                child: Text(localizations.translate('open_source_link_text')),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Section title widget
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.green[800],
        ),
      ),
    );
  }

  // Developer card
  Widget _buildDeveloperCard(BuildContext context, AppLocalizations localizations) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundImage: AssetImage('assets/images/developer_avatar.png'),
              onBackgroundImageError: (_, __) {},
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.translate('developer_name'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    localizations.translate('developer_bio_placeholder'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Social button
  Widget _buildSocialButton(IconData icon, String url) {
    return IconButton(
      icon: Icon(icon, size: 30),
      color: Colors.blueGrey,
      onPressed: () => _launchURL(url),
    );
  }
}