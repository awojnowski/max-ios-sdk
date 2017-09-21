Pod::Spec.new do |s|
  s.name             = 'MAX'
  s.version          = '0.5.0'
  s.summary          = 'Parallel bidding wrapper for mobile ads.'
  s.description      = <<-DESC
MAX pre-bid wrapper that can be used alongside your existing mobile advertising SSP ad calls, 
giving you the ability to work with multiple programmatic buyers and exchanges in parallel at any 
point in your existing waterfall.
                       DESC

  s.homepage         = 'https://maxads.io'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'MAX' => 'hello@maxads.co' }
  s.source           = { :git => 'git@github.com:MAXAds/MAX.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.default_subspec = 'core'
  s.subspec 'core' do |d| 
  	d.source_files = 'MAX/**/*'
  	d.resources = ['MAX/SKFramework.private.modulemap', 'MAX/SKFramework']
  	d.pod_target_xcconfig = {'SWIFT_INCLUDE_PATHS' => '$(SRCROOT)/MAX/MAX/SKFramework', 'MODULEMAP_PRIVATE_FILE' => '$(SRCROOT)/MAX/MAX/SKFramework.private.modulemap'}
  	d.xcconfig = { 'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2' }
  	d.libraries = 'xml2'
  end

  s.subspec 'mopub' do |d| 
	d.dependency 'mopub-ios-sdk', '~>4.11.1'
  	d.source_files = ['MAX/**/*', 'Adapters/mopub/*']
  	d.resources = ['MAX/SKFramework.private.modulemap', 'MAX/SKFramework']
  	d.pod_target_xcconfig = {'SWIFT_INCLUDE_PATHS' => '$(SRCROOT)/MAX/MAX/SKFramework', 'MODULEMAP_PRIVATE_FILE' => '$(SRCROOT)/MAX/MAX/SKFramework.private.modulemap'}
  	d.xcconfig = { 'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2' }
  	d.libraries = 'xml2'
  end

end