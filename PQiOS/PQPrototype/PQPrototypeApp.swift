//
//  PQPrototypeApp.swift
//  PQPrototype
//
//  Created by William Hart on 27/11/2025.
//

import SwiftUI
import CoreLocation
@main

struct PQPrototypeApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

//BUG STEPS:
//CREATE QUEST
//  CREATE TASK
//  CREATE SCH -> 1 DAY DELAY -> CLOSE SCH
// WAIT
//COMPLETE QUEST
//CLOSE APP
//REOPEN


import Foundation
import SystemConfiguration
import Network
 
// Returns dictionary: interfaceName -> [addresses]
func getIPAddresses() -> [String: [String]] {
    var results = [String: [String]]()
    var ifaddrPtr: UnsafeMutablePointer<ifaddrs>?
 
    guard getifaddrs(&ifaddrPtr) == 0, let firstAddr = ifaddrPtr else { return results }
    defer { freeifaddrs(ifaddrPtr) }
 
    var ptr = firstAddr
    while ptr.pointee.ifa_next != nil || ptr.pointee.ifa_addr != nil {
        let name = String(cString: ptr.pointee.ifa_name)
        let addr = ptr.pointee.ifa_addr.pointee
 
        if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let result = getnameinfo(ptr.pointee.ifa_addr,
                                     socklen_t(addr.sa_len),
                                     &hostname,
                                     socklen_t(hostname.count),
                                     nil,
                                     socklen_t(0),
                                     NI_NUMERICHOST)
            if result == 0 {
                let address = String(cString: hostname)
                results[name, default: []].append(address)
            }
        }
        if let next = ptr.pointee.ifa_next {
            ptr = next
        } else {
            break
        }
    }
 
    return results
}
