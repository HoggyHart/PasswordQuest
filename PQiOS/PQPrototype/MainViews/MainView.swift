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
                bgContext.perform {
                    do{
                        //load schedules
                        let createdSchedules = try bgContext.fetch(Schedule.fetchRequest())
                        
                        //for each scheduled quest
                        for schedule in createdSchedules {
                            
                            //if schedule isnt active skip this one
                            if !schedule.isActive { continue }
                            
                            let quest = schedule.quest!
                            //if scheduled quest is already active
                            //  OR scheduled quest has already been completed today
                            //IMPROVEMENT: add a "complete quest ahead of schedule" option
                            //
                            //if quest already active OR it was completed and the startTime has not updated (via turning in quest)
                            if quest.isActive
                                || (schedule.lastEndDate ?? Date.distantPast > schedule.startTime!)
                            { continue }
                            
                            //if still in window to start quest, start it
                            if schedule.startTime! <= Date.now && Date.now < schedule.getActualEndTime() {
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
