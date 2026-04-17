abstract class SDKPresentationStyle {
  const SDKPresentationStyle();

  Map<String, dynamic> toJson();
}

class PushStyle extends SDKPresentationStyle {
  const PushStyle();

  @override
  Map<String, dynamic> toJson() => {
    'type': 'push',
  };
}

class PresentStyle extends SDKPresentationStyle {
  const PresentStyle();

  @override
  Map<String, dynamic> toJson() => {
    'type': 'present',
  };
}

class BottomSheetStyle extends SDKPresentationStyle {
  final double? maxHeightDp;

  const BottomSheetStyle({this.maxHeightDp});

  @override
  Map<String, dynamic> toJson() => {
    'type': 'bottomSheet',
    'maxHeightDp': maxHeightDp,
  };
}