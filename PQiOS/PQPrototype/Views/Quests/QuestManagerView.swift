//
//  ContentView.swift
//  PQPrototype
//
//  Created by William Hart on 27/11/2025.
//

import SwiftUI
import CoreData

struct QuestManagerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.editMode) private var editMode
    var editing: Bool { get { return  editMode!.wrappedValue.isEditing }}
    // @FetchRequest(sortDescriptors: []) var quests: FetchedResults<Quest>
    
    @State var predicateIndex: Int = 0
    let predicates: [NSPredicate?] =
    [nil, NSPredicate(format: "isActive == true"), NSPredicate(format: "isActive == false")]
    @State var curPredicate: NSPredicate? = nil
    let predicateName: [String] = ["", "Active ", "Inactive "]
    
    @StateObject var jviewModel = JournalViewModel()
    @StateObject var viewModel = QuestManagerViewModel()
    
    let rowHeight: CGFloat = 50
    
    var body: some View {
        JournalView(extraPages: viewModel.quests.count/viewModel.listSize, lines: 8, lineHeight: rowHeight, viewModel: jviewModel){
            ZStack{
                Button(){
                    viewContext.perform {
                        predicateIndex += 1
                        if predicateIndex == 3{
                            predicateIndex = 0
                        }
                        curPredicate = predicates[predicateIndex]
                       // viewModel.request.predicate = curPredicate
                        viewModel.controller.fetchRequest.predicate = curPredicate
                        viewModel.controllerDidChangeContent(viewModel.controller as! NSFetchedResultsController<any NSFetchRequestResult>)
                    }
                } label : {
                    Text(predicateName[predicateIndex]+"Quest Log").font(.journalSubheading)
                }
                HStack{
                    Spacer()
                    EditButton().font(.journalSubheading)
                }
            }.padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
        } content: {
            //quest list
            VStack(alignment: .leading, spacing:0){
                ForEach(viewModel.listOffset..<viewModel.listOffset+viewModel.listSize, id: \.self){i in
                    VStack(alignment: .leading, spacing: 0){
                        //Quest Line
                        if i < viewModel.quests.count{
                            SelectableView(selections: $viewModel.toDelete, value: i) {
                                NavigationLink(destination: QuestView(quest: viewModel.quests[i])) {
                                    ZStack{
                                        Text("\(viewModel.quests[i].name)")
                                            .font(.journalBody)
                                            .foregroundColor(.classicInk)
                                        if viewModel.toDelete.contains(i){
                                            Rectangle().frame(height: 2).foregroundColor(.red)
                                        }
                                    }
                                }
                                .disabled(editing)
                            }
                            //Add Quest
                        }else if i == viewModel.quests.count{
                            TextField("New Quest \(Image(systemName: "plus"))", text: $viewModel.newQuestName)
                                .submitLabel(.done)
                                .onSubmit {
                                    viewModel.addQuest()
                                }
                            //empty padding
                        }else{
                            Rectangle().opacity(0)
                        }
                    }
                    .frame(height:rowHeight)
                }.id(predicateIndex)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
            
        }
        .navigationViewStyle(.stack)
        .onChange(of: jviewModel.page, perform: { value in
            viewModel.listOffset = (jviewModel.page-1)*viewModel.listSize
        })
        .onChange(of: editing) { newValue in
            if viewModel.toDelete.isEmpty { return }
            viewModel.deleteQuests(offsets: viewModel.toDelete)
        }
    }
}
    
#Preview {
    QuestManagerView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

