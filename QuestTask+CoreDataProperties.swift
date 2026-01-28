//
//  QuestTask+CoreDataProperties.swift
//  PQPrototype
//
//  Created by William Hart on 27/12/2025.
//
//

import Foundation
import CoreData

extension QuestTask {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<QuestTask> {
        return NSFetchRequest<QuestTask>(entityName: "QuestTask")
    }

    @NSManaged public var completed: Bool
    @NSManaged public var name: String?
    @NSManaged public var quest: Quest?

}

extension QuestTask : Identifiable{

    @objc
    func lateInit(name: String){
        self.name = name
        self.completed = false
    }
    
    @objc
    func start() {
        reset()
    }
    
    @objc
    func update() {
        completed = true
    }
    
    @objc
    func reset(){
        completed = false
    }
    
    @objc
    func toString() -> String{
        return "No Task Completion Requirement"
    }
    
}
