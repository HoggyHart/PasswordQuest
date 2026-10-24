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
    
    let stampWHRatio: CGFloat = 1.75
    @State var stampRotation: Double = Double.random(in: QuestView.stampRotationRange)
    static let stampRotationRange: Range<Double> = -20..<20
    var questStatusButton: some View{
        Button(){
            startEndResetButtonFunc()
            stampRotation = Double.random(in: QuestView.stampRotationRange)
        } label : {
            ZStack{
                Rectangle()
                    .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .miter, miterLimit: 0,dash: [25,120*stampWHRatio-50,25,0,25,70,25,0],dashPhase: 0))
                    .foregroundColor(.classicInk)
                Text(startEndResetButtonText)
                    .font(Font.custom("Old Stamper", size: 60))
                    .foregroundColor(statusColor)
                    .minimumScaleFactor(0.1)
                    .lineLimit(1)
                    .rotationEffect(Angle(degrees: stampRotation))
                    .shadow(color:.classicInk, radius: 1.5)
            }.frame(width: 120*stampWHRatio, height: 120)
        }
        .buttonStyle(ButtonStampAnimationStyle())
    }
    
    @StateObject var jViewModel = JournalViewModel()
    @StateObject var viewModel = QuestTaskManagerViewModel()
 
    var extraTaskPages: Int{
        get{
            return 1 + viewModel.fullList.count/viewModel.subListSize
        }
    }
    
    var body: some View {
        JournalView(extraPages: 1 + extraTaskPages, backgroundPages: true, viewModel: jViewModel) {
            
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
                if jViewModel.page == 1{
                    VStack(spacing:0){
                        //Rewards
                        VStack(alignment:.leading, spacing:0){
                            Text("Rewards").underline().font(.journalSubheading).offset(y:jViewModel.lineHeight/2 - 12.5).frame(height: jViewModel.lineHeight)
                            HStack{
                                if quest.maxRewardValue.truncatingRemainder(dividingBy: 1) != 0{
                                    Text("\(Int(quest.maxRewardValue)) - \(Int(quest.maxRewardValue+1))")
                                }else{
                                    Text("\(Int(quest.maxRewardValue))")
                                }
                                Text("Time in a Bottle")
                            }.frame(height: JournalDefaults.defaultRowHeight)
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
                                      //  lockButton
                                    }
                                    //start/end button
                                    ZStack{
                                        questStatusButton
                                    }
                                }
//                                if quest.isActive{
//                                    Button(){
//                                        context.perform {
//                                            quest.delay(seconds: 300)
//                                            do{try context.save()}catch{}
//                                        }
//                                    } label: {
//                                        Text("Delay 5 Minutes (5\(Image(systemName: "hourglass")))")
//                                    }
//                                }
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
                //page 2+
                else{
                    VStack(spacing:0){
                        //pages 2 -> (x-1)
                        if jViewModel.page <= 1 + extraTaskPages{
                            VStack(alignment: .leading, spacing: 0){
                                HStack(spacing: 0){
                                    Text("Tasks").underline().font(.journalSubheading).frame(height:jViewModel.lineHeight).offset(y:jViewModel.lineHeight/2 - 25/2)
                                }
                                QuestTaskListView(quest: quest, listItemHeight: jViewModel.lineHeight,viewModel: viewModel).frame(minHeight:0)
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
                    .id(jViewModel.page)
                    .onChange(of: jViewModel.page) { newValue in
                        print("hi")
                        viewModel.updateSubList(newOffset: (jViewModel.page-2)*viewModel.subListSize)
                    }
                }
            }
        }.navigationBarHidden(true)
            .onAppear(){
                viewModel.subListSize = jViewModel.lines-1
                viewModel.assignPredicateQuest(quest: quest)
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
    var startEndResetButtonText: String{
        ///-2: inactive, no tasks
        ///-1: inactive, failed
        ///0: inactive, not started
        ///1: active
        ///2: inactive, completed successfully
        switch(quest.questStatus()){
        case .failed:
            return "[Failed]"
        case .inactive:
            return ""
        case .inProgress:
//            if quest.locked{
//                return "Skip? (\(Int(quest.maxRewardValue)))"
//            }
            return "[Active]"
        case .completed:
            return "[Complete]"
        case .paused:
            return "[Paused]"
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
            return .yellow
        case .completed:
            return .green
        default:
            return .purple
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
        QuestView(quest: stdQuest)
    }.environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
