import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grammarian_web/main.dart';

class TopHeader extends StatelessWidget {
  const TopHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark.withValues(alpha: 0.2), // More transparent
            border: Border(
              bottom: BorderSide(
                color: AppColors.surfaceBorder.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    padding: const EdgeInsets.all(4), // Add padding for the image
                    child: Image.asset(
                      'assets/ring.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Grammarian Sage',
                    style: GoogleFonts.cinzel( // Updated font
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textWhite,
                    ),
                  ),
                ],
              ),
              if (user != null)
                PopupMenuButton(
                  offset: const Offset(0, 48),
                  color: AppColors.surfaceCard,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: AppColors.surfaceBorder),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.surfaceBorder,
                    backgroundImage: user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : null,
                    child: user.photoURL == null
                        ? const Icon(
                            Icons.person,
                            size: 20,
                            color: AppColors.textGray,
                          )
                        : null,
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      onTap: () => FirebaseAuth.instance.signOut(),
                      child: const Row(
                        children: [
                          Icon(Icons.logout, size: 18, color: AppColors.textGray),
                          SizedBox(width: 8),
                          Text(
                            'Log out',
                            style: TextStyle(color: AppColors.textGray),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
