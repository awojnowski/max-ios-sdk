#
# Be sure to run `pod lib lint MAX.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MAX'
  s.version          = '0.1.0'
  s.summary          = 'Parallel bidding wrapper for mobile ads.'
  s.description      = <<-DESC
MAX pre-bid wrapper that can be used alongside your existing mobile advertising SSP ad calls, 
giving you the ability to work with multiple programmatic buyers and exchanges in parallel at any 
point in your existing waterfall.
                       DESC

  s.homepage         = 'http://maxads.co'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'MAX' => 'hello@maxads.co' }
  s.source           = { :git => 'git@github.com:MAXAds/MAX.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'MAX/Classes/**/*'
  
  s.dependency 'mopub-ios-sdk', '~> 4.11.1'
  s.dependency 'XCGLogger', '~> 4.0.0'

  s.xcconfig = { 'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2' }
  s.libraries = 'xml2'

end
