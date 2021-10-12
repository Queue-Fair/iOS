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
    
    /* Called by the Adapter when settings could not be downloaded.
     * This will normally be becaus the device does not have internet access.
     * You would normally start the protected activity in this case.
     */
    func queueFairOnNoSettings() {
        ViewController.info("QFD: No Settings");
        launchProtectedScene()
    }

    /* Called by the Adapter when an error has occurred. This will
     * normally be because the device has lost internet access during
     * a queue process.  You would normally start the protected activity
     * in this case.
     */
    func queueFairOnError(_ message: String) {
        ViewController.info("QFD: Error "+message);
        launchProtectedScene()
    }
    
    /*
     * Called by the Adapter when a visitor has been Passed by the queue,
     * immediately passed by SafeGuard, or is Repassed because they have
     * already been passed and the queue's Passed Lifetime has not expired.
     */
    func queueFairOnPass(_ passType: String) {
        ViewController.info("QFD: Pass "+passType);
        launchProtectedScene()
    }
    
    /* Called by the Adapter when it is about to show a Queue Page, Hold Page,
     * PreSale Page or PostSale Page to your user.
     */
    func queueFairOnShow() {
        ViewController.info("QFD: Showing");
    }
    
    /* Called when the user uses the Back button to leave the queue
     * (when a NavigationController is present for the parent ViewController),
     * navigates to another app, or their phone goes to sleep.  In this
     * case the user's place in the queue is saved, and the queue process
     * will continue when the user comes back to the app automatically.
     */
    func queueFairOnAbandon(_ cause: String) {
        ViewController.info("QFD: Abandon: "+cause);
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
        //QueueFairConfig.debug = true;
        
        // Uncommenting the following will force a fresh download
        // of your account and queuesettings every time a QueueFairClient is run.
        // Please set this to at least 5 for release versions of your app.
        QueueFairConfig.settingsCacheLifetimeMinutes = 0;
        
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

