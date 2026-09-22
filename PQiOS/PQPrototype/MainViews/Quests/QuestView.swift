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
    
    var taskStartIndex: Int{
        get{
            return max(0, (viewModel.page-2)*16 + 8 - 1)
        }
    }
    var taskEndIndex: Int{
        get{
            if viewModel.page == 1 {
                return tasks.count > 7 ? 7 : 8 //step back for "More on next page" label
            }
            return (viewModel.page-2)*16 + 24 - 1
        }
    }
    var extraTaskPages: Int{
        get{
            if tasks.count < 8 { return 0 }
            else if tasks.count < 23 { return 1 }
            return 2+((tasks.count-23)/16)
        }
    }
    var body: some View {
        JournalView(extraPages: 1 + extraTaskPages, backgroundPages: true, viewModel: viewModel) {
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
                            Text("Tasks").underline().font(.custom("Bradley Hand", size: 25)).frame(height:30).offset(y:5)
                            QuestTaskList(quest: quest,firstTaskIndex: taskStartIndex,lastTaskIndex: taskEndIndex)
                            if tasks.count>7{
                                Text("Continued on next page...").frame(height: 30)
                            }
                        }
                        //Rewards
                        VStack(alignment:.leading, spacing:0){
                            Text("Rewards").underline().font(.custom("Bradley Hand", size: 25)).offset(y:5).frame(height: 30)
                            HStack{
                                if quest.maxRewardValue.truncatingRemainder(dividingBy: 1) != 0{
                                    Text("\(Int(quest.maxRewardValue)) - \(Int(quest.maxRewardValue+1))")
                                }else{
                                    Text("\(Int(quest.maxRewardValue))")
                                }
                                Text("Time in a Bottle")
                            }.frame(height: 30)
                        }.frame(maxWidth: .infinity,alignment: .leading)
                        Spacer()
                        
                        //Quest Start/Scheduling
                        HStack(spacing:0){
                            //TODO: replace with stamp area, questStatusButton will be replaced with Empty, Completed, Failed, Paused, etc. stamps
                            //When active stamp is tapped, replace text with "End?" and highlight a stopwatch to the right with a "Pause?" label
                            VStack{
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
                                            quest.delay(seconds: 300)
                                            do{try context.save()}catch{}
                                        }
                                    } label: {
                                        Text("Delay 5 Minutes (5\(Image(systemName: "hourglass")))")
                                    }
                                }
                            }
                            Spacer()
                            NavigationLink(destination: ScheduleManagerView(predicate: NSPredicate(format:"quest == %@",quest))) {
                                ZStack{
                                    Image("Stopwatch").resizable()
                                        .aspectRatio(contentMode: .fit).rotationEffect(.degrees(20))
                                    Text("Schedules").font(.title)
                                }
                            }
                        }.frame(height: 120)
                    }.frame(maxWidth:.infinity, alignment: .topLeading)
                    .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                }
                else{
                    VStack(spacing:0){
                        if viewModel.page <= 1 + extraTaskPages{
                            VStack(alignment: .leading, spacing: 0){
                                HStack(spacing: 0){
                                    Text("Tasks").underline().font(.custom("Bradley Hand", size: 25)).frame(height:30).offset(y:5)
                                    Text(" cont. (\(viewModel.page-1)/\(extraTaskPages))").font(.custom("Bradley Hand", size: 15)).offset(y:10)
                                }
                                QuestTaskList(quest: quest,
                                              firstTaskIndex: taskStartIndex,
                                              lastTaskIndex: taskEndIndex)
                                .frame(minHeight:0)
                            }
                        }
                        else{
                            EditButton()
                            ScheduleList(quest: quest).frame(height: 100)
                            
                          //  start/end/lock buttons
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
                                        quest.delay(seconds: 300)
                                        do{try context.save()}catch{}
                                    }
                                } label: {
                                    Text("Delay 5 Minutes (5\(Image(systemName: "hourglass")))")
                                }
                            }
                        }
                    }
                    .frame(maxWidth:.infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                    .id(viewModel.page)
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
    task.name = "Manual Task"
    stdQuest.addToTasks(task)
    let task1 = TrainingQuestTask(context: PersistenceController.preview.container.viewContext)
    task1.name = "Training Task"
    stdQuest.addToTasks(task1)
    let task2 = SingleLocationTask(context: PersistenceController.preview.container.viewContext, dummyVar: true)
    stdQuest.addToTasks(task2)
    task2.name = "Single Location Task"
    let task3 = RNGLocationTask(context: PersistenceController.preview.container.viewContext, dummyVar: true)
    task3.name = "Randomly Generated Location Task"
    stdQuest.addToTasks(task3)
    let schedule = Schedule(context: PersistenceController.preview.container.viewContext, quest: stdQuest)
    //0,7,8,23,38
    for i in 0..<35{
        let task3 = RNGLocationTask(context: PersistenceController.preview.container.viewContext, dummyVar: true)
        task3.name = "Task \(i)"
        stdQuest.addToTasks(task3)
    }
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
