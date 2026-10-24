//
//  ContentView.swift
//  PQPrototype
//
//  Created by William Hart on 27/11/2025.
//

import SwiftUI
import CoreData

struct ScheduleManagerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.editMode) private var editMode
    var editing: Bool { get { return  editMode!.wrappedValue.isEditing }}
    
    @StateObject private var jViewModel = JournalViewModel()
    @StateObject private var viewModel = ScheduleManagerViewModel()
    
    let filters: NSPredicate?
    init(predicate: NSPredicate? = nil){
        filters = predicate
    }
    
    var body: some View {
        JournalView(extraPages: viewModel.fullList.count/viewModel.subListSize, viewModel: jViewModel) {
            HStack{
                VStack{
                    Text("Schedule Manager").font(.journalTitle)
                    Button(){
                        viewContext.perform {
                            newSynchroniseWithDesktopApp()
                            do{try viewContext.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
                        }
                    } label: {
                        Text("Synchronise").font(.journalBody)
                    }
                }
                EditButton().font(.journalSubheading)
            }
        } content: {
            VStack(alignment: .leading,spacing: 0){
                ForEach(viewModel.subList){s in
                    //Quest Line
                    SelectableView(selections: $viewModel.selectedListItems,
                                   value: s.objectID) {
                        NavigationLink(destination: ScheduleView(scheduleToLoad: s)) {
                            ZStack{
                                HStack{
                                    Text("\(s.scheduleName!)").font(.journalBody).foregroundColor(.classicInk)
                                    Spacer()
                                    ScheduleInfoView(schedule: s)
                                    Image(systemName: "chevron.right")
                                }
                                if viewModel.selectedListItems.contains(where: { id in
                                    return id == s.objectID
                                }){
                                    Rectangle().frame(height: 2).foregroundColor(.red)
                                }
                            }
                        }
                        .disabled(editing)
                    }
                    .frame(height:jViewModel.lineHeight)
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
        }.onChange(of: jViewModel.page, perform: { value in
            viewModel.updateSubList(newOffset: (jViewModel.page-1)*viewModel.subListSize)
        })
        .onChange(of: editing) { newValue in
            viewModel.deleteItems()
        }
    }
    
    func synchroniseSchedules(){
        //print("attempting send")
        if let url = URL(string:"http://172.20.10.5:1617/synchronise/schedules") {
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            
            //sync scheedules
            var data = "{ \"scheduleList\": [\n"
            for schedule in viewModel.fullList{
                data += schedule.toJson() + ",\n"
            }
            data.removeLast(2) //removes last ",\n"
            data += "\n]\n}"
            print(data)
            //print("date = " + data)
            let newData = Data(data.utf8)
            let task = URLSession.shared.uploadTask(with: request, from: newData){ data, response, error in
                //print("sent")
                if let error = error {
                    // Handle the error
                    //print("Error: \(error.localizedDescription)")
                } else if let response = (response as? HTTPURLResponse){
                    // Process the data
                    //print("response: \(response.statusCode)")
                    if response.statusCode == 200{
                    }
                }
            }
            task.resume()
        }
    }
    
    func newSynchroniseWithDesktopApp(){
        if let url = URL(string:"http://172.20.10.5:1617/redeem") {
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            
            do{
                let keyfetch: NSFetchRequest<QuestKey> = NSFetchRequest()
                keyfetch.entity = QuestKey.entity()
                keyfetch.sortDescriptors = [NSSortDescriptor(keyPath: \QuestKey.obtainmentDate, ascending: true)]
                let keys = try keyfetch.execute()
                for key in keys{ //TODO: copied from QuestReewardManager. just make method for both to use or smth
                    if key.keyType == .admin { continue }
                    let keyd = key.toJson()
                    
                    let newData = Data(keyd.utf8)
                    let task = URLSession.shared.uploadTask(with: request, from: newData){ data, response, error in
                        //print("sent")
                        if error != nil {
                            // Handle the error
                            //print("Error: \(error.localizedDescription)")
                        } else if let response = (response as? HTTPURLResponse){
                            // Process the data
                            //print(response.statusCode)
                            if response.statusCode == 200{
                                viewContext.perform {
                                    viewContext.delete(key)
                                    do{try viewContext.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
                                }
                            }
                        }
                    }
                    task.resume()
                }
            }catch{
                fatalError("er uh oh")
            }
        }
        
        synchroniseSchedules()
        
    }
}

#Preview {
    ScheduleManagerView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
