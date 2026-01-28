//
//  File.swift
//  PQPrototype
//
//  Created by William Hart on 01/01/2026.
//
import Foundation

extension Schedule : Identifiable {
    public func lateInit(quest: Quest){
        isActive = false
        let d = Date.now.addingTimeInterval(10)
        scheduledStartTime = d
        scheduledEndTime = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: Date.now)
        scheduleName = "Scheduled "+quest.questName!
        scheduleUUID = UUID()
        startTime = scheduledStartTime
        schedule = ScheduleTypeInfo(scheduledDays: .everyday)
        lastEndDate = nil
        lastScheduleCompletedOnTime = true
        synchronised = false
        self.quest = quest
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
        else if (Date.now < self.startTime!){
            return -1
        }
        else { return 0 }
        
        
    }
    
    func getNext_XDayDelay_StartTime(fromDate: Date) -> Date{
        return fromDate.addingTimeInterval(Double(schedule!.XDayDelay * 86400))
    }
    
    func getNext_ScheduledDays_StartTime(fromDate: Date) -> Date{
        let curDay = Calendar.current.component(.weekday, from: fromDate)
        
        let curDayOfWeek = curDay - 2 < 0 ? 6 : curDay - 2
        
        var gap: Int = Int.max
        for i in 0..<7{
            //if day scheduled and first scheduled day found
            if schedule!.scheduledDays.contains(.Element(rawValue: 1<<i)) && gap == Int.max{
                gap = i - curDayOfWeek
            }
            
            if schedule!.scheduledDays.contains(.Element(rawValue: 1<<i)) && i > curDayOfWeek{
                gap = i - curDayOfWeek
                break
            }
        }
        if gap < 0{
            gap += 7
        }
        return fromDate.addingTimeInterval(Double(gap*86400))
    }
    
    func updateStartTime(delay: Double?){
        
        if delay != nil{
            startTime!.addTimeInterval(delay!)
            return
        }
        
        let dur = scheduledEndTime!.timeIntervalSince(scheduledStartTime!)
        
        let startMinute = Calendar.current.component(.minute, from: scheduledStartTime!)
        let startHour = Calendar.current.component(.hour, from: scheduledStartTime!)
        scheduledStartTime = Calendar.current.date(bySettingHour: startHour, minute: startMinute, second: 0, of: startTime!)!
        
        if schedule!.everyXDays{
            scheduledStartTime = getNext_XDayDelay_StartTime(fromDate: scheduledStartTime!)
        }else{
            scheduledStartTime = getNext_ScheduledDays_StartTime(fromDate: scheduledStartTime!)
        }
        startTime = scheduledStartTime
        scheduledEndTime = scheduledStartTime!.addingTimeInterval(dur)
    }
    
    func toJson() -> String{
        var data = "{\n"
        data.append("\"isActive\" : \"" + (self.isActive ? "True" : "False") + "\",\n")
        data.append("\"questInProgress\" : \"" + (self.quest!.isActive ? "True" : "False") + "\",\n")
        data.append("\"schedule_everyXDays\" : \"" + (self.schedule!.everyXDays ? "True" : "False") + "\",\n")
        data.append("\"scheduleName\" : \"" + self.scheduleName! + "\",\n")
        data.append("\"scheduleUUID\" : \"" + self.scheduleUUID!.uuidString + "\",\n")
        data.append("\"questUUID\" : \"" + self.quest!.questUUID!.uuidString + "\",\n")
        data.append("\"schedule_XDayDelay\" : \"" + String(self.schedule!.XDayDelay) + "\",\n")
        data.append("\"startTime\" : \"" + self.startTime!.formatted(date: .numeric, time: .standard) + "\",\n")
        data.append("\"scheduledStartTime\" : \"" + self.scheduledStartTime!.formatted(date: .numeric, time: .standard) + "\",\n")
        data.append("\"scheduledEndTime\" : \"" + self.scheduledEndTime!.formatted(date: .numeric, time: .standard) + "\",\n")
        data.append("\"schedule_lastCompletionTime\" : \"" + (self.lastEndDate?.formatted(date: .numeric, time: .standard) ?? "nil") + "\",\n")
        data.append("\"schedule_scheduledDays\" : \"" + self.schedule!.scheduledDays.toBitSetString() + "\"\n}")
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
    
    func getActualEndTime() -> Date{
         return startTime!
            .addingTimeInterval(
                scheduledEndTime!
                    .timeIntervalSince(scheduledStartTime!))
    }
    //called at a time where lastCompletionDate < Date.now.
    // if quest turned in, then schedule update goes to next start time since lastCompletionDate
    // this allows the user to stack up schedule completions since lastScheduleCompletedOnTime is set to true here
    // I think this is a nice feature, but could lead to a potential system abuse problem
    func turnInQuest(){
        if let url = URL(string:"http://172.20.10.5:1617") {
            var request = URLRequest(url: url)
            
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            let key = self.scheduleUUID!.uuidString + "_" + (lastScheduleCompletedOnTime ? "YES" : "nil")
            let newData = Data(key.utf8)
            let task = URLSession.shared.uploadTask(with: request, from: newData){ data, response, error in
                if let error = error {
                    // Handle the error
                    print("Error: \(error.localizedDescription)")
                } else if let response = (response as? HTTPURLResponse){
                    // Process the data
                    if response.statusCode == 200{
                        //if quest is still in progress then end it
                        //questStartTime = nil if quest has ended (i.e. completed successfully
                        if self.startTime!.timeIntervalSince1970 == self.quest!.questStartTime?.timeIntervalSince1970{
                            self.quest!.end()
                        }
                
                        self.updateStartTime(delay: nil)
                        self.lastEndDate = Date.now
                        self.lastScheduleCompletedOnTime = true
                    }
                }
            }
            task.resume()
        }
    }
}
