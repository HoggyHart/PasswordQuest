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
    private var editing: Bool { get { return  editMode!.wrappedValue.isEditing }}
    
    @Environment(\.managedObjectContext) public var context
    
    @ObservedObject
    var locationTask: LocationOccupationQuestTask
    
    @State var saved: Bool = false
    
    @State var editedName: String = ""
    @State var editedLatitude: String = ""
    @State var editedLongitude: String = ""
    @State var editedSize: String = ""
    @State var editedDuration: Date = Date(timeIntervalSinceReferenceDate:3600)

    
    @State var latIsValidV = true
    @State var longIsValidV = true
    @State var radIsValidV = true
    @StateObject var viewModel = LocationTaskViewModel()
    
    init(locationTask: LocationOccupationQuestTask){
        self.locationTask = locationTask
    }
    func loadData(){
        editedName = locationTask.taskArea!.name!
        editedLatitude = String(locationTask.taskArea!.latitude)
        editedLongitude = String(locationTask.taskArea!.longitude)
        editedSize = String(locationTask.taskArea!.radius)
        editedDuration = Date(timeIntervalSinceReferenceDate: locationTask.requiredOccupationDuration)
        viewModel.lateInit(area: locationTask)
    }
    var body: some View {
        VStack{
            VStack{
                //edit button header since atm this view is broght up as a form from the bottom of QuestView
                if !locationTask.quest!.isActive{
                    HStack{
                        Spacer()
                        EditButton()
                    }
                }
                HStack{
                    TextField("Location Name: ", text: $editedName).font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/).disabled(!editing)
                    if editing {Image(systemName:"pencil")}
                }.frame(height:40) //needs set height, the pencil image causes this to get shorter (???) which resizes the map and causes lag
                
                Divider()
                
                // -- Latitude and Longitude
                HStack{
                    HStack{
                        Text("Lat:")
                        Spacer()
                        VStack(spacing: 0){
                            HStack(spacing:0){
                                TextField("Latitude", text: $editedLatitude).disabled(!editing)
                                if !latIsValidV{ Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(.red)
                                    .frame(alignment: .trailing) }
                                if editing {Image(systemName:"pencil")}
                            }
                            Rectangle().frame(height: 1)
                        }
                    }
                    
                    HStack{
                        Text("Lon:")
                        Spacer()
                        VStack(spacing: 0){
                            HStack(spacing:0){
                                TextField("Longitude", text: $editedLongitude).disabled(!editing)
                                if !longIsValidV{ Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(.red)
                                    .frame(alignment: .trailing) }
                                if editing {Image(systemName:"pencil")}
                            }
                            Rectangle().frame(height: 1)
                        }
                    }
                }
                
                Divider()
                
                // -- Radius of location  area
                HStack{
                    HStack{
                        Text("Radius:")
                        Spacer()
                        VStack(spacing:0){
                            HStack(spacing:0){
                                TextField("size", text: $editedSize)
                                    .disabled(!editing)
                                if !radIsValidV{ Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(.red)
                                    .frame(alignment: .trailing) }
                                if editing {Image(systemName:"pencil")}
                            }
                            Rectangle().frame(height:1)
                        }
                    }
                    HStack{
                        DatePicker(selection: $editedDuration, displayedComponents:.hourAndMinute, label: {Text("Duration:")})
                            .environment(\.locale, Locale(identifier: "en_UK"))
                            .datePickerStyle(GraphicalDatePickerStyle())
                    }
                }
            }.padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
            
            // -- MAP
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
                        .frame(width: 50,height: 50)
                        Spacer()
                        Button(){
                            viewModel.map.setCenter(CLLocationCoordinate2D(latitude: locationTask.taskArea!.latitude, longitude: locationTask.taskArea!.longitude), animated: true)
                        } label :{
                            ZStack{
                                Image(systemName: "mappin.and.ellipse").shadow(radius: 10)
                            }
                        }
                        .frame(width: 50,height: 50)
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
                //if attempted to save and couldnt
                if !save() {
                    //maintain edit mode
                    editMode?.wrappedValue = EditMode.active
                }
            }
        }
        .onAppear(perform: loadData)
    }
    
    func latIsValid() -> Bool{
        guard let lat: Double = Double(editedLatitude) else {
            latIsValidV = false
            return latIsValidV
        }
        
        if lat < -90 || lat > 90 { latIsValidV = false }
        else { latIsValidV = true }
        return latIsValidV
    }
    
    func longIsValid() -> Bool{
        guard let long: Double = Double(editedLongitude) else {
            return false
        }
        
        if long < -180 || long > 180 { return false }
        return true
    }
    
    func radIsValid() -> Bool{
        guard let rad: Double = Double(editedSize) else {
            return false
        }
        
        if rad < 1 { return false }
        else { return true }
    }
    
    func save() -> Bool{
        radIsValidV = radIsValid()
        longIsValidV = longIsValid()
        latIsValidV = latIsValid()
        if !radIsValidV || !longIsValidV || !latIsValidV{
            // flash the error
            //return false "couldnt save, invalid data"
            return false
        }
        context.perform {
            let task = locationTask
            //FIX: region ID needs to be made unique somewhere
            let lat: Double = Double(editedLatitude)!
            let lon: Double = Double(editedLongitude)!
            let rad: Double = Double(editedSize)!
            
            //let dur = Calendar.current.date(bySetting: .second, value: 5, of: editedDuration)!.timeIntervalSinceReferenceDate
            let dur = editedDuration.timeIntervalSinceReferenceDate
            task.taskArea!.latitude = lat
            task.taskArea!.longitude = lon
            task.taskArea!.radius = rad
            task.taskArea!.name = editedName
            task.requiredOccupationDuration = dur
            do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
            viewModel.refresh()
        }
        return true
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
