# Low Effort Sensing
A platform for low-effort data contributions, supported on iOS and Apple Watch.

# Installation
1. Make sure you have an iPhone with an Apple Watch paired to the phone
2. Clone the repo and open in XCode
3. Run application and wait for installation to complete
4. On iPhone, launch the Watch application and install low-effort-sensing WatchKit App. Wait for app to install on Watch.

# Development
## Development on iOS
1. You will need 5 separate proivsioning profiles to build on device (iPhone Application, Today Widget, Watch Application, Watch Extension, and Notification Extension). Please talk to either Kapil or Yongsung to obtain these.
2. Open **low-effort-sensing.xcworkspace** in Xcode. Navigate to **LES Widget/TodayViewController.swift** and ensure the following lines are correctly commented/uncommented:
    ```
    // App Group for Sharing Data (MUST BE CHANGED DEPENDING ON BUILD)
    let appGroup = "group.com.delta.les-debug" // for debug builds
    // let appGroup = "group.com.delta.les"       // for enterprise distribution builds

    // Containing Application for Parse (MUST BE CHANGED DEPENDING ON BUILD)
    let containingApplication = "edu.northwestern.delta.les-debug.widget" // for debug builds
    // let containingApplication = "edu.northwestern.delta.les.widget"       // for enterprise distribution builds
    ```
    Repeat for **low-effort-sensing/AppDelegate.swift**:
    ```
    // App Group for Sharing Data (MUST BE CHANGED DEPENDING ON BUILD)
    let appGroup = "group.com.delta.les-debug" // for debug builds
    // let appGroup = "group.com.delta.les"       // for enterprise distribution builds
    ```
3. Run the application.

## Development on Parse Cloud Code
1. Make sure you have [Node](https://nodejs.org/en/) installed.
2. Navigate to low-effort-sensing/low-effort-sensing-cloud and run `npm install`.
3. Run `gulp` to begin development.
4. To deploy Parse cloud code, run `gulp deploy`. Note that code must be linted before deployment.

# Enterprise Deployment
1. Make sure you have all 5 enterprise provisioning profiles and the NU enterprise deployment certificate. Please talk to either Kapil or Yongsung to obtain these.
2. Open **low-effort-sensing.xcworkspace** in Xcode. Navigate to **LES Widget/TodayViewController.swift** and ensure the following lines are correctly commented/uncommented:
    ```
    // App Group for Sharing Data (MUST BE CHANGED DEPENDING ON BUILD)
    // let appGroup = "group.com.delta.les-debug" // for debug builds
    let appGroup = "group.com.delta.les"       // for enterprise distribution builds

    // Containing Application for Parse (MUST BE CHANGED DEPENDING ON BUILD)
    // let containingApplication = "edu.northwestern.delta.les-debug.widget" // for debug builds
    let containingApplication = "edu.northwestern.delta.les.widget"       // for enterprise distribution builds
    ```
    Repeat for **low-effort-sensing/AppDelegate.swift**:
    ```
    // App Group for Sharing Data (MUST BE CHANGED DEPENDING ON BUILD)
    // let appGroup = "group.com.delta.les-debug" // for debug builds
    let appGroup = "group.com.delta.les"       // for enterprise distribution builds
    ```
3. Close Xcode and navigate to the **low-effort-sensing** folder in the repository.
4. Run `chmod +x LES_Enterprise_export.sh` to make the shell script executable and then `./LES_Enterprise_export.sh` to execute. This will start cleaning, archiving, and exporting LES.
5. Once the process is complete, the *.ipa* file can be found in **low-effort-sensing/low-effort-sensing.ipa/low-effort-sensing.ipa**. To deploy to users, we recommend using [Diwai](https://www.diawi.com/).