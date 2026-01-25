import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:grammarian_web/footer.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  String? _errorMessage;

  // --- Auth Logic (Preserved) ---

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          setState(() => _isLoading = false);
          return;
        }
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Google Sign-In failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- UI Constants & Styles ---

  static const Color _primaryColor = Color(0xFF9333ea);
  static const Color _primaryHover = Color(0xFF7e22ce);
  static const Color _darkBg = Color(0xFF0f0c16);

  // --- Widget Build ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      body: Stack(
        children: [
          // Background Layers
          _buildBackground(),

          // Main Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280), // max-w-7xl
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Mobile vs Desktop Layout
                    if (constraints.maxWidth < 1024) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSageSection(isMobile: true),
                          const SizedBox(height: 48),
                          _buildLoginCard(),
                        ],
                      );
                    } else {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: _buildSageSection(isMobile: false)),
                          const SizedBox(width: 96), // gap-24
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 448,
                            ), // max-w-md
                            child: _buildLoginCard(),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
            ),
          ),

          // Footer
          const FooterLink(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        // Base gradient
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [
                Color.fromRGBO(17, 24, 39, 0.4),
                Color.fromRGBO(17, 24, 39, 0),
              ],
            ),
          ),
        ),
        // Top-left purple blob
        Positioned(
          top: MediaQuery.of(context).size.height * 0.1,
          left: MediaQuery.of(context).size.width * 0.1,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _primaryColor.withValues(alpha: 0.2),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
        // Bottom-right darker purple blob
        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.1,
          right: MediaQuery.of(context).size.width * 0.1,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.purple.shade900.withValues(alpha: 0.2),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSageSection({required bool isMobile}) {
    return Column(
      crossAxisAlignment: isMobile
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        // Image Container
        Stack(
          alignment: Alignment.center,
          children: [
            // Glow behind sage
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primaryColor.withValues(alpha: 0.3),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(color: Colors.transparent),
              ),
            ),
            // Sage Image
            Image.asset(
              'assets/sage.png',
              width: isMobile ? 300 : 512, // w-72 md:w-96 lg:w-[32rem] approx
              fit: BoxFit.contain,
              // Adding a subtle shadow manually since drop-shadow isn't direct
              // But Image.network doesn't take shadow directly. Wrapped in container or ignore for now.
            ),
          ],
        ),
        const SizedBox(height: 32),
        // Glass Bubble
        Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 576), // max-w-xl
                  padding: const EdgeInsets.all(24), // p-6
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF).withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Greetings, traveler!',
                        style: GoogleFonts.cinzel(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '"Ah, I spot the glimmer of the Ring of the Grammarian upon your finger! A chaotic trinket, indeed. It grants you the power to alter a single letter of a spell’s name to birth a new enchantment. Describe your current predicament, and I shall instruct you on how to twist your vocabulary to survive it!"',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          color: Colors.grey.shade300,
                          height: 1.6, // leading-relaxed
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // The little triangle tail
            Positioned(
              top: -6,
              left: isMobile ? 0 : 96,
              right: isMobile ? 0 : null,
              child: Center(
                child: Transform.rotate(
                  angle: 0.785398, // 45 degrees
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF171221,
                      ), // Closest approximation to blended bg
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        left: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(32), // p-8
          decoration: BoxDecoration(
            color: const Color.fromRGBO(20, 15, 35, 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color.fromRGBO(139, 92, 246, 0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glow effect behind title (approximated)
              // Absolute positioning is tricky inside a column without a stack wrapper for the whole card content,
              // but the mock has it top-right. Let's simplify and put a glow behind the text or just skip the specific corner blob for cleaner code.
              Text(
                'Welcome',
                style: GoogleFonts.cinzel(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                ),

              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(color: _primaryColor),
                )
              else ...[
                _buildSocialButton(
                  text: 'Sign in with Google',
                  icon: FontAwesomeIcons.google,
                  color: _primaryColor,
                  hoverColor: _primaryHover,
                  textColor: Colors.white,
                  borderColor: _primaryColor.withValues(alpha: 0.4),
                  onPressed: _signInWithGoogle,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String text,
    required IconData icon,
    required Color color,
    required Color hoverColor,
    required Color textColor,
    required Color borderColor,
    required VoidCallback onPressed,
  }) {
    // Note: Flutter's standard buttons don't have built-in hover color transitions quite like CSS.
    // We can use ButtonStyle with WidgetStateProperty.

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.hovered)) {
              return hoverColor;
            }
            return color;
          }),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: borderColor),
            ),
          ),
          elevation: WidgetStateProperty.all(0), // Handled by container shadow
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: FaIcon(icon, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: GoogleFonts.cinzel(
                fontSize: 18,
                fontWeight: FontWeight.w500, // font-medium
                letterSpacing: 0.5, // tracking-wide
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
