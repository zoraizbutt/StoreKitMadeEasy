Pod::Spec.new do |s|
  s.name             = 'StoreKitMadeEasy'
  s.version          = '1.0.0'
  s.summary          = 'A lightweight, modern StoreKit 2 In-App Purchase framework for Swift.'
  s.description      = <<-DESC
StoreKitMadeEasy is a pure Swift In-App Purchase library built on top of Apple's StoreKit 2.
It simplifies StoreKit 2 implementation with automatic transaction listening, JWS verification,
subscription lifecycle tracking, free trial eligibility checks, native refund and subscription
management sheets, and offline SwiftUI preview mocking.
                       DESC

  s.homepage         = 'https://github.com/zoraizbutt/StoreKitMadeEasy'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Zoraiz Hassan' => 'developer@example.com' }
  s.source           = { :git => 'https://github.com/zoraizbutt/StoreKitMadeEasy.git', :tag => s.version.to_s }

  s.ios.deployment_target = '15.0'
  s.osx.deployment_target = '12.0'

  s.swift_versions = ['5.9', '5.10', '6.0']
  s.source_files = 'Sources/StoreKitMadeEasy/**/*.swift'
  s.frameworks = 'StoreKit', 'Combine', 'SwiftUI'
end
