//
//  SCGlobalOptions.swift
//  SimpleCacheStore
//
//  Created by Moritz Kanzler on 19.07.16.
//  Copyright © 2016 Moritz Kanzler. All rights reserved.
//

import Foundation

class SCGlobalOptions {
    
    struct Options {
        /** CACHE **/
        static var cacheLimit: Int = 0
        static var cacheMode: SCManager.CacheMode = SCManager.CacheMode.rebuild
        static let concurrentSCSQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated) //dispatch_queue_create("de.MK.SimpleCacheStore", DISPATCH_QUEUE_CONCURRENT)
        
        /** LABELS **/
        static let defaultLabel: String = "default"
        
        /** DEBUGGING **/
        static var errorLogFile: String = "scserror.log"
        static var debugMode: Bool = false
        static let scsDebugIdentifier: String = "[SCS]"
    }
}
