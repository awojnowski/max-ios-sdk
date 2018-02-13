platform :ios, '9.0'
use_frameworks!

source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/MAXAds/Specs.git'

target 'MAX' do

# MAX repos
	
  pod 'MAXBase', '1.0.0'

# Third party repos

	pod 'SwiftLint' 
	pod 'mopub-ios-sdk', '>= 4.18.0'
	pod 'FBAudienceNetwork', '= 4.27.2'

	target 'MAXTests' do
		inherit! :search_paths

		pod 'Quick'
		pod 'Nimble'
	end

end
