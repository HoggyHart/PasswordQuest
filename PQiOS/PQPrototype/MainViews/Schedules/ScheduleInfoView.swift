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
        ZStack{
            RoundedRectangle(cornerRadius: 1000, style: .circular)
                .foregroundColor(dynamicColour(schedule: schedule, dateOnly: schButtonFlip))
                .shadow(color: .black, radius: 1)
            dynamicText(schedule: schedule, dateOnly: schButtonFlip)
                .foregroundColor(.black)
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
    
    
    func dynamicColour(schedule: Schedule, dateOnly: Bool = false) -> Color{
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
    
    func dynamicWidth(schedule: Schedule, dateOnly: Bool = false) -> CGFloat{
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
    let qst = Quest(entity: Quest.entity(), insertInto: nil)
    qst.lateInit(name: "PreviewQuest")
    let sch = Schedule(entity: Schedule.entity(), insertInto: nil)
    sch.lateInit(quest: qst)
    return previewWrapper(sc:sch).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
