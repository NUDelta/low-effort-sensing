#!/bin/bash
xcodebuild clean \
    -workspace low-effort-sensing.xcworkspace/ \
    -scheme low-effort-sensing
    
xcodebuild \
    -workspace low-effort-sensing.xcworkspace \
    -scheme low-effort-sensing \
    -archivePath build/low-effort-sensing.xcarchive \
    archive 

xcodebuild \
	-exportArchive \
	-archivePath build/low-effort-sensing.xcarchive \
	-exportOptionsPlist exportEnterprise.plist \
	-exportPath low-effort-sensing.ipa
