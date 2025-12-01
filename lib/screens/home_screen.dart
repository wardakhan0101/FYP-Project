import 'package:flutter/material.dart';
import 'package:lingua_franca/screens/chat_screen.dart';
import 'package:lingua_franca/screens/developers_screen.dart';
import 'package:lingua_franca/screens/profile_screen.dart';
import 'package:lingua_franca/screens/stt_test.dart';
import 'package:lingua_franca/screens/timed_presentation_screen.dart';

// -----------------------------------------------------------
// 1. CUSTOM PAINTER FOR GRADIENT CIRCULAR PROGRESS
// -----------------------------------------------------------

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color trackColor;
  final double strokeWidth;
  final List<Color> gradientColors;

  _CircularProgressPainter({
    required this.progress,
    required this.primaryColor,
    required this.trackColor,
    required this.strokeWidth,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;
    const double startAngle = -3.14159 / 2; // -90 degrees (top)

    // 1. Draw the Track (Background Circle)
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, trackPaint);

    // 2. Draw the Progress Arc with Gradient
    final rect = Rect.fromCircle(center: center, radius: radius);
    final progressSweepAngle = 3.14159 * 2 * progress;

    final progressPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..shader = LinearGradient(
        colors: gradientColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    if (progress > 0) {
      canvas.drawArc(
        rect,
        startAngle,
        progressSweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor;
  }
}

// -----------------------------------------------------------
// 2. WIDGET WRAPPER FOR THE CUSTOM PAINTER
// -----------------------------------------------------------

class GradientCircularProgress extends StatelessWidget {
  final double progress;
  final Color primaryColor;
  final Color trackColor;
  final double strokeWidth;

  const GradientCircularProgress({
    super.key,
    required this.progress,
    required this.primaryColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  Widget build(BuildContext context) {
    final gradientColors = [
      primaryColor,
      primaryColor.withOpacity(0.8),
    ];

    return CustomPaint(
      painter: _CircularProgressPainter(
        progress: progress,
        primaryColor: primaryColor,
        trackColor: trackColor,
        strokeWidth: strokeWidth,
        gradientColors: gradientColors,
      ),
      child: const SizedBox.expand(),
    );
  }
}

// -----------------------------------------------------------
// 3. HOME SCREEN IMPLEMENTATION
// -----------------------------------------------------------

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryPurple = const Color(0xFF8A48F0);
    final Color secondaryPurple = const Color(0xFFD9BFFF);
    final Color softBackground = const Color(0xFFF7F7FA);
    final Color textDark = const Color(0xFF101828);
    final Color textGrey = const Color(0xFF667085);

    return Scaffold(
      backgroundColor: softBackground,
      // 2. Pass 'context' to the builder method
      bottomNavigationBar: _buildBottomNavBar(context, primaryPurple),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, primaryPurple, textDark),
                const SizedBox(height: 24),
                _buildWelcomeBanner(primaryPurple, secondaryPurple),
                const SizedBox(height: 24),
                _buildProgressCard(primaryPurple, textDark, textGrey),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SttTest(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: primaryPurple.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Start Conversation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Weekly Practice Streak', textDark),
                const SizedBox(height: 12),
                _buildStreakRow(Colors.white, primaryPurple),
                const SizedBox(height: 24),
                _buildSectionTitle('Your Achievements', textDark),
                const SizedBox(height: 12),
                _buildAchievementsRow(Colors.white, textDark),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildHeader(BuildContext context, Color primary, Color textDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Lingua Franca',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: primary,
          ),
        ),
        Row(
          children: [
            Row(
              children: [
                const Icon(Icons.local_fire_department, color: Color(0xFFFF0000), size: 20),
                const SizedBox(width: 4),
                Text('0 days', style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
              ],
            ),
            const SizedBox(width: 12),
            Row(
              children: [
                const Icon(Icons.flash_on, color: Color(0xFFFF9900), size: 20),
                const SizedBox(width: 4),
                Text('0 pts', style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
              ],
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const DevelopersScreen()),
                );
              },
              child: CircleAvatar(
                backgroundColor: primary.withOpacity(0.1),
                radius: 18,
                child: Icon(Icons.bug_report, color: primary, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeBanner(Color primary, Color accent) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Welcome Back!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF344054),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Intermediate B2',
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(Color primary, Color textDark, Color textGrey) {
    final double currentProgress = 0.0;
    final String currentProgressText = '0%';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Speaking Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatRow('Speaking', '0/100', 0.0, primary),
                    const SizedBox(height: 12),
                    _buildStatRow('Fluency', '0%', 0.0, primary),
                    const SizedBox(height: 12),
                    _buildStatRow('Grammar', '0%', 0.0, primary),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      GradientCircularProgress(
                        progress: currentProgress,
                        primaryColor: primary,
                        trackColor: Colors.grey.shade200,
                        strokeWidth: 12,
                      ),
                      Text(
                        currentProgressText,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: textDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'View Detailed Report',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, double pct, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475467)),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  Widget _buildStreakRow(Color bg, Color primary) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: days.map((day) {
          return Column(
            children: [
              Text(
                day,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAchievementsRow(Color bg, Color textDark) {
    Color inactiveColor = Colors.grey.shade400;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildBadge(Icons.star, 'Master', inactiveColor),
          _buildBadge(Icons.mic, 'Pronounce', inactiveColor),
          _buildBadge(Icons.emoji_events, 'Grammar', inactiveColor),
          _buildBadge(Icons.book, 'Vocab', inactiveColor),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey.shade100,
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF475467)),
        ),
      ],
    );
  }

  // 3. UPDATED NAV BAR WITH ONTAP LOGIC
  Widget _buildBottomNavBar(BuildContext context, Color primary) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey.shade500,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        // Add onTap listener
        onTap: (index) {
          if (index == 1){
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SttTest(),
              ),
            );
          }
          if (index == 3) {
            // Index 3 is Profile
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ProfileScreen(),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Practice'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}