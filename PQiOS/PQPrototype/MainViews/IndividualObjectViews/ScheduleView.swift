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
    @Environment(\.managedObjectContext) private var context
    
    @ObservedObject
    var schedule: Schedule
    
   // @State var quest: Quest?
    @State var scheduleName: String = "no name"
    @State var everyXDays: Bool = false
    @State var XDayDelay: Int = 1
    @State var editedScheduledDaysArr: [Bool] = [true,true,true,true,true,true,true]
    @State var editedStartTime: Date = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date.now)!
    @State var editedScheduledEndTime: Date = Calendar.current.date(bySettingHour: 23, minute: 59, second: 1, of: Date.now)!
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Quest.objectID, ascending: true)], animation: .default)
    private var quests: FetchedResults<Quest>
    
    init(scheduleToLoad: Schedule){
        self.schedule = scheduleToLoad
     //   self.quest = schedule.quest!
    }
    
    func loadData(){
      //  self.quest = schedule.quest!
        self.scheduleName = schedule.scheduleName!
        self.everyXDays = schedule.schedule!.everyXDays
        self.XDayDelay = schedule.schedule!.XDayDelay
        for i in 0..<7{
            self.editedScheduledDaysArr[i] = schedule.schedule!.scheduledDays.contains(.Element(rawValue: 1<<i))
        }
        self.editedStartTime = schedule.scheduledStartTime!
        self.editedScheduledEndTime = schedule.scheduledEndTime!
    }
    var body: some View {
        VStack{
            if !schedule.quest!.isActive {
                HStack{
                    Spacer()
                    EditButton()
                }
            }
            HStack{
                TextField("Quest Name", text: $scheduleName)
                    .font(.title)
                    .disabled(!editMode!.wrappedValue.isEditing)
                if editMode!.wrappedValue.isEditing {Image(systemName:"pencil")}
            }
            
            Divider()
            
           // HStack{
                Text("Scheduled Quest: "+schedule.quest!.questName!)
             //   Picker("Scheduled Quest", selection: $quest) {
               //     ForEach(quests){ q in
             //           Text(q.questName!)
             //       }
             //   }
            //    .disabled(!editMode!.wrappedValue.isEditing)
          //  }
            
            Divider()
            
            VStack{
                HStack{
                    Toggle(isOn: $everyXDays){}.disabled(!editMode!.wrappedValue.isEditing)
                        .opacity(editMode!.wrappedValue.isEditing ? 1 : 0)
                        .labelsHidden()
                        .frame(width: editMode!.wrappedValue.isEditing ? 50 : 0)
                    if everyXDays{
                        HStack(spacing: 0){
                            Text("Schedule every \(XDayDelay) days")
                            Spacer()
                            Stepper(label: {}, onIncrement: {XDayDelay+=1}, onDecrement: {XDayDelay-=1; if XDayDelay<=0 {XDayDelay = 1}})
                                .disabled(!editMode!.wrappedValue.isEditing)
                                .opacity(editMode!.wrappedValue.isEditing ? 1 : 0)
                                .frame(alignment: .trailing)
                                .labelsHidden()
                        }
                    }else{
                        HStack{
                            Text("Schedule every")
                            Spacer()
                            ForEach(0..<7) { i in
                                Button(){
                                    editedScheduledDaysArr[i].toggle()
                                } label: {
                                    ZStack{
                                        if editedScheduledDaysArr[i] { Image(systemName:"circle.fill").foregroundColor(.green)}
                                        else{ Image(systemName:"circle")}
                                        Text(Week.daysOfTheWeek[i][..<Week.daysOfTheWeek[i].index(Week.daysOfTheWeek[i].startIndex, offsetBy: 1)]).foregroundColor(.black)
                                    }
                                }
                                .disabled(!editMode!.wrappedValue.isEditing)
                            }
                        }
                    }
                }
            }
            HStack{
                Spacer()
                Text("From")
                DatePicker("ScheduledStart", selection: $editedStartTime, displayedComponents: .hourAndMinute).labelsHidden()
                    .disabled(!editMode!.wrappedValue.isEditing)
                Text("to")
                DatePicker(selection: $editedScheduledEndTime, displayedComponents: .hourAndMinute, label: {Text("to")})
                    .labelsHidden()
                    .disabled(!editMode!.wrappedValue.isEditing)
                //if end time hour+min is before start time hour+min
                if editedStartTime
                    > Calendar.current.date(
                        bySettingHour: Calendar.current.component(.hour, from: editedScheduledEndTime),
                        minute: Calendar.current.component(.minute, from: editedScheduledEndTime),
                        second: Calendar.current.component(.second, from: editedScheduledEndTime),
                        of: editedStartTime)!{
                    Text("next day")
                }
                Spacer()
            }
            HStack{
                Text("Next start date:")
                DatePicker(selection: $editedStartTime, in: Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date.now)!..., displayedComponents: .date, label: {Text("Next start date ")})
                    .labelsHidden()
                    .disabled(!editMode!.wrappedValue.isEditing)
            }
            Divider()
            if !editMode!.wrappedValue.isEditing{
                Button(){
                    context.perform {
                        schedule.isActive.toggle()
                        do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
                        
                    }
                } label : {
                    Text(schedule.isActive ? "Stop" : "Start")
                }
                Button(){
                    context.perform {
                        schedule.synchronise()
                        do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
                    }
                } label :{
                    Text("Synchronise")
                }
            }
            
        }
        .toolbar(){
            EditButton()
        }
        .onAppear(perform: loadData)
        .onChange(of: editMode!.wrappedValue.isEditing) { v in
            if v == false{
               updateSchedule()
            }else{
                context.perform{
                    schedule.isActive = false
                    do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
                }
            }
        }
    }
    
    func updateSchedule(){
        context.perform {
            //ordered by UI appearance
            self.schedule.scheduleName = scheduleName
        
            //type of schedule
            schedule.schedule!.everyXDays = everyXDays
            //xdaydelay
            schedule.schedule!.XDayDelay = XDayDelay
            //scheduleddays
            for i in 0..<7{
                if editedScheduledDaysArr[i]{
                    if !schedule.schedule!.scheduledDays.contains(.Element(rawValue: 1<<i)) {schedule.schedule!.scheduledDays.insert(.Element(rawValue: 1<<i))}
                }else{
                    if schedule.schedule!.scheduledDays.contains(.Element(rawValue: 1<<i))
                    {schedule.schedule!.scheduledDays.remove(.Element(rawValue: 1<<i))}
                }
            }
            
            //IMPROVEMENT: add distinctions between CUTOFF end times and TIME LIMIT end times in schedule creation (i.e. "needs to be done by 6pm" vs "give me 2 hours to complete it"
            //I.E.: if its start time, an the user needs 30 minutes more, should that 30 minutes extend to the end time? or should the end time be treated as a hard cutoff for the schedule?
            //  perhaps this should be included in the hypothetical delay system
            //  --> "Delay reason, how much time delay do you need, should this affect the end time, etc."
            
        //---validate scheduled time to ensure it hasnt already passed
            //set it to start date
            let hour = Calendar.current.component(.hour, from: editedScheduledEndTime)
            let minute = Calendar.current.component(.minute, from: editedScheduledEndTime)
            editedScheduledEndTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 5, of: editedStartTime)!
            //then push it ahead if needed (i.e. 22:00 start - 8:00 end --> move end to next day)
            while editedScheduledEndTime < editedStartTime{
                editedScheduledEndTime.addTimeInterval(86400)
            }
            //then check that it cannot have already ended, moving the start time to the next day if it needs to
            if editedScheduledEndTime < Date.now{
                //if it is before, then either
                //   - skip to starting tomorrow
                //or - skip to starting at next scheduled day of week
                editedStartTime = everyXDays ? editedStartTime.addingTimeInterval(86400) : schedule.getNext_ScheduledDays_StartTime(fromDate: editedStartTime)
            }
            //and move the end time to keep up
            while editedScheduledEndTime < editedStartTime{
                editedScheduledEndTime.addTimeInterval(86400)
            }
            //then set the times
            schedule.scheduledStartTime = editedStartTime
            schedule.startTime = editedStartTime
            schedule.scheduledEndTime = editedScheduledEndTime
            
            do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
        }
    }
}

#Preview {
    let q = Quest(context: PersistenceController.preview.container.viewContext)
    q.lateInit(name: "Preview Quest")
    let sch = Schedule(context: PersistenceController.preview.container.viewContext)
    sch.lateInit(quest: q)
    return VStack{
    EditButton()
    
    ScheduleView(
        scheduleToLoad: sch)
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
}
