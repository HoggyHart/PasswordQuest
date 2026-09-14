import Foundation
import UserNotifications
import CoreData

class FailedStartError: Error{
    let reasons: String
    init(reasons: String) {
        self.reasons = reasons
    }
}

extension Quest{
    convenience init(context: NSManagedObjectContext, name: String){
        self.init(context: context)
        self.name = name
        self.questUUID = UUID()
    }
    
    var minRewardValue: Float{
        get{ return 0 }
    }
    
    var maxRewardValue: Float{
        get{
            var tot: Float = 0
            for t in tasks!.allObjects as! [QuestTask]{
                tot += t.maxReward
            }
            return tot
        }
    }
    
    
//Start, Update, End, Reset
    //make throw as a result of failed task starts
    public func start(withSchedule sch: Schedule? = nil) throws{
        if tasks!.allObjects.isEmpty || self.isActive { return } //if no tasks or already in progress, nothing to start
        self.reset()
        
        
        self.isActive = true
        self.questStartTime = sch?.startTime ?? Date.now
        
        var errors: String = ""
        for t in tasks!{
            do{
                try (t as! QuestTask).start()
            }catch let e as InvalidTaskError{
                errors.append("\(e.task) with invalid \(e.invalidAttribute), ")
            }
        }
        if errors != ""{
            errors.removeLast(2)
            self.managedObjectContext!.undo()
            throw FailedStartError(reasons: errors)
        }
        
        //if scheduled start, check schedule data that impacts quest
        guard let sch = sch else {return}
        self.locked = sch.nextSchLocked
        sch.lastScheduleCompletedOnTime = false
    }
    
    public func updateProgress(){
        if self.isActive{
            if self.questStartTime == nil {
                self.end(reason: .error, error:"active quest with no start time") //TODO: make an in-app notification about this
                return
            }
            var stillInProgress = false
            
            for qTask in self.tasks!{
                let qTask = qTask as! QuestTask
                if !qTask.completed{
                    do{
                        try qTask.update()
                    }catch let e as InvalidTaskError{
                        self.end(reason: .error, error:"\(e.task) with invalid \(e.invalidAttribute)")
                    }catch let e{
                        fatalError(e.localizedDescription)
                    }
                    //if still not completed
                    if !qTask.completed{
                        //mark that a task in still in progress
                        stillInProgress = true
                    }
                }
            }
            //if all tasks completed, end quest
            if !stillInProgress{
                self.end()
            }
            //alternatively, if quest not finished BUT time has run out
            else if Date.now.timeIntervalSince(self.questStartTime!) > self.maxQuestDuration{
                self.end()
            }//or via schedule end if it is active due to a scheduler
            else if let sch = self.getCurrentScheduler(){
                if Date.now > sch.getActualEndTime(){
                    self.end()
                }
            }
        }
    }
    public enum QuestEndReason{
        case natural
        case error
        case skipped
        case cancelled
    }
    public func end(reason: QuestEndReason = .natural, error: String? = nil){
        if self.isActive{
        
            for t in tasks!{
                (t as! QuestTask).endDependenciesAndTrackers()
            }
            //geeenerate notif
            let notif = UNMutableNotificationContent()
            notif.title = "Quest Complete!"
            notif.body = error == nil ? self.name + " is now complete!" : self.name + " ended due to a goblin hex!"
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: notif, trigger: trigger)
            let notifCenter = UNUserNotificationCenter.current()
            notifCenter.add(request)
            
            //create quest reward (key)
            let reward = QuestKey.generateKey(quest: self)
            if reason == .error || reason == .cancelled{
                reward.keyType = .cancelled
            } else if reason == .skipped{
                reward.keyType = .complete
            } else if reason == .natural{
                var rewardT: Float = 0
                for t in tasks!.allObjects{
                    let t = t as! QuestTask
                    rewardT += t.currentReward
                }
                _ = GlobalQuestLoot.getLoot(self.managedObjectContext!).timeInABottle.updateStoredTime(amount: rewardT, impactTrackers: true)
            }
            self.addToRewards(reward)
            
            //end scheduler
            endCurrentScheduler()
            
            //leave task progress and questStartTime alone to indicate quest status as completed or failed
            //these are changed in reset()
            self.isActive = false
            self.locked = false
        }
    }
    
    public func reset(){
        endCurrentScheduler()
        
        for qTask in self.tasks!{
            (qTask as! QuestTask).reset()
        }
        
        self.questStartTime = nil
    }
    
    public func pause(){
        self.isActive = false
        self.questStartTime = Date.distantFuture //so the quest is flagged as paused in Quest.questStatus()
        for t in tasks!{
            (t as! QuestTask).endDependenciesAndTrackers()
        }
    }
    
    public func resume() throws{
        self.isActive = true
        self.questStartTime = Date.now
        for t in tasks!{
            do{
                try (t as! QuestTask).initDependenciesAndTrackers()
            }catch let e as InvalidTaskError{
            }
        }
    }
//Status Checking
    ///-2: inactive, no quests
    ///-1: inactive, failed
    ///0: inactive, not started
    ///1: active
    ///2: inactive, completed successfully
    public enum QuestStatus: Int{
        case inactive = -2
        case failed = -1
        case notStarted = 0
        case inProgress = 1
        case completed = 2
        case paused = 3
    }
    public func questStatus() -> QuestStatus{
        
        //if active, its in progress
        if self.isActive { return .inProgress }
        //if no quests to be completed, indicate there is nothing to start
        else if self.tasks?.allObjects.isEmpty ?? true { return .inactive }
        //if inactive and questStartTime == nil, that means the quest has been officially ended and is waiting for next start
        else if questStartTime == nil { return .inactive}
        else if questStartTime! > Date.now { return .paused}
        //if inactive and tasks are complete, that means successfully finished and pending submission
        else if tasksComplete(){ return .completed }
        //only option left is inactive with incomplete quests - failed
        else { return .failed }
        
    }
    public func tasksComplete() -> Bool{
        //optionals used here because when deleting a quest that just been QuestView'd the app crashes (not tested if it is based on not having added any tasks or not)
        //if no tasks -> return false (this is so QuestView doesnt let you turn in an empty quest
        if self.tasks?.allObjects.isEmpty ?? true { return false }
        for qTask in self.tasks!{
            if !(qTask as! QuestTask).completed{
                return false
            }
        }
        return true
    }
    
    public func getCurrentScheduler() -> Schedule?{
        guard let qst = self.questStartTime else { return nil }
        for schedule in schedulers!{
            let schedule = schedule as! Schedule
            //if this scheduler is active and was scheduled to start a quest at the same time this quest was started (i.e. this scheduler started this now-ending quest) then log the last completion date
            if schedule.isActive && schedule.nextStart.equals(date2: qst) {
                return schedule
            }
        }
        return nil
    }
    
    public func delay(seconds: Double) {
        //delay schedule, or if no scheduler, create temp schedule
        if self.getCurrentScheduler()?.delay(duration: seconds) == nil{
            let tempSch = Schedule(context: self.managedObjectContext!, quest: self)
            tempSch.setSchedule(scheduledDays: Week(rawValue: 0))
            tempSch.nextScheduledStart = self.questStartTime!.addingTimeInterval(seconds)
            tempSch.nextScheduledEnd = self.questStartTime!.addingTimeInterval(seconds+86400)
            tempSch.isActive = true
            tempSch.nextSchLocked = true
            
            self.pause()
            self.questStartTime = tempSch.startTime
        }
        
        let k = QuestKey.generateKey(quest: self)
        k.keyType = .cancelled
    }
    public func endCurrentScheduler(){
        if let scheduler = getCurrentScheduler(){
            scheduler.endScheduledPeriod()
        }
    }
    
    public func delay(){
        //https://developer.apple.com/documentation/usernotifications/untimeintervalnotificationtrigger
    }
}

//Portability stuff
extension Quest{
    
    func toJson() -> String{
        var string = "{\n"
        string += "    \"questName\" : \""+self.name+"\",\n"
        string += "    \"questUUID\" : \"" + self.questUUID!.uuidString + "\",\n"
        string += "    \"expiryDate\" : \"" + (self.getCurrentScheduler()?.scheduledEndTime ?? (self.questStartTime ?? Date.now).addingTimeInterval(maxQuestDuration)).formatted(date: .numeric, time: .standard) + "\"\n"
        string +=   "}"
        print(string)
        return string
    }
    
    func sendStartQuestSignal(){
        if let url = URL(string:"http://172.20.10.5:1617/synchronise/activequest") {
            var request = URLRequest(url: url)
            
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            
            let questKey = self.toJson()
            
            let newData = Data(questKey.utf8)
            let task = URLSession.shared.uploadTask(with: request, from: newData){ data, response, error in
                //print("sent")
                if let error = error {
                    // Handle the error
                    //print("Error: \(error.localizedDescription)")
                } else if let response = (response as? HTTPURLResponse){
                    // Process the data
                    //print(response.statusCode)
                    if response.statusCode == 200{
                        //print("Success")
                    }
                }
            }
            task.resume()
        }
    }
}
