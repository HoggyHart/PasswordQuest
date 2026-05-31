//
//  QuestTask.swift
//  PQPrototype
//
//  Created by William Hart on 11/02/2026.
//

import Foundation
import CoreData
import SwiftUI

extension QuestTask{
    
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
        return "toString()"
    }
    
    @objc
    func currentStatus() -> String{
        return "currentStatus()"
    }
    
}
