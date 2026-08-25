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
    var nextStart: Date {
        get{
            return startTime ?? nextScheduledStart
        }
        set{
            self.startTime = newValue
        }
    }
    var nextScheduledStart: Date{
        get{
            
            return scheduledStartTime ?? {
                scheduledStartTime = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date.now.addingTimeInterval(86400))
                self.startTime = scheduledStartTime
                return scheduledStartTime!
                }()
        }
        set{
            self.scheduledStartTime = newValue
            self.startTime = newValue
        }
    }
    var nextScheduledEnd: Date{
        get{
            return self.scheduledEndTime ?? {
                scheduledEndTime = nextScheduledStart.addingTimeInterval(86400)
                return scheduledEndTime!
            }()
        }
        set{
            self.scheduledEndTime = newValue
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
            return nextScheduledEnd.timeIntervalSince(nextScheduledStart)
        }
    }
    func correctEndTime(){
        while self.duration <= 0{
            nextScheduledEnd.addTimeInterval(86400)
        }
        while self.duration > 86400{
            nextScheduledEnd.addTimeInterval(-86400)
        }
    }
}

extension Schedule {

//init stuff
    convenience init(context: NSManagedObjectContext, quest: Quest){
        self.init(context: context)
        scheduleName = quest.name+" Schedule"
        nextScheduledStart = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date.now.addingTimeInterval(86400))!
        nextScheduledEnd = nextScheduledStart.addingTimeInterval(86400)
        scheduleUUID = UUID()
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
    
    var endTime: Date{
        get{
            return scheduledEndTime!
        }
    }
    func getActualEndTime() -> Date{
         return scheduledEndTime!
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
    
    func delay(duration: Double) -> Void{
        if (GlobalQuestLoot.getLoot(self.managedObjectContext!).timeInABottle.updateStoredTime(amount: -Int(duration)/60) == 0) {
            return
        }
        if self.scheduledPeriodRelativity() == .now{
            self.startTime = Date.now.addingTimeInterval(duration)
            self.quest?.isActive = false
            self.quest?.questStartTime = self.startTime
        }
        else{
            self.startTime?.addTimeInterval(duration)
        }
        /*
         let delayImpactsSchedule = true //FIX: Not yet fully implemented / may also affect hour/minute depending on frequency of schedule if I improve schedule versatility to sub-day intervals
         if delayImpactsSchedule{
             scheduledStartTime!.addTimeInterval(delay)
             scheduledEndTime!.addTimeInterval(delay)
         }
         */
    }
    func getNext_XDayDelay_StartTime(fromDate: Date) -> Date{
        
        let startHour = Calendar.current.component(.hour, from: nextScheduledStart)
        let startMin = Calendar.current.component(.minute, from: nextScheduledStart)
        let start = Calendar.current.date(bySettingHour: startHour, minute: startMin, second: 0, of: fromDate)!
        return start.addingTimeInterval(Double(self.xDayDelay * 86400))
    }
    
    func getNext_ScheduledDays_StartTime(fromDate: Date) -> Date?{
        if self.isOneTime() {
            return nil
        }
        
        //Calendar: 1..<8
        //mine:     0..<7 (-1)
        let curDayOfWeek = Calendar.current.component(.weekday, from: fromDate) - 1
        
        var gap: Int = Int.max
        for i in 0..<7{
            //if day scheduled and is the first scheduled day found
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
        let startHour = Calendar.current.component(.hour, from: nextScheduledStart)
        let startMin = Calendar.current.component(.minute, from: nextScheduledStart)
        let start = Calendar.current.date(bySettingHour: startHour, minute: startMin, second: 0, of: fromDate)!
        return start.addingTimeInterval(Double(gap*86400))
    }
    
    
    
    func getNextStartTime(fromDate: Date) -> Date?{
        return self.everyXDays ? getNext_XDayDelay_StartTime(fromDate: fromDate) : getNext_ScheduledDays_StartTime(fromDate: fromDate)
    }
    
    ///Called when scheduled quest finishes
    func endScheduledPeriod(){
        //finish period
        self.lastEndDate = Date.now
        self.lastScheduleCompletedOnTime = self.quest!.tasksComplete()
        self.updateSchedule()
    }
    func updateSchedule(){
        let dur = self.duration
        var nextStart = getNextStartTime(fromDate: self.nextScheduledStart)
        if nextStart == nil { self.deactivateSchedule() }
        
        nextScheduledStart = nextStart ?? nextScheduledStart
        nextScheduledEnd = nextScheduledStart.addingTimeInterval(dur)
        scheduleNotification()
    }
    
    ///-1: scheduled period has passed by given date
    ///0: schedule is/would be active at given date
    ///1: schedule will not have started by given date
    public enum ScheduleRelativity: Int{
        case past = -1
        case now = 0
        case future = 1
    }
    func scheduledPeriodRelativity(toDate: Date = Date.now) -> ScheduleRelativity{
        if self.endTime <= toDate { return .past }
        else if self.startTime! <= toDate { return .now }
        else { return .future }
    }
    ///Used to move the scheduled start/end dates forward to make it possible for the scheduled quest to start automatically again
    ///Can pad with QuestKeys to pretend it was doing schedules the whole time
    ///return value indicates whether start time was moved forward, backward, or stayed the same
    ///
    func ensureValidAutostart(from givenTime: Date, padQuestFailures: Bool = false){
        let oneTime = self.isOneTime()
        
        let moveAlongOne = { [self] in
            //add quest fails]
            if padQuestFailures{
                let reward = QuestKey.generateKey(quest: self.quest!)
                reward.keyType = QuestKeyType.failed
                reward.scheduled = self.scheduleUUID
                reward.obtainmentDate = self.scheduledEndTime!
                self.quest!.addToRewards(reward)
            }
            //move schedule ahead
            scheduledStartTime = getNextStartTime(fromDate: scheduledStartTime!)
        }
        //push back start until start date is in the future
        if oneTime{ self.everyXDays = true; self.xDayDelay = 1}
        while self.scheduledStartTime! <= givenTime{
            moveAlongOne()
        }
        if oneTime{ self.everyXDays = false }
        
        //finalise start time and end time
        startTime = scheduledStartTime
        self.correctEndTime()
    }
    
    public func toggleActive(){
        if self.isActive{
            self.deactivateSchedule()
        }
        else{
            self.correctEndTime()
            self.activateSchedule()
        }
    }
    
    private func activateSchedule(){
        self.isActive = true
        self.scheduleNotification()
    }
    
    private func deactivateSchedule(){
        self.isActive = false
        self.nextSchLocked = false
        //generate key in case of PC quest start on cancelled schedule due to desync between devices
        let key = QuestKey.generateKey(quest: self.quest!)
        key.keyType = .cancelled
        //cancel notifications
        let notcen = UNUserNotificationCenter.current()
        notcen.removePendingNotificationRequests(withIdentifiers: self.notificationUUIDs)
        
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
    func scheduleNotification(){
        if everyXDays{
            createIntervalNotification()
        }else{
            createDatedNotification()
        }
    }
    
    func queueNotif(content: UNNotificationContent, trigger: UNNotificationTrigger){
        //create actual notification
        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)

        // Schedule the request with the system.
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.add(request)
    }
    
    private func createDatedNotification(){
        let content = QuestStartNotification(questName: self.quest!.name, scheduleName: self.scheduleName)
        
        //create notification schedule info
        
        var dateComponents = DateComponents()
        dateComponents.calendar = Calendar.current
        dateComponents.day = Calendar.current.component(.day, from: self.nextScheduledStart)
        dateComponents.hour = Calendar.current.component(.hour, from: self.nextScheduledStart)
        dateComponents.minute = Calendar.current.component(.minute, from: self.nextScheduledStart)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        queueNotif(content: content, trigger: trigger)
    }
    
    private func createIntervalNotification(){
        let content = QuestStartNotification(questName: self.quest!.name, scheduleName: self.scheduleName)
        //create notification schedule info
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(self.nextScheduledStart.timeIntervalSince(Date.now),1), repeats: false)
        
        queueNotif(content: content, trigger: trigger)
    }
}
