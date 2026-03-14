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
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Schedule.objectID, ascending: true)],animation: .default)
    private var schedules: FetchedResults<Schedule>
    
    var body: some View {
        VStack{
            HStack{
                Text("Schedule Manager")
                Button(){
                    viewContext.perform {
                        synchroniseWithDesktopApp()
                        do{try viewContext.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
                    }
                } label: {
                    Text("Synchronise")
                }
            }
            NavigationView {
                List {
                    ForEach(schedules) { schedule in
                        NavigationLink {
                            ScheduleView(scheduleToLoad: schedule)
                            
                        } label: {
                            Text("\(schedule.scheduleName!)")
                        }
                    }
                }
                Text("Select a schedule")
            }
        }
    }
    
    func synchroniseWithDesktopApp(){
        print("attempting send")
        if let url = URL(string:"http://172.20.10.5:1617/synchronise/schedules") {
            var request = URLRequest(url: url)
            
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            var data = ""
            for schedule in schedules{
                data += schedule.toJson() + "\r\n\r\n"
            }
            data.removeLast(2)
            print("date = " + data)
            let newData = Data(data.utf8)
            let task = URLSession.shared.uploadTask(with: request, from: newData){ data, response, error in
                print("sent")
                if let error = error {
                    // Handle the error
                    print("Error: \(error.localizedDescription)")
                } else if let response = (response as? HTTPURLResponse){
                    // Process the data
                    print("response: \(response.statusCode)")
                    if response.statusCode == 200{
                        for schedule in schedules{
                            schedule.synchronised = true
                        }
                    }
                }
            }
            task.resume()
        }
    }
}

#Preview {
    ScheduleManagerView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
