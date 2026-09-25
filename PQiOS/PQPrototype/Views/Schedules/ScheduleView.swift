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

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Quest.objectID, ascending: true)], animation: .default)
    private var quests: FetchedResults<Quest>
    
    init(scheduleToLoad: Schedule){
        self.schedule = scheduleToLoad
        if !self.schedule.isActive { self.schedule.ensureValidAutostart(from: Date.now) }
    }
    
    // UI Elements
    var activeToggleButton: some View {
        Button(){
            context.perform {
                schedule.toggleActive()
                do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
                
            }
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
            if schedule.getState() != .inProgress {
                HStack{
                    Spacer()
                    EditButton()
                }
            }
            VStack(alignment: .leading, spacing:0){
                HStack{
                    TextField("Schedule Name", text: $schedule.scheduleName ?? "Schedule")
                        .font(.title)
                        .disabled(!editing)
                    if editing {Image(systemName:"pencil")}
                }
                Text("Scheduled Quest: "+schedule.quest!.name)
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
                DatePicker("ScheduledStart", selection: $schedule.scheduledStartTime ?? schedule.nextScheduledStart, displayedComponents: .hourAndMinute).labelsHidden()
                    .disabled(!editing)
                Text("to")
                DatePicker(selection: $schedule.scheduledEndTime ?? schedule.nextScheduledEnd, displayedComponents: .hourAndMinute, label: {Text("to")})
                    .labelsHidden()
                    .disabled(!editing)
                //if end time hour+min is before start time hour+min
                if schedule.nextScheduledEnd < schedule.nextScheduledStart || Calendar.current.component(.day, from: schedule.nextScheduledEnd) > Calendar.current.component(.day, from: schedule.nextScheduledStart){
                    Text("next day")
                }
                Spacer()
            }
            HStack{
                Text("Next start date:")
                DatePicker(selection: $schedule.scheduledStartTime ?? schedule.nextScheduledStart, in: Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date.now)!..., displayedComponents: .date, label: {Text("Next start date ")})
                    .labelsHidden()
                    .disabled(!editing)
            }
            Divider()
            
            //toggle active + toggle lock buttons
            //these access the actual schedule object
            if !editing{
                ZStack{
                    HStack{
                        
                        activeToggleButton
                        
                        if schedule.isActive{
                            scheduleLockBtn
                        }
                    }
                }
                //start early button, to speed up locked quests
                if !schedule.quest!.isActive{
                    Button(){
                        startScheduleEarly()
                    } label: {
                        Text("Start Early")
                    }
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
            applyChanges()
            do{
                schedule.startTime = Date.now
                try schedule.quest!.start(withSchedule: schedule)
            }
            catch _ as FailedStartError{
                context.undo()
                //HIGHLIGHT error on screen
                return
            }catch{context.undo()
                return}
            do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
        }
    }
    func onEditChange(nowEditing: Bool){
        context.perform {
            //deactivate while editing, not possible while schLocked
            if nowEditing && schedule.isActive{
                schedule.toggleActive()
            }else if !nowEditing{
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
            
            schedule.correctEndTime()
            schedule.ensureValidAutostart(from: Date.now)
            
            //generate key to amend unsynchronised behaviour on PC app
            if prevStartTime != nil && schedule.nextStart > prevStartTime!{
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
