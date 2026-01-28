import Foundation
extension Quest : Identifiable {
    
    public func lateInit(name: String){
        self.isActive = false
        self.maxQuestDuration = 86400
        self.restrictedDeviceIPs = ""
        self.questName = name
        self.questUUID = UUID()
    }
    //start time usually is Date.now, but care must be taken to sync it with a scheduler if appropriate, so pass in the exact Date object
    public func start(intendedStartTime: Date){
        if tasks!.allObjects.isEmpty { return }
        reset()
        self.isActive = true
        self.questStartTime = intendedStartTime
        for t in tasks!{
            (t as! QuestTask).start()
        }
    }
    
    public func updateProgress(){
        if self.isActive{
            var stillInProgress = false
            
            for qTask in self.tasks!{
                let qTask = qTask as! QuestTask
                if !qTask.completed{
                    //did not see any .isUpdatingLocation checks, so just keep starting everytime a task is found to be still active
                    LocationServices.service.locationManager.startUpdatingLocation()
                    //and update progress
                    qTask.update()
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
            else if self.questStartTime!.timeIntervalSinceNow > self.maxQuestDuration{
                self.fail()
            }//or via schedule end if it is active due to a scheduler
            else if let sch = self.getCurrentScheduler(){
                if Date.now > sch.getActualEndTime(){
                    self.fail()
                }
            }
        }
    }
    ///-2: inactive, no quests
    ///-1: inactive, failed
    ///0: inactive, not started
    ///1: active
    ///2: inactive, completed successfully
    public func questStatus() -> Int{
        
        //if active, its in progress
        if self.isActive { return 1 }
        //if inactive and tasks are complete, that means successfully finished and pending submission
        else if tasksComplete(){ return 2 }
        //if no quests to be completed, indicate there is nothing to start
        else if self.tasks!.allObjects.isEmpty { return -2 }
        //if inactive and questStartTime == nil, that means the quest has been officially ended and is waiting for next start
        else if questStartTime == nil { return 0 }
        //only option left is inactive with incomplete quests - failed
        else { return -1 }
        
    }
    public func tasksComplete() -> Bool{
        if self.tasks!.allObjects.isEmpty { return false }
        for qTask in self.tasks!{
            if !(qTask as! QuestTask).completed{
                return false
            }
        }
        return true
    }
    
    public func getCurrentScheduler() -> Schedule?{
        for schedule in schedulers!{
            let schedule = schedule as! Schedule
            //if this scheduler is active and was scheduled to start a quest at the same time this quest was started (i.e. this scheduler started this now-ending quest) then log the last completion date
            if schedule.isActive && schedule.startTime?.timeIntervalSince1970 == questStartTime?.timeIntervalSince1970 {
                return schedule
            }
        }
        return nil
    }
    public func endCurrentSchduler(){
        if let scheduler = getCurrentScheduler(){
            //lastEndDate
            scheduler.lastEndDate = Date.now
            ////was it completed on time? is the current time earlier than the deadline?
            //was it completed on time -> Were the tasks complete? This assumes that the quest cannot continue beyond the scheduled time
            scheduler.lastScheduleCompletedOnTime = tasksComplete()//Date.now <= scheduler.getActualEndTime()
            scheduler.updateStartTime(delay: nil)
        }
    }
    
    public func reset(){
        for qTask in self.tasks!{
            (qTask as! QuestTask).reset()
        }
        
        endCurrentSchduler()
        
        self.isActive = false
        self.questStartTime = nil
    }
    public func end(){
        if self.isActive{
            self.isActive = false
            
            //create quest reward (key)
            let reward = QuestReward(context: self.managedObjectContext!)
            reward.completedOnTime = tasksComplete()
            reward.key = self.questUUID!
            reward.obtainmentDate = Date.now
            reward.scheduled = getCurrentScheduler() != nil
            self.addToRewards(reward)
            
            //end scheduler
            endCurrentSchduler()
            
            //leave task progress and questStartTime alone to indicate quest status as completed or failed
            //these are changed in reset()
            locked = false
        }
    }
    public func fail(){
        //just end, as proper failure mechanics are not yet implemented
        end()
    }
}
