import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Base shimmer wrapper with consistent styling
class BaseShimmer extends StatelessWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  const BaseShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? const Color(0xFFE0E0E0),
      highlightColor: highlightColor ?? Colors.white,
      child: child,
    );
  }
}

/// Skeleton box with customizable dimensions
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final Color? color;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return BaseShimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color ?? Colors.grey[300]!,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Skeleton for circular avatars
class SkeletonAvatar extends StatelessWidget {
  final double radius;

  const SkeletonAvatar({super.key, required this.radius});

  @override
  Widget build(BuildContext context) {
    return BaseShimmer(
      child: CircleAvatar(radius: radius, backgroundColor: Colors.grey[300]),
    );
  }
}

/// Skeleton for text lines
class SkeletonText extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonText({
    super.key,
    required this.width,
    this.height = 16,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }
}

/// Skeleton for list item cards (used in Activity, Assignment, Quiz, PIT lists)
class SkeletonListItem extends StatelessWidget {
  const SkeletonListItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SkeletonAvatar(radius: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonText(width: double.infinity, height: 18),
                const SizedBox(height: 8),
                SkeletonText(width: 120, height: 14),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SkeletonBox(width: 60, height: 24, borderRadius: 12),
        ],
      ),
    );
  }
}

/// Skeleton for grid item cards (used in Materials list)
class SkeletonGridItem extends StatelessWidget {
  const SkeletonGridItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF34A853).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox(width: 4, height: 20, borderRadius: 2),
              const SizedBox(width: 12),
              Expanded(child: SkeletonText(width: double.infinity, height: 18)),
            ],
          ),
          const SizedBox(height: 8),
          SkeletonText(width: double.infinity, height: 14),
          const SizedBox(height: 8),
          SkeletonText(width: double.infinity, height: 14),
          const Spacer(),
          SkeletonBox(width: double.infinity, height: 32, borderRadius: 8),
        ],
      ),
    );
  }
}

/// Skeleton for home screen plant progress card
class SkeletonHomeProgressCard extends StatelessWidget {
  const SkeletonHomeProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 320,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: SkeletonBox(width: 40, height: 40, borderRadius: 20),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SkeletonBox(width: 250, height: 250, borderRadius: 125),
              SkeletonBox(width: 150, height: 150, borderRadius: 75),
            ],
          ),
          Positioned(bottom: 0, child: SkeletonText(width: 150, height: 16)),
        ],
      ),
    );
  }
}

/// Skeleton for category completion card
class SkeletonCategoryCompletionCard extends StatelessWidget {
  const SkeletonCategoryCompletionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox(width: 24, height: 24, borderRadius: 12),
              const SizedBox(width: 8),
              SkeletonText(width: 180, height: 18),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(3, (index) => const _SkeletonCategoryItem()),
        ],
      ),
    );
  }
}

class _SkeletonCategoryItem extends StatelessWidget {
  const _SkeletonCategoryItem();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          SkeletonAvatar(radius: 14),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonText(width: double.infinity, height: 16),
                const SizedBox(height: 4),
                Row(
                  children: [
                    SkeletonText(width: 100, height: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SkeletonBox(
                        width: double.infinity,
                        height: 6,
                        borderRadius: 4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SkeletonText(width: 40, height: 12),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for "Submit Your Work" section
class SkeletonSubmitWorkCard extends StatelessWidget {
  const SkeletonSubmitWorkCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox(width: 50, height: 50, borderRadius: 12),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonText(width: 150, height: 18),
                    const SizedBox(height: 4),
                    SkeletonText(width: 200, height: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...List.generate(4, (index) => const _SkeletonSubmitItem()),
        ],
      ),
    );
  }
}

class _SkeletonSubmitItem extends StatelessWidget {
  const _SkeletonSubmitItem();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          SkeletonBox(width: 50, height: 50, borderRadius: 15),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonText(width: 120, height: 16),
                const SizedBox(height: 4),
                SkeletonText(width: 180, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for leaderboard podium (top 3)
class SkeletonLeaderboardPodium extends StatelessWidget {
  const SkeletonLeaderboardPodium({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SkeletonPodiumItem(height: 130),
        const SizedBox(width: 18),
        _SkeletonPodiumItem(height: 190),
        const SizedBox(width: 18),
        _SkeletonPodiumItem(height: 130),
      ],
    );
  }
}

class _SkeletonPodiumItem extends StatelessWidget {
  final double height;

  const _SkeletonPodiumItem({required this.height});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SkeletonBox(width: 100, height: 100, borderRadius: 50),
              SkeletonAvatar(radius: 45),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SkeletonText(width: 90, height: 16),
        const SizedBox(height: 4),
        SkeletonText(width: 60, height: 14),
      ],
    );
  }
}

/// Skeleton for leaderboard list item
class SkeletonLeaderboardItem extends StatelessWidget {
  const SkeletonLeaderboardItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            SkeletonText(width: 32, height: 16),
            const SizedBox(width: 8),
            SkeletonAvatar(radius: 30),
            const SizedBox(width: 12),
            Expanded(child: SkeletonText(width: double.infinity, height: 16)),
            SkeletonText(width: 60, height: 16),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for profile screen
class SkeletonProfileScreen extends StatelessWidget {
  const SkeletonProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 32),
        Stack(
          alignment: Alignment.center,
          children: [
            SkeletonAvatar(radius: 48),
            Positioned(
              right: 0,
              bottom: 0,
              child: SkeletonBox(width: 32, height: 32, borderRadius: 16),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SkeletonText(width: 150, height: 18),
        const SizedBox(height: 4),
        SkeletonText(width: 200, height: 14),
        const SizedBox(height: 16),
        SkeletonBox(width: 120, height: 32, borderRadius: 20),
        const SizedBox(height: 32),
        ...List.generate(3, (index) => const _SkeletonProfileItem()),
      ],
    );
  }
}

class _SkeletonProfileItem extends StatelessWidget {
  const _SkeletonProfileItem();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SkeletonBox(width: 26, height: 26, borderRadius: 4),
      title: SkeletonText(width: 100, height: 16),
      trailing: SkeletonBox(width: 18, height: 18, borderRadius: 4),
    );
  }
}

/// Skeleton for message list screen (instructor card)
class SkeletonMessageCard extends StatelessWidget {
  const SkeletonMessageCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SkeletonAvatar(radius: 30),
      title: SkeletonText(width: 150, height: 16),
      subtitle: SkeletonText(width: 80, height: 14),
      trailing: SkeletonBox(width: 70, height: 36, borderRadius: 6),
    );
  }
}

/// Skeleton for announcement card
class SkeletonAnnouncementCard extends StatelessWidget {
  const SkeletonAnnouncementCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        width: double.infinity,
        height: 100,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            SkeletonAvatar(radius: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonText(width: 150, height: 18),
                  const SizedBox(height: 4),
                  SkeletonText(width: 180, height: 14),
                ],
              ),
            ),
            SkeletonBox(width: 12, height: 12, borderRadius: 6),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for instructor student list item (message list screen)
class SkeletonInstructorStudentItem extends StatelessWidget {
  const SkeletonInstructorStudentItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 200),
      child: Row(
        children: [
          SkeletonAvatar(radius: 26),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonText(width: 150, height: 17),
                const SizedBox(height: 4),
                SkeletonText(width: 200, height: 13),
              ],
            ),
          ),
          SkeletonBox(width: 24, height: 24, borderRadius: 12),
        ],
      ),
    );
  }
}

/// Skeleton for message chat bubble (instructor message screen)
class SkeletonMessageBubble extends StatelessWidget {
  final bool isMe;

  const SkeletonMessageBubble({super.key, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              SkeletonAvatar(radius: 16),
              const SizedBox(width: 8),
            ],
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Container(
                      constraints: const BoxConstraints(maxWidth: 250),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isMe
                                ? const Color(0xFF22C55E)
                                : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(
                            width: isMe ? 180 : 200,
                            height: 16,
                            borderRadius: 4,
                            color:
                                isMe
                                    ? Colors.white.withOpacity(0.3)
                                    : Colors.grey[300],
                          ),
                          if (isMe) ...[
                            const SizedBox(height: 6),
                            SkeletonBox(
                              width: 120,
                              height: 16,
                              borderRadius: 4,
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    SkeletonBox(width: 60, height: 12, borderRadius: 4),
                  ],
                ),
              ],
            ),
            if (isMe) ...[const SizedBox(width: 8), SkeletonAvatar(radius: 16)],
          ],
        ),
      ),
    );
  }
}

/// Skeleton for instructor message screen profile header
class SkeletonInstructorMessageHeader extends StatelessWidget {
  const SkeletonInstructorMessageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              SkeletonAvatar(radius: 28),
              Positioned(
                right: 0,
                bottom: 0,
                child: SkeletonBox(width: 14, height: 14, borderRadius: 7),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonText(width: 150, height: 18),
                const SizedBox(height: 4),
                SkeletonText(width: 120, height: 13),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for instructor class card
class SkeletonInstructorClassCard extends StatelessWidget {
  const SkeletonInstructorClassCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Section (Image Background)
          Container(
            height: 120,
            decoration: const BoxDecoration(
              color: Color(0xFF34A853),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Stack(
              children: [
                // Skeleton for image background
                SkeletonBox(
                  width: double.infinity,
                  height: 120,
                  borderRadius: 0,
                ),
                // Skeleton for class name and time
                Positioned(
                  left: 20,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(
                        width: 120,
                        height: 20,
                        borderRadius: 4,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(height: 8),
                      SkeletonBox(
                        width: 150,
                        height: 14,
                        borderRadius: 4,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  // Divider
                  Container(
                    width: double.infinity,
                    height: 1,
                    color: Colors.grey.withOpacity(0.4),
                  ),
                  const SizedBox(height: 8),
                  // Action Icons Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Room info
                      Row(
                        children: [
                          SkeletonBox(width: 24, height: 24, borderRadius: 4),
                          const SizedBox(width: 10),
                          SkeletonText(width: 60, height: 14),
                        ],
                      ),
                      // Action buttons
                      Row(
                        children: [
                          SkeletonBox(width: 32, height: 32, borderRadius: 8),
                          const SizedBox(width: 8),
                          SkeletonBox(width: 32, height: 32, borderRadius: 8),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for instructor dashboard statistics card
class SkeletonInstructorStatCard extends StatelessWidget {
  const SkeletonInstructorStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SkeletonBox(width: 80, height: 80, borderRadius: 8),
            const SizedBox(width: 20),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonText(width: 80, height: 15),
                const SizedBox(height: 6),
                SkeletonText(width: 50, height: 32),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for instructor dashboard leaderboard card
class SkeletonInstructorLeaderboardCard extends StatelessWidget {
  const SkeletonInstructorLeaderboardCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonText(width: 150, height: 18),
          const SizedBox(height: 15),
          SizedBox(
            height: 290,
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (context, i) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color:
                        i < 3
                            ? const Color(0xFFFFFDEB)
                            : const Color(0xFFF8FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.transparent, width: 1),
                  ),
                  child: Row(
                    children: [
                      // Trophy or number
                      if (i < 3)
                        SkeletonBox(width: 30, height: 30, borderRadius: 4)
                      else
                        SkeletonText(width: 32, height: 18),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonText(width: i < 3 ? 150 : 120, height: 16),
                            const SizedBox(height: 4),
                            SkeletonText(width: 100, height: 13),
                          ],
                        ),
                      ),
                      SkeletonBox(width: 70, height: 28, borderRadius: 20),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for instructor create item card
class SkeletonInstructorCreateItemCard extends StatelessWidget {
  const SkeletonInstructorCreateItemCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Type Icon
          SkeletonBox(width: 48, height: 48, borderRadius: 8),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type and Period badges
                Row(
                  children: [
                    SkeletonBox(width: 80, height: 24, borderRadius: 4),
                    const SizedBox(width: 8),
                    SkeletonBox(width: 70, height: 24, borderRadius: 4),
                  ],
                ),
                const SizedBox(height: 8),
                // Title
                SkeletonText(width: 200, height: 16),
                const SizedBox(height: 4),
                // Description
                SkeletonText(width: double.infinity, height: 13),
                const SizedBox(height: 4),
                SkeletonText(width: 250, height: 13),
                const SizedBox(height: 4),
                // Topic and Points
                Row(
                  children: [
                    SkeletonText(width: 100, height: 14),
                    const SizedBox(width: 16),
                    SkeletonText(width: 80, height: 14),
                  ],
                ),
                const SizedBox(height: 4),
                // Created date and Status
                Row(
                  children: [
                    SkeletonText(width: 120, height: 12),
                    const Spacer(),
                    SkeletonBox(width: 60, height: 20, borderRadius: 4),
                  ],
                ),
              ],
            ),
          ),
          // Actions Menu
          SkeletonBox(width: 24, height: 24, borderRadius: 4),
        ],
      ),
    );
  }
}

/// Skeleton for instructor report class card
class SkeletonInstructorReportClassCard extends StatelessWidget {
  const SkeletonInstructorReportClassCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          SkeletonText(width: 200, height: 20),
          const SizedBox(height: 4),
          // Description
          SkeletonText(width: 150, height: 12),
          const SizedBox(height: 6),
          // Student count and status
          Row(
            children: [
              SkeletonBox(width: 18, height: 18, borderRadius: 4),
              const SizedBox(width: 6),
              SkeletonText(width: 100, height: 13),
              const Spacer(),
              SkeletonBox(width: 10, height: 10, borderRadius: 5),
              const SizedBox(width: 4),
              SkeletonText(width: 50, height: 12),
            ],
          ),
          const SizedBox(height: 6),
          // Manage Class button
          SkeletonBox(width: double.infinity, height: 32, borderRadius: 6),
        ],
      ),
    );
  }
}

/// Skeleton for instructor profile page
class SkeletonInstructorProfile extends StatelessWidget {
  const SkeletonInstructorProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 800;
        return Flex(
          direction: isSmallScreen ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: isSmallScreen ? 0 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Picture
                  Stack(
                    children: [
                      SkeletonAvatar(radius: 48),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: SkeletonBox(
                          width: 32,
                          height: 32,
                          borderRadius: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Name
                  SkeletonText(width: 200, height: 22),
                  const SizedBox(height: 18),
                  // Email
                  Row(
                    children: [
                      SkeletonBox(width: 20, height: 20, borderRadius: 4),
                      const SizedBox(width: 8),
                      SkeletonText(width: 250, height: 15),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Phone
                  Row(
                    children: [
                      SkeletonBox(width: 20, height: 20, borderRadius: 4),
                      const SizedBox(width: 8),
                      SkeletonText(width: 150, height: 15),
                    ],
                  ),
                ],
              ),
            ),
            if (!isSmallScreen) const SizedBox(width: 32),
            if (isSmallScreen) const SizedBox(height: 20),
            Flexible(
              flex: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Edit Profile Button
                  SkeletonBox(width: 150, height: 48, borderRadius: 8),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Skeleton for admin dashboard
class SkeletonAdminDashboard extends StatelessWidget {
  const SkeletonAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // Check screen width for responsive layout
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;
    final isTablet = width >= 768 && width < 1024;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 24,
          vertical: isMobile ? 12 : 18,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin Page Hero Skeleton
            Container(
              margin: EdgeInsets.fromLTRB(
                isMobile ? 16 : 24,
                isMobile ? 12 : 20,
                isMobile ? 16 : 24,
                24,
              ),
              padding: EdgeInsets.all(isMobile ? 16 : 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      SkeletonBox(
                        width: isMobile ? 32 : 40,
                        height: isMobile ? 32 : 40,
                        borderRadius: 8,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonText(
                              width: 180,
                              height: isMobile ? 20 : 24,
                            ),
                            const SizedBox(height: 8),
                            SkeletonText(width: 250, height: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonText(
                              width: 150,
                              height: isMobile ? 24 : 32,
                            ),
                            const SizedBox(height: 8),
                            SkeletonText(width: double.infinity, height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Summary Cards Skeleton
            if (isMobile)
              Column(
                children: List.generate(
                  4,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: const _SkeletonSummaryCard(),
                  ),
                ),
              )
            else if (isTablet)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(
                  4,
                  (index) => SizedBox(
                    width:
                        (width - 48 - 12) / 2, // Approximate width calculation
                    child: const _SkeletonSummaryCard(),
                  ),
                ),
              )
            else
              Row(
                children: List.generate(
                  4,
                  (index) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: index < 3 ? 12 : 0),
                      child: const _SkeletonSummaryCard(),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Period Management Card Skeleton
            Container(
              width: double.infinity,
              height: 120, // Approximate height
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SkeletonText(width: 200, height: 20),
                        const SizedBox(height: 12),
                        SkeletonText(width: 300, height: 14),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  SkeletonBox(width: 40, height: 40, borderRadius: 20),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Search and Filter Skeleton
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 25,
                vertical: isMobile ? 12 : 15,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  // Search Bar
                  SkeletonBox(
                    width: isMobile ? 150 : width * 0.35,
                    height: 48,
                    borderRadius: 7,
                  ),
                  const SizedBox(width: 10),
                  // Chips
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: Row(
                        children: List.generate(
                          3,
                          (index) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: SkeletonBox(
                              width: 100,
                              height: 40,
                              borderRadius: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Instructors Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonText(width: 120, height: 24),
                SkeletonBox(width: 80, height: 24, borderRadius: 20),
              ],
            ),

            const SizedBox(height: 12),

            // Instructor List Skeletons
            Column(
              children: List.generate(
                3,
                (index) => Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFBDBDBD),
                        blurRadius: 2,
                        spreadRadius: 2,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      SkeletonAvatar(radius: 35),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonText(width: 150, height: 18),
                          const SizedBox(height: 6),
                          SkeletonText(width: 180, height: 13),
                          const SizedBox(height: 4),
                          SkeletonText(width: 100, height: 13),
                        ],
                      ),
                      const Spacer(),
                      if (!isMobile) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonText(width: 100, height: 13),
                            const SizedBox(height: 4),
                            SkeletonText(width: 100, height: 13),
                          ],
                        ),
                        const SizedBox(width: 20),
                      ],
                      SkeletonBox(width: 24, height: 24, borderRadius: 12),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonSummaryCard extends StatelessWidget {
  const _SkeletonSummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110, // Approximate height based on content
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonText(width: 100, height: 15),
              SkeletonBox(width: 26, height: 26, borderRadius: 4),
            ],
          ),
          SkeletonText(width: 60, height: 22),
          SkeletonText(width: 120, height: 13),
        ],
      ),
    );
  }
}

/// Skeleton for manage instructors list
class SkeletonInstructorList extends StatelessWidget {
  const SkeletonInstructorList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              // Avatar
              SkeletonAvatar(radius: 30),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonText(width: 180, height: 20),
                    const SizedBox(height: 8),
                    SkeletonText(width: 220, height: 14),
                    const SizedBox(height: 8),
                    SkeletonText(width: 150, height: 14),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SkeletonBox(width: 80, height: 24, borderRadius: 4),
                        const SizedBox(width: 8),
                        SkeletonBox(width: 60, height: 24, borderRadius: 4),
                      ],
                    ),
                  ],
                ),
              ),
              // Actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SkeletonBox(width: 100, height: 36, borderRadius: 8),
                  const SizedBox(height: 8),
                  SkeletonBox(width: 100, height: 36, borderRadius: 8),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Skeleton for department management list
class SkeletonDepartmentList extends StatelessWidget {
  const SkeletonDepartmentList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              // Department Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Icon placeholder
                    SkeletonBox(width: 50, height: 50, borderRadius: 12),
                    const SizedBox(width: 16),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonText(width: 200, height: 20),
                          const SizedBox(height: 8),
                          SkeletonText(width: 120, height: 14),
                          const SizedBox(height: 8),
                          SkeletonText(width: 250, height: 14),
                        ],
                      ),
                    ),
                    // Action buttons
                    Row(
                      children: [
                        SkeletonBox(width: 32, height: 32, borderRadius: 4),
                        const SizedBox(width: 12),
                        SkeletonBox(width: 32, height: 32, borderRadius: 4),
                        const SizedBox(width: 12),
                        SkeletonBox(width: 32, height: 32, borderRadius: 4),
                      ],
                    ),
                  ],
                ),
              ),
              // Sections placeholder (optional, just a small box to imply content)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SkeletonBox(
                  width: double.infinity,
                  height: 60,
                  borderRadius: 8,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Skeleton for class management list
class SkeletonClassManagementList extends StatelessWidget {
  const SkeletonClassManagementList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              // Avatar
              SkeletonAvatar(radius: 25),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonText(width: 150, height: 18),
                    const SizedBox(height: 8),
                    SkeletonText(width: 180, height: 14),
                    const SizedBox(height: 8),
                    SkeletonText(width: 120, height: 14),
                  ],
                ),
              ),
              // Stats
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      SkeletonBox(width: 60, height: 20, borderRadius: 6),
                      const SizedBox(width: 8),
                      SkeletonBox(width: 60, height: 20, borderRadius: 6),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SkeletonBox(width: 60, height: 20, borderRadius: 6),
                      const SizedBox(width: 8),
                      SkeletonBox(width: 60, height: 20, borderRadius: 6),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Skeleton for a chart area
class SkeletonChartArea extends StatelessWidget {
  const SkeletonChartArea({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Background grid lines
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                5,
                (index) => Container(
                  width: double.infinity,
                  height: 1,
                  color: Colors.grey[100],
                ),
              ),
            ),
            // Skeleton bars mimicking a trend
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(12, (index) {
                // Generate a wave-like pattern for the heights
                final double heightFactor =
                    0.3 +
                    0.4 * (0.5 + 0.5 * (index / 11)); // linear increase trend
                return SkeletonBox(
                  width: (constraints.maxWidth / 12) - 8, // Spacing
                  height: constraints.maxHeight * heightFactor,
                  borderRadius: 4,
                );
              }),
            ),
          ],
        );
      },
    );
  }
}
