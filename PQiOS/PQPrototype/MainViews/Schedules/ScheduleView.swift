//
//  ScheduleView.swift
//  PQPrototype
//
//  Created by William Hart on 12/12/2025.
//

import SwiftUI
import CoreLocation

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
                        Button(){ //TODO: make price tied to individual schedules (based on frequency + quest difficulty)
                            if GlobalQuestLoot.getLoot(context).timeInABottle!.updateStoredTime(amount: -60){
                                schedule.nextSchLocked = false
                            }
                        } label:{
                            ZStack{
                                Image(systemName:"lock.fill").resizable().foregroundColor(.cyan).frame(width: 150, height: 75)
                                HStack(spacing:0){Text("60T"); Image(systemName: "hourglass")}
                            }.foregroundColor(.white)
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
    
    func loadData(){
        for i in 0..<7{
            schDayArr[i] = schedule.scheduledDays.contains(.Element(rawValue: 1<<i))
        }
        prevStartTime = schedule.startTime
        
    }
    
    func startScheduleEarly(){
        context.perform {
            do{
                try schedule.quest!.start(withSchedule: schedule)
            }
            catch let _ as FailedStartError{
                context.undo()
                //HIGHLIGHT error on screen
                
                return
            }catch{context.undo()
                return}
            schedule.startTime = Date.now
            do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
        }
    }
    func onEditChange(nowEditing: Bool){
        context.perform {
            //deactivate while editing, not possible while schLocked
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
            
            let scheduleOnTimeline = schedule.scheduledPeriodRelativity()
            //if scheduled period has passed, move scheduled period to now/future (whichever fits the scheduled pattern)
            if scheduleOnTimeline == -1{
                _ = schedule.amendNextScheduledPeriod(toNextStartFrom: Date.now)
                //FIX: and add a popup to say (couldnt activate, moved schedule forward to feasible time)
            }
            //if scheduled period is not in the past
            else {
                if scheduleOnTimeline == 0 && !areYouSure{
                    //TODO: add popup "scheduled period is right now, are you sure?"
                    schedule.toggleActive()
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
    
    func fixEndTime(){
        //get hour and min of end time, and set it to later time in start day or next day if endhour < starthour
        let hour = Calendar.current.component(.hour, from: schedule.scheduledEndTime!)
        let minute = Calendar.current.component(.minute, from: schedule.scheduledEndTime!)
        schedule.scheduledEndTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 5, of: schedule.scheduledStartTime!)!
        //then push it ahead if needed (i.e. 22:00 start - 8:00 end --> move end to next day)
        while schedule.scheduledEndTime! < schedule.scheduledStartTime!{
            schedule.scheduledEndTime!.addTimeInterval(86400)
        }
    }
    
    //similar to schedule.amendNextScheduledPeriod BUT it doesn't abide by the schedule, just makes sure end > now
    ///return cases:
    ///0: scheduled period is NOW
    ///1: scheduled period is LATER
    func ensureAutoStartIsPossible(){
        //makes it so end time lines up with start time (i.e. 10:00-12:00 is same day and 22:00-8:00 is day X to X+1)
        fixEndTime()
        while schedule.scheduledEndTime! < Date.now{
            schedule.scheduledStartTime!.addTimeInterval(86400)
            schedule.scheduledEndTime!.addTimeInterval(86400)
        }
        schedule.startTime = schedule.scheduledStartTime
    }
    
    func applyChanges(){
        context.perform {
            //save scheduledDays data
            for i in 0..<7{
                if schDayArr[i]{
                    if !schedule.scheduledDays.contains(.Element(rawValue: 1<<i)) {schedule.scheduledDays.insert(.Element(rawValue: 1<<i))}
                }else{
                    if schedule.scheduledDays.contains(.Element(rawValue: 1<<i))
                    {schedule.scheduledDays.remove(.Element(rawValue: 1<<i))}
                }
            }
            //validate changes so scheduling is still possible with given startTime
            ensureAutoStartIsPossible()
            
            //generate key to amend unsynchronised behaviour on PC app
            if prevStartTime != nil && schedule.startTime! > prevStartTime!{
                //if startTime has been pushed back, generate nullify key in case synchronisation doesnt happen in time and active quest on PC needs to be ended
                //key stores date of creation, so on PC it can check quest start time against key creation date to see "does this key cancel *this* quest?"
                //i.e. if quest.startTime <= key.creationDate: endQuest()
                let key = QuestKey.generateKey(quest: schedule.quest!)
                key.keyType = .cancelled
            }
            do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
        }
    }
}

#Preview {
    let q = Quest(context: PersistenceController.preview.container.viewContext, name: "Preview Quest")
    let sch = Schedule(context: PersistenceController.preview.container.viewContext, quest: q)
    return ScheduleView(
        scheduleToLoad: sch).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
