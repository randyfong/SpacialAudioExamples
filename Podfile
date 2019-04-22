platform :ios, '11.4'

workspace '3rdPartySamples'
project 'CodeSamples/CodeSamples.xcodeproj'

inhibit_all_warnings!

pod 'BoseWearable', :git => 'git@github.com:BoseWCTC/BoseWearable-iOS.git', :branch => 'master'
pod 'BoseWearable/SearchUI', :git => 'git@github.com:BoseWCTC/BoseWearable-iOS.git', :branch => 'master'

# Required: The following three pods are dependencies of the BoseWearable library.
pod 'BLECore', :git => 'git@github.com:BoseWCTC/BoseWearable-iOS.git', :branch => 'master'
pod 'Logging', :git => 'git@github.com:BoseWCTC/BoseWearable-iOS.git', :branch => 'master'

pod 'SwiftLint'

target 'SpatialAudio' do
  use_frameworks!
end
