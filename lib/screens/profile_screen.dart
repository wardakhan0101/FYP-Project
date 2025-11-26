import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // FIREBASE LOGIC: Sign out function
  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. GET CURRENT USER
    final User? user = FirebaseAuth.instance.currentUser;
    final String displayName = user?.displayName ?? "Language Learner";
    final String email = user?.email ?? "user@example.com";
    final String? photoUrl = user?.photoURL;

    // 2. DEFINE PALETTE
    final Color primaryPurple = const Color(0xFF8A48F0);
    final Color softBackground = const Color(0xFFF7F7FA);
    final Color textDark = const Color(0xFF101828);
    final Color textGrey = const Color(0xFF667085);

    // Exact Colors from Home Screen
    final Color fireRed = const Color(0xFFFF0000);
    final Color xpYellow = const Color(0xFFFF9900);

    return Scaffold(
      backgroundColor: softBackground,
      appBar: AppBar(
        backgroundColor: softBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textDark, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'My Profile',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // --- PROFILE HEADER ---
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: primaryPurple.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: photoUrl != null
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl == null
                              ? Icon(Icons.person, size: 50, color: textGrey)
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryPurple,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.edit, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 14,
                      color: textGrey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: primaryPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Intermediate B2",
                      style: TextStyle(
                        color: primaryPurple,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- STATS ROW (UPDATED) ---
            Row(
              children: [
                // Streak: Fire Icon (Red)
                _buildStatCard(
                    "Streak",
                    "0",
                    "Days",
                    Icons.local_fire_department,
                    fireRed
                ),
                const SizedBox(width: 16),
                // XP: Lightning Icon (Yellow)
                _buildStatCard(
                    "XP",
                    "0",
                    "Pts",
                    Icons.flash_on,
                    xpYellow
                ),
              ],
            ),

            const SizedBox(height: 40),

            // --- LOGOUT BUTTON ---
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => _signOut(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFFFEE4E2), // Light Red
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.logout, color: Color(0xFFD92D20)),
                    SizedBox(width: 8),
                    Text(
                      "Log Out",
                      style: TextStyle(
                        color: Color(0xFFD92D20), // Dark Red
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGET (UPDATED) ---

  Widget _buildStatCard(String label, String value, String unit, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Dynamic Icon here
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      color: Color(0xFF101828),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const TextSpan(text: " "),
                  TextSpan(
                    text: unit,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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
}