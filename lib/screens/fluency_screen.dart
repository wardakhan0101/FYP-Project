import 'package:flutter/material.dart';

class FluencyScreen extends StatelessWidget {
  const FluencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Fluency Report',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Transcript Section (Green Box)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "I go to school... um... basically I like to study math but... uh... sometimes it gets hard.",
                style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 24),

            // 2. Header
            const Text(
              "Fluency Issues (2)",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 3. Mistake Cards
            _buildFluencyCard(
              title: "FILLER WORDS",
              errorText: "um... uh...",
              explanation: "Frequent use of filler words interrupts the flow of speech.",
              suggestions: ["Pause silently instead", "Take a breath"],
            ),
            const SizedBox(height: 16),
            _buildFluencyCard(
              title: "PACING",
              errorText: "[Long Pause > 3s]",
              explanation: "There was an unnaturally long pause between sentences.",
              suggestions: ["Keep speaking rhythm consistent"],
            ),

            const SizedBox(height: 24),

            // 4. Categories Header (Bottom)
            const Text(
              "Mistake Categories",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build the red error cards
  Widget _buildFluencyCard({
    required String title,
    required String errorText,
    required String explanation,
    required List<String> suggestions,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header: Category Only (Severity Removed)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              // Removed the severity container from here
            ],
          ),
          const SizedBox(height: 12),

          // Red Error Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.close, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Text(
                  errorText,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Explanation
          Text(
            explanation,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
          const SizedBox(height: 12),

          // Suggestions Label
          const Text(
            "Suggestions:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),

          // Suggestions Chips
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: suggestions.map((suggestion) {
              return Chip(
                avatar: const Icon(Icons.check, color: Colors.green, size: 18),
                label: Text(
                  suggestion,
                  style: const TextStyle(color: Colors.green),
                ),
                backgroundColor: Colors.green.shade50,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}