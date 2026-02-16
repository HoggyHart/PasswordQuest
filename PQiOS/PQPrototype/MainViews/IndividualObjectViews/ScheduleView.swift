//
//  ScheduleView.swift
//  PQPrototype
//
//  Created by William Hart on 12/12/2025.
//

import SwiftUI
import CoreLocation

///CONTINUE HERE: changing this from a copy of ScheduleView to a ScheduleView


struct ScheduleView: View {
    @Environment(\.editMode) private var editMode
    private var editing: Bool { get { return  editMode!.wrappedValue.isEditing }}
    @Environment(\.managedObjectContext) private var context
    
    @ObservedObject
    var schedule: Schedule

    //havent quite figured out how to properly handle Transformables, so this is here still
    @State var schDayArr: [Bool] = [true,true,true,true,true,true,true]
    
    let defaultStartTime = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date.now)!
    let defaultEndTime = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: Date.now)!
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Quest.objectID, ascending: true)], animation: .default)
    private var quests: FetchedResults<Quest>
    
    init(scheduleToLoad: Schedule){
        self.schedule = scheduleToLoad
    }
    
    func loadData(){
        for i in 0..<7{
            schDayArr[i] = schedule.scheduledDays!.week.contains(.Element(rawValue: 1<<i))
        }
    }
    var body: some View {
        VStack{
            // --EDIT TOOLBAR ==needed since ScheduleView is raised as a form from the bottom of QuestView, it needs its own edit button.
            if !schedule.quest!.isActive {
                HStack{
                    Spacer()
                    EditButton()
                }
            }
            HStack{
                TextField("Quest Name", text: $schedule.scheduleName ?? "Unset Name")
                    .font(.title)
                    .disabled(!editing)
                if editing {Image(systemName:"pencil")}
            }
            
            Divider()
            Text("Scheduled Quest: "+schedule.quest!.questName!)
            Divider()
            
            VStack{
                HStack{
                    if editing {
                        Toggle(isOn: $schedule.everyXDays){}
                            .labelsHidden()
                    }
                    if schedule.everyXDays{
                        HStack(spacing: 0){
                            Text("Schedule every \(schedule.xDayDelay) days")
                            if editing {
                                Spacer()
                                Stepper(label: {}, 
                                        onIncrement: {schedule.xDayDelay+=1},
                                        onDecrement: {
                                            schedule.xDayDelay-=1;
                                            if schedule.xDayDelay<=0 {
                                                schedule.xDayDelay = 1}}
                                ).disabled(!editing)
                                    .frame(alignment: .trailing)
                                    .labelsHidden()
                            }
                        }
                    }else{
                        HStack{
                            Text("Schedule every")
                            Spacer()
                            ForEach(0..<7) { i in
                                Button(){
                                    schDayArr[i].toggle()
                                } label: {
                                    ZStack{
                                        Image(systemName: schDayArr[i] ?
                                              "circle.fill" : "circle")
                                        .foregroundColor(schDayArr[i] ? .green : .red)
                                        Text(StringUtils.firstLetterOfString(str: Week.daysOfTheWeek[i])).foregroundColor(.black)
                                    }
                                }
                                .disabled(!editing)
                            }
                        }
                    }
                }
            }
            HStack{
                Spacer()
                Text("From")
                DatePicker("ScheduledStart", selection: $schedule.scheduledStartTime ?? defaultStartTime, displayedComponents: .hourAndMinute).labelsHidden()
                    .disabled(!editing)
                Text("to")
                DatePicker(selection: $schedule.scheduledEndTime ?? defaultEndTime, displayedComponents: .hourAndMinute, label: {Text("to")})
                    .labelsHidden()
                    .disabled(!editing)
                //if end time hour+min is before start time hour+min
                if endBeforeStart(){
                    Text("next day")
                }
                Spacer()
            }
            HStack{
                Text("Next start date:")
                DatePicker(selection: $schedule.scheduledStartTime ?? defaultStartTime, in: Calendar.current.date(bySetting: .second, value: 0, of: Date.now)!..., displayedComponents: .date, label: {Text("Next start date ")})
                    .labelsHidden()
                    .disabled(!editing)
            }
            Divider()
            
            // --Activate Schedule **and** Synchronise schedule data with server buttons
            //only possible during stable state (not editing)
            if !editing{
                Button(){
                    toggleScheduleActiveStatus()
                } label : {
                    Text(schedule.isActive ? "Stop" : "Start")
                }
                Button(){
                    synchroniseWithServer()
                } label :{
                    Text("Synchronise")
                }
            }
            
        }
        .toolbar(){
            EditButton()
        }
        .onAppear(perform: loadData)
        .onChange(of: editing) { nowEditing in
            if nowEditing == true{
                deactivateSchedule()
            }else{
                updateSchedule()
            }
        }
        .onDisappear {
            undoUnsavedChanges()
        }
    }
    
    func deactivateSchedule(){
        context.perform{
            schedule.isActive = false
            do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
        }
    }
    func undoUnsavedChanges(){
        context.perform{
            context.rollback()
            do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
        }
    }
    func toggleScheduleActiveStatus(){
        context.perform {
            //if schedule has not ended yet
            if schedule.scheduledPeriodRelativity() > -1 {
                schedule.isActive.toggle()
            }
            //else if schedule has already passed, it cannot be activated.
            //  update start time to next opportunity
            else { _ = schedule.amendNextScheduledPeriod(toNextStartFrom: Date.now) }
            
            //try saving this attribute change
            do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
            
        }
    }
    
    func synchroniseWithServer(){
        context.perform {
            schedule.synchronise()
            do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
        }
    }
    
    func endBeforeStart() -> Bool{
        return schedule.scheduledStartTime! > Calendar.current.date(  bySettingHour: Calendar.current.component(.hour, from: schedule.scheduledEndTime!), minute: Calendar.current.component(.minute, from: schedule.scheduledEndTime!), second: Calendar.current.component(.second, from: schedule.scheduledEndTime!), of: schedule.scheduledStartTime!)!
    }
    func updateSchedule(){
        context.perform {
            //ordered by UI appearance
           // self.schedule.scheduleName = scheduleName
        
            for i in 0..<7{
                if schDayArr[i]{
                    if !schedule.scheduledDays!.week.contains(.Element(rawValue: 1<<i)) {schedule.scheduledDays!.week.insert(.Element(rawValue: 1<<i))}
                }else{
                    if schedule.scheduledDays!.week.contains(.Element(rawValue: 1<<i))
                    {schedule.scheduledDays!.week.remove(.Element(rawValue: 1<<i))}
                }
            }
            
            //IMPROVEMENT: add distinctions between CUTOFF end times and TIME LIMIT end times in schedule creation (i.e. "needs to be done by 6pm" vs "give me 2 hours to complete it"
            //I.E.: if its start time, an the user needs 30 minutes more, should that 30 minutes extend to the end time? or should the end time be treated as a hard cutoff for the schedule?
            //  perhaps this should be included in the hypothetical delay system
            //  --> "Delay reason, how much time delay do you need, should this affect the end time, etc."
            
        //---validate scheduled time to ensure it hasnt already passed
            //set it to start date
            let hour = Calendar.current.component(.hour, from: schedule.scheduledEndTime!)
            let minute = Calendar.current.component(.minute, from: schedule.scheduledEndTime!)
            schedule.scheduledEndTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 5, of: schedule.scheduledStartTime!)!
            //then push it ahead if needed (i.e. 22:00 start - 8:00 end --> move end to next day)
            while schedule.scheduledEndTime! < schedule.scheduledStartTime!{
                schedule.scheduledEndTime!.addTimeInterval(86400)
            }
            //then check that it cannot have already ended, moving the start time to the next day if it needs to
            if schedule.scheduledEndTime! < Date.now{
                //if it is before then skip to starting tomorrow (next possible time that fits schedulede time period)
                schedule.scheduledStartTime = schedule.scheduledStartTime!.addingTimeInterval(86400)
            }
            //and move the end time to keep up
            while schedule.scheduledEndTime! < schedule.scheduledStartTime!{
                schedule.scheduledEndTime!.addTimeInterval(86400)
            }
            //then set the times
            //schedule.scheduledStartTime = editedStartTime
            schedule.startTime = schedule.scheduledStartTime
            //schedule.scheduledEndTime = editedScheduledEndTime
            
            do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
        }
    }
}

#Preview {
    let q = Quest(context: PersistenceController.preview.container.viewContext)
    q.lateInit(name: "Preview Quest")
    let sch = Schedule(context: PersistenceController.preview.container.viewContext)
    sch.lateInit(quest: q)
    return
    ScheduleView(
        scheduleToLoad: sch)
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
