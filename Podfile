# Uncomment the next line to define a global platform for your project
# platform :ios, '11.0'

target 'GithubStarsSample' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for GithubStarsSample
	
  # Rx
  pod 'ReactorKit', '2.1.0'
  pod 'RxSwift', '5.1.1'
  pod 'RxCocoa', '5.1.1'
  pod 'RxDataSources', '4.0.1'
  pod 'RxOptional', '4.1.0'
  pod 'RxViewController', '1.0.0'
  pod 'RxKeyboard'
  
  # Database
  pod 'Realm', '~> 10.18'
  pod 'RealmSwift', '~> 10.18'
  
  # Util
  pod 'Toaster'
  pod 'Then'
  
  # DI
  pod 'Pure'

  # UI
  pod 'SnapKit'

  # Networking
  pod 'Alamofire', '5.2.1'
  pod 'Moya'
  pod 'Moya/RxSwift', '~> 14.0'
  
  # Image Cache
  pod 'Kingfisher', '~> 5.0'

  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '11.0'
      end
    end
  end
end


