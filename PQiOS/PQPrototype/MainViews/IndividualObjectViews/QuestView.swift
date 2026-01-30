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
    @Environment(\.managedObjectContext) private var context
    
    @ObservedObject 
    var quest: Quest
    
    //needs to be QuestTask realistically, but using that makes it crash "fetch request must have an entity"
    @FetchRequest private var tasks: FetchedResults<LocationOccupationQuestTask>
    @FetchRequest private var schedules: FetchedResults<Schedule>
    
    @State private var inspectedTaskID: NSManagedObjectID? = nil
    @State private var inspectedScheduleID: NSManagedObjectID? = nil
    @State private var schButtonFlip: Bool = false
    private var isTaskSheetPresented: Binding<Bool> { Binding(get: { inspectedTaskID != nil }, set: { if !$0 { inspectedTaskID = nil } }) }
    private var isScheduleSheetPresented: Binding<Bool> { Binding(get: { inspectedScheduleID != nil }, set: { if !$0 { inspectedScheduleID = nil } }) }
    
    @State private var liveUpdater: Timer?
    
    init(quest: Quest){
        self.quest = quest
        
        _tasks = FetchRequest(
                sortDescriptors: [
                    NSSortDescriptor(keyPath: \LocationOccupationQuestTask.objectID, ascending: true)
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
    
    func startLiveUpdater(){
        self.liveUpdater = Timer.scheduledTimer(withTimeInterval: 1, repeats: true){_ in
            let bgContext = PersistenceController.shared.container.newBackgroundContext()
            bgContext.perform {
                do{
                    let quest = bgContext.object(with: quest.objectID) as! Quest
                    if !quest.isActive { return; }
                    
                    quest.updateProgress()
                    print("updated")
                    //if now completed
                    if !quest.isActive{
                        //check if there are any other quests still in progress
                        let allQuests = try bgContext.fetch(Quest.fetchRequest())
                        var anyActive = false
                        //FIX: the quest used here is from the mainContext, but this fetches from the background context. they do not share the same status and as such the bgContext one has not ended yet so the location service does not stop. Also this may have something to do with the liveUpdate not updating values correctly?
                        for individualQuest in allQuests{
                            if individualQuest.isActive{
                                anyActive = true
                            }
                        }
                        //if this was the only active quest, stop updating location
                        if !anyActive {LocationServices.service.locationManager.stopUpdatingLocation() }
                    }
                    
                    try bgContext.save()
                }catch{
                    print("FAILED QUEST UPDATING")
                    //mark flag to indicate failure to update
                }
            }
        }
    }
    
    var body: some View {
        VStack{
            HStack{
                TextField("Quest Name", text: $quest.questName ?? "Unset")
                    .font(.title)
                    .disabled(!editMode!.wrappedValue.isEditing)
                if editMode!.wrappedValue.isEditing {Image(systemName:"pencil")}
            }
            Divider()
            HStack{
                Text("Tasks: ")
                Spacer()
                if editMode!.wrappedValue.isEditing {
                    Button(){
                        addTask()
                    } label: {
                        Label("Add Task", systemImage: "plus")
                    }
                }
            }
            List{
                ForEach(tasks){qtask in
                    Button(){
                        inspectedTaskID = qtask.objectID
                    } label:{
                        HStack{
                            Image(systemName: "circle.fill")
                                .foregroundColor( taskStatusColor(task: qtask) )
                            Text(qtask.toString())
                            Spacer()
                        }
                    }
                }
                .onDelete(perform: deleteTasks)
            }
            .listStyle(PlainListStyle())
            
            HStack{
                Text("Schedules")
                Spacer()
                if editMode!.wrappedValue.isEditing {
                    Button(){
                        addSchedule()
                    } label: {
                        Label("Create Schedule", systemImage: "timer")
                    }
                }
            }
            List{
                ForEach(schedules){schedule in
                    Button(){
                        inspectedScheduleID = schedule.objectID
                        schButtonFlip = false
                    } label:{
                        HStack{
                            Text("\(schedule.scheduleName!)")
                            Spacer()
                            Button(){
                                ///-2 -> inactive, no start date
                                ///-1 -> already displaying start date
                                ///0 -> in progress
                                if schedule.getState() == 1
                                    || schedule.getState() == 2 {//schButtonFlip.toggle()
                                }
                            } label : {
                                ZStack{
                                    RoundedRectangle(cornerRadius: 1000, style: .circular)
                                        .foregroundColor(schBtnClr(schedule: schedule, dateOnly: schButtonFlip))
                                        .shadow(color: .black, radius: 1)
                                    schBtnText(schedule: schedule, dateOnly: schButtonFlip)
                                        .foregroundColor(.black)
                                }
                                .frame(width: schBtnWidth(schedule: schedule, dateOnly: schButtonFlip), height: 40)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteSchedules)
            }
            .listStyle(PlainListStyle())
            HStack{
                if quest.isActive {
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
                Button(){
                    startEndResetButtonFunc()
                } label : {
                    ZStack{
                        RoundedRectangle(cornerRadius: 50, style: .circular)
                            .foregroundColor(statusColor())
                        Text(startEndResetButtonText()).foregroundColor(.white)
                    }
                }
                .disabled(quest.locked ? true : false)
            }.frame(width: 250, height: 50)
        }
        .padding(EdgeInsets(top: 0.0, leading: 30.0, bottom: 0.0, trailing: 30.0))
        .toolbar(){
            if !quest.isActive { EditButton() }
        }
        .sheet(isPresented: isTaskSheetPresented){
            if let id = inspectedTaskID {
                let localTask = context.object(with: id) as! LocationOccupationQuestTask
                LocationTaskView(locationTask: localTask) }
        }
        .sheet(isPresented: isScheduleSheetPresented) {
            if let id = inspectedScheduleID {
                let localSchedule = context.object(with: id) as! Schedule 
                ScheduleView(scheduleToLoad: localSchedule)
            }
        }
        .onChange(of: editMode!.wrappedValue.isEditing) { v in
            if v == false{
                context.perform {
                    do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
                }
            }
        }
        .onAppear(perform: startLiveUpdater)
        .onDisappear {
            liveUpdater?.invalidate()
            liveUpdater = nil
        }
    }
    
    func taskStatusColor(task: QuestTask) -> Color{
        ///-2: inactive, no tasks -> doesnt matter what colour - take default
        ///-1: inactive, failed
        ///0: inactive, not started
        ///1: active
        ///2: inactive, completed successfully
        switch(quest.questStatus()){
        case -1:
            return .red
        case 0:
            return .white
        case 1:
            if task.completed { return .green }
            return .yellow
        case 2:
            return .green
        default:
            return .purple
        }
    }
    func startEndResetButtonFunc(){
        context.perform{
            switch(quest.questStatus()){
                //ended due to failed/succeeded
            case -1, 2:
                quest.reset()
                //inactive
            case 0:
                quest.start(intendedStartTime: Date.now)
                //active
            case 1:
                quest.end()
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
        case -1:
            return "Failed"
        case 0, -2:
            return "Start"
        case 1:
            return "End"
        case 2:
            return "Turn In"
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
        case -1:
            return .red
        case 0, -2:
            return .blue
        case 1:
            return .gray
        case 2:
            return .green
        default:
            return .yellow
        }
    }
    
    func schBtnText(schedule: Schedule, dateOnly: Bool = false) -> Text{
        ///-2: inactive
        ///-1: not started yet
        ///0: in progress
        ///1: failed
        ///2: succeeded
        var text: Text
        switch(dateOnly ? -1 : schedule.getState()){
        case -2:
            text = Text("Inactive \(Image(systemName:"x.circle.fill"))")
        case -1:
            text = Text("\(Image(systemName: "timer")) ") + Text(!Calendar.current.isDateInToday(schedule.startTime!) ? schedule.startTime!.formatted(date: .abbreviated, time: .omitted)
                :
                schedule.startTime!.formatted(date: .omitted, time: .shortened))
        case 0:
            text = Text("\(Image(systemName: "timer")) In Progress ")
        case 1:
            text = Text("\(Image(systemName: "x.circle.fill")) Failed")
        case 2:
            text = Text("\(Image(systemName: "checkmark.circle.fill")) Success")
        default:
            text = Text("Error")
        }
        return text
    }
    func schBtnClr(schedule: Schedule, dateOnly: Bool = false) -> Color{
        ///-2: inactive
        ///-1: not started yet
        ///0: in progress
        ///1: failed
        ///2: succeeded
        var btnColor: Color
        switch(dateOnly ? -1 : schedule.getState()){
        case -2:
            btnColor = .gray
        case -1:
            btnColor = .white
        case 0:
            btnColor = .yellow
        case 1:
            btnColor = .red
        case 2:
            btnColor = .green
        default:
            btnColor = .purple
        }
        return btnColor
    }
    func schBtnWidth(schedule: Schedule, dateOnly: Bool = false) -> CGFloat{
        ///-2: inactive
        ///-1: not started yet
        ///0: in progress
        ///1: failed
        ///2: succeeded
        var btnWidth: CGFloat
        switch(dateOnly ? -1 : schedule.getState()){
        case -2:
            btnWidth = 105
        case -1:
            btnWidth = !Calendar.current.isDateInToday(schedule.startTime!) ? 150 : 105
        case 0:
            btnWidth = 130
        case 1:
            btnWidth = 100
        case 2:
            btnWidth = 115
        default:
            btnWidth = 75
        }
        return btnWidth
    }
    
    func addTask(){
        context.perform {
        withAnimation {
                let task = LocationOccupationQuestTask(context: context)
                task.lateInit(
                    locName: "Unnamed Location",
                    taskArea: CLCircularRegion(
                        center: CLLocationCoordinate2D(
                            latitude: 53.827443,
                            longitude: -1.592948
                        ),
                        radius: 50,
                        identifier: "newLocTask"),
                    questDuration: 3
                )
                quest.addToTasks(task)
                do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
            }
        }
    }
    private func deleteTasks(offsets: IndexSet) {
        context.perform {
            withAnimation {
            
                offsets.map {tasks[$0] }.forEach(context.delete)
                do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
            }
        }
    }
    
    func addSchedule(){
        context.perform {
            withAnimation {
            
                let schedule = Schedule(context: context)
                schedule.lateInit(quest: quest)
                do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
            }
        }
    }
    private func deleteSchedules(offsets: IndexSet) {
        context.perform {
            withAnimation {
            
                offsets.map {schedules[$0] }.forEach(context.delete)
                do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
            }
        }
    }
}

#Preview {
    var stdQuest = Quest(context: PersistenceController.preview.container.viewContext)
    stdQuest.lateInit(name: "New Quest")
    let task = LocationOccupationQuestTask(context: PersistenceController.preview.container.viewContext)
    task.lateInit(locName: "Uni Library", taskArea: CLCircularRegion(center: CLLocationCoordinate2D(latitude: 50, longitude: 70), radius: 25, identifier: "idk"), questDuration: 5400)
    stdQuest.addToTasks(task)
    let schedule = Schedule(context: PersistenceController.preview.container.viewContext)
    schedule.lateInit(quest: stdQuest)
    
    return NavigationView{QuestView(quest: stdQuest).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
