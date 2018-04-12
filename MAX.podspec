Pod::Spec.new do |s| 
  s.name             = 'MAX'
  s.version          = '1.1.0'
  s.summary          = 'Parallel bidding wrapper for mobile ads.'
  s.description      = <<-DESC
MAX pre-bid wrapper that can be used alongside your existing mobile advertising SSP ad calls,
giving you the ability to work with multiple programmatic buyers and exchanges in parallel at any
point in your existing waterfall.
                       DESC
  s.homepage         = 'https://app.maxads.io'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'MAX' => 'hello@maxads.co' }
  s.source           = { :git => 'git@github.com:MAXAds/max-ios-sdk.git', :tag => s.version.to_s }
  s.xcconfig         = { 'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2' }
  s.libraries        = 'xml2' 
  s.swift_version    = "4.0" 
 
  s.requires_arc     = true 
  s.platform         = :ios, '8.0'
  s.static_framework = true

  s.subspec 'Core' do |d|
    d.dependency 'SnapKit', '4.0'
    d.dependency 'mopub-ios-sdk', '>= 4.17.0'
    d.source_files = [
     'MAX/UmbrellaHeader/*.{h,m,swift}',
     'MAX/Core/**/*.{h,m,swift}',
     'MAX/ThirdParty/MoPub/**/*'
   ]
  end

  s.subspec 'Facebook' do |d|
    d.dependency 'MAX/Core'
    d.dependency 'FBAudienceNetwork', '4.27.2'
    d.source_files = ['MAX/ThirdParty/*.swift', 'MAX/ThirdParty/Facebook/**/*']
  end

  s.subspec 'Vungle' do |d|
    d.dependency 'MAX/Core'
    d.dependency 'VungleSDK-iOS', '5.4.0'
    d.source_files = ['MAX/ThirdParty/*.swift', 'MAX/ThirdParty/Vungle/**/*']
    d.xcconfig = { 'SWIFT_INCLUDE_PATHS' => '$(PODS_TARGET_SRCROOT)/MAX/ThirdParty/Vungle/ModuleMap' }
    d.preserve_paths = 'MAX/ThirdParty/Vungle/ModuleMap/module.modulemap'
  end

end
