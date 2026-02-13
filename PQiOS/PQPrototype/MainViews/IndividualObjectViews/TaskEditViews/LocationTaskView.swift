//
//  LocationTaskEditView.swift
//  PQPrototype
//
//  Created by William Hart on 29/12/2025.
//

import SwiftUI
import CoreLocation
import MapKit

struct LocationTaskView: View {
    @Environment(\.editMode) private var editMode
    @Environment(\.managedObjectContext) public var context
    
    @ObservedObject
    var locationTask: LocationOccupationQuestTask
    @State var saved: Bool = false
    
    @State var editedName: String = ""
    @State var editedLatitude: String = ""
    @State var editedLongitude: String = ""
    @State var editedSize: String = ""
    @State var editedDuration: Date = Date(timeIntervalSinceReferenceDate:3600)

    @StateObject var viewModel = LocationTaskViewModel()
    
    init(locationTask: LocationOccupationQuestTask){
        self.locationTask = locationTask
    }
    func loadData(){
        editedName = locationTask.locationName!
        editedLatitude = String(locationTask.taskArea!.center.latitude)
        editedLongitude = String(locationTask.taskArea!.center.longitude)
        editedSize = String(locationTask.taskArea!.radius)
        editedDuration = Date(timeIntervalSinceReferenceDate: locationTask.requiredOccupationDuration)
        viewModel.lateInit(area: locationTask)
    }
    var body: some View {
        VStack{
            VStack{
                //FIX: does not update automatically when value changes
                // if session gets started via scheduler, user can change values to cheat / cause problems?
                if !locationTask.quest!.isActive{
                    HStack{
                        Spacer()
                        EditButton()
                    }
                }
                Divider()
                HStack{
                    Text("Location Name: ")
                    Spacer()
                    TextField("name", text: $editedName)
                        .disabled(false)
                }
                Divider()
                HStack{
                    Text("Latitude: ")
                    Spacer()
                    TextField("lat", text: $editedLatitude)
                }
                HStack{
                    Text("Longitude: ")
                    Spacer()
                    TextField("lon", text: $editedLongitude)
                }
                Divider()
                HStack{
                    Text("Radius: ")
                    Spacer()
                    TextField("size", text: $editedSize)
                }
                Divider()
                DatePicker(selection: $editedDuration, displayedComponents:.hourAndMinute, label: {Text("Required Occupation Period (hrs+mins)")})
                    .environment(\.locale, Locale(identifier: "en_UK"))
                    .datePickerStyle(GraphicalDatePickerStyle())
            }.padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 30))
            Divider()
            ZStack{
                UIViewToViewWrapper(view: viewModel.map)
                VStack{
                    Spacer()
                    HStack{
                        Button(){
                            viewModel.map.setCenter(LocationServices.service.getLocation(), animated: true)
                        } label :{
                            Image(systemName: "person.fill.questionmark")
                        }
                        .frame(width: 40,height: 40)
                        Spacer()
                        Button(){
                            viewModel.map.setCenter(locationTask.taskArea!.center, animated: true)
                        } label :{
                            ZStack{
                                Image(systemName: "mappin.and.ellipse").shadow(radius: 10)
                            }
                        }
                        .frame(width: 40,height: 40)
                    }
                }
                .padding(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
            }
        }
        .toolbar(){
            EditButton()
        }
        .onChange(of: editMode!.wrappedValue.isEditing) { v in
            if v == false{
                save()
            }
        }
        .onAppear(perform: loadData)
    }
    
    func save(){
        context.perform {
            let task = locationTask
            //FIX: region ID needs to be made unique somewhere
            guard let lat: Double = Double(editedLatitude) else {
                editedLatitude.append(" IS INVALID")
                return
            }
            guard let lon: Double = Double(editedLongitude) else{
                editedLongitude.append(" IS INVALID")
                return
            }
            guard let rad: Double = Double(editedSize) else{
                editedSize.append(" IS INVALID")
                return
            }
            //let dur = Calendar.current.date(bySetting: .second, value: 5, of: editedDuration)!.timeIntervalSinceReferenceDate
            let dur = editedDuration.timeIntervalSinceReferenceDate
            task.lateInit(
                locName: editedName,
                taskArea: CLCircularRegion(
                    center: CLLocationCoordinate2D(
                        latitude: lat,
                        longitude: lon
                    ),
                    radius: rad,
                    identifier: editedName+"_"+locationTask.quest!.questUUID!.uuidString),
                questDuration: dur
            )
            do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
            viewModel.refresh()
        }
    }
  
}

#Preview {
    var quest: Quest
    do{
        quest = try PersistenceController.preview.container.viewContext.fetch(Quest.fetchRequest())[0]
    }catch{quest = Quest(context: PersistenceController.preview.container.viewContext)}
    let task = LocationOccupationQuestTask(context: PersistenceController.preview.container.viewContext)
    task.lateInit(
        locName: "Unnamed Location",
        taskArea: CLCircularRegion(
            center: CLLocationCoordinate2D(
                latitude: 0,
                longitude: 0
            ),
            radius: 0,
            identifier: "newLocTask"),
        questDuration: 1
    )
    quest.addToTasks(task)
    return LocationTaskView(locationTask: task).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
