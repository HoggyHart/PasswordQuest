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
    
    
    // -- CoreData
    @ObservedObject
    var quest: Quest
    
    //needs to be QuestTask realistically, but using that makes it crash "fetch request must have an entity"

    // -- View state stuff
    
    
    @State private var liveUpdater: Timer?
    
    init(quest: Quest){
        self.quest = quest
    }
    
    func startLiveUpdater(){
        self.liveUpdater = Timer.scheduledTimer(withTimeInterval: 1, repeats: true){_ in
            let bgContext = PQPrototypeApp.isPreview ?  PersistenceController.preview.container.newBackgroundContext() : PersistenceController.shared.container.newBackgroundContext()
            bgContext.perform {
                do{
                    let quest = bgContext.object(with: quest.objectID) as! Quest
                    if !quest.isActive { return; }
                    
                    quest.updateProgress()
                    
                    //if now completed
                    if !quest.isActive{
                        //check if there are any other quests still in progress
                        let allQuests = try bgContext.fetch(Quest.fetchRequest())
                        var anyActive = false
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
                    //when debugging, a merge error arises due to (i think) the timer spawning new background things while debugging has the program paused.
                    // It is low risk, but this should probably be investigated so it doesnt happen in actual deeployment.
                    let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")
                }
            }
        }
    }
    
    var body: some View {
        
        VStack{
            //title
            HStack{
                TextField("Quest Name", text: $quest.questName ?? "Unset")
                    .font(.title)
                    .disabled(!editing)
                if editing {Image(systemName:"pencil")}
            }
            Divider()
            
            //task list
            QuestTaskList(quest: quest)
            
            //schedule list
            ScheduleList(quest: quest)
            
            //start/end/lock buttons
            HStack{
                //lock/unlock button
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
                //start/end button
                Button(){
                    startEndResetButtonFunc()
                } label : {
                    ZStack{
                        RoundedRectangle(cornerRadius: 50, style: .circular)
                            .foregroundColor(statusColor())
                        Text(startEndResetButtonText()).foregroundColor(.white)
                    }
                }
                .disabled(quest.locked)
            }.frame(width: 250, height: 50)
        }
        .padding(EdgeInsets(top: 0.0, leading: 30.0, bottom: 0.0, trailing: 30.0))
        .toolbar(){
            if !quest.isActive { EditButton() }
        }
        .onChange(of: editing) { v in
            if v == false{
                context.perform {
                    do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
                }
            }
        }
        .onAppear(){
            startLiveUpdater()
        }
        .onDisappear {
            liveUpdater?.invalidate()
            liveUpdater = nil
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
                quest.start()
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
}

#Preview {
    let stdQuest = Quest(context: PersistenceController.preview.container.viewContext, name: "New Quest")
    let task = LocationOccupationQuestTask(context: PersistenceController.preview.container.viewContext, location: nil, questDuration: 5400)
    stdQuest.addToTasks(task)
    let schedule = Schedule(context: PersistenceController.preview.container.viewContext, quest: stdQuest)
    
    return NavigationView{QuestView(quest: stdQuest).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
