import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../home/data/search_repository.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  final query = ref.watch(searchQueryProvider);
  log('Search Query in Provider: "$query"');
  if (query.isEmpty) {
    return [];
  }

  // Debouncing logic is handled in the UI (SearchWidget).
  // No need for delay here.

  final repository = ref.watch(searchRepositoryProvider);
  log('Calling repository.search with query: "$query"');
  return repository.search(query);
});
