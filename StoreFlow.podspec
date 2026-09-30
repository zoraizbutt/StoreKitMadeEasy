Pod::Spec.new do |s|
  s.name             = 'StoreFlow'
  s.version          = '1.0.0'
  s.summary          = 'A modern, lightweight StoreKit 2 In-App Purchase framework for Swift.'
  s.description      = <<-DESC
StoreFlow is a lightweight, pure Swift In-App Purchase library built on top of Apple's StoreKit 2.
It handles asynchronous transaction management, auto-renewable subscriptions, free trials,
promotional offers, native refund sheets, sandbox testing, and real-time entitlement tracking.
                       DESC

  s.homepage         = 'https://github.com/username/StoreFlow'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Zoraiz Hassan' => 'developer@example.com' }
  s.source           = { :git => 'https://github.com/username/StoreFlow.git', :tag => s.version.to_s }

  s.ios.deployment_target = '15.0'
  s.osx.deployment_target = '12.0'
  s.watchos.deployment_target = '8.0'
  s.tvos.deployment_target = '15.0'

  s.swift_versions = ['5.9', '5.10', '6.0']
  s.source_files = 'Sources/StoreFlow/**/*.swift'
  s.frameworks = 'StoreKit', 'Combine', 'SwiftUI'
end
