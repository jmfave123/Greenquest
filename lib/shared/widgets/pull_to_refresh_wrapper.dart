import 'package:flutter/material.dart';

/// Reusable pull-to-refresh wrapper that ensures consistent theming and
/// scroll physics across the user/mobile experience.
///
/// When [wrapContent] is true (default), the widget wraps [child] inside a
/// [SingleChildScrollView] configured with an [AlwaysScrollableScrollPhysics]
/// so that the refresh gesture still works when the content is shorter than
/// the viewport.
///
/// When embedding an existing scroll view (e.g. `ListView`, `GridView`), set
/// [wrapContent] to false and make sure that scroll view uses
/// `AlwaysScrollableScrollPhysics` (or equivalent) so the refresh gesture is
/// available even when the list is short.
class PullToRefreshWrapper extends StatefulWidget {
  const PullToRefreshWrapper({
    super.key,
    required this.onRefresh,
    required this.child,
    this.padding,
    this.physics,
    this.controller,
    this.wrapContent = true,
    this.showScrollbar = false,
    this.indicatorColor,
    this.backgroundColor,
    this.displacement = 36,
    this.triggerMode = RefreshIndicatorTriggerMode.onEdge,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  final bool wrapContent;
  final bool showScrollbar;
  final Color? indicatorColor;
  final Color? backgroundColor;
  final double displacement;
  final RefreshIndicatorTriggerMode triggerMode;

  @override
  State<PullToRefreshWrapper> createState() => _PullToRefreshWrapperState();
}

class _PullToRefreshWrapperState extends State<PullToRefreshWrapper> {
  ScrollController? _internalController;

  ScrollController get _effectiveController {
    return widget.controller ?? (_internalController ??= ScrollController());
  }

  bool get _shouldDisposeController => widget.controller == null;

  ScrollPhysics get _effectivePhysics {
    final ScrollPhysics base = widget.physics ?? const BouncingScrollPhysics();
    return const AlwaysScrollableScrollPhysics().applyTo(base);
  }

  @override
  void dispose() {
    if (_shouldDisposeController && _internalController != null) {
      _internalController!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content =
        widget.wrapContent
            ? SingleChildScrollView(
              controller: _effectiveController,
              physics: _effectivePhysics,
              padding: widget.padding,
              child: widget.child,
            )
            : widget.child;

    if (widget.showScrollbar) {
      content = Scrollbar(
        controller:
            widget.wrapContent ? _effectiveController : widget.controller,
        child: content,
      );
    }

    return RefreshIndicator.adaptive(
      color: widget.indicatorColor ?? const Color(0xFF34A853),
      backgroundColor: widget.backgroundColor ?? Colors.white,
      displacement: widget.displacement,
      triggerMode: widget.triggerMode,
      onRefresh: widget.onRefresh,
      child: content,
    );
  }
}
