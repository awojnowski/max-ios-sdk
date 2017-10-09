Pod::Spec.new do |spec|
  spec.name     = 'MAX'
  spec.version  = '0.6.0'
  spec.summary  = 'MaxAds parallel bidding SDK.'
  spec.homepage = 'https://app.maxads.io'
  spec.license  = { :type => 'MIT', :file => 'LICENSE' }
  spec.author   = { 'MAX' => 'hello@maxads.co' }
  spec.source   = { :git => 'git@github.com:MAXAds/MAX.git', :tag => s.version.to_s }

  spec.ios.deployment_target = '8.0'

  spec.default_subspec = 'core'
  spec.subspec 'core' do |core| 
  	core.source_files        = 'MAX/**/*'
  	core.resources           = ['MAX/SKFramework.private.modulemap', 'MAX/SKFramework']
  	core.pod_target_xcconfig = {'SWIFT_INCLUDE_PATHS' => '$(SRCROOT)/MAX/MAX/SKFramework', 'MODULEMAP_PRIVATE_FILE' => '$(SRCROOT)/MAX/MAX/SKFramework.private.modulemap'}
  	core.xcconfig            = { 'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2' }
  	core.libraries           = 'xml2'
  end

  spec.subspec 'mopub' do |mopub| 
    mopub.dependency 'mopub-ios-sdk', '~>4.11.1'
    mopub.source_files = ['Adapters/mopub/*']
  end

  spec.subspec 'facebook' do |fb|
    fb.dependency 'FBAudienceNetwork', '~>4.26.0'
    fb.source_files = ['Adapters/facebook/*']
  end
end
