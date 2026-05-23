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
    let views = 4
    @State var menu = 0

    static private var scheduleAndQuestUpdater: Timer? = nil
    let locMan = LocationServices.service
    
    init(){
        Task {
                let center = UNUserNotificationCenter.current()


                do {
                    try await center.requestAuthorization(options: [.alert, .sound, .badge])
                } catch {
                    // Handle the error here.
                }
        }
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
                            //if schedule isnt active or has already started: skip this one
                            if !schedule.isActive || schedule.getState() == 0 { continue }
                            let quest = schedule.quest! //shorten syntax for convenience
                            if quest.isActive { continue }
                            
                            // if scheduled period has already passed, fail quests until schedule has caught up to now
                            if Date.now > schedule.getActualEndTime(){
                                schedule.nextSchLocked = false
                                _ = schedule.amendNextScheduledPeriod(toNextStartFrom: Date.now, safe: false, padQuestFailures: true)
                            }
                            
                            //if past start time (and before end time), start
                            if Date.now > schedule.startTime!{
                                quest.start(withSchedule: schedule)
                            }
                        }
                        try bgContext.save()
                    }catch{}
                }
            }
        }
        
    }
    
    
    @Environment(\.managedObjectContext) public var viewContext
    var body: some View {
        NavigationView{
            VStack{
                
                if menu == 0{
                    QuestManagerView()
                }
                else if menu == 1{
                    ScheduleManagerView()
                }
                else if menu == 2{
                    QuestKeyManagerView()
                }
                else if menu == 3{
                    LocationManagerView()
                }
            }.navigationTitle("PasswordQuest")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden()
        }
        
        HStack(spacing: 1){
            ForEach(0..<views,id:\.self){i in
                Button(){
                    menu = i
                } label: {
                    Rectangle()
                }
            }
        }
        .frame(height: 30)
    }
}

#Preview {
    MainView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
