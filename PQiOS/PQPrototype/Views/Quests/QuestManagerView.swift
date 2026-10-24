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
    
    @StateObject var jViewModel = JournalViewModel()
    @StateObject var viewModel = QuestManagerViewModel()

    var body: some View {
        JournalView(extraPages: viewModel.fullList.count/viewModel.subListSize, viewModel: jViewModel){
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
                ForEach(viewModel.subList){q in
                    //Quest Line
                    SelectableView(selections: $viewModel.selectedListItems,
                                   value: q.objectID) {
                        NavigationLink(destination: QuestView(quest: q)) {
                            ZStack{
                                HStack(){
                                    Text("\(q.name)")
                                        .font(.journalBody)
                                        .foregroundColor(.classicInk)
                                        .strikethrough(viewModel.selectedListItems.contains(where: { id in
                                                        return id == q.objectID
                                                        }),
                                            color: .red)
                                    if !editing{
                                        Spacer()
                                        Image(systemName: "chevron.right").foregroundColor(.classicInk)
                                    }
                                }.frame(maxWidth: .infinity, alignment:.leading)
                            }.frame(maxWidth: .infinity)
                        }
                        .disabled(editing)
                    }
                                   .frame(height:jViewModel.lineHeight)
                }
                if viewModel.subList.count<viewModel.subListSize{
                    ForEach(0..<viewModel.subListSize-viewModel.subList.count, id: \.self){i in                    //Add Quest (as long as not implying adding new active quest)
                        if i == 0 && predicateIndex != 1{
                            TextField("New Quest \(Image(systemName: "plus"))", text: $viewModel.newQuestName)
                                .submitLabel(.done)
                                .onSubmit {
                                    viewModel.addItem()
                                }.frame(height:jViewModel.lineHeight)
                            //empty padding
                        }else{
                            Rectangle().opacity(0).frame(height:jViewModel.lineHeight)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
            
        }
        .navigationViewStyle(.stack)
        .onChange(of: jViewModel.page, perform: { value in
            viewModel.updateSubList(newOffset: (jViewModel.page-1)*viewModel.subListSize)
        })
        .onChange(of: editing) { newValue in
            viewModel.deleteItems()
        }
    }
}
    
#Preview {
    QuestManagerView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

