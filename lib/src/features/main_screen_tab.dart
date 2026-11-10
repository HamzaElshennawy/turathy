import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Active bottom-navigation tab. Home is 0.
final mainScreenTabIndexProvider = StateProvider<int>((ref) => 0);
