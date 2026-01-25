import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/link.dart';

class FooterLink extends StatelessWidget {
  const FooterLink({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Link(
          uri: Uri.parse('https://github.com/brianquinlan/grammarian'),
          target: LinkTarget.blank,
          builder: (context, followLink) {
            return InkWell(
              onTap: followLink,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Source on GitHub',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}