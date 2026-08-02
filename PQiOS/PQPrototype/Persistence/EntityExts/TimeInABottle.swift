//
//  TimeInABottle.swift
//  PQPrototype
//
//  Created by William Hart on 15/07/2026.
//

import Foundation

extension TimeInABottle{
    
    static let weeklyCapIncrease: Int = 30
    
    //wrapper for simplicity of using regular Int
    var weeklyTally: Int {
        get { return Int(self.weeklyTimeCollected)}
        set { self.weeklyTimeCollected = Int16(newValue)}
    }
    
    //returns the softcap - or 'pre-upgrade' - weekly limit
    var weeklySoftCap: Int {
        get { return self.weeklyTimeLimit > 0 ? Int(self.weeklyTimeLimit) : Int(-self.weeklyTimeLimit) - TimeInABottle.weeklyCapIncrease}
    }
    
    //returns the hardcap - or 'post-upgrade' - weekly limit
    var weeklyHardcap: Int {
        get { return self.weeklyTimeLimit < 0 ? Int(-self.weeklyTimeLimit) : Int(self.weeklyTimeLimit) + TimeInABottle.weeklyCapIncrease}
    }
    
    var weeklyCap: Int {
        get { return Int(abs(self.weeklyTimeLimit))}
        set { self.weeklyTimeLimit = Int16(newValue)}
    }
    
    var weeklyUpgradeChallengeDate: Date {
        get { return self.weeklyLimitIncreaseDate ??
            {
                self.weeklyLimitIncreaseDate = Date.now.addingTimeInterval(86400*7)
                return self.weeklyLimitIncreaseDate!
            }()
        }
        set { self.weeklyLimitIncreaseDate = newValue}
    }
    
    var weeklyTallyResetDate: Date {
        get {
            return self.weeklyTimeReset ??
            {
                self.weeklyTimeReset = Date.now
                self.weeklyTimeReset = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date.now)! //set to 00:00:00
                self.weeklyTimeReset = Calendar.current.date(bySetting: .day, value: 1, of: Date.now)! //set to monday
                //now either the date is the monday at the beginning of this week or it is tomorrow (now.day == 0 i.e. sunday)
        
                if Date.now > self.weeklyTimeReset!{
                    self.weeklyTimeReset!.addTimeInterval(86400*7)
                }
                return self.weeklyTimeReset!
            }()}
        set {
            self.weeklyTimeReset = newValue
        }
    }
    
    public func updateStoredTime(amount: Int, limit: Bool = false) -> Bool{
        var added = amount
        //if this contributes to the weekly limit
        if (amount>0 && limit){
            if self.weeklyTally >= self.weeklyCap { return false }
            
            let ogTally = self.weeklyTally
            self.weeklyTally = min(ogTally+amount, self.weeklyCap)
            //get capped amount added (to add to actual tiab)
            added = self.weeklyTally - ogTally
        }
        //else if spending time
        else if amount < 0 {
            //and its more than there is *to* spend
            if Int(self.timeStored) + amount < 0{
                return false
            }
            //reset duration required of no spending
            self.weeklyUpgradeChallengeDate.addTimeInterval(86400*7)
        }
        self.timeStored+=Int64(added)
        return true
    }
}
