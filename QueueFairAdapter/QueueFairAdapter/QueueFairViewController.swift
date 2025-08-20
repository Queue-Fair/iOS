//
//  QueueFairViewController.swift
//  QueueFairDemo
//
//  Created by Matt King on 10/3/2021.
//  For more information see https://queue-fair.com
//

import Foundation
import UIKit
import WebKit


class QueueFairViewController : UIViewController, WKScriptMessageHandler {

    var webView : WKWebView!
    
    var client : QueueFairClient?
    
    var dismissing : Bool = false;
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration();
        
        let source = "function captureLog(msg) { window.webkit.messageHandlers.logHandler.postMessage(msg); } window.console.log = captureLog;"
        let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        webConfiguration.userContentController.addUserScript(script)
        // register the bridge script that listens for the output
        webConfiguration.userContentController.add(self, name: "logHandler")
        
        webView = WKWebView(frame: .zero, configuration: webConfiguration);
       // webView.uiDelegate = self;
        view = webView;
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if(QueueFairConfig.debug) {
            QueueFairViewController.info("View will disappear \(dismissing)");
        }
        if(dismissing) {
            return;
        }
        finishWebView();
        client!.onAbandon("Back Pressed");
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if(QueueFairConfig.debug) {
            QueueFairViewController.info("ViewController loaded");
        }
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        var urlStr = QueueFairClient.queuePageLoc!;
        if(QueueFairAdapter.indexOf(urlStr,"?") != -1) {
            urlStr += "&";
        } else {
            urlStr += "?";
        }

        urlStr+="qfnoredirect=true"
        if(QueueFairConfig.debug) {
            QueueFairViewController.info("Getting page from "+urlStr)
        }
        let url = URL(string: urlStr);
        let req = URLRequest(url: url!);
        webView.load(req);
    }
    
    @objc func applicationDidEnterBackground() {
        if(QueueFairConfig.debug) {
            QueueFairViewController.info("Entered background");
        }
        client!.onAbandon("Entered Background");
    }
    
    static func info(_ message: String) {
        print("QFVC: "+message);
    }
    
    func finishWebView() {
        webView.configuration.preferences.javaScriptEnabled = false;
    }
    
    func clearFromNavigation() {
        if(navigationController != nil) {
            
            var navigationArray = navigationController!.viewControllers // To get all UIViewController stack as Array
            navigationArray.remove(at: navigationArray.count - 1) // To remove previous UIViewController
            navigationController!.viewControllers = navigationArray
        }
    }
    
    func error(_ message: String) {
        finishWebView();
        clearFromNavigation();
        dismissing=true;
        dismiss(animated: true, completion: nil);
        if(client != nil) {
            client!.onError(message);
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if (message.name != "logHandler") {
            return;
        }
        let msg = String(describing: message.body);
        if(QueueFairConfig.debug) {
            QueueFairViewController.info(msg);
        }
        
        let i = QueueFairAdapter.indexOf(msg, "{");
        if(i == -1) {
            return;
        }
        
        if(QueueFairAdapter.indexOf(msg, "REDIRECT") == -1 && QueueFairAdapter.indexOf(msg, "JOIN") == -1) {
            return;
        }
        
        
        
        
        let j = QueueFairAdapter.indexOf(msg, "}");
        
        if(i == -1 || j == -1) {
            error("Invalid json.");
            return;
        }
        let jsonStr = QueueFairAdapter.substring(msg,i,j-i+1);
        let jsonData = jsonStr.data(using: .utf8);
        let json = try? JSONSerialization.jsonObject(with: jsonData!, options: []) as? [String: Any]
        
        if(json == nil) {
            error("Could not parse json.");
            return;
        }
        
        if(QueueFairAdapter.indexOf(msg, "JOIN") != -1) {
            let requestObj = json!["request"];
            if(requestObj == nil) {
                return;
            }
            
            let request = Int(String(describing: requestObj!));
            if(request == nil) {
                return;
            }
            
            QueueFairIOSService.setPreference("mostRecentRequestNumber",String(describing: request!));
            
            if(client != nil) {
                client!.onJoin(request!);
            }
            return;
        }
        
        //It's a REDIRECT
        if(QueueFairAdapter.indexOf(msg, "qfpt") == -1) {
            return;
        }
        
        let whenObj = json!["when"];
        if(whenObj == nil) {
            error("Untimed redirect");
            return;
        }
        
        var when = Int(String(describing: whenObj!));
        
        if(when == nil) {
            error("Invalid time for redirect");
            return;
        }
        
        if(when! > 500) {
            when! -= 500;
        }
        
        let ptObj = json!["type"];
        if(ptObj == nil) {
            error("No pass type.");
            return;
        }
        
        let passType = String(describing: ptObj!);
        
        let targetObj = json!["target"];
        if(targetObj == nil) {
            error("Redirect with no target.");
            return;
        }
        
        let target = String(describing: targetObj!);

        var pl = -1;
        let plObj = json!["pl"];
        if(plObj != nil) {
            let pli = Int(String(describing: plObj!));
            pl = pli!;
        } 
        
        DispatchQueue.main.asyncAfter(deadline: .now() + (Double(when!) / 1000.0)) {
            self.finishWebView();
            self.clearFromNavigation()
            self.dismissing=true;
            self.dismiss(animated: true, completion: nil);
            self.client!.onPassFromQueue(target, passType, when!, pl);
        }
        
    }
       
}
