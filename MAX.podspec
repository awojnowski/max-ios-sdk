Pod::Spec.new do |s|
  s.name             = 'MAX'
  s.version          = '0.6.1'
  s.summary          = 'Parallel bidding wrapper for mobile ads.'
  s.description      = <<-DESC
MAX pre-bid wrapper that can be used alongside your existing mobile advertising SSP ad calls, 
giving you the ability to work with multiple programmatic buyers and exchanges in parallel at any 
point in your existing waterfall.
                       DESC

  s.homepage         = 'https://app.maxads.io'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'MAX' => 'hello@maxads.co' }
  s.source           = { :git => 'git@github.com:MAXAds/MAX.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.default_subspec = 'Core'
  s.subspec 'Core' do |d| 
    d.dependency 'MRAID', '1.0.0'
    d.dependency 'VAST', '1.0.0'
  	d.source_files = 'MAX/**/*'
  end

  s.subspec 'MoPub' do |d| 
  	d.dependency 'mopub-ios-sdk', '~>4.17.0'
  	d.source_files = ['Adapters/mopub/*']
  end

end
