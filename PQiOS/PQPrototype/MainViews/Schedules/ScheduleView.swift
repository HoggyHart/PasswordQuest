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

    @State var prevStartTime: Date? = nil
    
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
            schDayArr[i] = schedule.scheduledDays.contains(.Element(rawValue: 1<<i))
        }
        prevStartTime = schedule.startTime
    }
    
    // UI Elements
    var activeToggleButton: some View {
        Button(){
            toggleScheduleActiveStatus()
        } label : {
            VStack(spacing:0){
                ZStack{
                    RoundedRectangle(cornerRadius: 50, style: .circular)
                        .foregroundColor(schedule.isActive ? .green : .red)
                    Image(systemName: schedule.isActive ? "checkmark" : "xmark")
                        .foregroundColor(schedule.isActive ? .black : .white)
                        .font(.title2)
                }
                .frame(width: 50, height: 50)
                Text(schedule.isActive ? "Active" : "Inactive")
            }
        }
    }
    
    var inputScheduledInterval: some View {
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
    }
    
    var inputPatternedSchedule: some View {
        HStack{
            Text("Schedule every")
            Spacer()
            ForEach(0..<7) { i in
                Button(){
                    schDayArr[i].toggle()
                } label: {
                    ZStack{
                        Image(systemName: schDayArr[i] ? "circle.fill" : "circle")
                        .foregroundColor(schDayArr[i] ? .green : .red)
                        Text(StringUtils.firstXLettersOfString(str: Week.daysOfTheWeek[i], x: 1)).foregroundColor(.black)
                    }
                }
                .disabled(!editing)
            }
        }
    }
    
    var scheduleLockBtn: some View {
        Button(){
            context.perform{
                schedule.nextSchLocked.toggle()
                do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
            }
        } label :{
            VStack(spacing:0){
                ZStack{
                    RoundedRectangle(cornerRadius: 50, style: .circular)
                        .foregroundColor(schedule.nextSchLocked ? .red : .green)
                    Image(systemName: schedule.nextSchLocked ? "lock.fill" : "lock.open.fill")
                        .foregroundColor(schedule.nextSchLocked ? .black : .white)
                        .font(.title2)
                }
                .frame(width: 50, height: 50)
                Text(schedule.nextSchLocked ? "Locked" : "Unlocked")
            }
        }
    }
    
    var body: some View {
        VStack{
            // --EDIT TOOLBAR ==needed since ScheduleView is raised as a form from the bottom of QuestView, it needs its own edit button.
            if !schedule.quest!.isActive && !schedule.nextSchLocked{
                HStack{
                    Spacer()
                    EditButton()
                }
            }
            VStack(alignment: .leading, spacing:0){
                HStack{
                    TextField("Quest Name", text: $schedule.scheduleName ?? "Unset Name")
                        .font(.title)
                        .disabled(!editing)
                    if editing {Image(systemName:"pencil")}
                }
                Text("Scheduled Quest: "+schedule.quest!.questName!)
                    .font(.footnote)
            }
            Divider()
            
            VStack{
                HStack{
                    if editing {
                        Toggle(isOn: $schedule.everyXDays){}
                            .labelsHidden()
                    }
                    if schedule.everyXDays{
                        inputScheduledInterval
                    }else{
                        inputPatternedSchedule
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
                if isEndBeforeStart(){
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
            
            //toggle active + toggle lock buttons
            if !editing{
                ZStack{
                    HStack{
                        
                        activeToggleButton
                        
                        if schedule.isActive{
                            scheduleLockBtn
                        }
                    }
                    //lock to block buttons
                    if schedule.isActive && schedule.nextSchLocked{
                        ZStack{
                            Image(systemName:"lock.fill").resizable().foregroundColor(.cyan).frame(width: 150, height: 75)
                            Text(schedule.nxtDateTxt())
                        }
                    }
                }
                //start early button, to speed up locked quests
                Button(){
                    startScheduleEarly()
                } label: {
                    Text("Start Early")
                }
            }
        }
        .onAppear(perform: loadData)
        .onChange(of: editing, perform: onEditChange)
        .onDisappear(perform: undoChanges)
    }
    
    func startScheduleEarly(){
        context.perform {
            schedule.startTime = Date.now
            schedule.quest!.start(withSchedule: schedule)
            
            do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
        }
    }
    func onEditChange(nowEditing: Bool){
        context.perform {
            if nowEditing && schedule.isActive{
                schedule.toggleActive()
            }else{
                applyChanges()
            }
            do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
        }
    }
    
    func undoChanges(){
        context.perform{
            context.rollback()
            do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
        }
    }
    
    //try to active/deactivate schedule
    func toggleScheduleActiveStatus(areYouSure: Bool = false){
        context.perform {
            
            var scheduleOnTimeline = schedule.scheduledPeriodRelativity()
            //if scheduled period has passed, move scheduled period to now/future (whichever fits the scheduled pattern)
            if scheduleOnTimeline == -1{
                _ = schedule.amendNextScheduledPeriod(toNextStartFrom: Date.now)
                //FIX: and add a popup to say (couldnt activate, moved schedule forward to feasible time)
            }
            //if scheduled period is not in the past
            else {
                if scheduleOnTimeline == 0 && !areYouSure{
                    //FIX: add popup "scheduled period is right now, are you sure?"
                    return
                }
                //if scheduled period is in future or force start, go ahead and toggle active status
                schedule.toggleActive()
            }
            
            //try saving this attribute change
            do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
            
        }
    }
    
    func isEndBeforeStart() -> Bool{
        return schedule.scheduledStartTime! > Calendar.current.date(  bySettingHour: Calendar.current.component(.hour, from: schedule.scheduledEndTime!), minute: Calendar.current.component(.minute, from: schedule.scheduledEndTime!), second: Calendar.current.component(.second, from: schedule.scheduledEndTime!), of: schedule.scheduledStartTime!)!
    }
    
    func applyChanges(){
        context.perform {
            
            //ordered by UI appearance
           // self.schedule.scheduleName = scheduleName
            
            for i in 0..<7{
                if schDayArr[i]{
                    if !schedule.scheduledDays.contains(.Element(rawValue: 1<<i)) {schedule.scheduledDays.insert(.Element(rawValue: 1<<i))}
                }else{
                    if schedule.scheduledDays.contains(.Element(rawValue: 1<<i))
                    {schedule.scheduledDays.remove(.Element(rawValue: 1<<i))}
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
            
            if prevStartTime != nil && schedule.startTime! > prevStartTime!{
                //afaik nullify for schedules only needs to be done if there is potential for the quest to have started on PC before the scheduled time on the phone
                //  so, if startTime has been pushed back, generate nullify key in case synchronisation doesnt happen in time and active quest on PC needs to be ended
                _ = QuestReward.generateNullifyKey(quest: schedule.quest!)
            }
            do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
        }
    }
}

#Preview {
    let q = Quest(context: PersistenceController.preview.container.viewContext)
    q.lateInit(name: "Preview Quest")
    let sch = Schedule(context: PersistenceController.preview.container.viewContext)
    sch.lateInit(quest: q)
    return ScheduleView(
        scheduleToLoad: sch).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
