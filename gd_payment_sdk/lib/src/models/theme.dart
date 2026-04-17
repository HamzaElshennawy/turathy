class SDKTheme {
  final String? primaryColor;
  final String? secondaryColor;
  final String merchantLogoPath;

  const SDKTheme({
    this.primaryColor,
    this.secondaryColor,
    required this.merchantLogoPath,
  });

  Map<String, dynamic> toJson() => {
    'primaryColor': primaryColor,
    'secondaryColor': secondaryColor,
    'merchantLogoPath': merchantLogoPath,
  };
}
