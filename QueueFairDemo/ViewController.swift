//
//  ViewController.swift
//  QueueFairDemo
//
//  Created by Matt King on 10/10/2021.
//

import UIKit
import System
import QueueFairAdapter

class ViewController: UIViewController, QueueFairClientDelegate {
    
    /* Remote settings file not used by this Adapter 
    func queueFairOnNoSettings() {
        ViewController.info("QFD: No Settings");
        launchProtectedScene()
    }
    */

    /* Called by the Adapter when an error has occurred. This will
     * normally be because the device has lost internet access during
     * a queue process.  You would normally start the protected activity
     * in this case.
     */
    func queueFairOnError(_ message: String) {
        ViewController.info("QFD: Error " + message);
        launchProtectedScene()
    }
    
    /*
     * Called by the Adapter when a visitor has been Passed by the queue,
     * immediately passed by SafeGuard, or is Repassed because they have
     * already been passed and the queue's Passed Lifetime has not expired.
     */
    func queueFairOnPass(_ passType: String) {
        // If you have already told your Push Notification system to send a notification in queueFairOnAbandon(),
        // tell it to cancel the request here.
        ViewController.info("QFD: Pass " + passType);
        launchProtectedScene()
    }
    
    /* Called by the Adapter when it is about to show a Queue Page, Hold Page,
     * PreSale Page or PostSale Page to your user.
     */
    func queueFairOnShow() {
        // If you have already requested your Push Notification system to send a notification when this user
        // reaches the front of the queue in your implementation of queueFairOnAbandon(), cancel the request here.
        ViewController.info("QFD: Showing");
    }
    
    /* Called by the adapter when a user is assigned a queue position.  You can use this with
     * your notification system to send a Push Notification to a user who has closed your app
     * that they have reached the front of the queue.  See https://firebase.google.com/docs/cloud-messaging
     * and https://firebase.google.com/docs/cloud-messaging/ios/first-message for a tutorial on Push Notifications.
     * or if you wish to use Apple's own Push Notfication service, see https://developer.apple.com/documentation/usernotifications/
     */
    func queueFairOnJoin(_ request: Int) {
        // You may wish to store the request number (queue position) within your own code.  It will also be persistently
        // stored by the Adapter automatically.  You can also get the most recently assigned request number (queue position)
        // with QueueFairIOSService.getPreference("mostRecentRequestNumber") at any time
        //
        // You should wait until queueFairOnAbandon() is called to tell your Push Notification system to send a
        // notification when the visitor reaches the front of the queue.  For now just remember the request number.
        
        ViewController.info("QFD Joined with request " + String(describing: request));
    }
    
    /* Called when the user uses the Back button to leave the queue
     * (when a NavigationController is present for the parent ViewController),
     * navigates to another app, or their phone goes to sleep.  In this
     * case the user's place in the queue is saved, and the queue process
     * will continue when the user comes back to the app automatically.
     */
    func queueFairOnAbandon(_ cause: String) {
        // If you wish to send the user a notification when this user has reached the front of the queue,
        // tell your Push Notification system here, using the request number stored from queueFairOnJoin()
        ViewController.info("QFD: Abandon: " + cause);
    }    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

        
    @IBAction func continueButtonClicked(_ sender: UIButton) {
        ViewController.info("Continue Clicked");

        // Without Queue-Fair, would launch protected scene
        // or start protected operation here.
        // launchProtectedScene();
        
        // Uncommenting the following will produce debug console output.
        // Comment it out for release versions of your app.
        //QueueFairConfig.debug = true
        
        // The client requires a parent UIViewController, and an object
        // implementing the QueueFairClientDelegate protocol.
        // This is normally the same object, but does not have to be.
        // Set the accountSystemName to the Account System Name shown on
        // the Account -> Your Account page of the Queue-Fair Portal.
        // Set the queueSystemName to the System Name of the queue
        // you wish to use, shown on the Queue -> Queue Settings page
        // of the Queue-Fair Portal.
        // You can optionally provide a Variant name to provide custom
        // language, content or display for your users - or use nil if you
        // want to use the default variant for your queue.

        // This Adapter does not download queue settings from the Portal. You can set
        // a PassedLifetime here, otherwise the Queue Servers will supply this at the
        // moment a Passed Cookie is to be created (recommended).
        let client = QueueFairClient(parent: self, queueServerDomain: nil, accountSystemName: "YOUR_ACCOUNT_SYSTEM_NAME", queueSystemName: "YOUR_QUEUE_SYSTEM_NAME", variant: nil, delegate:  self);
        
        //Run the adapter.
        client.go();
    }

    @IBAction func resetAdapterClicked(_ sender: UIButton) {
        // Convenience method for testing.  Resets Passed information
        // if present.  Do not expose to users in release versions of your app.
        ViewController.info("Reset Adapter Clicked");
        
        QueueFairClient.clearAdapter();
    }
    
    @IBAction func resetQueueFairClicked(_ sender: UIButton) {
        // Convenience method for testing.  Resets Queue
        // information (Cookies) if present.  Do not expose to users
        // in release versions of your app.
        ViewController.info("Reset Queue-Fair Clicked");
        
        QueueFairClient.clearQueueFair();
    }
    
    private func launchProtectedScene() {
        // Launches the protected scene - but this could be any operation
        // that you wish to protect with Queue-Fair.
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let protectedViewController = storyBoard.instantiateViewController(withIdentifier: "protectedViewController") as! ProtectedViewController
        navigationController?.pushViewController(protectedViewController,animated: true);
    }
    
    static func info(_ output: String) {
        print(output);
    }
}

