//
//  ContentView.swift
//  PQPrototype
//
//  Created by William Hart on 27/11/2025.
//

import SwiftUI
import CoreData

class QuestListViewModel: ObservableObject{
    var viewContext: NSManagedObjectContext? = nil
    var qfr: NSFetchRequest<Quest>? = nil
    @Published var quests: [Quest] = []
    
    @Published var toDelete: IndexSet = IndexSet()
    @Published var newQuestName: String = ""
    
    @Published var listOffset: Int = 0
    var listSize: Int = 8
    
    init(){
        self.qfr = NSFetchRequest<Quest>(entityName: "Quest")
        self.qfr?.sortDescriptors = []
    }
    func assignContext(context: NSManagedObjectContext){
        viewContext = context
        update()
    }
    func update(){
        do{
            quests = try viewContext?.fetch(qfr!) ?? []
        }catch{quests = []}
    }
    
    func addQuest() {
        if newQuestName == "" || newQuestName == "Error" { return }
        guard let viewContext = viewContext else {
            newQuestName = "Error";
            return
        }
        viewContext.perform{ [self] in
            withAnimation {
                _ = Quest(context: viewContext, name: newQuestName)
                do {
                    try viewContext.save()
                    newQuestName = ""
                } catch {
                    viewContext.rollback()
                    newQuestName = "Error"
                    let nsError = error as NSError
                    fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                }
                update()
            }
        }
    }
    
    func deleteQuests(offsets: IndexSet) {
        guard let viewContext = viewContext else { return }
        viewContext.perform { [self] in
            withAnimation {
                offsets.map {quests[$0] }.forEach { q in
                    let nullifyKey = QuestKey.generateKey(quest: q)
                    nullifyKey.keyType = .deleted
                    viewContext.delete(q)
                }
               // lviewModel.displayedQuests.remove(atOffsets: offsets)
                toDelete = IndexSet()
                quests = []
                do{try viewContext.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
                update()
            }
        }
    }
}

struct QuestList: View {
    @Environment(\.editMode) private var editMode
    var editing: Bool { get { return  editMode!.wrappedValue.isEditing }}
    
    @ObservedObject var viewModel: QuestListViewModel
    
    init(viewModel: QuestListViewModel? = nil) {
        self.viewModel = viewModel ?? QuestListViewModel()
    }
    
    var body: some View{
        ForEach(viewModel.listOffset..<viewModel.listOffset+viewModel.listSize, id: \.self){i in
            VStack(alignment: .leading, spacing: 0){
                //Quest Line
                if i < viewModel.quests.count{
                    SelectableLine(selections: $viewModel.toDelete, value: i) {
                        NavigationLink(destination: QuestView(quest: viewModel.quests[i])) {
                            ZStack{
                                Text("\(viewModel.quests[i].name)")
                                    .font(.custom("Bradley Hand", fixedSize: 20))
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
            .frame(height:60)
        }
    }
}
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
    @StateObject var lviewModel = QuestListViewModel()
    
    var body: some View {
        Text("\(lviewModel.quests.count)").id(lviewModel.quests.count)
        JournalView(extraPages: lviewModel.quests.count/lviewModel.listSize, lines: 8, lineHeight: 60, viewModel: jviewModel){
            ZStack{
                Button(){
                    predicateIndex += 1
                    if predicateIndex == 3{
                        predicateIndex = 0
                    }
                    curPredicate = predicates[predicateIndex]
                    lviewModel.qfr?.predicate = curPredicate
                    lviewModel.update()
                } label : {
                    Text(predicateName[predicateIndex]+"Quest Log").font(.custom("Bradley Hand", fixedSize: 25))
                }
                HStack{
                    Spacer()
                    EditButton().font(.custom("Bradley Hand", fixedSize: 25))
                   
                }
            }.padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
        } content: {
            //quest list
            HStack{
                VStack(alignment: .leading, spacing:0){
                    //  Text("\(UIScreen.main.bounds.height)")
                    Spacer().frame(minHeight: 0)
                    // Text("\(h.size.height)")
                    QuestList(viewModel: lviewModel)
                }
                Spacer()
            }.padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
        }
        .navigationViewStyle(.stack)
        .onChange(of: jviewModel.page, perform: { value in
            lviewModel.listOffset = (jviewModel.page-1)*lviewModel.listSize
        })
        .onChange(of: editing) { newValue in
            if lviewModel.toDelete.isEmpty { return }
            lviewModel.deleteQuests(offsets: lviewModel.toDelete)
        }.onAppear(){
            //lviewModel.update()
            lviewModel.assignContext(context: viewContext)
        }
    }
}

#Preview {
    QuestManagerView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

