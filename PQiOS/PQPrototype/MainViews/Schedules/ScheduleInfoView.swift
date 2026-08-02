//
//  ScheduleInfo.swift
//  PQPrototype
//
//  Created by William Hart on 30/03/2026.
//

import SwiftUI

struct ScheduleInfoView: View {
    
    @ObservedObject var schedule: Schedule
    @State private var schButtonFlip: Bool = false //unused atm
    
    var body: some View {
        Button(){
            schButtonFlip.toggle()
        } label : {
            ZStack{
                RoundedRectangle(cornerRadius: 1000, style: .circular)
                    .foregroundColor(dynamicColour(schedule: schedule, dateOnly: schButtonFlip))
                    .shadow(color: .black, radius: 1)
                dynamicText(schedule: schedule, dateOnly: schButtonFlip)
                    .foregroundColor(.black)
            }
        }
        .frame(width: dynamicWidth(schedule: schedule, dateOnly: schButtonFlip), height: 40)
    }
    
    func dynamicText(schedule: Schedule, dateOnly: Bool = false) -> Text{
        ///-2: inactive
        ///-1: not started yet
        ///0: in progress
        ///1: failed
        ///2: succeeded
        var text: Text
        switch(dateOnly ? Schedule.ScheduleState.notStarted : schedule.getState()){
        case .inactive:
            text = Text("Inactive \(Image(systemName:"x.circle.fill"))")
        case .notStarted:
            text = Text("\(Image(systemName: "timer")) ") + Text(!Calendar.current.isDateInToday(schedule.startTime!) ? schedule.startTime!.formatted(date: .abbreviated, time: .omitted)
                                                                 :
                                                                    schedule.startTime!.formatted(date: .omitted, time: .shortened))
        case .inProgress:
            text = Text("\(Image(systemName: "timer")) In Progress ")
        case .failed:
            text = Text("\(Image(systemName: "x.circle.fill")) Failed")
        case .completed:
            text = Text("\(Image(systemName: "checkmark.circle.fill")) Success")
        }
        return text
    }
    
    
    func dynamicColour(schedule: Schedule, dateOnly: Bool = false) -> Color{
        ///-2: inactive
        ///-1: not started yet
        ///0: in progress
        ///1: failed
        ///2: succeeded
        var btnColor: Color
        switch(dateOnly ? Schedule.ScheduleState.notStarted : schedule.getState()){
        case .inactive:
            btnColor = .gray
        case .notStarted:
            btnColor = .white
        case .inProgress:
            btnColor = .yellow
        case .failed:
            btnColor = .red
        case .completed:
            btnColor = .green
        }
        return btnColor
    }
    
    func dynamicWidth(schedule: Schedule, dateOnly: Bool = false) -> CGFloat{
        ///-2: inactive
        ///-1: not started yet
        ///0: in progress
        ///1: failed
        ///2: succeeded
        var btnWidth: CGFloat
        switch(dateOnly ? Schedule.ScheduleState.notStarted : schedule.getState()){
            case .inactive:
                btnWidth = 105
            case .notStarted:
                btnWidth = !Calendar.current.isDateInToday(schedule.startTime!) ? 150 : 105
            case .inProgress:
                btnWidth = 130
            case .failed:
                btnWidth = 100
            case .completed:
                btnWidth = 115
        }
        return btnWidth
    }
}

#Preview {
    struct previewWrapper: View{
        @Environment(\.managedObjectContext) private var context
        let sch: Schedule
        init(sc:Schedule){
            sch=sc
        }
        var body: some View{
            ScheduleInfoView(schedule: sch)
        }
    }
    let qst = Quest(context: PersistenceController.preview.container.viewContext, name: "PreviewQuest")
    let sch = Schedule(context: PersistenceController.preview.container.viewContext, quest: qst)
    return previewWrapper(sc:sch).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
