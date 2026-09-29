//
//  TaskTypeSelectionView.swift
//  PQPrototype
//
//  Created by William Hart on 28/09/2026.
//

import SwiftUI
import CoreData

struct TaskCreationView: View {
    @Environment(\.managedObjectContext) private var context
    
    @ObservedObject var viewModel: QuestTaskManagerViewModel
    
    var body: some View {
        VStack{
            Text(viewModel.taskCreationError)
            ScrollView{
                LazyVGrid(columns: [GridItem(), GridItem()]) {
                    Button(){
                        viewModel.newTaskType = ManualQuestTask.self
                    } label:{
                        ZStack{
                            Image(systemName: "checklist").frame(width: UIScreen.main.bounds.width/2,height: UIScreen.main.bounds.width/2)
                            if viewModel.newTaskType == ManualQuestTask.self{
                                Rectangle().opacity(0).border(.black)
                            }
                        }
                    }
                    // for each task type
                    Button(){
                        viewModel.newTaskType = TrainingQuestTask.self
                    } label:{
                        ZStack{
                            Image(systemName:"timer")
                                .frame(width: UIScreen.main.bounds.width/2,height: UIScreen.main.bounds.width/2)
                            if viewModel.newTaskType == TrainingQuestTask.self{
                                Rectangle().opacity(0).border(.black)
                            }
                        }
                    }
                    Button(){
                        viewModel.newTaskType = SingleLocationTask.self
                    } label:{
                        ZStack{
                            Image("SingleLocationTaskIcon")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: UIScreen.main.bounds.width/2,height: UIScreen.main.bounds.width/2)
                            if viewModel.newTaskType == SingleLocationTask.self{
                                Rectangle().opacity(0).border(.black)
                            }
                        }
                    }
                    Button(){
                        viewModel.newTaskType = RNGLocationTask.self
                    } label:{
                        ZStack{
                            Image("RandomLocationTaskIcon")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: UIScreen.main.bounds.width/2,height: UIScreen.main.bounds.width/2)
                            if viewModel.newTaskType == RNGLocationTask.self{
                                Rectangle().opacity(0).border(.black)
                            }
                        }
                    }
                }
            }
            Button(){
                viewModel.addTask()
            } label : {
                Text("Confirm")
            }
        }
    }
}

#Preview{
    Text("nope")
//    let quest = Quest(context: PQPrototypeApp.mainContext)
//    return TaskCreationView(viewModel: quest)
}
