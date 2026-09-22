//
//  ManualQuestTask.swift
//  PQPrototype
//
//  Created by William Hart on 10/09/2026.
//

import Foundation

extension ManualQuestTask{
    public func getQuest() -> Quest{
        return self.quest ?? superTask!.getQuest()
    }
    
    public func chainCompletionToggle(){
        guard let superTaskComplete = self.superTask?.completed  else { return }
        
        //if chaining completion, abort if any other tasks are not complete
        if self.completed{
            for task in superTask?.subTasks ?? []{
                if !(task as! ManualQuestTask).completed{
                    return
                }
            }
        }
        
        superTask?.completed = self.completed // supertask completion state is appropriately set
        if superTaskComplete != superTask?.completed{ //if supertask became true or false, chain the toggle
            superTask?.chainCompletionToggle()
        }
    }
    override func start() throws{
        try super.start()
        if subTasks?.count == 0{
            self.completed = true
        }
    }
    
    override func reset() {
        self.completed = false
        for task in subTasks ?? []{
            (task as! ManualQuestTask).completed = false
            (task as! ManualQuestTask).reset()
        }
    }
    
    override func currentStatus() -> String {
        var comp = 0
        for task in subTasks?.allObjects ?? []{
            if (task as! ManualQuestTask).completed{
                comp += 1
            }
        }
        return "\(comp)/\(subTasks?.allObjects.count ?? 0)"
    }
}
