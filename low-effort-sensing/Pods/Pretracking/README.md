# Pretracking
Pretracking, a location manager that starts fine-grained monitoring when a user is within a region of interest, and make decision based on current context. For the moment, only distance feature is implemented by default.

[![CI Status](http://img.shields.io/travis/YK/Pretracking.svg?style=flat)](https://travis-ci.org/YK/Pretracking)
[![Version](https://img.shields.io/cocoapods/v/Pretracking.svg?style=flat)](http://cocoapods.org/pods/Pretracking)
[![License](https://img.shields.io/cocoapods/l/Pretracking.svg?style=flat)](http://cocoapods.org/pods/Pretracking)
[![Platform](https://img.shields.io/cocoapods/p/Pretracking.svg?style=flat)](http://cocoapods.org/pods/Pretracking)

## How To
- set ```latitude, longitude, radius of monitoring region```
- set ```distance``` to the region
- set ```accuracy``` of location tracking when the user is outside of the region.

Example:
```swift
setupParameters(distance: Double, latitude: Double, longitude: Double, radius: Double, accuracy: CLLocationAccuracy)
```

- modify ```notifyPeople()``` in MyPretracker.swift


## Requirements
[CocoaPods](https://guides.cocoapods.org/using/getting-started.html)

## Usage
To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation
Pretracking is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Pretracking"
```

## Future Improvements
- enable background tracking
- add local notification to the ```notifyPeople()```

## License

Pretracking is available under the MIT license. See the LICENSE file for more info.
