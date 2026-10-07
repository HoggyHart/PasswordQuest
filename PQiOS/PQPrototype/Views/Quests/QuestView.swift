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
    
    @Environment(\.editMode) private var editMode
    private var editing: Bool { get { return  editMode!.wrappedValue.isEditing }}
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) var dismiss
    
    // -- CoreData
    @ObservedObject
    var quest: Quest
    @FetchRequest private var schedules: FetchedResults<Schedule>
    
    init(quest: Quest){
        self.quest = quest
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
                    .foregroundColor(statusColor)
                Text(startEndResetButtonText).foregroundColor(.white)
            }
        }
    }
    
    @StateObject var journalViewModel = JournalViewModel()
    @StateObject var viewModel = QuestTaskManagerViewModel()
    let rowHeight: CGFloat = 50
    
    let pageLines = 8
    
    var extraTaskPages: Int{
        get{
            
            // 0 to F-1 ( the Xth one is replaced with "cont next page" to signify where overflow tasks go )
//            if viewModel.questTasks.count < firstPageTasks { return 1 }
//            // F to F + Y-1 -1 ( overflow Firstpage + amount that fit on a page - 1 (-1 since the Fth is one of those on-page tasks)
//            else if viewModel.questTasks.count < firstPageTasks + perPageTasks - 1 { return 2 }
//            //first extra page + first of these new pages + extra page per full page of tasks
//            // eppfpot =  (total tasks - tasks shown already)/perPageTasks
//            return 3+(viewModel.questTasks.count - (firstPageTasks - 1 + perPageTasks))/perPageTasks
            return 1 + viewModel.questTasks.count/8
        }
    }
    
    var body: some View {
        JournalView(extraPages: 1 + extraTaskPages, lines: viewModel.listSize+1, lineHeight: rowHeight, backgroundPages: true, viewModel: journalViewModel) {
            
            //Header: Page title and quest name
            VStack(spacing:0){
                Button {
                    dismiss()
                } label: {
                    Label {
                        Text("Quest Log")
                    } icon: {
                        Image(systemName: "arrowshape.turn.up.left.fill")
                            .foregroundColor(.darkRed)
                    }.foregroundColor(.gray)
                }.frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                HStack(){
                    TextField("Quest Name", text: $quest.name)
                        .font(.journalTitle)
                    if !quest.isActive{
                        EditButton().font(.journalSubheading)
                        Image(systemName:"pencil").foregroundColor(.blue)
                    }
                }
                Rectangle().frame(height: 2)
            }.frame(maxWidth: .infinity,alignment: .leading)
            .padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 10))
        } content: {
            VStack{
                if journalViewModel.page == 1{
                    VStack(spacing:0){
                        //task list
//                        VStack(alignment: .leading, spacing: 0){
//                            Text("Tasks").underline().font(.journalSubheading).frame(height:rowHeight)
//                                .offset(y:rowHeight/2 - 12.5)
//                            QuestTaskList(quest: quest, listItemHeight: rowHeight, viewModel: viewModel)
//                            if viewModel.displayedQuestTasks.count>firstPageTasks-1{
//                                Text("Continued on next page...").frame(height: rowHeight) //TODO: make nicer. conceptually i like this, but having 1 task on a separate layout from all the rest feels strange
//                            }
//                        }
                        //Rewards
                        VStack(alignment:.leading, spacing:0){
                            Text("Rewards").underline().font(.journalSubheading).offset(y:rowHeight/2 - 12.5).frame(height: rowHeight)
                            HStack{
                                if quest.maxRewardValue.truncatingRemainder(dividingBy: 1) != 0{
                                    Text("\(Int(quest.maxRewardValue)) - \(Int(quest.maxRewardValue+1))")
                                }else{
                                    Text("\(Int(quest.maxRewardValue))")
                                }
                                Text("Time in a Bottle")
                            }.frame(height: rowHeight)
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
                    }
                    .frame(maxWidth:.infinity, alignment: .topLeading)
                    .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                }
                else{
                    VStack(spacing:0){
                        if journalViewModel.page <= 1 + extraTaskPages{
                            VStack(alignment: .leading, spacing: 0){
                                HStack(spacing: 0){
                                    Text("Tasks").underline().font(.journalSubheading).frame(height:rowHeight).offset(y:rowHeight/2 - 25/2)
                                }
                                QuestTaskListView(quest: quest, listItemHeight: rowHeight,viewModel: viewModel).frame(minHeight:0)
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
                    .id(journalViewModel.page)
                }
            }
        }.navigationBarHidden(true)
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
    var startEndResetButtonText: String{
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
    var statusColor: Color {
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
    let schedule = Schedule(context: PersistenceController.preview.container.viewContext, quest: stdQuest)
    //0,7,8,23,38
    for i in 0..<22{
        let task3 = TrainingQuestTask(context: PersistenceController.preview.container.viewContext)
        task3.name = "Task \(i)"
        stdQuest.addToTasks(task3)
    }
    
    
    
    stdQuest.isActive = true
    return VStack(spacing: 0){
        MainHeader()
        QuestView(quest: stdQuest)}.environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
