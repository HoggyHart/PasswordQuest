//
//  File.swift
//  PQPrototype
//
//  Created by William Hart on 01/01/2026.
//
import Foundation
import UserNotifications
import CoreData

//TODO: add distinctions between CUTOFF end times and TIME LIMIT end times in schedule creation (i.e. "needs to be done by 6pm" vs "give me 2 hours to complete it"
//I.E.: if its start time, an the user needs 30 minutes more, should that 30 minutes extend to the end time? or should the end time be treated as a hard cutoff for the schedule?
//  perhaps this should be included in the hypothetical delay system
//  --> "Delay reason, how much time delay do you need, should this affect the end time, etc."



//computed properties
extension Schedule {
    var scheduledDays: Week{
        get {
            return Week(rawValue: self.rawScheduledDays)
        }
        set {
            self.rawScheduledDays = Int16(newValue.rawValue)
        }
    }
    
    var notificationUUIDs: [String]{
        get {
            return self.notificationIDs?.split(separator: ",").map({ ss in
                return String(ss)
            }) ?? []
        }
        set{
            self.notificationIDs = newValue.joined(separator: ",")
        }
    }
    
    ///to alter the duration, set the scheduledStart and scheduledEnd properties
    var duration: Double{
        get{
            return scheduledEndTime!.timeIntervalSince(scheduledStartTime!)
        }
    }
}

extension Schedule {

//init stuff
    convenience init(context: NSManagedObjectContext, quest: Quest){
        self.init(context: context)
        isActive = false
        let d = Date.now.addingTimeInterval(10)
        scheduledStartTime = d
        scheduledEndTime = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: Date.now)
        scheduleName = quest.questName!+" Schedule"
        scheduleUUID = UUID()
        startTime = scheduledStartTime
        setSchedule(scheduledDays: .weekdays)
        lastEndDate = nil
        lastScheduleCompletedOnTime = true
        self.quest = quest
    }
    
    func setSchedule(scheduledDays: Week){
        self.everyXDays = false
        self.scheduledDays = scheduledDays
    }

    func setSchedule(frequency: Int32){
        everyXDays = true
        self.xDayDelay = frequency
    }

//Info Funcs
    func isOneTime() -> Bool{
        //if days of the week schedule with no scheduled days of the week
        return !self.everyXDays && self.rawScheduledDays == 0
    }
    
    func getActualEndTime() -> Date{
         return startTime!
            .addingTimeInterval(
                scheduledEndTime!
                    .timeIntervalSince(scheduledStartTime!))
    }
    
    
    public enum ScheduleState: Int{
        case inactive = -2
        case notStarted = -1
        case inProgress = 0
        case failed = 1
        case completed = 2
    }
    ///-2: inactive
    ///-1: not started yet
    ///0: in progress
    ///1: failed
    ///2: succeeded
    func getState() -> ScheduleState{
        //logic assumes lastEndTime < startTime < endTime
        
        //if sch not active, say that
        if(!self.isActive){ // -2
            return .inactive
        }
        //else if going to start today, return not started yet
        else if (Calendar.current.isDateInToday(self.startTime!) && Date.now < self.startTime!){
            return .notStarted
        }
        //else if after schedule start, and quest is active due to this scheduler, return in progress
        else if quest!.getCurrentScheduler() == self {
            return .inProgress
        }
        //if sch completed today -> show succeed/fail
        else if (Calendar.current.isDateInToday(self.lastEndDate ?? Date.distantFuture)){ // 1/2
            if (self.lastScheduleCompletedOnTime == false){ return .failed }
            return .completed
        }
        //else: not scheduled today, return not started yet
        else { return .failed }
    }
    
    func getNext_XDayDelay_StartTime(fromDate: Date) -> Date{
        
        let startHour = Calendar.current.component(.hour, from: scheduledStartTime!)
        let startMin = Calendar.current.component(.minute, from: scheduledStartTime!)
        let start = Calendar.current.date(bySettingHour: startHour, minute: startMin, second: 0, of: fromDate)!
        return start.addingTimeInterval(Double(self.xDayDelay * 86400))
    }
    
    func getNext_ScheduledDays_StartTime(fromDate: Date) -> Date?{
        
        if self.isOneTime() {
            return nil
        }
        //Calendar: 1..<8
        //mine:     0..<7
        let curDay = Calendar.current.component(.weekday, from: fromDate)
        
        let curDayOfWeek = curDay - 1
        
        var gap: Int = Int.max
        for i in 0..<7{
            //if day scheduled and first scheduled day found
            if scheduledDays.contains(.Element(rawValue: 1<<i)) && gap == Int.max{
                gap = i - curDayOfWeek
            }
            
            if scheduledDays.contains(.Element(rawValue: 1<<i)) && i > curDayOfWeek{
                gap = i - curDayOfWeek
                break
            }
        }
        if gap <= 0{
            gap += 7
        }
        let startHour = Calendar.current.component(.hour, from: scheduledStartTime!)
        let startMin = Calendar.current.component(.minute, from: scheduledStartTime!)
        let start = Calendar.current.date(bySettingHour: startHour, minute: startMin, second: 0, of: fromDate)!
        return start.addingTimeInterval(Double(gap*86400))
    }
    
    func getNextStartTime(fromDate: Date) -> Date{
        guard let nextStart = self.everyXDays ? getNext_XDayDelay_StartTime(fromDate: fromDate) : getNext_ScheduledDays_StartTime(fromDate: fromDate)
        else{ //if cannot get a scheduled day (no days of the week chosen or invalid delay (<1))
            //deactivate and leave start time as date given
            self.deactivateSchedule()
            return fromDate
        }
        return nextStart
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
    
    ///-1: scheduled period has passed by given date
    ///0: schedule is/would be active at given date
    ///1: schedule will not have started by given date
    func scheduledPeriodRelativity(toDate: Date = Date.now) -> Int{
        if self.getActualEndTime() <= toDate { return -1 }
        else if self.startTime! <= toDate { return 0 }
        else { return 1 }
    }
    ///Used to move the scheduled start/end dates forward to make it possible for the scheduled quest to start automatically again
    ///Can pad with QuestKeys to pretend it was doing schedules the whole time
    ///return value indicates whether start time was moved forward, backward, or stayed the same
    ///
    ///safe: indicates whether the shift could result in 'now' being between the start and end time, true = now will be before a start, false = could be between
    func amendNextScheduledPeriod(toNextStartFrom givenTime: Date, safe: Bool = true, padQuestFailures: Bool = false) -> Int{
        if self.isOneTime(){
            self.deactivateSchedule()
            return 0
        }
        
        //if start time is already ahead of the given date
        if self.startTime! > givenTime {
            //just make sure it's the IMMEDIATE next possible start
            let soonestStart = getNextStartTime(fromDate: givenTime)
            //if self.startTime is too far ahead, move it backwards
            if !soonestStart.equals(date2: self.scheduledStartTime!){
                scheduledStartTime = soonestStart
                startTime = scheduledStartTime
                scheduledEndTime = scheduledStartTime!.addingTimeInterval(self.duration)
            }
        }
        //if startTime is behind
        else{
            let moveAlongOne = { [self] in
                //add quest fails
                var duration = scheduledEndTime!.timeIntervalSince(scheduledStartTime!)
                if padQuestFailures{
                    let reward = QuestKey.generateKey(quest: self.quest!)
                    reward.keyType = QuestKeyType.failed
                    reward.scheduled = self.scheduleUUID
                    reward.obtainmentDate = self.scheduledEndTime!
                    self.quest!.addToRewards(reward)
                }
                //move schedule ahead
                scheduledStartTime = getNextStartTime(fromDate: scheduledStartTime!)
                scheduledEndTime = scheduledStartTime!.addingTimeInterval(duration)
            }
            //while current scheduled end is earlier than the given date
            while self.scheduledEndTime! < givenTime{
                moveAlongOne()
            }
            //then, move again if between start/end and safe is true
            if safe == true && self.scheduledStartTime! < givenTime{
                moveAlongOne()
            }
            
            //finalise start time
            startTime = scheduledStartTime
        }
        
        //doesnt reeally matter as this result isnt used anywhere atm.
        return givenTime.timeIntervalSince(startTime!) < 0 ? -1 : givenTime.equals(date2: startTime!) ? 0 : 1
    }
    
    public func toggleActive(){
        if self.isActive{
            self.deactivateSchedule()
        }
        else{
            self.activateSchedule()
        }
    }
    
    private func activateSchedule(){
        self.isActive = true
        self.scheduleNotifications()
    }
    
    private func deactivateSchedule(){
        self.isActive = false
        self.nextSchLocked = false
        //cancel notifications
        let notcen = UNUserNotificationCenter.current()
        notcen.removePendingNotificationRequests(withIdentifiers: self.notificationUUIDs)
        //generate key in case of PC quest start on cancelled schedule due to desync between devices
        let key = QuestKey.generateKey(quest: self.quest!)
        key.keyType = .cancelled
        
    }
    
}

//json/pc lock stuff
extension Schedule {
    
    func toJson() -> String{
        var data = "{\n"
        data.append("    \"isActive\" : " + MyJson.toJson(self.isActive) + ",\n")
        data.append("    \"questInProgress\" : " + MyJson.toJson(self.quest!.isActive) + ",\n")
        data.append("    \"schedule_everyXDays\" : " + MyJson.toJson(self.everyXDays) + ",\n")
        data.append("    \"scheduleName\" : \"" + self.scheduleName! + "\",\n")
        data.append("    \"scheduleUUID\" : \"" + self.scheduleUUID!.uuidString + "\",\n")
        data.append("    \"quest\":" + quest!.toJson() + ",\n")
        data.append("    \"schedule_XDayDelay\" : \"" + String(self.xDayDelay) + "\",\n")
        data.append("    \"startTime\" : \"" + self.startTime!.formatted(date: .numeric, time: .standard) + "\",\n")
        data.append("    \"scheduledStartTime\" : \"" + self.scheduledStartTime!.formatted(date: .numeric, time: .standard) + "\",\n")
        data.append("    \"scheduledEndTime\" : \"" + self.scheduledEndTime!.formatted(date: .numeric, time: .standard) + "\",\n")
        data.append("    \"schedule_lastCompletionTime\" : \"" + (self.lastEndDate?.formatted(date: .numeric, time: .standard) ?? "nil") + "\",\n")
        data.append("    \"schedule_scheduledDays\" : \"" + self.scheduledDays.toBitSetString() + "\"\n}")
        print(data)
        return data
    }
}

extension Schedule {
    
    //schedules the single next start time notification
    func scheduleNotifications(){
        if everyXDays{
            createIntervalNotifications()
        }else{
            createDatedNotifications()
        }
    }
    
    private func createDatedNotifications(){
        let content = UNMutableNotificationContent()
        
        content.title = self.scheduleName!
        content.body = "desc: time n date n dat"
        
        for i in 0..<7{
            if scheduledDays.contains(.Element(rawValue: 1<<i)){
                
                //create notification schedule info
                var dateComponents = DateComponents()
                dateComponents.calendar = Calendar.current
                dateComponents.weekday = i+1 // my scale 0-6 theirs 1-7
                dateComponents.hour = Calendar.current.component(.hour, from: self.scheduledStartTime!)
                dateComponents.minute = Calendar.current.component(.minute, from: self.scheduledStartTime!)
             
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                
                //create actual notification
                let uuidString = UUID().uuidString
                
                let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)

                // Schedule the request with the system.
                let notificationCenter = UNUserNotificationCenter.current()
                notificationCenter.add(request)
                self.notificationIDs?.append(","+uuidString)
            }
        }
    }
    
    private func createIntervalNotifications(){
        let nextScheduled = self.scheduledStartTime!
        print(nextScheduled)
        let content = UNMutableNotificationContent()
        
        content.title = "Scheduled Quest Start"
        content.body = self.scheduleName! + " is starting!"
        
        //create notification schedule info
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: nextScheduled.timeIntervalSince(Date.now), repeats: false)
        
        //create actual notification
        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)

        // Schedule the request with the system.
        let notificationCenter = UNUserNotificationCenter.current()
        
        notificationCenter.add(request)

    }
}
