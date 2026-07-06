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
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Schedule.isActive, ascending: false), NSSortDescriptor(keyPath: \Schedule.startTime, ascending: true)],animation: .default)
    private var schedules: FetchedResults<Schedule>
    
    var body: some View {
        VStack{
            HStack{
                Text("Schedule Manager")
                Button(){
                    viewContext.perform {
                        newSynchroniseWithDesktopApp()
                        do{try viewContext.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
                    }
                } label: {
                    Text("Synchronise")
                }
            }
            List {
                ForEach(schedules) { schedule in
                    NavigationLink {
                        ScheduleView(scheduleToLoad: schedule)
                        
                    } label: {
                        HStack{
                            Text("\(schedule.scheduleName!)")
                            Spacer()
                            ScheduleInfoView(schedule: schedule)
                        }
                    }
                }
            }
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
            for schedule in schedules{
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
                var keyfetch: NSFetchRequest<QuestKey> = NSFetchRequest()
                keyfetch.entity = QuestKey.entity()
                keyfetch.sortDescriptors = [NSSortDescriptor(keyPath: \QuestKey.obtainmentDate, ascending: true)]
                var keys = try keyfetch.execute()
                for key in keys{ //TODO: copied from QuestReewardManager. just make method for both to use or smth
                    let keyd = key.toJson()
                    
                    let newData = Data(keyd.utf8)
                    let task = URLSession.shared.uploadTask(with: request, from: newData){ data, response, error in
                        //print("sent")
                        if let error = error {
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
