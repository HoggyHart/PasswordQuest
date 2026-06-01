//
//  AdvancedQuestTaskView.swift
//  PQPrototype
//
//  Created by William Hart on 25/05/2026.
//

import SwiftUI

struct QuestTaskConfigView: View {
    
    let task: QuestTask
    
    @State var b: Bool = false
    @State var tv: Int = 0
    @State var mtv: Int = 0
    @State var actualStateVar: Bool = false
    init(task: QuestTask){
        self.task = task
    }
    var body: some View {
        VStack{
            Toggle("Partial Completion Reward", isOn: $b)
            HStack(spacing: 0){
                Stepper(label: {Text("Task Min Reward Value: \(tv)")},
                        onIncrement: {tv+=1
                    if mtv<tv {actualStateVar = false}},
                        onDecrement: {
                            tv-=1;
                            if tv<0 {
                                tv = 0}}
                )
                .frame(alignment: .trailing)
            }
            HStack(spacing: 0){
                ZStack{
                    if !actualStateVar {Toggle("Task Max Reward Value", isOn: $actualStateVar)}
                    else{Stepper(label: {Text("Task Max Reward Value: \(mtv)")},
                                 onIncrement: {mtv+=1},
                                 onDecrement: {mtv-=1; if mtv<tv {actualStateVar = false}}
                    )
                    .frame(alignment: .trailing)
                    }
                }
            }
        }
        .onChange(of: actualStateVar, perform: { value in
            mtv=tv
        })
    }
}

#Preview {
    let stdQuest = Quest(context: PersistenceController.preview.container.viewContext, name: "New Quest")
    let task = SingleLocationTask(context: PersistenceController.preview.container.viewContext, dummyVar: true)
    stdQuest.addToTasks(task)
    return QuestTaskConfigView(task: task)
}
