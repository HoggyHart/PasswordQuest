//
//  PQPrototypeApp.swift
//  PQPrototype
//
//  Created by William Hart on 27/11/2025.
//

import SwiftUI
import CoreLocation
import CoreData
@main

struct PQPrototypeApp: App {
    
    static var isPreview: Bool {
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    static var mainContext: NSManagedObjectContext{
        return PQPrototypeApp.isPreview ?  PersistenceController.preview.container.viewContext : PersistenceController.shared.container.viewContext
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
        let bgContext = PQPrototypeApp.mainContext
        do{
            let tasks = try bgContext.fetch(QuestTask.fetchRequest())
            for task in tasks{
                do{
                    if task.quest?.isActive == true && !task.completed{
                        try task.initDependenciesAndTrackers()
                    }
                }
                catch{
                    
                }
            }}
        catch{
            
        }
        PQPrototypeApp.scheduleAndQuestUpdater = Timer.scheduledTimer(withTimeInterval: 1, repeats: true){_ in
            if PQPrototypeApp.updatingThreadActive == true{return}
            PQPrototypeApp.updatingThreadActive = true
            
            let bgContext = PQPrototypeApp.isPreview ?  PersistenceController.preview.container.viewContext : PersistenceController.shared.container.viewContext
            //try to start scheduled quests
            bgContext.perform {
                
                //update in-progress quests
                do{
                    
                    let quests = try bgContext.fetch(Quest.fetchRequest())
                    for quest in quests{
                        if !quest.isActive { continue; }
                        quest.updateProgress()
                    }
                    try bgContext.save()
    //SCHEDULES
                    //load schedules
                    let createdSchedules = try bgContext.fetch(Schedule.fetchRequest())
                    
                    //for each scheduled quest
                    for schedule in createdSchedules {
                        //if schedule isnt active or has already started: skip this one
                        if !schedule.isActive || schedule.getState() == .inProgress { continue }
                        let quest = schedule.quest! //shorten syntax for convenience
                        if quest.isActive { continue }
                        
                        // if scheduled period has already passed, fail quests until schedule has caught up to now
                        if Date.now > schedule.getActualEndTime(){
                            _ = schedule.amendNextScheduledPeriod(toNextStartFrom: Date.now, safe: false, padQuestFailures: true)
                        }
                        
                        //if past start time (and before end time), start
                        if Date.now > schedule.startTime!{
                            do{
                                if !schedule.startTime!.equals(date2: schedule.scheduledStartTime!){
                                    //indicates schedule was delayed meaning quest was paused
                                    quest.isActive = true
                                }else{
                                    try quest.start(withSchedule: schedule)
                                }
                            }catch{bgContext.undo(); continue}
                        }
                    }
                    
                    try bgContext.save()
                    
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
    
    private func initMainBackgroundLoop(){
        PQPrototypeApp.scheduleAndQuestUpdater = Timer.scheduledTimer(withTimeInterval: 1, repeats: true){_ in
            //TODO: use a more standard multithreading safety lock
            if PQPrototypeApp.updatingThreadActive == true{return}
            PQPrototypeApp.updatingThreadActive = true
            
            let bgContext = PQPrototypeApp.isPreview ?  PersistenceController.preview.container.viewContext : PersistenceController.shared.container.viewContext
            //try to start scheduled quests
            bgContext.perform {
                
                do{
//QUESTS
                    let quests = try bgContext.fetch(Quest.fetchRequest())
                    for quest in quests{
                        if !quest.isActive { continue; }
                        quest.updateProgress()
                    }
                    try bgContext.save()
//SCHEDULES
                    let createdSchedules = try bgContext.fetch(Schedule.fetchRequest())
                    
                    //for each scheduled quest
                    for schedule in createdSchedules {
                        //if schedule isnt active or has already started: skip this one
                        if !schedule.isActive || schedule.getState().rawValue == 0 { continue }
                        let quest = schedule.quest! //shorten syntax for convenience
                        if quest.isActive { continue }
                        
                        // if scheduled period has already passed, fail quests until schedule has caught up to now
                        if Date.now > schedule.getActualEndTime(){
                            _ = schedule.amendNextScheduledPeriod(toNextStartFrom: Date.now, safe: false, padQuestFailures: true)
                        }
                        
                        //if past start time (and before end time), start
                        if Date.now > schedule.startTime!{
                            do{
                                try quest.start(withSchedule: schedule)
                            }catch{bgContext.undo(); continue}
                        }
                    }
                    
                    try bgContext.save()
                    
                }catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
            }
            
            PQPrototypeApp.updatingThreadActive = false
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
