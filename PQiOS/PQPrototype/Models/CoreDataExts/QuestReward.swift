//
//  QuestReward.swift
//  PQPrototype
//
//  Created by William Hart on 11/02/2026.
//

import Foundation

extension QuestReward{

    func toJson() -> String{
        var data = "{\n"
        data.append("\"questUUID\" : \"" + key!.uuidString + "\",\n")
        data.append("\"completedOnTime\" : \"" + (self.completedOnTime ? "True" : "False") + "\",\n")
        data.append("\"obtainmentDate\" : \"" + self.obtainmentDate!.formatted(date: .numeric, time: .standard) + "\",\n")
        data.append("\"scheduled\" : \"" + (self.scheduled ? "True" : "False") + "\"\n}")
        return data
    }
}
