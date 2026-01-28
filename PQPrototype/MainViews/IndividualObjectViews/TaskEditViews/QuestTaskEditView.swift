//
//  QuestTaskEditVieew.swift
//  PQPrototype
//
//  Created by William Hart on 30/12/2025.
//

import SwiftUI

struct QuestTaskEditView: View {
    
    let task: QuestTask
    
    @State var editedTaskName = ""
    init(task: QuestTask){
        self.task = task
    }
    var body: some View {
        TextField("Task Name", text: $editedTaskName)
    }
}

#Preview {
    let task = QuestTask(context: PersistenceController.preview.container.viewContext)
    task.lateInit(name: "New Task")
    return QuestTaskEditView(task: task).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
