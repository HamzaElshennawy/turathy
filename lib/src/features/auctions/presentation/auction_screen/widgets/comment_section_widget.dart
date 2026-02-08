import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/helper/cache/cached_variables.dart';
import 'package:turathy/src/features/auctions/domain/auction_model.dart';

import '../../../../../core/constants/app_strings/app_strings.dart';
import '../../../../../core/helper/socket/socket_exports.dart';

class CommentsSectionWidget extends ConsumerStatefulWidget {
  final AuctionModel auction;
  const CommentsSectionWidget(this.auction, {super.key});

  @override
  ConsumerState createState() => _CommentsSectionWidgetState();
}

class _CommentsSectionWidgetState extends ConsumerState<CommentsSectionWidget>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false; // Track whether the list is collapsed or expanded
  late final AnimationController _controller;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<SocketComment> _comments = [];
  final _commentController = TextEditingController();
  bool _isCommentFieldVisible = true;

  @override
  void initState() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 75,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
        );
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _addComment(SocketComment comment) {
    _comments.add(comment);
    _listKey.currentState?.insertItem(_comments.length - 1);
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 75,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(auctionEndedProvider, (previous, next) {
      _comments.clear();
    });
    final commentsValue = ref.watch(newCommentProvider);
    ref.listen(newCommentProvider, (prev, next) {
      next.whenData((data) {
        if (data.allComments.isNotEmpty) {
          final newComment = data.allComments.last;
          _addComment(newComment);
        }
      });
    });

    if (commentsValue.valueOrNull != null) {
      if (commentsValue.value!.allComments.isNotEmpty) {
        _comments = commentsValue.value!.allComments;
      } else {
        _comments = widget.auction.auctionComments ?? [];
      }
    } else {
      _comments = widget.auction.auctionComments ?? [];
    }

    return AnimatedContainer(
      margin: EdgeInsets.all(
        _isCollapsed ? 0 : 8,
      ), // Add margin when the list is expanded

      padding: EdgeInsets.all(
        _isCollapsed ? 0 : 8,
      ), // Add padding when the list is expanded
      decoration: BoxDecoration(
        gradient: _isCollapsed
            ? null
            : LinearGradient(
                colors: [
                  Theme.of(context).primaryColorDark.withAlpha(220),
                  Colors.black54,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
        borderRadius: BorderRadius.circular(20),
      ),
      duration: const Duration(milliseconds: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.comments.tr(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).primaryColorLight,
                ),
              ),
              IconButton(
                icon: AnimatedIcon(
                  icon: AnimatedIcons.close_menu,
                  color: Theme.of(context).primaryColorLight,
                  progress: _controller,
                ),
                onPressed: () {
                  setState(() {
                    _isCollapsed = !_isCollapsed;
                    if (_isCollapsed) {
                      _controller.forward().then(
                        (value) => _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent + 75,
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                        ),
                      );
                    } else {
                      _controller.reverse().then(
                        (value) => _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent + 75,
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                        ),
                      );
                    }
                  });
                },
              ),
            ],
          ),
          Expanded(
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 300), // Animation duration
              crossFadeState: _isCollapsed
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: const SizedBox.shrink(), // Collapsed state
              secondChild: _comments.isEmpty
                  ? Text(
                      'لا يوجد تعليقات',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).primaryColorLight,
                      ),
                    )
                  : AnimatedList(
                      key: _listKey,
                      controller: _scrollController,
                      shrinkWrap: true,
                      initialItemCount: _comments.length,
                      itemBuilder: (context, index, animation) {
                        return SizeTransition(
                          sizeFactor: animation,
                          child: ListTile(
                            title: Text(
                              _comments[index].user.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Theme.of(context).primaryColorLight,
                                  ),
                            ),
                            subtitle: Text(
                              _comments[index].comment,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(color: Colors.white),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          AnimatedOpacity(
            onEnd: () {
              setState(() {
                _isCommentFieldVisible = !_isCollapsed;
              });
            },
            opacity: _isCollapsed ? 0 : 1,
            duration: const Duration(milliseconds: 400),
            child: Visibility(
              visible: _isCommentFieldVisible,
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          suffixIcon: IconButton(
                            color: Theme.of(context).primaryColorDark,
                            icon: const Icon(Icons.send),
                            onPressed: () {
                              if (_commentController.text.isNotEmpty) {
                                ref
                                    .read(socketActionsProvider)
                                    .sendComment(
                                      widget.auction.id ?? 0,
                                      CachedVariables.userId!,
                                      _commentController.text,
                                    );
                                _commentController.clear();
                              }
                            },
                          ),
                          hintText: AppStrings.writeComment.tr(),
                          hintStyle: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(color: Colors.black),
                          filled: true,
                          fillColor: Colors.white70,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            ref
                                .read(socketActionsProvider)
                                .sendComment(
                                  widget.auction.id ?? 0,
                                  CachedVariables.userId!,
                                  value,
                                );
                            _commentController.clear();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 75),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
