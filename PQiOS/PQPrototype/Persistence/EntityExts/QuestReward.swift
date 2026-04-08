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
        data.append("\"completedOnTime\" : \"" + MyJson.toJson(self.questComplete) + "\",\n")
        data.append("\"obtainmentDate\" : \"" + self.obtainmentDate!.formatted(date: .numeric, time: .standard) + "\",\n")
        data.append("\"scheduled\" : \"" + MyJson.toJson(self.scheduled) + "\",\n")
        data.append("\"type\" : \"" + "None" + "\"\n") //Not yet implemented. type could be nullify (in case of quest deletion / uuid change
        data.append("}")
        return data
    }
}
