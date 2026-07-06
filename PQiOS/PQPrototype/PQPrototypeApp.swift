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
    
    static var isPreview: Bool {
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    static public var updatingThreadActive = false
    
    static private var scheduleAndQuestUpdater: Timer?
    
    init(){
        Task {
            let center = UNUserNotificationCenter.current()
            
            do {
                try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                // Handle the error here.
            }
        }
        PQPrototypeApp.scheduleAndQuestUpdater = Timer.scheduledTimer(withTimeInterval: 1, repeats: true){_ in
            if PQPrototypeApp.updatingThreadActive == true{return}
            PQPrototypeApp.updatingThreadActive = true
            
            let bgContext = PQPrototypeApp.isPreview ?  PersistenceController.preview.container.newBackgroundContext() : PersistenceController.shared.container.newBackgroundContext()
            //try to start scheduled quests
            bgContext.perform {
                
                //update in-progress quests
                do{
                    
                    let quests = try bgContext.fetch(Quest.fetchRequest())
                    for quest in quests{
                        if !quest.isActive { continue; }
                        
                        quest.updateProgress()
                        
                        //if now completed
                        if !quest.isActive{
                            //check if there are any other quests still in progress
                            let allQuests = try bgContext.fetch(Quest.fetchRequest())
                            var anyActive = false
                            for individualQuest in allQuests{
                                if individualQuest.isActive{
                                    anyActive = true
                                }
                            }
                            //if this was the only active quest, stop updating location
                            if !anyActive {LocationServices.service.locationManager.stopUpdatingLocation() }
                        }
                    }
    //SCHEDULES
                    //load schedules
                    let createdSchedules = try bgContext.fetch(Schedule.fetchRequest())
                    
                    //for each scheduled quest
                    for schedule in createdSchedules {
                        //if schedule isnt active or has already started: skip this one
                        if !schedule.isActive || schedule.getState() == 0 { continue }
                        let quest = schedule.quest! //shorten syntax for convenience
                        if quest.isActive { continue }
                        
                        // if scheduled period has already passed, fail quests until schedule has caught up to now
                        if Date.now > schedule.getActualEndTime(){
                            schedule.nextSchLocked = false
                            _ = schedule.amendNextScheduledPeriod(toNextStartFrom: Date.now, safe: false, padQuestFailures: true)
                        }
                        
                        //if past start time (and before end time), start
                        if Date.now > schedule.startTime!{
                            do{
                                try quest.start(withSchedule: schedule)
                            }catch{bgContext.undo(); continue}
                        }
                        try bgContext.save()
                    }
                }catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
            }
            
            PQPrototypeApp.updatingThreadActive = false
        }

    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        }
    }
}

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
