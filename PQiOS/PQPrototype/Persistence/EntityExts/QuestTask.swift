//
//  QuestTask.swift
//  PQPrototype
//
//  Created by William Hart on 11/02/2026.
//

import Foundation


extension QuestTask{

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
