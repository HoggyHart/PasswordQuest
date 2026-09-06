//
//  TrainingQuestTask.swift
//  PQPrototype
//
//  Created by William Hart on 17/08/2026.
//

import Foundation

extension TrainingQuestTask{
    
    override func update() throws {
        if Date.now.timeIntervalSince(self.quest!.questStartTime ?? Date.distantFuture) >= duration{
            self.completed = true
        }
    }
    
    var completionPercent: Double{
        get{
            if completed { return 100.0 }
            return Date.now.timeIntervalSince(self.quest!.questStartTime ?? Date.distantFuture) * 100.0 / duration
        }
    }
    
    public override var currentReward: Float {
        get{
            if completed { return Float(duration/720) } //5 per hour
            return 0 //
        }
    }
    override func currentStatus() -> String {
        if !(self.quest?.isActive ?? true) { return "" }
        let nf = NumberFormatter()
        nf.roundingMode = .up
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = 3
        return nf.string(for:  self.completionPercent)! + "%"
    }
    
}
