//
//  QueueFairIOSService.swift
//  QueueFairDemo
//
//  Created by Matt King on 10/3/2021.
//  For more information see https://queue-fair.com
//

import Foundation

public class QueueFairIOSService {
    
    static var doPreferencesSynch : Bool = true;
    var redirectLoc : String?
    
    func getCookie(_ name: String) -> String? {
        let ret = QueueFairIOSService.getPreference(name);
        if(QueueFairConfig.debug) {
            QueueFairIOSService.info("Preference for "+name+" is "+ret);
        }
        if("DEFAULT_VALUE" == ret) {
            return nil;
        }
        let expires = QueueFairIOSService.getPreference(name+":expires");
        if("DEFAULT_VALUE" == expires) {
            QueueFairIOSService.setPreference(name, "DEFAULT_VALUE");
            return nil;
        }
        let expireEpoch = Double(expires);
        if(expireEpoch == nil) {
            if(QueueFairConfig.debug) {
                QueueFairIOSService.info("Preference for "+name+" has bad expires "+expires);
            }
        }
        if(expireEpoch! < NSDate().timeIntervalSince1970) {
            if(QueueFairConfig.debug) {
                QueueFairIOSService.info("Preference for "+name+" has expired.");
                QueueFairIOSService.setPreference(name, "DEFAULT_VALUE");
                QueueFairIOSService.setPreference(name+":expires", "DEFAULT_VALUE");
                return nil;
            }
        }
        return ret;
    }
    
    func setCookie(_ name: String,_ value: String,_ lifetimeSeconds: Int,_ domain: String?) {
        if(QueueFairConfig.debug) {
            QueueFairIOSService.info("Setting cookie "+name+" to "+value+" life "+String(describing: lifetimeSeconds));
        }
        if(lifetimeSeconds <= 0) {
            QueueFairIOSService.setPreference(name,"DEFAULT_VALUE");
            QueueFairIOSService.setPreference(name+":expires","DEFAULT_VALUE");
            return;
        }
        var expires=NSDate().timeIntervalSince1970;
        expires += Double(lifetimeSeconds);
        QueueFairIOSService.setPreference(name, value);
        QueueFairIOSService.setPreference(name+":expires",String(describing: expires));
    }
    
    func redirect(_ location: String) {
        if(QueueFairConfig.debug) {
            QueueFairIOSService.info("Redirecting to "+location);
        }
        self.redirectLoc = location;
    }
    
    static func info(_ message: String) {
        print("QFS: "+message);
    }
    
    public static func setPreference(_ key: String,_ value: String) {
        if(QueueFairConfig.debug) {
            info("Setting "+key+" to "+value);
        }
        UserDefaults.standard.set(value, forKey: "QueueFairAdapter."+key);
        
        if(doPreferencesSynch) {
            UserDefaults.standard.synchronize();
        }
        
    }
    
    public static func indexOf(_ haystack: String,_ needle: String) -> Int {
        let range: Range<String.Index>? = haystack.range(of: needle);
        
        if(range == nil) {
            return -1;
        }
        
        let index: Int = haystack.distance(from: haystack.startIndex, to: range!.lowerBound);
        
        return index;
    }
    
    public static func clear() {
        let keys = UserDefaults.standard.dictionaryRepresentation().keys;
        for key in keys {
            if(indexOf(key,"QueueFairAdapter.") != 0) {
                continue;
            }
            UserDefaults.standard.removeObject(forKey: key);
        }
    }
    
    public static func getPreference(_ key: String) -> String {
        var ret = "DEFAULT_VALUE";
        
        let got: String? = UserDefaults.standard.string(forKey: "QueueFairAdapter."+key);
        
        
        if(got == nil || got == "") {
            // Do nothing
        } else {
            ret = got!;
        }
        
        return ret;
    }
}
