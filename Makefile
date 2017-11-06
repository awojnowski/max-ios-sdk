SHELL=/bin/bash

test: 
	set -o pipefail && xcodebuild -workspace MAX.xcworkspace -scheme MAX -destination 'platform=iOS Simulator,name=iPhone 7' test | xcpretty

test-raw:
	xcodebuild -workspace MAX.xcworkspace -scheme MAX -destination 'platform=iOS Simulator,name=iPhone 7' test

check-version:
	bin/check-version

deploy:
	bin/deploy
