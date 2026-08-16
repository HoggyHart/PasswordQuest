//
//  QuestView.swift
//  PQPrototype
//
//  Created by William Hart on 12/12/2025.
//

import SwiftUI
import CoreData
import CoreLocation
struct QuestView: View {
    @Environment(\.managedObjectContext) private var context
    
    
    // -- CoreData
    @ObservedObject
    var quest: Quest
    @FetchRequest private var tasks: FetchedResults<SingleLocationTask>
    
    //needs to be QuestTask realistically, but using that makes it crash "fetch request must have an entity"

    // -- View state stuff
    
    init(quest: Quest){
        self.quest = quest
        
        
        _tasks = FetchRequest(
                sortDescriptors: [
                    NSSortDescriptor(keyPath: \QuestTask.objectID, ascending: true)
                ],
                predicate: NSPredicate(format: "quest == %@", quest)
            )
    }
    
    var lockButton: some View {
        Button(){
            context.perform{
                quest.locked = true
                do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
            }
        } label :{
            ZStack{
                RoundedRectangle(cornerRadius: 50, style: .circular)
                    .foregroundColor(quest.locked ? .gray : .red)
                Image(systemName: quest.locked ? "lock.fill" : "lock.open.fill")
                    .foregroundColor(quest.locked ? .black : .white)
                    .font(.title2)
            }
            .frame(width: 50)
        }
        .disabled(quest.locked ? true : false)
    }
    
    var questStatusButton: some View{
        Button(){
            startEndResetButtonFunc()
        } label : {
            ZStack{
                RoundedRectangle(cornerRadius: 50, style: .circular)
                    .foregroundColor(statusColor())
                Text(startEndResetButtonText()).foregroundColor(.white)
            }
        }
    }
    
    var body: some View {
        
        VStack{
            //title
            HStack{
                TextField("Quest Name", text: $quest.questName)
                    .font(.title)
                Image(systemName:"pencil")
            }
            Divider()
            
            //task list
            QuestTaskList(quest: quest, full: false)

            //schedule list
            ScheduleList(quest: quest)
            
            //start/end/lock buttons
            HStack{
                //lock/unlock button
                if quest.isActive {
                    lockButton
                }
                //start/end button
                ZStack{
                    questStatusButton
                }
            }.frame(width: 250, height: 50)
            if quest.isActive{
                Button(){
                    context.perform {
                        if quest.getCurrentScheduler()?.delay(duration: 300) == nil{
                            let tempSch = Schedule(context: context, quest: quest)
                            tempSch.setSchedule(scheduledDays: Week(rawValue: 0))
                            tempSch.scheduledStartTime = quest.questStartTime
                            tempSch.startTime = Date.now.addingTimeInterval(300)
                            tempSch.scheduledEndTime = Date.distantFuture
                            tempSch.isActive = true
                            tempSch.nextSchLocked = true
                            //TODO: simplify this whole chunk. make schedule making quicker
                            //      AND see about just calling .delay() on the sch and remove need for this below bit VVV
                            quest.isActive = false
                            quest.questStartTime = tempSch.startTime
                            for t in quest.tasks!{
                                (t as! QuestTask).endDependenciesAndTrackers()
                            }
                        }
                        
                        let k = QuestKey.generateKey(quest: quest)
                        k.keyType = .cancelled
                        do{try context.save()}catch{}
                    }
                } label: {
                    Text("Delay 5 Minutes (5\(Image(systemName: "hourglass")))")
                }
            }
        }
        .padding(EdgeInsets(top: 0.0, leading: 30.0, bottom: 0.0, trailing: 30.0))
    }

    func startEndResetButtonFunc(){
        context.perform{
            switch(quest.questStatus()){
                //ended due to failed/succeeded
            case .failed, .completed:
                quest.reset()
                //inactive
            case .inactive:
                do{
                    try quest.start()
                }catch _ as FailedStartError{
                    
                    //highlight problematic task/ pop up with whatever the fail reason was
                }catch{}
                //active
            case .inProgress:
                if quest.locked{
                    if GlobalQuestLoot.getLoot(context).timeInABottle.updateStoredTime(amount: -quest.maxRewardValue, impactTrackers: true) != 0{
                        quest.end()
                        let k = QuestKey.generateKey(quest: quest)
                        k.keyType = .complete
                    }
                    do{try context.save()}catch{}
                }
                else{
                    quest.end()
                }
            case .paused:
                quest.isActive = true
                do{
                    for t in quest.tasks!{
                        try (t as! QuestTask).initDependenciesAndTrackers()
                    }
                }catch{}
                guard let sch = quest.getCurrentScheduler() else { break }
                sch.startTime = Date.now
                quest.questStartTime = sch.startTime
            default: // also for -2: inactive + no quests
                //do nothing, unknown status
                
                print("no tasks/unknown quest state")
            }
            do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
        }
    }
    func startEndResetButtonText() -> String{
        ///-2: inactive, no tasks
        ///-1: inactive, failed
        ///0: inactive, not started
        ///1: active
        ///2: inactive, completed successfully
        switch(quest.questStatus()){
        case .failed:
            return "Failed"
        case .inactive:
            return "Start"
        case .inProgress:
            if quest.locked{
                return "Skip? (\(quest.maxRewardValue))"
            }
            return "End"
        case .completed:
            return "Turn In"
        case .paused:
            return "Resume"
        default:
            return "Unknown status"
        }
    }
    func statusColor() -> Color {
        ///-2: inactive, no tasks
        ///-1: inactive, failed
        ///0: inactive, not started
        ///1: active
        ///2: inactive, completed successfully
        switch(quest.questStatus()){
        case .failed:
            return .red
        case .inactive, .paused:
            return .blue
        case .inProgress:
            return .gray
        case .completed:
            return .green
        default:
            return .yellow
        }
    }
}

#Preview {
    let stdQuest = Quest(context: PersistenceController.preview.container.viewContext, name: "New Quest")
    let task = SingleLocationTask(context: PersistenceController.preview.container.viewContext, dummyVar: true)
    stdQuest.addToTasks(task)
    let schedule = Schedule(context: PersistenceController.preview.container.viewContext, quest: stdQuest)
    
    return NavigationView{QuestView(quest: stdQuest).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
