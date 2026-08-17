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
        self.isActive = false
        self.maxQuestDuration = 86400
        self.restrictedDeviceIPs = ""
        self.questName = name
        self.questUUID = UUID()
    }
    
    var minRewardValue: Int{
        get{ return 0 }
    }
    
    var maxRewardValue: Int{
        get{
            var tot = 0
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
        
        self.isActive = true
        self.questStartTime = sch?.startTime ?? Date.now
        
        //populate with initial task data
        self.updateProgress()
        
        //if scheduled start, check schedule data that impacts quest
        guard let sch = sch else {return}
        if sch.nextSchLocked{
            self.locked = true
        }
        sch.lastScheduleCompletedOnTime = false
    }
    
    public func updateProgress(){
        if self.isActive{
            //TODO: remove this when the various getScheduler and start early issues are fixed
            if self.questStartTime == nil { self.questStartTime = Date.now}
            var stillInProgress = false
            
            for qTask in self.tasks!{
                let qTask = qTask as! QuestTask
                if !qTask.completed{
                    do{
                        try qTask.update()
                    }catch let e as InvalidTaskError{
                        self.end(error:"\(e.task) with invalid \(e.invalidAttribute)")
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
    
    public func end(error: String? = nil){
        if self.isActive{
        
            for t in tasks!{
                (t as! QuestTask).endDependenciesAndTrackers()
            }
            //geeenerate notif
            let notif = UNMutableNotificationContent()
            notif.title = "Quest Complete!"
            notif.body = error == nil ? self.questName + " is now complete!" : self.questName + " ended due to a goblin hex!"
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: notif, trigger: trigger)
            let notifCenter = UNUserNotificationCenter.current()
            notifCenter.add(request)
            
            //create quest reward (key)
            let reward = QuestKey.generateKey(quest: self)
            if error != nil {reward.keyType = QuestKeyType.cancelled}
            var rewardT: Int = 0
            for t in tasks!.allObjects{
                let t = t as! QuestTask
                rewardT += t.currentReward
            }
            if error == nil {_ = GlobalQuestLoot.getLoot(self.managedObjectContext!).timeInABottle.updateStoredTime(amount: rewardT, impactTrackers: true)}
            self.addToRewards(reward)
            
            //end scheduler
            endCurrentSchduler()
            
            //leave task progress and questStartTime alone to indicate quest status as completed or failed
            //these are changed in reset()
            self.isActive = false
            self.locked = false
            self.questStartTime = nil
        }
    }
    
    //set progress to 0 and deactivate
    public func reset(){
        for qTask in self.tasks!{
            (qTask as! QuestTask).reset()
        }
        
        endCurrentSchduler()
        
        self.isActive = false
        self.questStartTime = nil
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
        //if inactive and tasks are complete, that means successfully finished and pending submission
        else if tasksComplete(){ return .completed }
        //if no quests to be completed, indicate there is nothing to start
        else if self.tasks?.allObjects.isEmpty ?? true { return .inactive }
        //if inactive and questStartTime == nil, that means the quest has been officially ended and is waiting for next start
        else if questStartTime == nil { return .inactive}
        else if questStartTime! > Date.now { return .paused}
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
        if !self.isActive || self.questStartTime == nil {return nil}
        for schedule in schedulers!{
            let schedule = schedule as! Schedule
            //if this scheduler is active and was scheduled to start a quest at the same time this quest was started (i.e. this scheduler started this now-ending quest) then log the last completion date
            if schedule.isActive && schedule.startTime!.equals(date2: questStartTime!) {
                return schedule
            }
        }
        return nil
    }
    public func endCurrentSchduler(){
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
        string += "    \"questName\" : \""+self.questName+"\",\n"
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
