//
//  LocationAttributeEditView.swift
//  PQPrototype
//
//  Created by William Hart on 19/02/2026.
//

import SwiftUI
import CoreData
import MapKit

struct LocationView: View {
    @Environment(\.editMode) private var editMode
    private var editing: Bool { get { return  editMode!.wrappedValue.isEditing }}
    @Environment(\.managedObjectContext) private var context
    
    @ObservedObject
    var location: Location
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Location.name, ascending: true)],animation: .default)
    private var locations: FetchedResults<Location>
   
    @State var editedSize: String = ""
    
    @State var nameIsValidV = true
    @State var radIsValidV = true
    
    @StateObject var viewModel = LocationMapModel()
    
    init(loc: Location){
        location = loc
    }
    
    
    var body: some View {
        VStack{
        VStack{
            HStack{
                TextField("Location Name: ", text: $location.name ?? "Unnamed Location").font(.title).disabled(!editing)
                if !nameIsValidV{ Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                    .frame(alignment: .trailing) }
                if editing {Image(systemName:"pencil")}
            }.frame(height:40) //needs set height, the pencil image causes this to get shorter (???) which resizes the map and causes lag
            
            Divider()
            
            // -- map center controls
            HStack{
                Button(){
                    viewModel.map.setCenter(LocationServices.service.getLocation(), animated: true)
                } label :{
                    ZStack{
                        Circle().foregroundColor(.red)
                        Image(systemName: "person.fill.questionmark").foregroundColor(.white)
                    }
                }.frame(width:40, height:40)
                
                Button(){
                    viewModel.map.setCenter(location.center(), animated: true)
                } label :{
                    ZStack{
                        Circle().foregroundColor(.red)
                        Image(systemName: "mappin.and.ellipse").foregroundColor(.white)
                    }
                }.frame(width:40, height:40)
            }
        }.padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
        
        // -- MAP + Overlay attribute controls
            ZStack{
                UIViewToViewWrapper(view: viewModel.map)
                
                if editing{
                    VStack{
                        Spacer()
                        ZStack{
                            Rectangle().foregroundColor(.white)
                            VStack(spacing:0){
                                Text("Radius:")
                                Slider(value: $location.radius,in: 10...1000,step:1) { _ in
                                    viewModel.updateMarker()
                                }
                            }.padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                        }.frame(height: 70)
                    }
                }
            }
    }
        
        .toolbar(){
            EditButton()
        }
        .onChange(of: editing) { nowEditing in
            viewModel.editing = nowEditing
            if nowEditing == false{
                if save() == false {
                    editMode?.wrappedValue = EditMode.active
                }
            }
        }
        .onAppear(perform: loadData)
        
        .onChange(of: location) { newValue in
            loadData()
        }
    }
    
    func loadData(){
        viewModel.markArea(area: location)
    }
    
    private func save() -> Bool{
        context.perform {
            do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
            
            viewModel.updateMarker()
        }
        return true
    }
    
}


