#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint gd_payment_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'gd_payment_sdk'
  s.version          = '1.0.0'
  s.summary          = 'GD Payment SDK Flutter Plugin'
  s.description      = <<-DESC
Flutter plugin for GD Payment SDK with native iOS and Android support.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'

  # Pod installation settings
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # XCFrameworks
  s.vendored_frameworks = [
    'Frameworks/GeideaPaymentSDK.xcframework',
    'Frameworks/CardScan.xcframework',
  ]

  # If you need to preserve paths
  s.preserve_paths = [
    'Frameworks/GeideaPaymentSDK.xcframework',
    'Frameworks/CardScan.xcframework',
  ]
end
