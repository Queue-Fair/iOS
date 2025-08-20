//
//  QueueFairAdapter.swift
//  QueueFairDemo
//
//  Created by Matt King on 10/3/2021.
//  For more information see https://queue-fair.com
//

import Foundation
import System



class QueueFairAdapter {
    
    var now : TimeInterval
    var service : QueueFairIOSService
    var variant : String?
    var userAgent : String?
    var requestedURL : String?
    var uid : String?
    var client : QueueFairClient
    var adapterQueue : [String : Any]?
    var extra : String?
    
    init(_ service: QueueFairIOSService,_ client: QueueFairClient) {
        self.service = service;
        self.client = client;
        now = NSDate().timeIntervalSince1970;
    }
    
    static func indexOf(_ haystack: String,_ needle: String) -> Int {
        let range: Range<String.Index>? = haystack.range(of: needle);
        
        if(range == nil) {
            return -1;
        }
        
        let index: Int = haystack.distance(from: haystack.startIndex, to: range!.lowerBound);
        
        return index;
    }
    
    static func lastIndexOf(_ haystack: String,_ needle: String) -> Int {
        let options : String.CompareOptions = [.backwards];
        let range  = haystack.range(of: needle, options: options)
        if(range == nil) {
            return -1
        }
        return haystack.distance(from: haystack.startIndex, to: range!.lowerBound)
    }
    
    static func substring(_ str: String,_ start: Int,_ length: Int?) -> String {
        let startIndex = str.index(str.startIndex, offsetBy: start);
        if(length == nil) {
            //Single argument means all characters from index.
            return String(str.suffix(from: startIndex));
        }
        
        let endIndex = str.index(str.startIndex, offsetBy: start+length!);
        
        let range = startIndex..<endIndex;
        
        return String(str[range]);
        
    }
    
    func setUIDFromCookie() {
        let cookieBase = "QueueFair-Store-" + QueueFairConfig.account;
        let uidCookie = service.getCookie(cookieBase);
        if(uidCookie == nil || uidCookie == "") {
            return;
        }
        var i = uidCookie!.firstIndex(of: ":");
        if( i == nil) {
            i = uidCookie!.firstIndex(of: "=");
        }
        if(i == nil) {
            return;
        }
        let j=uidCookie!.index(after: i!);
        uid = String(uidCookie![j...]);
    }
    
    func getValueQuick(_ haystack: String,_ name: String) -> String? {
        var i = QueueFairAdapter.lastIndexOf(haystack, name)
        if(i == -1) {
            return nil;
        }
        i = i + name.count
        
        let str = QueueFairAdapter.substring(haystack,i,nil);
        let j = QueueFairAdapter.indexOf(str,"&");
        if(j == -1) {
            return str;
        }
        return QueueFairAdapter.substring(str,0,j);
    }
    
    func validateCookie(_ queue: [String: Any], _ cookie: String) -> Bool {
        
        let plOpt = queue["passedLifetimeMinutes"];
        if(plOpt == nil) {
            error("Queue has no passed lifetime.");
            return false;
        }
        
        let pl = Int(String(describing: plOpt!));
        if(pl == nil) {
            error("Could not parse passed lifetime \(plOpt!)");
            return false;
        }
                
        let hPos = QueueFairAdapter.lastIndexOf(cookie,"qfh=");
        if(hPos == -1) {
            return false;
        }
        
        let accountFromCookie = getValueQuick(cookie,"qfa=");
        
        if(accountFromCookie == nil) {
            if(QueueFairConfig.debug) {
                QueueFairAdapter.info("Account mismatch.");
            }
            return false;
        }
        if(QueueFairConfig.account != accountFromCookie!) {
            if(QueueFairConfig.debug) {
                QueueFairAdapter.info("Account mismatch.");
            }
            return false;
        }
        
        let tsFromCookie = getValueQuick(cookie,"qfts=");
        if(tsFromCookie == nil) {
            if(QueueFairConfig.debug) {
                QueueFairAdapter.info("Missing timestamp.");
            }
            return false;
        }
        if(QueueFairConfig.debug) {
            QueueFairAdapter.info("Cookie validated.");
        }
        return true;
        
    }
    
    func consultAdapter(_ queue: [String:Any]) {
        if(QueueFairConfig.debug) {
            QueueFairAdapter.info("Consulting adapter server for \(queue["name"]!)")
        }
        
        let qName = queue["name"];
        let adapterServer = queue["adapterServer"];
        if(qName == nil) {
            error("No queue name.");
            return;
        }
        if(adapterServer == nil) {
            error("No adapter server.");
            return;
        }
        adapterQueue = queue;
        var url = "\(QueueFairConfig.proto)://\(adapterServer!)/adapter/\(qName!)";
        
        var sep = "?";
        if(uid != nil) {
            url += sep + "uid="+uid!;
            sep = "&";
        }
        url += sep + "identifier=" + userAgent!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!;
        
        let urlObj = URL(string: url)!;
        var request = URLRequest(url: urlObj);
        request.timeoutInterval = QueueFairConfig.readTimeoutSeconds;
        
        let session = URLSession.shared;
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                self.error("Cannot reach adapter: "+String(describing: error));
            } else if let data = data {
                self.gotAdapter(data);
            } else {
                self.error("Cannot reach adapter: Unknown error.");
            }
        }
        task.resume();
    }
    
    func gotAdapter(_ data: Data) {
        if(QueueFairConfig.debug) {
            QueueFairAdapter.info("Got Adapter "+String(describing: data));
        }
        let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        if(json == nil) {
            error("Could not parse adapter json.");
            return;
        }
        let uidFromJSON = json!["uid"];
        if(uidFromJSON != nil) {
            let cookieDomain = adapterQueue!["cookieDomain"];
            var cookieDomainStr : String?;
            if(cookieDomain != nil) {
                cookieDomainStr = String(describing: cookieDomain!);
            }
            
            let csOpt = json!["cookieSeconds"];
            if(csOpt == nil) {
                error("Cookie has no lifetime.");
                return;
            }
            let cs = Int(String(describing: csOpt!));
            if(cs == nil) {
                error("Could not parse cookie lifetime \(csOpt!)");
                return;
            }
            let cookieSeconds = cs!;
            
            uid = String(describing: uidFromJSON!);
            service.setCookie("QueueFair-Store-\(QueueFairConfig.account)","u:\(uid!)",cookieSeconds,cookieDomainStr);
        }
        
        let actionObj = json!["action"];
        
        if(actionObj == nil) {
            error("Adapter has no action.");
            return;
        }
        
        let action = String(describing: actionObj!);
        
        if("SendToQueue" == action) {
            if(QueueFairConfig.debug) {
                QueueFairAdapter.info("GotAdapter Sending to Queue Server");
            }
            let dtObj = adapterQueue!["dynamicTarget"];
            
            var dt : String?
            if(dtObj != nil) {
                dt = String(describing: dtObj!);
            }
            var queryParams = "";
            
            var target = requestedURL!;
            
            if(dt != nil && "disabled" != dt!) {
                if("path" == dt!) {
                    let i = QueueFairAdapter.indexOf(target,"?");
                    if(i != -1) {
                        target = QueueFairAdapter.substring(target,0,i);
                    }
                }
                queryParams += "target=";
                queryParams += target.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            }
            
            if(uid != nil) {
                if("" != queryParams) {
                    queryParams += "&";
                }
                queryParams += "qfuid=" + uid!;
            }
            
            let redirectObj = json!["location"];
            if(redirectObj == nil) {
                error("SendToQueue with no target!")
                return;
            }
            var redirectLoc = String(describing: redirectObj!);
            if(variant != nil) {
                if(QueueFairAdapter.indexOf(redirectLoc,"?") != -1) {
                    redirectLoc += "&";
                } else {
                    redirectLoc += "?";
                }
                redirectLoc += "qfv="+variant!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!;
            }
            
            if(extra != nil) {
                if(QueueFairAdapter.indexOf(redirectLoc,"?") != -1) {
                    redirectLoc += "&";
                } else {
                    redirectLoc += "?";
                }
                redirectLoc += extra!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!;
            }
            
            if(QueueFairConfig.debug) {
                QueueFairAdapter.info("GotAdapter Redirecting to "+redirectLoc);
            }
            service.redirect(redirectLoc)
            
            client.gotRedirect(redirectLoc);
            return;
            
            
        }
        
        let qObj = json!["queue"];
        if(qObj == nil) {
            error("Adapter has no queue.");
            return;
        }
        let qName = String(describing: qObj!);
        let vObj = json!["validation"];
        if(vObj == nil) {
            error("Adapter has no validation.");
            return;
        }
        let validation = String(describing: vObj!).removingPercentEncoding;
        if(validation == nil) {
            error("Invalid validation");
            return;
        }
        
        let cookieDomain = adapterQueue!["cookieDomain"];
        
        var cookieDomainStr : String?;
        
        if(cookieDomain != nil) {
            cookieDomainStr = String(describing: cookieDomain!);
        }
        
        var pl = -1;
        
        let plOpt = json!["pl"];
        if(plOpt != nil) {
            let ploi = Int(String(describing: plOpt!));
            if(ploi != nil) {
                pl = ploi!;
            }
        }
        
        let passedLifetimeMinutes = conditionalSetPassedLifetime(pl);
        
        setCookie(qName, validation!, passedLifetimeMinutes*60,cookieDomainStr);
        
        var passType = getValueQuick(validation!, "qfpt=");
        
        if(passType == nil) {
            passType = "Unset";
        }
        
        client.onPass(passType!);   
    }

    func conditionalSetPassedLifetime(_ pl: Int) -> Int {
        let plOpt = adapterQueue!["passedLifetimeMinutes"];
        if(plOpt == nil) {
            error("Queue has no passed lifetime.");
            adapterQueue!["passedLifetimeMinutes"] = 20;
            return 20;
        }
        
        let pla = Int(String(describing: plOpt!));
        if(pla == nil) {
            error("Could not parse passed lifetime \(plOpt!)");
            adapterQueue!["passedLifetimeMinutes"] = 20;
            return 20;
        }
        
        
        if pla != -1 {
            if QueueFairConfig.debug {
                QueueFairAdapter.info("PassedLifetime set in code as " + String(describing: pla) + " - using.")
            }
            return pla!;
        }

        if pl > 0 {
            if QueueFairConfig.debug {
                QueueFairAdapter.info("Using received PassedLifetime " + String(describing: pl) + " minutes.")
            }
            adapterQueue!["passedLifetimeMinutes"] = pl
            return pl
        }

        if QueueFairConfig.debug {
            QueueFairAdapter.info("Response does not contain PassedLifetime and not set in code - defaulting to 20 mins")
        }
        adapterQueue!["passedLifetimeMinutes"] = 20
        return 20
    }
    
    func setCookie(_ qName: String,_ value: String,_ lifetimeSeconds: Int,_ domain: String? ) {
        if(QueueFairConfig.debug) {
            QueueFairAdapter.info("Setting cookie for "+qName+" to "+value);
        }
        
        let cName="QueueFair-Pass-"+qName;
        
        service.setCookie(cName,value,lifetimeSeconds,domain);
        
    }
    
    func error(_ message: String) {
        if(QueueFairConfig.debug) {
            QueueFairAdapter.info("Error: "+message);
        }
        client.onError(message);
    
    
    static func info(_ message: String) {
        print("QFA: "+message);
    }
}
