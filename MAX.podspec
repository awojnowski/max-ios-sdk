#
#
#

Pod::Spec.new do |s|
  s.name             = 'MAX'
  s.version          = '0.2.1'
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

  s.default_subspec = 'base'
  s.subspec 'base' do |d| 
	#	 
	# No SSP 
	#

  	d.source_files = 'MAX/**/*'
  	d.resources = 'MAX/SKFramework.private.modulemap', 'MAX/SKFramework'
  	d.pod_target_xcconfig = {'SWIFT_INCLUDE_PATHS' => '$(SRCROOT)/MAX/MAX/SKFramework', 'MODULEMAP_PRIVATE_FILE' => '$(SRCROOT)/MAX/MAX/SKFramework.private.modulemap'}
  
  	d.xcconfig = { 'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2' }
  	d.libraries = 'xml2'
  end

  s.subspec 'mopub' do |m| 
	m.dependency 'mopub-ios-sdk', '~>4.11.1'
	m.source_files = 'Adapters/mopub/*'
  end

end
