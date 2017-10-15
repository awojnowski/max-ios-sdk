use_frameworks!

target 'MAX' do

  source 'https://github.com/MAXAds/Specs.git'
  pod 'MRAID', '1.0.1'
  pod 'VAST', '1.0.0'

  post_install do |installer|
    installer.pods_project.build_configuration_list.build_configurations.each do |configuration|
      configuration.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
    end
  end

  target 'MAXTests' do
    inherit! :search_paths

    source 'https://github.com/CocoaPods/Specs.git'
    pod 'Quick'
    pod 'Nimble'
  end

end
