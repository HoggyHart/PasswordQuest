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
    var task: LocationOccupationQuestTask
    
    // -- Editable attributes
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Location.name, ascending: true)],animation: .default)
    private var locations: FetchedResults<Location>
    
    
    @State var editedDuration: Date = Date(timeIntervalSinceReferenceDate:3600)

    // --

    //var locationView: LocationView = LocationView()
    @StateObject var viewModel = LocationTaskViewModel()
    
    init(locationTask: LocationOccupationQuestTask){
        self.task = locationTask
        //self.locationView = LocationView(location: locationTask.taskArea!)
    }
    func loadData(){
        editedDuration = Date(timeIntervalSinceReferenceDate: task.requiredOccupationDuration)
    }
    var body: some View {
        VStack{
            VStack{
                //edit button header since atm this view is broght up as a form from the bottom of QuestView
                if !task.quest!.isActive{
                    HStack{
                        Spacer()
                        EditButton()
                    }
                }
                TextField("Task Name", text: $task.name ?? "Task Name")
                    .font(.title)
                    .disabled(!editing)
                HStack{
                    HStack{
                        Text("Location: ").frame(width: UIScreen.main.bounds.width/4 - 10)
                        Picker("whass",selection: $task.taskArea){
                            ForEach(locations){loc in
                                let loc = loc as Location
                                Text(StringUtils.firstXLettersOfString(str: loc.name!, x: 7, trailingEllipse: true)).tag(loc as Location?)
                            }
                            (Text(Image(systemName: "plus")) + Text("New")).foregroundColor(.blue).tag(nil as Location?)
                        }.onChange(of: task.taskArea, perform: { value in
                            if value == nil{
                                task.taskArea = Location(context: context)
                            }
                        })
                        .frame(width: UIScreen.main.bounds.width/4 - 10)
                        .disabled(!editing)
                    }.frame(height: 35)
                    DatePicker(selection: $editedDuration, displayedComponents:.hourAndMinute, label: {Text("Duration:")})
                        .environment(\.locale, Locale(identifier: "en_UK"))
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .frame(width: 170)
                        .disabled(!editing)
                }
            }.padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
            if let area = task.taskArea{
                LocationView(loc: area)
                    .id(area.objectID)
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
    
    func save() -> Bool{
        context.perform {
            let dur = editedDuration.timeIntervalSinceReferenceDate
            task.requiredOccupationDuration = dur
            do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
            
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

