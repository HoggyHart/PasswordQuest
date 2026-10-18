//
//  File.swift
//  PQPrototype
//
//  Created by William Hart on 10/10/2026.
//

import Foundation
import CoreData

class QuestScheduleManager: ObservableObject{
    static var shared = QuestScheduleManager()
    
    typealias QuestID = NSManagedObjectID
    typealias ScheduleID = NSManagedObjectID
    
    var activeRegister = Dictionary<QuestID,Schedule>()
    
    init(){
        //Load register of quests and their active schedulers
        do{
            let quests = try PQPrototypeApp.mainContext.fetch(Quest.fetchRequest())
            for q in quests{
                if let schedule = q.getCurrentScheduler(thorough: true){
                    activeRegister.updateValue(schedule, forKey: q.objectID)
                }
            }
        }catch{
            
        }
    }
    
    public func isInUse(schedule: Schedule) -> Bool{
        guard let key = schedule.quest?.objectID else { return false }
        return activeRegister[key]?.objectID == schedule.objectID
    }
}
