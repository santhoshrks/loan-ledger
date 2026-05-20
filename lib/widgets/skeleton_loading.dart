import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLoanCard extends StatelessWidget {
  const SkeletonLoanCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE5E7EB),
      highlightColor: const Color(0xFFF9FAFB),
      period: const Duration(milliseconds: 1400),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // Top accent bar
              Container(height: 3, color: Colors.white),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon placeholder
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Name + date placeholders
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 14, width: 140,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 11, width: 90,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Amount + badge placeholders
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              height: 16, width: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 22, width: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Progress bar placeholder
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          height: 11, width: 70,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 28, width: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SkeletonDashboard extends StatelessWidget {
  const SkeletonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE5E7EB),
      highlightColor: const Color(0xFFF9FAFB),
      period: const Duration(milliseconds: 1400),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(height: 12, width: 110,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                Container(height: 22, width: 90,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
              ],
            ),
            const SizedBox(height: 14),
            Container(height: 36, width: 160,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 6),
            Container(height: 12, width: 120,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
            const SizedBox(height: 18),
            Row(children: [
              _pill(), const SizedBox(width: 10),
              _pill(), const SizedBox(width: 10),
              _pill(),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _pill() => Expanded(
    child: Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
    ),
  );
}

/// Full skeleton loading screen (header + dashboard + 3 cards)
class SkeletonHomeScreen extends StatelessWidget {
  const SkeletonHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header skeleton
        Shimmer.fromColors(
          baseColor: const Color(0xFFD1D5DB),
          highlightColor: const Color(0xFFE5E7EB),
          child: Container(
            height: 130,
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(height: 16),
        const SkeletonDashboard(),
        const SizedBox(height: 8),
        // Quick actions skeleton
        Shimmer.fromColors(
          baseColor: const Color(0xFFE5E7EB),
          highlightColor: const Color(0xFFF9FAFB),
          child: SizedBox(
            height: 86,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
              itemBuilder: (_, __) => Container(
                margin: const EdgeInsets.only(right: 10),
                width: 70,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 50, height: 50,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
                    const SizedBox(height: 6),
                    Container(height: 10, width: 48,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 4,
            itemBuilder: (_, __) => const SkeletonLoanCard(),
          ),
        ),
      ],
    );
  }
}

