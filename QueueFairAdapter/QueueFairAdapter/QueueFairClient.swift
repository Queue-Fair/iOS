//
//  QueueFairClient.swift
//  QueueFairDemo
//
//  Created by Matt King on 10/3/2021.
//  For more information see https://queue-fair.com
//

import Foundation
import SystemConfiguration
import UIKit
import WebKit

public protocol QueueFairClientDelegate {

    /* Remote settings not used by this Adapter.
    func queueFairOnNoSettings();
    */
    
    func queueFairOnError(_ message: String);
    
    func queueFairOnPass(_ passType: String);
    
    func queueFairOnShow();
    
    func queueFairOnAbandon(_ cause: String);
    
    func queueFairOnJoin(_ request: Int);
    
}

public class QueueFairClient {
    
    var parent : UIViewController
    var queueServerDomain : String?
    var accountSystemName : String
    var queueSystemName : String
    var passedLifetimeMinutes : Int = -1
    var variant : String?
    var delegate : QueueFairClientDelegate
    var d = false;
    var adapter : QueueFairAdapter?
    var service : QueueFairIOSService?
    
    static var queuePageLoc : String?
    
    public init(parent: UIViewController, queueServerDomain: String?, accountSystemName: String, queueSystemName: String, variant: String?, passedLifetimeMinutes: Int = -1, delegate: QueueFairClientDelegate) {
        self.parent = parent;
        self.queueServerDomain = queueServerDomain;
        if(queueServerDomain != nil) {
            self.queueServerDomain = queueServerDomain!;
        } else {
            self.queueServerDomain = accountSystemName + ".queue-fair.net";
        }
        self.accountSystemName = accountSystemName;
        self.queueSystemName = queueSystemName;
        self.variant = variant;
        self.passedLifetimeMinutes = passedLifetimeMinutes;
        self.delegate = delegate;
        
        QueueFairConfig.account = accountSystemName;
        d = QueueFairConfig.debug;
    }
    
    public func go() {
        let service = QueueFairIOSService();
        let adapter = QueueFairAdapter(service, self);
        self.adapter = adapter;
        self.service = service;
        adapter.variant = self.variant;
        adapter.userAgent = "QueueFair iOS Adapter";
        adapter.requestedURL = "javascript:void(0)";
        adapter.setUIDFromCookie();

        let queue : [String: Any] = [
            "name" : queueSystemName,
            "displayName" : queueSystemName,
            "queueServer" : queueServerDomain!,
            "adapterServer" : queueServerDomain!,
            "passedLifetimeMinutes" : String(passedLifetimeMinutes)
        ];
        
        gotQueue(queue);
    }
    
    func onError(_ message: String) {
        DispatchQueue.main.async {
            self.delegate.queueFairOnError(message);
        }
    }
    
    func onPass(_ passType: String) {
        DispatchQueue.main.async {
            self.delegate.queueFairOnPass(passType);
        }
    }
    
    func onAbandon(_ cause: String) {
        DispatchQueue.main.async {
            self.delegate.queueFairOnAbandon(cause);
        }
    }
    
    func onJoin(_ request: Int) {
        DispatchQueue.main.async {
            self.delegate.queueFairOnJoin(request);
        }
    }
    
    func gotRedirect(_ location: String) {
        QueueFairClient.queuePageLoc = location
        
        DispatchQueue.main.async {
            
            let queueFairViewController = QueueFairViewController();
            queueFairViewController.client = self;
            
            if(self.parent.navigationController != nil) {
                self.parent.navigationController!.pushViewController(queueFairViewController,animated: true);
                return;
            }
            
            queueFairViewController.modalPresentationStyle = .fullScreen;
            self.parent.present(queueFairViewController, animated: true, completion: nil)
        }
    }
    
    func onPassFromQueue(_ target: String,_ passType: String,_ when: Int,_ pl: Int) {
        if(d) {
            QueueFairClient.info("Passed by queue "+passType+" t: "+target);
        }
        let i = QueueFairAdapter.lastIndexOf(target,"qfqid=");
        if(i == -1) {
            self.delegate.queueFairOnError("Target does not contain Passed String");
            return;
        }
        let passedString = QueueFairAdapter.substring(target,i,nil);

        let passedLifetimeMinutes = adapter?.conditionalSetPassedLifetime(pl);
        
        service!.setCookie("QueueFair-Pass-"+queueSystemName, passedString, passedLifetimeMinutes!*60,nil);
        
        onPass(passType);
    }
    
    public static func clearAdapter() {
        QueueFairIOSService.clear();
    }
    
    public static func clearQueueFair() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        print("[WebCacheCleaner] All cookies deleted")
        
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
                print("[WebCacheCleaner] Record \(record) deleted")
            }
        }
    }
    
    func gotQueue(_ queue: [String:Any]) {
        let cookie = service?.getCookie("QueueFair-Pass-"+queueSystemName);
        if(cookie != nil && adapter!.validateCookie(queue, cookie!)) {
            DispatchQueue.main.async {
                self.delegate.queueFairOnPass("Repass");
            }
            return;
        }
        
        adapter!.consultAdapter(queue);
    }
    
    static func info(_ message: String) {
        print("QFC: "+message);
    }
    
}
