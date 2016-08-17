# Low Effort Sensing
A platform for low-effort data contributions, supported on iOS and Apple Watch

# Installation
1. Make sure you have an iPhone with an Apple Watch paired to the phone
2. Clone the repo and open in XCode
3. Run application and wait for installation to complete
4. On iPhone, launch the Watch application and install low-effort-sensing WatchKit App. Wait for app to install on Watch.

# Development on iOS Application
1. You will need 3 separate proivsioning profiles to build on device (iPhone Application, Today Widget, Watch Application). Please talk to either Kapil or Yongsung to obtain these.
2. Open Xcode and run application

# Development on Parse Cloud Code
1. Make sure you have [Node](https://nodejs.org/en/) installed.
2. Navigate to low-effort-sensing/low-effort-sensing-cloud and run `npm install`.
3. Run `gulp` to begin development.
4. To deploy Parse cloud code, run `gulp deploy`. Note that code must be linted before deployment.
