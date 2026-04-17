enum SDKLanguage {
  english,
  arabic;

  String toJson() => name.toUpperCase();
}

enum Region {
  egy,
  ksa,
  uae;

  String toJson() => name.toUpperCase();
}
