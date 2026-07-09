//
//  LocationAttributeEditView.swift
//  PQPrototype
//
//  Created by William Hart on 13/03/2026.
//

import SwiftUI
import CoreData
import MapKit

struct LocationManagerView: View {
    @Environment(\.editMode) private var editMode
    private var editing: Bool { get { return  editMode!.wrappedValue.isEditing }}
    @Environment(\.managedObjectContext) private var context
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Location.name, ascending: true),NSSortDescriptor(keyPath: \Location.objectID, ascending: true)], animation: .default)
    private var locations: FetchedResults<Location>
   
    @State var location: Location?
    
    @StateObject var viewModel = LocationManagerModel()
    
    @State var showList = true
    @State var areasDrawn: Dictionary<NSManagedObjectID,Bool> = [:]
    @State var areaSelected: Dictionary<NSManagedObjectID, Bool> = [:]
    
    var body: some View {
        ZStack{
            // -- MAP
            ZStack{
                UIViewToViewWrapper(view: viewModel.map)
                    .frame(width: UIScreen.main.bounds.width)
            
                //notepad background/content
                ZStack(){
                    VStack{
                        ZStack{
                            //notepad
                            ZStack{
                                VStack{
                                    //background paper
                                    RoundedRectangle(cornerRadius: 22.5)
                                        .foregroundColor(MyColors.parchment)
                                        .frame(
                                            height: CGFloat.minimum(CGFloat(35*locations.count)+45,UIScreen.main.bounds.height*0.5))
                                    Spacer()
                                }
                                VStack{
                                    //background header
                                    RoundedRectangle(cornerRadius: 0)
                                        .foregroundColor(MyColors.leather)
                                        .frame(
                                            height: 45)
                                    Spacer()
                                }
                            }
                            //locations
                            VStack{ZStack{
                                ScrollView(){
                                    VStack(spacing:5){
                                            ForEach(locations) { loc in
                                                HStack(spacing:20){
                                                    Button(){
                                                        toggleLocation(loc)
                                                    } label: {
                                                        Circle().foregroundColor(
                                                            areasDrawn.count > 0
                                                            && areasDrawn[loc.objectID] ?? false ? .black : .white)
                                                    }
                                                    .frame(width:30,height:30)
                                                    Button(){
                                                        showLocation(location: loc)
                                                    }label: {
                                                        NavigationLink(destination: LocationView(loc: loc)){
                                                            Text(loc.name!)
                                                        }
                                                    }
                                                    Spacer()
                                                    if editing && loc.tasks!.count == 0{
                                                        Button(){
                                                            deleteLocation(loc)
                                                        } label:{
                                                            Image(systemName:"xmark").foregroundColor(.red)
                                                        }
                                                    }
                                            }
                                        }
                                    }
                                }
                                .offset(y:45)
                                .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                                .frame(height: CGFloat.minimum(CGFloat(35*locations.count),UIScreen.main.bounds.height*0.5-45))
                            }
                                Spacer()
                            }
                            
                        }.opacity(showList ? 1 : 0)
                            .disabled(showList ? false : true)
                    }
                    //Main UI overlay buttons
                    VStack{
                        //header
                        HStack{
                            EditButton()
                                .foregroundColor(.white)
                                .opacity(showList ? 1 : 0)
                                    .disabled(showList ? false : true)
                            Button(){
                                addLocation()
                            } label:{
                                Image(systemName: "plus")
                            }
                            Spacer()
                            Button(){
                                showList.toggle()
                            } label :{
                                ZStack{
                                    Circle().foregroundColor(MyColors.leather)
                                    Image(systemName:"list.bullet")
                                        .foregroundColor(.white)
                                }
                                .frame(width: 45,height: 45)
                            }
                        }.padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 0))
                        Spacer()
                        //map buttons
                        HStack{
                            //center on user location
                            Button(){
                                viewModel.map.setCenter(LocationServices.shared.getLocation(), animated: true)
                            } label :{
                                ZStack{
                                    Circle().foregroundColor(.red)
                                    Image(systemName: "person.fill.questionmark").foregroundColor(.white)
                                }
                            }.frame(width:40, height:40)
                        }
                    }
                }
                .padding(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
            }
        }
        .onAppear(){
            locations.forEach { loc in
                areasDrawn.updateValue(true, forKey: loc.objectID)
                viewModel.registerLocation(loc: loc)
            }
        }
        .toolbar(){
            EditButton()
        }
        
    }
    
    private func addLocation() {
        withAnimation {
            
            let loc = Location(context: context, name: "New Location", area: CLCircularRegion(center: viewModel.map.centerCoordinate, radius: 50, identifier: UUID().uuidString))
            do {
                try context.save()
                viewModel.registerLocation(loc: loc)
                areasDrawn.updateValue(true, forKey: loc.objectID)
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    func deleteLocation(_ loc: Location){
        context.perform {
            context.delete(loc)
            viewModel.unregisterLocation(areaID: loc.objectID)
            areasDrawn.removeValue(forKey: loc.objectID)
                do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
        }
    }
    func toggleLocation(_ loc: Location){
        areasDrawn[loc.objectID]?.toggle()
        if areasDrawn[loc.objectID]!{
            viewModel.showArea(areaID: loc.objectID)
            viewModel.centerOn(loc)
        } else {
            viewModel.hideArea(areaID: loc.objectID)
        }
    }
    
    func showLocation(location: Location){
        areasDrawn.updateValue(true, forKey: location.objectID)
        viewModel.centerOn(location)
    }
    
    func showLocationDetails(){
        
    }
}

#Preview {
    LocationManagerView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
