# 3rd Party Bose Sample Applications for iOS


This repo contains the sample applications for iOS which demonstrate various ways of working with Bose hardware.

## Applications

#### Hands Free

This application shows how to connect to a hands free bluetooth device and route audio to/from the device.

#### Spatial Audio

This applications shows how to setup and listen to audio in a virtual 3D space. It shows how to use the basics of the BoseWearable API to get orientation information from a Bose BLE device and use that information to position a virtual speaker in space.

## Building & Running

### CocoaPods

Note that [CocoaPods](http://cocoapods.org/) is required to build the sample apps. You can install it with the following command:

    gem install cocoapods

### Building & Running

To run the sample apps, open a Terminal in the root of the clone, then run the following commands:

    # Assuming you are in the root of 3rdPartySamples-iOS

    $ git checkout master

    $ cd 3rdPartySamples-iOS
    
    $ pod install

    $ open 3rdPartySamples.xcworkspace
    
Within Xcode, select the desired target, build and run.

