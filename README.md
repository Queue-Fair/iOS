---
## Queue-Fair Virtual Waiting Room iOS Adapter for iPhone, iPad and MacOS - README & Installation Guide

Queue-Fair can be added to any iOS or MacOS app easily in minutes.  This Queue-Fair module is suitable for native iOS or MacOS apps - if your app is a Web App running entirely in a browser, then the Client Side JavaScript Adapter is more suited to that.  You will need a Queue-Fair account - please visit https://queue-fair.com/free-trial if you don't already have one.  You should also have received our Technical Guide.  You can find out all about Queue-Fair at https://queue-fair.com


## About the Adapter
The iOS Adapter has two major components, the Adapter code that checks and validates your users with the Queue-Fair service, which is similar to our Server-Side Adapters, and a Queue-Fair ViewController that displays Queue, Hold, PreSale and PostSale pages to your users when they cannot be Passed immediately by SafeGuard.

These pages are displayed inside a WebView.  You can create app-specific displays by using the Portal and a named Variant for your app.

All components are encapsulated into QueueFairClient, which is the class you will use to interact with Queue-Fair.

The Adapter manages its own persistent storage to remember that particular users have been Passed by Queue-Fair, in the form of UserDefaults, and also persistent Cookies when a QueueFairViewController is launched.

Typically, you will replace a call to launch a protected activity or start a protected operation with a call to QueueFairClient, with an object that implements the QueueFairClientDelegate protocol.  This is usually - but does not have to be - the parent ViewController.  Then call queueFairClient.go().  QueueFairClient will launch a QueueFairViewController if it is necessary to show your user a Queue display, or pass the user immediately.

This distribution also includes source code for a demonstration app, QueueFairDemo.  Example code for using QueueFairClient is contained within the QueueFairDemo's ViewController.swift file.

If your vistors navigate away from a displayed Queue Page (by using the back button when present, by opening another app, or their phone going to sleep, for example), they do not lose their place in the queue - it is saved in the same way as places are saved for your web visitors.

This guide assumes you already have Xcode.  We recommend you perform the steps below to build the QueueFairDemo app, before importing the QueueFairAdapter module into your existing iOS or MacOS app.

## Building the Demo App ##

**1.** Open Xcode.  From the File menu, select New Project.  Select App, and then Next.

**2.** In the dialog that appears, name the app "QueueFairDemo", and the Organization Identifier "com.qf.demo".  The Interface should be Storyboard, and the Language Swift.  You don't need Use Core Data or Include Tests.

**3.** Build and run your empty app with the Play button to make sure it's working.

**4.** In Finder (not Xcode), Copy-and-paste (using Right-click to paste, not CMD-V) the contents of the QueueFairDemo folder in this distribution into the QueueFairDemo -> QueueFairDemo folder that has been created by Xcode, overwriting any files therein.

**5.** Go back to Xcode, and the Project Navigator on the left hand side.  Open the Main storyboard.  There are three scenes - a Navigation Controller to ensure that a Back button exists (but you don't have to use a Navigation Controller on your own apps), a main scene with three buttons, and a protected scene, which represents the activity or operation you wish to protect with Queue-Fair.

**6.** If Xcode does not automatically pick up ProtectedViewController, then from Finder drag it from your QueueFairDemo->QueueFairDemo folder to the Project Navigator, placing it underneath ViewController, and accept the default options to add the file.  The demo app will contain build errors until you add the QueueFairAdapter Framework from this distribution, as described in the next section.

## Adding the library to an existing app

**7.** In Finder, drag the QueueFairAdapter.xcodeproj contained within the QueueFairAdapter folder of this distribution into Project Navigator.  It needs to go underneath the second QueueFairDemo entry there (not the first), or if you are not building QueueFairDemo, the second appearance of the name of your app.

**8.** Now tap the first (not the second) QueueFairDemo (or NameOfYourApp) entry in Project Navigator and go to the General tab.  Scroll down until you find the Frameworks, Libraries and Embedded Content tab.  Expand this, and select the '+' button at the bottom.

**9.** In the dialog that appears, select QueueFairAdapter.framework, then Add.

**10.** Your swift files that use the Adapter will need

	import QueueFairAdapter

at the top, with the rest of any import statements.  If you are building the QueueFairDemo app, this is already present.

## Running the Adapter

**11.**  Example code with instructions on how to use the QueueFairClient in your own code is contained in QueueFairDemo's ViewController.swift in the continueClicked() method at the end, and also in the methods implemented from QueueFairClientDelegate at the top of ViewController.swift.  Typically you will construct a QueueFairClient with a ViewController instance, and an instance that implements the QueueFairClientDelegate protocol.  Usually this will be the same object.  Then call queueFairClient.go();

**15.** In the line that constucts the QueueFairClient, change the accountSystemName to the System Name for your account from the Queue-Fair Portal's Account -> Your Account page.  Also change the queueSystemName to the System Name for the queue you want to use in this app or for your protected activity/operation, visible in the Queue-Fair Portal on the Queue Settings page.  If you create a custom Variant for display in your app, also pass in the variant name here, or leave it as 'nil' to use your queue's default variant.

**16.** Build and run your app.

That's it you're done!

### To test the iOS Adapter

Use a queue that is not in use on other pages/apps, or create a new queue for testing.

#### Testing SafeGuard
Make sure your code uses the correct queue System Name, and that the Queue is set to SafeGuard.

Open the app and hit Continue.  A message will appear in the Xcode console output to indicate that you have been passed by SafeGuard, without seeing a Queue Page, and the protected activity will launch.

Use the back button on your phone/emulator.  Tap Continue again.  The message in the Xcode console output will indicate that you have been Repassed, because the Passed Lifetime for your queue has not expired, and the protected activity will launch again.


#### Testing Queue
Go back to the Portal and put the queue in Demo mode on the Queue Settings page.  Hit Make Live.  

In the App tap Reset Adapter to delete your Passed status, stored by the app.

Tap Continue.
 - Verify that you are now sent to queue.
 - When you come back to the page from the queue, verify that Xcode console output appears containing the word "Passed", and that the protected activity launches.
 - Use the back button and hit Continue again.  Verify that you are shown as "Repassed", without seeing a Queue Page a second time.

If you wish to fully clear your Passed status, then if you have been shown a Queue Page, you must tap both Reset Adapter and Reset Queue-Fair buttons.  These buttons are present in the QueueFairDemo app to help you test - you would not normally show them in a production app.


### Advanced Topics

Activation Rules and Variant Rules from the portal are not germane to this use case and are ignored.  Instead, specify the queue you wish to use and (optionally) the variant you want to display in the construction call to QueueFairClient.

Any Target settings for your queue are also not germane to this use case and are also ignored - rather you set the target within your app in the QueueFairClientListener implementation that you supply to QueueFairClient.  Any Queue Pages shown within your app will not go on to request a target page from any site.

QueueFairClient objects are not reusable - you should create a new one every time your app is about to start the protected activity/operation.

The minimum iOS version for apps using this release of the Queue-Fair iOS Adapter is 11.0.  If you need a version of this Adapter that is compatible with earlier versions of iOS, please contact Queue-Fair support.

If it is determined that a Queue, Hold, PreSale or PostSale page should be shown, the Queue-Fair Adapter will by default launch a ViewController with a whole-screen WebView in which to run any Queue Pages.

If the parent ViewController has a navigationController, the launched ViewController will be inserted into the NavigationContoller stack, and a Back button will be present when a Queue Page is shown.  The launched ViewController is removed from the navigation stack automatically when it is no longer needed.

If the parent ViewController does not have a navigationController, there is no back button.

To customise the display for your app, the easiest way is to can create a variant of your queue for use within your app in the Queue-Fair Portal, and tell your app to use it by passing its name as the variant parameter to the QueueFairClient constructor.  This means that your app users can participate in the same queue as your website visitors, but have a custom display for your app.

For finer display control, you may wish to modify QueueFairViewController.swift, which will allow you to use your own custom layouts, including iOS UI components.  For example, you may wish to use iOS UI components for the text of the queue page, with just the progress bar within a WebView.

Logging to Xcode console is disabled by default, but you can enable it with QueueFairConfig.debug = true - but please make sure it is disabled for release versions of your app.

Your Account and Queue settings are downloaded by the Adapter in normal operation.  No queue or account secrets are downloaded or used, for security reasons (as they would be accessible to a very technically skilled user).  Secrets are not necessary for this use case.

The downloaded settings are cached for up to 5 minutes by default.  You can set QueueFairConfig.settingsCacheLifetimeMinutes to 0 to download a fresh copy of the settings every time, which may be useful while you are coding - but please set this back to at least 5 for release versions of your app.

Unlike our Server-Side Adapters, The iOS adapter always works in SAFE_MODE - SIMPLE_MODE is not suitable for this use case.


## AND FINALLY

Remember we are here to help you! The integration process shouldn't take you more than an hour - so if you are scratching your head, ask us.  Many answers are contained in the Technical Guide too.  We're always happy to help!

