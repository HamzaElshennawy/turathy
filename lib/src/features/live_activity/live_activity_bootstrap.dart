import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'live_activity_controller.dart';

/// Clears a previous process's Dynamic Island / Live Activity after the first
/// frame. This does not create an activity.
class LiveActivityBootstrap extends ConsumerStatefulWidget {
  const LiveActivityBootstrap({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<LiveActivityBootstrap> createState() =>
      _LiveActivityBootstrapState();
}

class _LiveActivityBootstrapState extends ConsumerState<LiveActivityBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(liveActivityControllerProvider).clearLeftovers();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
