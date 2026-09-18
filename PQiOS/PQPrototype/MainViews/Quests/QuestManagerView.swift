//
//  ContentView.swift
//  PQPrototype
//
//  Created by William Hart on 27/11/2025.
//

import SwiftUI
import CoreData

struct QuestPreview: View {
    
    @ObservedObject
    var quest: Quest
    
    @State var extended: Bool = false
    
    var header: some View {
        VStack(spacing: 0){
            ZStack{
             //   RoundedRectangle(cornerRadius: 3).foregroundColor(.brown).offset(y:-7).opacity(0.3)
               // RoundedRectangle(cornerRadius: 3).foregroundColor(Color(red: 243/255, green: 227/255, blue: 172/255))
                Text("\(quest.name)")
                    .font(.custom("Bradley Hand", fixedSize: 20))
                    .foregroundColor(Color(red: 22/255, green: 13/255, blue: 13/255))
            }
        }.frame(height: 30)
    }
    var content: some View {
        ZStack{
            Rectangle().foregroundColor(Color(red: 243/255, green: 227/255, blue: 172/255)).shadow(radius: 10)
            VStack(alignment: .trailing){
                NavigationLink(destination: QuestView(quest: quest)) {
                    Rectangle().foregroundStyle(.black).frame(width: 100, height: 50)
                }
                Image(systemName: "arrow.right")
                QuestView(quest: quest)
            }
        }
    }
    var body: some View{
     //   Button(){
        //    extended.toggle()
     //   } label: {
            //if !extended{
                header
           // }
     //   }
       // if extended{
         //   content
        //}
        
    }
}

struct QuestList: View {
    @Environment(\.managedObjectContext) private var context
   
    @Environment(\.editMode) private var editMode
    var editing: Bool { get { return  editMode!.wrappedValue.isEditing }}
    
  //  @FetchRequest private var quests: FetchedResults<Quest>
    @State private var questL: [Quest] = []
   // @State var ertext: String = ""
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
        }catch let e{
            self.questL = []
            //     self.ertext = e.localizedDescription
        }
    }

    @State var toDelete: IndexSet = IndexSet()
    var body: some View{
        ForEach(0..<size, id: \.self){i in
            VStack(alignment: .leading, spacing: 0){
                if i < questL.count{
                    ZStack{
                        if !editing{
                            NavigationLink(destination: QuestView(quest: questL[i])) {
                                QuestPreview(quest: questL[i])
                                    .frame(height: 30)
                            }
                        }
                        if editing{
                            Button(){
                                if toDelete.contains(i){
                                    toDelete.remove(i)
                                }else{
                                    toDelete.insert(i)
                                }
                            } label:{
                                ZStack{
                                    QuestPreview(quest: questL[i])
                                        .frame(height: 30)
                                    if toDelete.contains(i){
                                        Rectangle().frame(height: 2).foregroundColor(.red)
                                    }
                                }
                            }
                        }
                    }
                }else if i == questL.count && i > 0{
                    TextField("New Quest \(Image(systemName: "plus"))" , text: $newQuestName)
                        .frame(height:30)
                }else{
                    Rectangle().opacity(0)
                        .frame(height:30)
                }
                Divider()
            }.padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
        }.onAppear(){
            loadQuests()
        }.onChange(of: editing) { newValue in
            if toDelete.isEmpty { return }
            delQuests(offsets: toDelete)
            //loadQuests()
        }
    }
    func delQuests(offsets: IndexSet){
        context.perform {
            offsets.map{questL[$0]}.forEach(context.delete)
            questL.remove(atOffsets: offsets)
            toDelete = IndexSet()
            do{try context.save()}catch{}
        }
    }
}
struct QuestManagerView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @State private var questfs: [Quest] = [] //done to prevent FetchRequest causing view backtracking when activating quests (changing attributes)
    
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Quest.isActive, ascending: false),NSSortDescriptor(keyPath: \Quest.questName, ascending: true)]) private var quests: FetchedResults<Quest>
    
    @State var expandedQuest: Quest? = nil
    @State var page = 1
    @State var activeSort: Bool = false
    @State var pageSide: CGFloat = -1
    let listSize: Int
    
    //book cover vars
    var bCCornerRadius: CGFloat = 10
    
    init(pageSize: CGFloat = UIScreen.main.bounds.height){
        //arbitrary values obtained using GeometryReader and Divider+Row height
        //ideally this bit would be done in var body, but encasing the ForEach in a GeometryReader makes each loop result overlay eachother
        let px = pageSize - 136.5
        listSize = max(0,Int(px/31))
    }
    var body: some View {
        ZStack{
            //table
            Rectangle().foregroundColor(Color(red:96/255,green:58/255,blue:0))
            //book cover
            RoundedRectangle(cornerRadius: bCCornerRadius)
                .foregroundColor(Color(red:70/255,green:30/255,blue:0))
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
                    Rectangle().foregroundColor(Color(red: 243/255, green: 227/255, blue: 172/255)).offset(x:-pageSide*CGFloat(i)).shadow(radius: 1)
                }.id(page)
                //quest list
                //  list is 1 + 31*size pixels tall i beleievee
                VStack(spacing:0){
                  //  Text("\(UIScreen.main.bounds.height)")
                    Spacer()
                    
                    Divider()
                    
                       // Text("\(h.size.height)")
                        QuestList(size:listSize, offset: (page-1)*listSize, predicate: nil, context: viewContext
                        ).id(page).id(activeSort)
                    
                    Spacer()
                }
                
                
                //overlay
                VStack(spacing:0){
                
                    ZStack{
                        Text("Quest Log").font(.custom("Bradley Hand", fixedSize: 25))
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
                                .foregroundColor(Color(red:0.7,green:0,blue:0))
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
                                .foregroundColor(Color(red:0.7,green:0,blue:0))
                        }
                        
                    }.frame(height:30)
                }
                .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
            }
            .padding(EdgeInsets(top: 20,
                                leading: 11,
                                bottom: 20,
                                trailing: 11))
            if(pageSide == -1){
                HStack(spacing:0){
                    Spacer()
                    Rectangle().frame(width: 1).padding(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0))
                    Rectangle().frame(width: 11).padding(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0)).foregroundColor(Color(red: 243/255, green: 227/255, blue: 172/255))
                }
            }else{
                HStack(spacing:0){
                    Rectangle().frame(width: 11).padding(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0)).foregroundColor(Color(red: 243/255, green: 227/255, blue: 172/255))
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
    QuestManagerView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)

}

