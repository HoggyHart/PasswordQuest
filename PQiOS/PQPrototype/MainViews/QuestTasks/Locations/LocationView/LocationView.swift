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
    
    var location: Location
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Location.name, ascending: true)],animation: .default)
    private var locations: FetchedResults<Location>
   
    @State var editedName: String = ""
    @State var editedLatitude: String = ""
    @State var editedLongitude: String = ""
    @State var editedSize: String = ""
    
    @State var nameIsValidV = true
    @State var latIsValidV = true
    @State var longIsValidV = true
    @State var radIsValidV = true
    
    @StateObject var viewModel = LocationMapModel()
    
    init(loc: Location){
        location = loc
    }
    
    
    var body: some View {
        VStack{
            HStack{
                TextField("Location Name: ", text: $editedName).font(.title).disabled(!editing)
                if !nameIsValidV{ Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                    .frame(alignment: .trailing) }
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
                Button(){
                    viewModel.map.setCenter(LocationServices.service.getLocation(), animated: true)
                } label :{
                    ZStack{
                        Circle().foregroundColor(.red)
                        Image(systemName: "person.fill.questionmark").foregroundColor(.white)
                    }
                }.frame(width:40, height:40)
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
                }.padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
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
        
        // -- MAP
        UIViewToViewWrapper(view: viewModel.map)
        .toolbar(){
            EditButton()
        }
        .onChange(of: editing) { nowEditing in
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
        print("Location: \(location)")
        editedName = location.name!
        editedLatitude = String(location.latitude)
        editedLongitude = String(location.longitude)
        editedSize = String(location.radius)
        viewModel.markArea(area: location)
    }
    
    private func nameIsValid() -> Bool{
        return editedName != ""
    }
    private func latIsValid() -> Bool{
        guard let lat: Double = Double(editedLatitude) else {
            return false
        }
        
        if lat < -90 || lat > 90 { return false }
        return true
    }
    
    private func longIsValid() -> Bool{
        guard let long: Double = Double(editedLongitude) else {
            return false
        }
        
        if long < -180 || long > 180 { return false }
        return true
    }
    
    private func radIsValid() -> Bool{
        guard let rad: Double = Double(editedSize) else {
            return false
        }
        
        if rad < 1 { return false }
        else { return true }
    }
    
    
    private func save() -> Bool{
        radIsValidV = radIsValid()
        longIsValidV = longIsValid()
        latIsValidV = latIsValid()
        nameIsValidV = nameIsValid()
        if !radIsValidV || !longIsValidV || !latIsValidV || !nameIsValidV{
            return false
        }
        context.perform {
            let location = location
            
            //FIX: region ID needs to be made unique somewhere
            let lat: Double = Double(editedLatitude)!
            let lon: Double = Double(editedLongitude)!
            let rad: Double = Double(editedSize)!
            
            location.latitude = lat
            location.longitude = lon
            location.radius = rad
            location.name = editedName
            
            do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
            viewModel.markArea(area: location)
        }
        return true
    }
    
}


