//
//  File.swift
//  PQPrototype
//
//  Created by William Hart on 01/01/2026.
//
import Foundation
import UserNotifications

//cpomputed property
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
            return self.notificationIDs?.split(separator: ",") as! [String]
        }
        set{
            self.notificationIDs = newValue.joined(separator: ",")
        }
    }
}

extension Schedule {
    
    func setSchedule(scheduledDays: Week){
        self.everyXDays = false
        self.scheduledDays = scheduledDays
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
        scheduleName = quest.questName!+" Schedule"
        scheduleUUID = UUID()
        startTime = scheduledStartTime
        setSchedule(scheduledDays: .weekdays)
        lastEndDate = nil
        lastScheduleCompletedOnTime = true
        self.quest = quest
    }
    
    func nxtDateTxt() -> String{
            return !Calendar.current.isDateInToday(self.startTime!) ? self.startTime!.formatted(date: .abbreviated, time: .omitted)
                        :
                        self.startTime!.formatted(date: .omitted, time: .shortened)
    }
    
    func isOneTime() -> Bool{
        //if days of the week schedule with no scheduled days of the week
        return !self.everyXDays && self.rawScheduledDays == 0
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
        //else if going to start today, return not started yet
        else if (Calendar.current.isDateInToday(self.startTime!) && Date.now < self.startTime!){
            return -1
        }
        //else if after schedule start, and quest is active due to this scheduler, return in progress
        else if quest!.getCurrentScheduler() == self {
            return 0
        }
        //if sch completed today -> show succeed/fail
        else if (Calendar.current.isDateInToday(self.lastEndDate ?? Date.distantFuture)){ // 1/2
            if (self.lastScheduleCompletedOnTime == false){ return 1 }
            return 2
        }
        //else: not scheduled today, return not started yet
        else { return -1 }
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
        if gap < 0{
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
    ///Used to move the scheduled start/end dates forward to make it possible for the scheduled quest to start automatically
    ///Can pad with QuestRewards to pretend it was doing schedules the whole time
    ///return value indicates whether start time was moved forward, backward, or stayed the same
    func amendNextScheduledPeriod(toNextStartFrom: Date, padQuestFailures: Bool = false) -> Int{

        if self.isOneTime(){
            self.deactivateSchedule()
            return 0
        }
        
        let dur = self.getDuration()
        
        //if start time is already ahead of the given date
        if toNextStartFrom < self.startTime! {
            //just make sure it's the IMMEDIATE next possible start
            let nextScheduledStartTime = getNextStartTime(fromDate: toNextStartFrom)
            
            if !nextScheduledStartTime.equals(date2: self.scheduledStartTime!){
                scheduledStartTime = nextScheduledStartTime
                startTime = scheduledStartTime
                scheduledEndTime = scheduledStartTime!.addingTimeInterval(dur)
            }
        }
        else{
            //while current scheduled start is earlier than the given date
            
            while self.scheduledStartTime! < toNextStartFrom{
                //add quest "rewards"
                if padQuestFailures{
                    let reward = QuestReward.generateStandardKey(quest: self.quest!)
                    reward.questComplete = false
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
        }
        
        //doesnt reeally matter as this result isnt used anywhere atm.
        return toNextStartFrom.timeIntervalSince(startTime!) < 0 ? -1 : toNextStartFrom.equals(date2: startTime!) ? 0 : 1
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
        
        self.nextSchLocked = false
        self.scheduleNotifications()
    }
    
    private func deactivateSchedule(){
        self.isActive = false
        self.nextSchLocked = false
        //cancel notifications
        let notcen = UNUserNotificationCenter.current()
        notcen.removePendingNotificationRequests(withIdentifiers: self.notificationUUIDs)
        //generate key in case of PC quest start on cancelled schedule due to desync between devices
        _ = QuestReward.generateNullifyKey(quest: self.quest!)
        
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
        data.append("    \"schedule_scheduledDays\" : \"" + String(self.rawScheduledDays,radix: 2) + "\"\n}")
        print(data)
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
                    //print("Error: \(error.localizedDescription)")
                } else if let response = (response as? HTTPURLResponse){
                    // Process the data
                    if response.statusCode == 200{
                        
                    }
                }
            }
            task.resume()
        }
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
                self.notificationUUIDs.append(uuidString)
            }
        }
    }
    
    private func createIntervalNotifications(){
        let nextScheduled = self.scheduledStartTime!
        print(nextScheduled)
        let content = UNMutableNotificationContent()
        
        content.title = self.scheduleName!
        content.body = "desc: time n date n dat"
        
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
