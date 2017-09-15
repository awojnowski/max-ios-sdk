SHELL=/bin/bash

test: 
	set -o pipefail && xcodebuild -project MAX.xcodeproj -scheme MAX -destination 'platform=iOS Simulator,name=iPhone 7' test | xcpretty

test-raw:
	xcodebuild -project MAX.xcodeproj -scheme MAX -destination 'platform=iOS Simulator,name=iPhone 7' test

check-version:
	bin/check-version