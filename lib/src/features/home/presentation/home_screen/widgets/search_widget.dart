/// {@category Presentation}
///
/// A specialized header widget that coordinates search input and category filtering.
/// 
/// [SearchWidget] is a stateful component that manages a local text buffer with 
/// built-in debouncing to prevent excessive state updates during typing. It 
/// also provides a entry point for the advanced [FilterWidget] modal.
/// 
/// Logic:
/// - **Debouncing**: Updates the global [searchQueryProvider] only after 500ms 
///   of inactivity.
/// - **State Sync**: Reactively updates the UI (clear button visibility) based on 
///   the controller's text.
/// - **Theming**: Implements a 'floating' design with 16.0 border radius and 
///   low-opacity shadows.
library;

import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:turathy/src/core/constants/app_sizes.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/features/search/presentation/widgets/filter_widget/filter_widget.dart';
import '../controllers/search_provider.dart';

/// A composite search bar and filter button for the home screen.
class SearchWidget extends ConsumerStatefulWidget {
  /// Creates a [SearchWidget].
  const SearchWidget({super.key});

  @override
  ConsumerState<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends ConsumerState<SearchWidget> {
  /// Local controller for handling standard text input.
  final TextEditingController _controller = TextEditingController();

  /// Internal timer used to throttle the [searchQueryProvider] updates.
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel(); // Essential: prevent timers from firing after unmount
    super.dispose();
  }

  /// Internal: Handles text changes with a 500ms debounce buffer.
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // Syncs the local query with the global provider which drives result filtering
      ref.read(searchQueryProvider.notifier).state = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Search Input Field ──────────────────────────────────────────────
        Expanded(
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: Colors.grey.shade400,
                  size: 26,
                ),
                gapW12,
                Expanded(
                  child: TextField(
                    textAlignVertical: TextAlignVertical.center,
                    controller: _controller,
                    onChanged: (val) {
                      _onSearchChanged(val);
                      setState(() {}); // Logic: Refresh to show/hide 'clear' button
                    },
                    decoration: InputDecoration(
                      hintText: AppStrings.search.tr(),
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _controller.clear();
                                _onSearchChanged('');
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        gapW12,

        // ── Filter Entry Point ──────────────────────────────────────────────
        Container(
          height: 52,
          width: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () {
              // Action: Invoke the global filter system in a bottom sheet
              showModalBottomSheet(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                sheetAnimationStyle: AnimationStyle(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) => const FilterWidget(
                  contentType: FilterContentType.auction,
                ),
              );
            },
            icon: Icon(
              Icons.tune_rounded,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }
}
