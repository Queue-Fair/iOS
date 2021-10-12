//
//  QueueFairConfig.swift
//  QueueFairDemo
//
//  Created by Matt King on 10/3/2021.
//  For more information see https://queue-fair.com
//

import Foundation

public class QueueFairConfig {
    
    public static var account = "REPLACE_WITH_YOUR_ACCOUNT_SYSTEM_NAME";
    public static var debug = false;
    public static var settingsCacheLifetimeMinutes = 5;
    public static var proto = "https";
    public static var filesServer = "files.queue-fair.net";
    public static var readTimeoutSeconds : Double = 15.0;
}
