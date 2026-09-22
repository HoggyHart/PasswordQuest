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
    @FetchRequest private var tasks: FetchedResults<QuestTask>
    @FetchRequest private var schedules: FetchedResults<Schedule>
    
    init(quest: Quest){
        self.quest = quest
        _tasks = FetchRequest(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \QuestTask.objectID, ascending: true)
            ],
            predicate: NSPredicate(format: "quest == %@", quest)
        )
        _schedules = FetchRequest(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Schedule.objectID, ascending: true)
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
    
    @StateObject var viewModel = JournalViewModel()
    
    var body: some View {
        JournalView(extraPages: 1+(tasks.count-7)/8, backgroundPages: true, viewModel: viewModel) {
            VStack(spacing:0){
                Spacer()
                HStack(){
                    TextField("Quest Name", text: $quest.name)
                        .font(.custom("Bradley Hand", size: 30))
                    Image(systemName:"pencil")
                }
                Rectangle().frame(height: 2)
            }.padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
        } content: {
            VStack{
                if viewModel.page == 1{
                    VStack(spacing:0){
                        //task list
                        VStack(alignment: .leading, spacing: 0){
                            HStack{
                                Text("Tasks").underline().font(.custom("Bradley Hand", size: 25))
                            }.frame(height:30)
                            ForEach(0..<8){i in
                                if i < tasks.count{
                                    if i == 7{
                                        Text("Continued on next page...").frame(height: 30)
                                    }else{
                                        HStack(){
                                            ZStack{
                                                if quest.isActive{
                                                    RoundedRectangle(cornerRadius: 20).frame(width:60,height:20).foregroundColor( QuestTaskList.taskStatusColor(task: tasks[i]) )
                                                        .shadow(color:.black, radius: 1)
                                                    // Image(systemName: "circle.fill")
                                                    //    .foregroundColor( QuestTaskList.taskStatusColor(task: qtask) )
                                                    //  .shadow(color:.black, radius: 1)
                                                    Text(tasks[i].currentStatus() + " ")
                                                }
                                            }
                                            Text("- " + (tasks[i].name ?? "Error")).foregroundColor(UITraitCollection.current.userInterfaceStyle == .dark ? Color.white : Color.black).font(.custom("Bradley Hand", size: 20))
                                        }.frame(height: 30)
                                    }
                                }else{
                                    Spacer().frame(height: 30)
                                }
                            }.offset(y:-3.5)
                        }.frame(
                            maxWidth: .infinity,
                            alignment: .topLeading
                        ).offset(y:-1)
                        
                        
                        // ScheduleList(quest: quest).frame(height: 100)
                        
                        //start/end/lock buttons
                        //                    HStack{
                        //                        //lock/unlock button
                        //                        if quest.isActive {
                        //                            lockButton
                        //                        }
                        //                        //start/end button
                        //                        ZStack{
                        //                            questStatusButton
                        //                        }
                        //                    }.frame(width: 250, height: 50)
                        //                    if quest.isActive{
                        //                        Button(){
                        //                            context.perform {
                        //                                quest.delay(seconds: 300)
                        //                                do{try context.save()}catch{}
                        //                            }
                        //                        } label: {
                        //                            Text("Delay 5 Minutes (5\(Image(systemName: "hourglass")))")
                        //                        }
                        //                    }
                        //Rewards
                        VStack(alignment:.leading, spacing:0){
                            Text("Rewards").underline().font(.custom("Bradley Hand", size: 25))
                            if quest.maxRewardValue.truncatingRemainder(dividingBy: 1) != 0{
                                Text("\(Int(quest.maxRewardValue)) - \(Int(quest.maxRewardValue+1)) Grains of Time")
                            }else{
                                Text("\(Int(quest.maxRewardValue)) Grains of Time")
                            }
                        }.frame(maxWidth: .infinity,alignment: .leading).offset(y:-1)
                        Spacer()
                        HStack(spacing:0){
                            Placeholder(description: "Stamp Area")
                            Spacer()
                            NavigationLink(destination: ScheduleManagerView(predicates: [NSPredicate(format:"quest == %@",quest)])) {
                                ZStack{
                                    Image("Stopwatch").resizable()
                                        .aspectRatio(contentMode: .fit).rotationEffect(.degrees(20))
                                    Text("Schedules").font(.title)
                                }
                            }
                        }.frame(height: 120)
                    }.padding(EdgeInsets(top: 5, leading: 10, bottom: 0, trailing: 10))
                }
                else{
                    if tasks.count > 7{
                        VStack(alignment: .leading, spacing: 0){
                            HStack{
                                Text("Tasks").underline().font(.custom("Bradley Hand", size: 25))
                            }.frame(height:30)
                            ForEach(7..<22){i in
                                if i < tasks.count{
                                    if i == 22{
                                        Text("Continued on next page...").frame(height: 30)
                                    }else{
                                        HStack(){
                                            ZStack{
                                                if quest.isActive{
                                                    RoundedRectangle(cornerRadius: 20).frame(width:60,height:20).foregroundColor( QuestTaskList.taskStatusColor(task: tasks[i]) )
                                                        .shadow(color:.black, radius: 1)
                                                    // Image(systemName: "circle.fill")
                                                    //    .foregroundColor( QuestTaskList.taskStatusColor(task: qtask) )
                                                    //  .shadow(color:.black, radius: 1)
                                                    Text(tasks[i].currentStatus() + " ")
                                                }
                                            }
                                            Text("- " + (tasks[i].name ?? "Error")).foregroundColor(UITraitCollection.current.userInterfaceStyle == .dark ? Color.white : Color.black).font(.custom("Bradley Hand", size: 20))
                                        }.frame(height: 30)
                                    }
                                }else{
                                    Spacer().frame(height: 30)
                                }
                            }.offset(y:-3.5)
                            Spacer()
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(EdgeInsets(top: 5, leading: 10, bottom: 0, trailing: 10))
                    }
                }
            }
        }
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
                        quest.end(reason:.skipped)
                    }
                    do{try context.save()}catch{}
                }
                else{
                    quest.end(reason: .cancelled)
                }
            case .paused:
                let sch = quest.getCurrentScheduler()
                do{
                    try quest.resume()
                }catch{}
                sch?.startTime = quest.questStartTime
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
                return "Skip? (\(Int(quest.maxRewardValue))"
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
    let task = ManualQuestTask(context: PersistenceController.preview.container.viewContext)
    stdQuest.addToTasks(task)
    let task1 = TrainingQuestTask(context: PersistenceController.preview.container.viewContext)
    stdQuest.addToTasks(task1)
    let task2 = SingleLocationTask(context: PersistenceController.preview.container.viewContext, dummyVar: true)
    stdQuest.addToTasks(task2)
    task2.name = "SLT"
    let task3 = RNGLocationTask(context: PersistenceController.preview.container.viewContext, dummyVar: true)
    task3.name = "RNGLT"//eallyReallyLongNameToCheckWhatHappensIfItGoesOffTheEdge"
    stdQuest.addToTasks(task3)
    let schedule = Schedule(context: PersistenceController.preview.container.viewContext, quest: stdQuest)
    
    let task4 = ManualQuestTask(context: PersistenceController.preview.container.viewContext)
    stdQuest.addToTasks(task4)
    let task5 = ManualQuestTask(context: PersistenceController.preview.container.viewContext)
    stdQuest.addToTasks(task5)
    let task6 = ManualQuestTask(context: PersistenceController.preview.container.viewContext)
    stdQuest.addToTasks(task6)
    let task7 = ManualQuestTask(context: PersistenceController.preview.container.viewContext)
    stdQuest.addToTasks(task7)
//    let task8 = ManualQuestTask(context: PersistenceController.preview.container.viewContext)
//    stdQuest.addToTasks(task8)
//    let task9 = ManualQuestTask(context: PersistenceController.preview.container.viewContext)
//    stdQuest.addToTasks(task9)
//    let task10 = ManualQuestTask(context: PersistenceController.preview.container.viewContext)
//    stdQuest.addToTasks(task10)
//    let task11 = ManualQuestTask(context: PersistenceController.preview.container.viewContext)
//    stdQuest.addToTasks(task11)
//    let task12 = ManualQuestTask(context: PersistenceController.preview.container.viewContext)
//    stdQuest.addToTasks(task12)
//    let task13 = ManualQuestTask(context: PersistenceController.preview.container.viewContext)
//    stdQuest.addToTasks(task13)
//    let task14 = ManualQuestTask(context: PersistenceController.preview.container.viewContext)
//    stdQuest.addToTasks(task14)
    
    
    
    stdQuest.isActive = true
    return QuestView(quest: stdQuest).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
