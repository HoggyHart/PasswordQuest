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
                Divider()
            }.padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                .frame(height:25)
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
    @State var page = 1
    @State var predicateIndex: Int = 0
    let predicates: [NSPredicate?] =
        [nil, NSPredicate(format: "isActive == true"), NSPredicate(format: "isActive == false")]
    @State var pageSide: CGFloat = -1
    let predicateName: [String] = ["", "Active ", "Inactive "]
    let listSize: Int
    
    //book cover vars
    var bCCornerRadius: CGFloat = 10
    init(listLength: Int){
        //arbitrary values obtained using GeometryReader and Divider+Row height
        //ideally this bit would be done in var body, but encasing the ForEach in a GeometryReader makes each loop result overlay eachother
        listSize = listLength
    }
    var body: some View {
        ZStack{
            //table
            Rectangle().foregroundColor(.tableWood)
            //book cover
            RoundedRectangle(cornerRadius: bCCornerRadius)
                .foregroundColor(.bookCover)
                .padding(
                    EdgeInsets(top: 10,
                               leading: min(1,-pageSide*bCCornerRadius),
                               bottom: 10,
                               trailing: min(1,pageSide*bCCornerRadius)))
                .id(page)
            
            //page(s)
            ZStack{
                //gives page selection some 'UI depth'
                ForEach(0..<min(5,page)){i in
                    Rectangle().foregroundColor(.journalPaper).offset(x:-pageSide*CGFloat(i)).shadow(radius: 1)
                }.id(page)
                //quest list
                //  list is 1 + 31*size pixels tall i beleievee
                VStack(spacing:0){
                  //  Text("\(UIScreen.main.bounds.height)")
                    Spacer()
                    
                    Divider()
                    
                       // Text("\(h.size.height)")
                        QuestList(size:listSize, offset: (page-1)*listSize, predicate: predicates[predicateIndex], context: viewContext
                        ).id(page).id(predicateIndex)
                    
                    Spacer()
                }
                
                
                //overlay
                VStack(spacing:0){
                
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
                    }
                    
                
                    Spacer()
                    HStack{
                        
                        Button(){
                            if page == 1 {return}
                            page = max(1,page-1)
                            pageSide *= -1
                        } label: {
                            Image(systemName: "arrowshape.turn.up.left.fill")
                                .foregroundColor(.darkRed)
                        }
                        Spacer()
                        //Text("\(page*2 + min(0,Int(pageSide)))")
                        Text("\(page)")
                        Spacer()
                        Button(){
                            page += 1
                            pageSide *= -1
                        } label: {
                            Image(systemName: "arrowshape.turn.up.right.fill")
                                .foregroundColor(.darkRed)
                        }
                        
                    }.frame(height:30)
                }
                .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
            }
            .padding(EdgeInsets(top: 20,
                                leading: 11,
                                bottom: 20,
                                trailing: 11))
            
            //other side of journal, probably a smoother way to do this
            if(pageSide == -1){
                HStack(spacing:0){
                    Spacer()
                    Rectangle().frame(width: 1).padding(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0))
                    Rectangle().frame(width: 11).padding(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0)).foregroundColor(.journalPaper)
                }
            }else{
                HStack(spacing:0){
                    Rectangle().frame(width: 11).padding(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0)).foregroundColor(.journalPaper)
                    Rectangle().frame(width: 1).padding(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0))
                    Spacer()
                }
            }
        }
        .navigationViewStyle(.stack)
     //   .frame(height: 20)
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
    QuestManagerView(listLength: 20).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

