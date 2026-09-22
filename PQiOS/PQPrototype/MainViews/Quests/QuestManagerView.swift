//
//  ContentView.swift
//  PQPrototype
//
//  Created by William Hart on 27/11/2025.
//

import SwiftUI
import CoreData

struct QuestList: View {
    @Environment(\.managedObjectContext) private var context
   
    @Environment(\.editMode) private var editMode
    var editing: Bool { get { return  editMode!.wrappedValue.isEditing }}
    
    @State private var questL: [Quest] = []
    @State var toDelete: IndexSet = IndexSet()
    @State var questNav: [Bool] = []
    
    let pred: NSPredicate?
    let size: Int
    let offset: Int
    @State var newQuestName: String = ""
    
    init(size: Int, offset: Int, predicate: NSPredicate? = nil, context: NSManagedObjectContext) {
        self.size = size
        self.offset = offset
        pred = predicate
    }
    func loadQuests(){
        let fr = NSFetchRequest<Quest>()
        fr.entity = Quest.entity()
        fr.fetchLimit = size
        fr.fetchOffset = offset
        fr.sortDescriptors = [NSSortDescriptor(key: "questName", ascending: true)]
        fr.predicate = pred
        do{
            let arr = try context.fetch(fr)
         //   self.ertext = "\(arr.count)"
            self.questL = arr
            self.questNav = [Bool].init(repeating: false, count: arr.count)
        }catch _{}
    }
    
    var body: some View{
        ForEach(0..<size, id: \.self){i in
            VStack(alignment: .leading, spacing: 0){
                //Quest Line
                if i < questL.count{
                    Button(){
                        if editing{
                            toggleDelQuest(index: i)
                        }
                        else{
                            questNav[i] = true
                        }
                    } label:{
                        NavigationLink(isActive: $questNav[i]) {
                            QuestView(quest: questL[i])
                        } label: {
                            ZStack{
                                Text("\(questL[i].name)")
                                    .font(.custom("Bradley Hand", fixedSize: 20))
                                    .foregroundColor(.classicInk)
                                if toDelete.contains(i){
                                    Rectangle().frame(height: 2).foregroundColor(.red)
                                }
                            }
                        }
                        .disabled(editing)
                    }
                //Add Quest
                }else if i == questL.count{
                    TextField("New Quest \(Image(systemName: "plus"))" , text: $newQuestName)
                        .submitLabel(.done)
                        .onSubmit {
                            addQuest()
                        }
                //empty padding
                }else{
                    Rectangle().opacity(0)
                }
            }
            .frame(height:30)
        }.onAppear(){
            loadQuests()
        }.onChange(of: editing) { newValue in
            if toDelete.isEmpty { return }
            delQuests(offsets: toDelete)
            //loadQuests()
        }
    }
    func addQuest(){
        context.perform {
            if newQuestName == "" { return }
            _ = Quest(context: context, name: newQuestName)
            newQuestName = ""
            do{try context.save()}catch{}
            loadQuests()
        }
    }
    func delQuests(offsets: IndexSet){
        context.perform {
            //this instead of context.delete -> questL.remove to prevent editing deleted object warning AND visual issue of "Unnamed Quest" being removed from list
            offsets.map{questL[$0]}.forEach { q in
                questL.removeAll { qs in
                    q == qs
                }
                context.delete(q)
            }
            toDelete = IndexSet()
            do{try context.save()}catch{}
        }
    }
    func toggleDelQuest(index i: Int){
        if toDelete.contains(i){
            toDelete.remove(i)
        }else{
            toDelete.insert(i)
        }
    }
}
struct QuestManagerView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @State private var questfs: [Quest] = [] //done to prevent FetchRequest causing view backtracking when activating quests (changing attributes)
    
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Quest.isActive, ascending: false),NSSortDescriptor(keyPath: \Quest.questName, ascending: true)]) private var quests: FetchedResults<Quest>
    
    @State var expandedQuest: Quest? = nil
    @State var predicateIndex: Int = 0
    let predicates: [NSPredicate?] =
        [nil, NSPredicate(format: "isActive == true"), NSPredicate(format: "isActive == false")]
    let predicateName: [String] = ["", "Active ", "Inactive "]
    let listSize: Int
    @StateObject var jviewModel = JournalViewModel()
    //book cover vars
    init(listLength: Int){
        //arbitrary values obtained using GeometryReader and Divider+Row height
        //ideally this bit would be done in var body, but encasing the ForEach in a GeometryReader makes each loop result overlay eachother
        listSize = listLength
    }
    @State var myb: Bool = false
    var body: some View {
        JournalView(extraPages: (quests.count)/listSize, lines: listSize, viewModel: jviewModel){
            ZStack{
                Button(){
                    predicateIndex += 1
                    if predicateIndex == 3{
                        predicateIndex = 0
                    }
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
                    QuestList(size:listSize, offset: (jviewModel.page-1)*listSize, predicate: predicates[predicateIndex], context: viewContext
                    ).id(jviewModel.page).id(predicateIndex)
                }
                Spacer()
            }.padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
        }
        .navigationViewStyle(.stack)
    }
    
    private func refreshQuests(context: NSManagedObjectContext){
        let fr = NSFetchRequest<Quest>()
        fr.entity = Quest.entity()
        fr.sortDescriptors = [NSSortDescriptor(keyPath: \Quest.questName, ascending: true)]
        do{
            try questfs = context.fetch(fr)
            expandedQuest = questfs.last
        }catch{
            return
        }
    }
    
    
    private func addQuest() {
        withAnimation {
            _ = Quest(context: viewContext, name: "New Quest")

            do {
                try viewContext.save()
                refreshQuests(context: viewContext)
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func deleteQuests(offsets: IndexSet) {
        viewContext.perform {
            withAnimation {
                offsets.map {quests[$0] }.forEach { q in
                    let nullifyKey = QuestKey.generateKey(quest: q)
                    nullifyKey.keyType = .deleted
                    viewContext.delete(q)
                }
                do{try viewContext.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
                refreshQuests(context: viewContext)
            }
        }
    }
}

#Preview {
    QuestManagerView(listLength: 16).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

