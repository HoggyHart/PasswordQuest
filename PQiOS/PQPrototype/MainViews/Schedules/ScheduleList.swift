//
//  ScheduleList.swift
//  PQPrototype
//
//  Created by William Hart on 22/05/2026.
//

import SwiftUI
import CoreData

struct ScheduleList: View {
    @Environment(\.editMode) private var editMode
    private var editing: Bool { get { return  editMode!.wrappedValue.isEditing }}
    @Environment(\.managedObjectContext) private var context
    
    var quest: Quest
    @FetchRequest private var schedules: FetchedResults<Schedule>
    
    @State private var inspectedScheduleID: NSManagedObjectID? = nil
    private var isScheduleSheetPresented: Binding<Bool> { Binding(get: { inspectedScheduleID != nil }, set: { if !$0 { inspectedScheduleID = nil } }) }
    
    init(quest: Quest){
        self.quest = quest
        _schedules = FetchRequest(
                sortDescriptors: [
                    NSSortDescriptor(keyPath: \Schedule.objectID, ascending: true)
                ],
                predicate: NSPredicate(format: "quest == %@", quest)
            )
    }
    var body: some View {
        HStack{
            Text("Schedules")
            Spacer()
            if editing {
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
                } label:{
                    HStack{
                        Text("\(schedule.scheduleName!)")
                        Spacer()
                        Button(){
                            ///-2 -> inactive, no start date
                            ///-1 -> already displaying start date
                            ///0 -> in progress
                            if schedule.getState().rawValue == 1
                                || schedule.getState().rawValue == 2 {//schButtonFlip.toggle()
                            }
                        } label : {
                            ScheduleInfoView(schedule: schedule)
                        }
                    }
                }
            }
            .onDelete(perform: deleteSchedules)
        }
        .listStyle(PlainListStyle())
        
        .sheet(isPresented: isScheduleSheetPresented) {
            if let id = inspectedScheduleID {
                let localSchedule = context.object(with: id) as! Schedule
                ScheduleView(scheduleToLoad: localSchedule)
            }
        }
    }
    
    func addSchedule(){
        context.perform {
            withAnimation {
            
                let schedule = Schedule(context: context, quest: quest)
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
    let q = Quest(context: PersistenceController.preview.container.viewContext, name: "New Quest")
    let schedule = Schedule(context: PersistenceController.preview.container.viewContext, quest: q)
    q.addToSchedulers(schedule)
    return ScheduleList(quest: q).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
