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
    
    @objc
    func update() throws {//just for supercalls
        if completed {return}
    }
    
    @objc
    func reset(){
        completed = false
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
