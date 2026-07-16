//
//  TimeInABottle.swift
//  PQPrototype
//
//  Created by William Hart on 15/07/2026.
//

import Foundation

extension TimeInABottle{
    public func initRefreshDate(){
        if self.weeklyTimeReset == nil {
            var now = Date.now
            now = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: now)!
            now = Calendar.current.date(bySetting: .day, value: 1, of: now)!
            //now either the date is the monday at the beginning of this week or it is tomorrow
            //  either way, set the reset date to a week later since its either the proper reset time OR they have 24 hours to reach the weekly cap in which case theyre cheating if they reach that and dont deserve to get the tally reset tomorrow
            self.weeklyTimeReset = now.addingTimeInterval(86400*7)
        }
    }
    
    public func refreshWeeklyLimit(){
        //if this is the first time refreshing (aka initial creation of GQD)
        if(Date.now > self.weeklyTimeReset!){
            self.weeklyTimeCollected = 0
            self.weeklyTimeReset!.addTimeInterval(86400*7)
        }
    }
    public func updateStoredTime(amount: Int, limit: Bool = false) -> Bool{
        var added = amount
        //if this contributes to the weekly limit
        if (amount>0 && limit){
            if self.weeklyTimeCollected == self.weeklyTimeLimit{ return false }
            let ogTally = self.weeklyTimeCollected
            self.weeklyTimeCollected = Int16(min(ogTally+Int16(amount), self.weeklyTimeLimit))
            //get capped amoount added
            added = Int(self.weeklyTimeCollected - ogTally)
        }
        else if amount < 0 && Int(self.timeStored) + amount < 0{
            return false
        }
        self.timeStored+=Int64(added)
        return true
    }
}
