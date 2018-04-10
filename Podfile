platform :ios, '8.0'

source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/MAXAds/Specs.git'

def common_deps

  use_frameworks!

  pod 'SwiftLint'
  pod 'mopub-ios-sdk', '>= 4.18.0'
  pod 'SnapKit', '~> 4.0'


# Direct 

  pod 'FBAudienceNetwork', '= 4.27.2'
  pod "VungleSDK-iOS", "5.4.0"
 
end

target 'MAX' do

  common_deps

  target 'MAXTests' do
    inherit! :search_paths

    pod 'Quick'
    pod 'Nimble'
  end


end



