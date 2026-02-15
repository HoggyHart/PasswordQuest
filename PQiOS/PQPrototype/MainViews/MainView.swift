//
//  MainView.swift
//  PQPrototype
//
//  Created by William Hart on 11/12/2025.
//

import SwiftUI



struct MainView: View {
    
    @Environment(\.managedObjectContext) private var context
    
    @State var SeORSc = true
    @State var menu = 0

    static private var scheduleAndQuestUpdater: Timer? = nil
    let locMan = LocationServices.service
    
    init(){
        // QuestManager.createdQuestsArr = QuestManager.createdQuests.dropLast()
        if MainView.scheduleAndQuestUpdater == nil{
            MainView.scheduleAndQuestUpdater = Timer.scheduledTimer(withTimeInterval: 1, repeats: true){_ in
                let bgContext = PersistenceController.shared.container.newBackgroundContext()
                //try to start scheduled quests
                bgContext.perform {
                    do{
                        //load schedules
                        let createdSchedules = try bgContext.fetch(Schedule.fetchRequest())
                        
                        //for each scheduled quest
                        for schedule in createdSchedules {
                            
                            //if schedule isnt active skip this one
                            if !schedule.isActive { continue }
                            
                            let quest = schedule.quest!
                            //if in progress, skip as it has already started
                            if schedule.getState() == 0
                            { continue }
                            //else if NOT in progress but quest is active (i.e. started manually/by another scheduler
                            else if quest.isActive{
                                //if quest active because of another scheduler, continue
                                if quest.getCurrentScheduler() != nil{
                                    continue
                                }
                                //else: quest not scheduled but is active during schedule time -> assume it has been started early and update schedule startTime to make this quest contribute to the schedule's completion
                                else{
                                    schedule.startTime = quest.questStartTime
                                    continue
                                }
                            }
                            
                            //  ensures Date.now is < end time
                            if Date.now > schedule.getActualEndTime(){
                                _ = schedule.amendNextScheduledPeriod(toNextStartFrom: Date.now,padQuestFailures: true)
                            }
                            //starting scheduled quest
                            //if not time, go next
                            if Date.now < schedule.startTime!{
                                continue
                            }
                            //if past time to start (and < end thx to prev check)
                            //start!
                            else{
                                quest.start(intendedStartTime: schedule.startTime!)
                                schedule.lastScheduleCompletedOnTime = false
                            }
                        }
                        try bgContext.save()
                    }catch{}
                }
            }
        }
        
    }
    
    
    @Environment(\.managedObjectContext) static public var viewContext
    var body: some View {
        VStack{
            if menu == 0{
                QuestManagerView()
            }
            else if menu == 1{
                ScheduleManagerView()
            }
            else if menu == 2{
                QuestRewardManagerView()
            }
        }
        HStack(spacing: 1){
            Button(){
                menu = 0
            } label:
            {
                Rectangle()
            }
            Button(){
                menu = 1
            } label: {
                Rectangle()
            }
            Button(){
                menu = 2
            } label: {
                Rectangle()
            }
        }
        .frame(height: 30)
    }
}

#Preview {
    MainView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
