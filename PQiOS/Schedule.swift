//
//  File.swift
//  PQPrototype
//
//  Created by William Hart on 01/01/2026.
//
import Foundation

extension Schedule {
    func setSchedule(scheduledDays: Week){
        self.everyXDays = false
        self.scheduledDays = NSWeek(week: scheduledDays)
    }

    func setSchedule(frequency: Int32){
        everyXDays = true
        self.xDayDelay = frequency
    }
    public func lateInit(quest: Quest){
        isActive = false
        let d = Date.now.addingTimeInterval(10)
        scheduledStartTime = d
        scheduledEndTime = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: Date.now)
        scheduleName = "Scheduled "+quest.questName!
        scheduleUUID = UUID()
        startTime = scheduledStartTime
        setSchedule(scheduledDays: .weekdays)
        lastEndDate = nil
        lastScheduleCompletedOnTime = true
        synchronised = false
        self.quest = quest
    }
    
    func getDuration() -> TimeInterval{
        return scheduledEndTime!.timeIntervalSince(scheduledStartTime!)
    }
    func getActualEndTime() -> Date{
         return startTime!
            .addingTimeInterval(
                scheduledEndTime!
                    .timeIntervalSince(scheduledStartTime!))
    }
    
    ///-2: inactive
    ///-1: not started yet
    ///0: in progress
    ///1: failed
    ///2: succeeded
    func getState() -> Int{
        // lastEndTime < startTime < endTime
        
        //if sch not active, say that
        if(!self.isActive){ // -2
            return -2
        }
        //if sch completed today -> show succeed/fail
        else if (Calendar.current.isDateInToday(self.lastEndDate ?? Date.distantFuture)){ // 1/2
            if (!self.lastScheduleCompletedOnTime){ return 1 }
            return 2
        }
        //else if not completed today -> just indicate whether it has started or not
        else if (Date.now < self.startTime!){
            return -1
        }
        else if quest!.getCurrentScheduler() == self {
            return 0
        }
        //elses: 1. time to start but hasn't started for some reason (i.e. not started yet)
        //       2. unknown state
        else { return -1 }
    }
    
    func getNext_XDayDelay_StartTime(fromDate: Date) -> Date{
        let startHour = Calendar.current.component(.hour, from: scheduledStartTime!)
        let startMin = Calendar.current.component(.minute, from: scheduledStartTime!)
        let start = Calendar.current.date(bySettingHour: startHour, minute: startMin, second: 0, of: fromDate)!
        return start.addingTimeInterval(Double(self.xDayDelay * 86400))
    }
    
    func getNext_ScheduledDays_StartTime(fromDate: Date) -> Date{
        
        let curDay = Calendar.current.component(.weekday, from: fromDate)
        
        let curDayOfWeek = curDay - 2 < 0 ? 6 : curDay - 2
        
        var gap: Int = Int.max
        for i in 0..<7{
            //if day scheduled and first scheduled day found
            if scheduledDays!.week.contains(.Element(rawValue: 1<<i)) && gap == Int.max{
                gap = i - curDayOfWeek
            }
            
            if scheduledDays!.week.contains(.Element(rawValue: 1<<i)) && i > curDayOfWeek{
                gap = i - curDayOfWeek
                break
            }
        }
        if gap < 0{
            gap += 7
        }
        let startHour = Calendar.current.component(.hour, from: scheduledStartTime!)
        let startMin = Calendar.current.component(.minute, from: scheduledStartTime!)
        let start = Calendar.current.date(bySettingHour: startHour, minute: startMin, second: 0, of: fromDate)!
        return start.addingTimeInterval(Double(gap*86400))
    }
    
    func getNextStartTime(fromDate: Date) -> Date{
        if self.everyXDays{
            return getNext_XDayDelay_StartTime(fromDate: fromDate)
        }else{
            return getNext_ScheduledDays_StartTime(fromDate: fromDate)
        }
    }
    
    ///delay schedule start (in seconds)
    func delayStart(delay: Double){
        startTime!.addTimeInterval(delay)
        
        //FIX: make user toggleable
        //  i.e. if scheduled for every 3 days, and I delay for 1 day, should the next start be on that 3rd day still?
        //      or should the delay be carried on from that new start date
        //FIX: Also to add - to what degree should the delay impact? should it go down to minutes? or just days?
        //  if I delay by 22 hours, should the next schedule still be scheduled for 2 hours later?
        //  when delaying prhaps have a "impact schedule?" with a Before -> After comparison
        let delayImpactsSchedule = true //FIX: Not yet fully implemented / may also affect hour/minute depending on frequency of schedule if I improve schedule versatility to sub-day intervals
        if delayImpactsSchedule{
            scheduledStartTime!.addTimeInterval(delay)
            scheduledEndTime!.addTimeInterval(delay)
        }
        return
    }
    
    ///Called when scheduled quest finishes
    func endScheduledPeriod(){
        //finish period
        self.lastEndDate = Date.now
        self.lastScheduleCompletedOnTime = self.quest!.tasksComplete()
        
        //set next start/end times
        _ = amendNextScheduledPeriod(toNextStartFrom: Date.now) //_ = to get rid of warning
    }
    
    ///-1: before
    ///0: during
    ///1: after
    func scheduledPeriodRelativity(ofDate: Date = Date.now) -> Int{
        if ofDate < self.startTime! { return -1 }
        else if ofDate < self.getActualEndTime() { return 0 }
        else { return 1 }
    }
    ///Used to move the scheduled start/end dates forward to make it possible for the scheduled quest to start automatically
    ///Can pad with QuestRewards to pretend it was doing schedules the whole time
    func amendNextScheduledPeriod(toNextStartFrom: Date, padQuestFailures: Bool = false) -> Int{
        //track whether scheduled moved back(-1), forward(1), or not at all (0)
        var moved = 0
        
        let dur = self.getDuration()
        //if start time is already ahead of the given date
        if toNextStartFrom < self.startTime! {
            //just make sure it's the IMMEDIATE next possible start
            let nextScheduledStartTime = getNextStartTime(fromDate: toNextStartFrom)
            if !nextScheduledStartTime.equals(date2: self.scheduledStartTime!){
                //if updated next start time is not the same as the old next start time, assume it moved backward (i.e. 4th jan -> 3rd)
                moved = -1
                scheduledStartTime = nextScheduledStartTime
                startTime = scheduledStartTime
                scheduledEndTime = scheduledStartTime!.addingTimeInterval(dur)
            }
            return moved
        }
        
        //while current scheduled start is earlier than the given date
        while self.scheduledStartTime! < toNextStartFrom{
            //mark as having moved forward
            moved = 1
            //add quest "rewards"
            if padQuestFailures{
                let reward = QuestReward(context: self.managedObjectContext!)
                reward.completedOnTime = false
                reward.key = self.quest!.questUUID!
                reward.scheduled = true
                reward.obtainmentDate = self.scheduledEndTime!
                self.quest!.addToRewards(reward)
            }
            //move schedule ahead
            scheduledStartTime = getNextStartTime(fromDate: scheduledStartTime!)
            scheduledEndTime = scheduledStartTime!.addingTimeInterval(dur)
        }
        //finalise start time
        startTime = scheduledStartTime
        return moved
    }
}

//json/pc lock stuff
extension Schedule {
    
    func toJson() -> String{
        var data = "{\n"
        data.append("\"isActive\" : \"" + (self.isActive ? "True" : "False") + "\",\n")
        data.append("\"questInProgress\" : \"" + (self.quest!.isActive ? "True" : "False") + "\",\n")
        data.append("\"schedule_everyXDays\" : \"" + (self.everyXDays ? "True" : "False") + "\",\n")
        data.append("\"scheduleName\" : \"" + self.scheduleName! + "\",\n")
        data.append("\"scheduleUUID\" : \"" + self.scheduleUUID!.uuidString + "\",\n")
        data.append("\"questUUID\" : \"" + self.quest!.questUUID!.uuidString + "\",\n")
        data.append("\"schedule_XDayDelay\" : \"" + String(self.xDayDelay) + "\",\n")
        data.append("\"startTime\" : \"" + self.startTime!.formatted(date: .numeric, time: .standard) + "\",\n")
        data.append("\"scheduledStartTime\" : \"" + self.scheduledStartTime!.formatted(date: .numeric, time: .standard) + "\",\n")
        data.append("\"scheduledEndTime\" : \"" + self.scheduledEndTime!.formatted(date: .numeric, time: .standard) + "\",\n")
        data.append("\"schedule_lastCompletionTime\" : \"" + (self.lastEndDate?.formatted(date: .numeric, time: .standard) ?? "nil") + "\",\n")
        data.append("\"schedule_scheduledDays\" : \"" + self.scheduledDays!.week.toBitSetString() + "\"\n}")
        return data
    }
    
    func synchronise(){
        if let url = URL(string:"http://172.20.10.5:1617") {
            var request = URLRequest(url: url)
            
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            let data = self.toJson()
            let newData = Data(data.utf8)
            let task = URLSession.shared.uploadTask(with: request, from: newData){ data, response, error in
                if let error = error {
                    // Handle the error
                    print("Error: \(error.localizedDescription)")
                } else if let response = (response as? HTTPURLResponse){
                    // Process the data
                    if response.statusCode == 200{
                        self.synchronised = true
                    }
                }
            }
            task.resume()
        }
    }
}
