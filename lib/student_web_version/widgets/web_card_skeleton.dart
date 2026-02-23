import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/web_responsive_utils.dart';

// Shared shimmer wrapper used by all public skeleton widgets in this file.
Widget _shimmer({required Widget child}) => Shimmer.fromColors(
  baseColor: const Color(0xFFE0E0E0),
  highlightColor: Colors.white,
  child: child,
);

// ─────────────────────────────────────────────────────────────────────────────
// Private helpers
// ─────────────────────────────────────────────────────────────────────────────

/// A plain grey rectangle placeholder.
/// [width] null → expands to fill the available horizontal space.
class _SkeletonBlock extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const _SkeletonBlock({this.width, required this.height, this.radius = 4});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// A single skeleton placeholder card that mirrors the exact layout of the
/// web activity / assignment / quiz / PIT cards:
///
/// ┌────────────────────────────────────┐
/// │ [icon box]              [badge]    │  ← top row
/// │                                    │
/// │ ██████████████████████████████     │  ← title line 1 (full width)
/// │ ██████████████                     │  ← title line 2 (partial)
/// │                                    │
/// │ [●] ████████████████               │  ← due date row
/// └────────────────────────────────────┘
class _WebCardSkeleton extends StatelessWidget {
  const _WebCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: icon box + status badge
          Row(
            children: [
              _SkeletonBlock(width: 36, height: 36, radius: 8),
              const Spacer(),
              _SkeletonBlock(width: 60, height: 22, radius: 6),
            ],
          ),
          const SizedBox(height: 16),
          // Title – line 1 (full width)
          const _SkeletonBlock(height: 16),
          const SizedBox(height: 8),
          // Title – line 2 (partial width)
          _SkeletonBlock(width: 140, height: 14),
          const Spacer(),
          // Due date row
          Row(
            children: [
              _SkeletonBlock(width: 14, height: 14),
              const SizedBox(width: 4),
              _SkeletonBlock(width: 120, height: 12),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

/// A shimmer-animated skeleton that mirrors the full page layout of the web
/// list screens (activities, assignments, quizzes, PITs).
///
/// Drop-in replacement for the per-screen `_buildSkeletonLoading` methods.
///
/// Usage:
/// ```dart
/// if (controller.isLoading.value && controller.items.isEmpty) {
///   return const WebCardSkeletonGrid();
/// }
/// ```
///
/// Optionally override [itemCount] to control how many placeholder cards
/// are rendered (default: 6).
class WebCardSkeletonGrid extends StatelessWidget {
  /// Number of placeholder cards to render. Matches the default
  /// crossAxisCount × 2 rows (max 3 cols × 2 = 6).
  final int itemCount;

  const WebCardSkeletonGrid({super.key, this.itemCount = 6});

  // Mirrors web_activity_list_screen._buildActivityGrid breakpoints exactly.
  int _crossAxisCount(double screenWidth) {
    if (screenWidth > 1200) return 3;
    if (screenWidth > 800) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: SingleChildScrollView(
          // Matches the same padding used in _buildContent on each screen.
          padding: WebResponsiveUtils.getResponsivePadding(context),
          child: Shimmer.fromColors(
            baseColor: const Color(0xFFE0E0E0),
            highlightColor: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header skeleton ──────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // "Your Activities / Assignments / …" title
                    _SkeletonBlock(width: 200, height: 28, radius: 6),
                    // Refresh icon button
                    _SkeletonBlock(width: 36, height: 36, radius: 18),
                  ],
                ),
                const SizedBox(height: 10),
                // Subtitle / instructor name line
                _SkeletonBlock(width: 280, height: 14),
                const SizedBox(height: 24),

                // ── Card grid skeleton ────────────────────────────────────────
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _crossAxisCount(screenWidth),
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    // Identical to the real card mainAxisExtent.
                    mainAxisExtent: 180,
                  ),
                  itemCount: itemCount,
                  itemBuilder: (_, __) => const _WebCardSkeleton(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Materials skeleton
// ─────────────────────────────────────────────────────────────────────────────

/// Placeholder card matching the Materials card layout:
///
/// ┌────────────────────────────────────┐  height: 220
/// │ [type badge]              [arrow]  │
/// │                                    │
/// │ █████████████████████████████████  │  ← title line 1
/// │ ████████████████                   │  ← title line 2
/// │ ███████████████████████████        │  ← description line 1
/// │ ████████████████████               │  ← description line 2
/// │ ─────────────────────────────────  │  ← divider
/// │ [●] █████████████   [●] ████████   │  ← footer (instructor + date)
/// └────────────────────────────────────┘
class _WebMaterialCardSkeleton extends StatelessWidget {
  const _WebMaterialCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type badge + arrow
          Row(
            children: [
              _SkeletonBlock(width: 56, height: 24, radius: 6),
              const Spacer(),
              _SkeletonBlock(width: 14, height: 14),
            ],
          ),
          const SizedBox(height: 16),
          // Title line 1
          const _SkeletonBlock(height: 18),
          const SizedBox(height: 6),
          // Title line 2
          _SkeletonBlock(width: 160, height: 16),
          const SizedBox(height: 10),
          // Description line 1
          const _SkeletonBlock(height: 14),
          const SizedBox(height: 6),
          // Description line 2
          _SkeletonBlock(width: 200, height: 14),
          const Spacer(),
          // Divider
          Container(height: 1, color: Colors.grey[300]),
          const SizedBox(height: 12),
          // Footer: instructor + date
          Row(
            children: [
              _SkeletonBlock(width: 14, height: 14),
              const SizedBox(width: 4),
              _SkeletonBlock(width: 90, height: 12),
              const Spacer(),
              _SkeletonBlock(width: 14, height: 14),
              const SizedBox(width: 4),
              _SkeletonBlock(width: 60, height: 12),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shimmer skeleton for `WebMaterialsListScreen`.
///
/// Mirrors the exact page structure:
/// - Header (title + subtitle)
/// - Search bar
/// - Responsive grid (1/2/3 cols), `mainAxisExtent: 220`
class WebMaterialsSkeletonGrid extends StatelessWidget {
  final int itemCount;

  const WebMaterialsSkeletonGrid({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return _shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBlock(width: 220, height: 32, radius: 6),
                const SizedBox(height: 10),
                _SkeletonBlock(width: 300, height: 16),
              ],
            ),
          ),
          // ── Search bar ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFE8E8E8)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  _SkeletonBlock(width: 20, height: 20),
                  const SizedBox(width: 12),
                  _SkeletonBlock(width: 240, height: 14),
                ],
              ),
            ),
          ),
          // ── Grid ─────────────────────────────────────────────────────────
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: WebResponsiveUtils.getGridCrossAxisCount(
                  context,
                ),
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                mainAxisExtent: 220,
              ),
              itemCount: itemCount,
              itemBuilder: (_, __) => const _WebMaterialCardSkeleton(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Messages skeleton
// ─────────────────────────────────────────────────────────────────────────────

/// One chat bubble placeholder — [sentByMe] controls which side it sits on.
class _BubbleSkeleton extends StatelessWidget {
  final bool sentByMe;
  final double width;

  const _BubbleSkeleton({required this.sentByMe, required this.width});

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      width: width,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            sentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!sentByMe) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
          ],
          bubble,
          if (sentByMe) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shimmer skeleton for `WebMessageListScreen`.
///
/// On desktop — mirrors the 2-panel layout:
///   [Instructor info sidebar 300px] | [Chat panel: header + bubbles + input]
///
/// On mobile/tablet — chat panel only.
class WebMessageSkeletonView extends StatelessWidget {
  const WebMessageSkeletonView({super.key});

  // Bubble widths cycle to look natural.
  static const _bubbles = [
    (sent: false, width: 200.0),
    (sent: true, width: 160.0),
    (sent: false, width: 240.0),
    (sent: true, width: 180.0),
    (sent: false, width: 140.0),
    (sent: true, width: 220.0),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = WebResponsiveUtils.isDesktop(context);

    return _shimmer(
      child: Row(
        children: [
          // ── Instructor info sidebar (desktop only) ──────────────────────
          if (isDesktop)
            Container(
              width: 300,
              margin: const EdgeInsets.fromLTRB(24, 24, 0, 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8E8E8)),
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Name
                  _SkeletonBlock(width: 140, height: 20, radius: 4),
                  const SizedBox(height: 10),
                  // Online status
                  _SkeletonBlock(width: 80, height: 14),
                  const SizedBox(height: 32),
                  Container(height: 1, color: Colors.grey[300]),
                  const SizedBox(height: 32),
                  // Email row
                  Row(
                    children: [
                      _SkeletonBlock(width: 20, height: 20),
                      const SizedBox(width: 12),
                      _SkeletonBlock(width: 160, height: 14),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Phone row
                  Row(
                    children: [
                      _SkeletonBlock(width: 20, height: 20),
                      const SizedBox(width: 12),
                      _SkeletonBlock(width: 120, height: 14),
                    ],
                  ),
                ],
              ),
            ),

          // ── Chat panel ─────────────────────────────────────────────────
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8E8E8)),
              ),
              child: Column(
                children: [
                  // Chat header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SkeletonBlock(width: 130, height: 16),
                            const SizedBox(height: 6),
                            _SkeletonBlock(width: 70, height: 12),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: Colors.grey[300]),
                  // Message bubbles
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (final b in _bubbles)
                          _BubbleSkeleton(sentByMe: b.sent, width: b.width),
                      ],
                    ),
                  ),
                  Container(height: 1, color: Colors.grey[300]),
                  // Input bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Announcement skeleton
// ─────────────────────────────────────────────────────────────────────────────

/// Single announcement card placeholder that mirrors the real card layout:
/// badge+date row → title (2 lines) → content (3 lines) → avatar+name footer.
class _WebAnnouncementCardSkeleton extends StatelessWidget {
  const _WebAnnouncementCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge + date row
          Row(
            children: [
              const _SkeletonBlock(width: 72, height: 24, radius: 20),
              const Spacer(),
              const _SkeletonBlock(width: 90, height: 13),
            ],
          ),
          const SizedBox(height: 16),
          // Title (2 lines)
          const _SkeletonBlock(height: 22),
          const SizedBox(height: 8),
          const _SkeletonBlock(width: 260, height: 22),
          const SizedBox(height: 12),
          // Content lines
          const _SkeletonBlock(height: 14),
          const SizedBox(height: 6),
          const _SkeletonBlock(height: 14),
          const SizedBox(height: 6),
          const _SkeletonBlock(width: 200, height: 14),
          const SizedBox(height: 20),
          // Footer: avatar + name + views + Read More
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              const _SkeletonBlock(width: 110, height: 14),
              const Spacer(),
              const _SkeletonBlock(width: 60, height: 13),
            ],
          ),
        ],
      ),
    );
  }
}

/// Full-page skeleton for the web announcements list screen.
///
/// Mirrors: header (title + subtitle + refresh icon) + list of 4 cards.
class WebAnnouncementSkeletonView extends StatelessWidget {
  const WebAnnouncementSkeletonView({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmer(
      child: SingleChildScrollView(
        padding: WebResponsiveUtils.getResponsivePadding(context),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          _SkeletonBlock(width: 220, height: 32),
                          SizedBox(height: 10),
                          _SkeletonBlock(width: 360, height: 16),
                        ],
                      ),
                    ),
                    const _SkeletonBlock(width: 36, height: 36, radius: 18),
                  ],
                ),
                const SizedBox(height: 24),
                // 4 announcement card skeletons
                for (int i = 0; i < 4; i++) ...[
                  const _WebAnnouncementCardSkeleton(),
                  if (i < 3) const SizedBox(height: 16),
                ],
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
