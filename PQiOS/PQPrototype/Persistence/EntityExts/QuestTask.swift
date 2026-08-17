//
//  QuestTask.swift
//  PQPrototype
//
//  Created by William Hart on 11/02/2026.
//

import Foundation
import CoreData
import SwiftUI


class InvalidTaskError: Error{
    let task: String
    let invalidAttribute: String
    init(task: String, invalidAttribute: String) {
        self.task = task
        self.invalidAttribute = invalidAttribute
    }
}

extension QuestTask{
    @objc
    public var currentReward: Int{
        get { if completed {return 5} else {return 0} }
    }
    @objc
    public var maxReward: Int{
        return 5
    }
    
    @objc
    public var type: String {
        "\(self.classForCoder)".lowercased()
    }
    
    @objc
    func start() throws{
        
        try initDependenciesAndTrackers()
        
    }
    
    @objc
    func initDependenciesAndTrackers() throws{
        
    }
    //like reset() but doesn't stop indicating completion status
    //  use cases include failing a quest, wheere you dont want to reset yet so the user can see what they did/didnt do, but the tasks have ended so no need to keep tracking sensors
    @objc
    func endDependenciesAndTrackers(){
        
    }
    
    @objc
    func update() throws {//just for supercalls
        if completed {return}
    }
    
    @objc
    func reset(){
        completed = false
        self.endDependenciesAndTrackers()
    }
    
    @objc
    func toString() -> String{
        return "toString()"
    }
    
    @objc
    func currentStatus() -> String{
        return "currentStatus()"
    }
    
}
