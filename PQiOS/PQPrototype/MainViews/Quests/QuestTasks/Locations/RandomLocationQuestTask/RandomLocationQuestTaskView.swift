//
//  RandomLocationQuestTaskView].swift
//  PQPrototype
//
//  Created by William Hart on 26/05/2026.
//

import SwiftUI
import CoreData
struct RandomLocationQuestTaskView: View {
    
    @Environment(\.editMode) private var editMode
    private var editing: Bool { get { return  editMode!.wrappedValue.isEditing }}
    
    @Environment(\.managedObjectContext) public var context
    
    @ObservedObject
    var task: RandomLocationQuestTask
    
    // -- Editable attributes
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Location.name, ascending: true)],animation: .default)
    private var locations: FetchedResults<Location>
    
    @FetchRequest private var individualLocations: FetchedResults<LocationOccupationQuestTask>
    // --

    @StateObject var viewModel = RandomLocationQuestTaskViewModel()
    
    init(locationTask: RandomLocationQuestTask){
        self.task = locationTask
        //self.locationView = LocationView(location: locationTask.taskArea!)
        _individualLocations = FetchRequest(
                sortDescriptors: [
                    NSSortDescriptor(keyPath: \LocationOccupationQuestTask.objectID, ascending: true)
                ],
                predicate: NSPredicate(format: "quest == %@", locationTask.quest!)
            )
    }
    
    var body: some View {
        VStack{
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
                    Text("Origin: ").frame(width: 55)
                    Picker("ThisDoesn'tMatterAFAIK",selection: $task.location){
                        ForEach(locations){loc in
                            let loc = loc as Location
                            Text(StringUtils.firstXLettersOfString(str: loc.name!, x: 7, trailingEllipse: true)).tag(loc as Location?)
                        }
                        (Text(Image(systemName: "plus")) + Text("New"))
                            .foregroundColor(.blue).tag(nil as Location?)
                    }.onChange(of: task.location, perform: { value in
                        if value == nil{
                            task.location = Location(context: context)
                        }
                    })
                    .frame(width: UIScreen.main.bounds.width/4 - 10)
                    .disabled(!editing)
                    Text("Locations: ").frame(width: 100)
                    Picker("", selection: $task.numberOfGeneratedLocations) {
                        ForEach(1..<11){i in
                            Text("\(i)")
                                .tag(Int16(i))
                        }
                    }.disabled(!editing)
                }.frame(height: 35)
            }
            Button{
                viewModel.refreshMarkers()
            } label: {
                Text("Generate Example Areas")
            }
            
            
            LocationView(loc: task.location!)
                .id(task.location!.objectID)
            
        }.onChange(of: editMode!.wrappedValue.isEditing) { v in
            if v == false{
                //if attempted to save and couldnt
                if !save() {
                    //maintain edit mode
                    editMode?.wrappedValue = EditMode.active
                }
            }
        }.onAppear{
            viewModel.loadTaskData(task: task)
        }
    }
    
    private func save() -> Bool{
        context.perform {
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
    let task = RandomLocationQuestTask(context: PersistenceController.preview.container.viewContext,dummyVar: true)
    
    quest.addToTasks(task)
    return RandomLocationQuestTaskView(locationTask: task).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
   //return Text("HI")
}
