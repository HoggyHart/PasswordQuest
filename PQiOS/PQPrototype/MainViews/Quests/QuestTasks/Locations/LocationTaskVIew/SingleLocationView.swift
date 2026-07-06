//
//  SingleeLocationView.swift
//  PQPrototype
//
//  Created by William Hart on 21/06/2026.
//

import SwiftUI
import CoreData
import MapKit

struct SingleLocationView: View {
    @Environment(\.editMode) private var editMode
    private var editing: Bool { get { return  editMode!.wrappedValue.isEditing }}
    @Environment(\.managedObjectContext) private var context
    
    @ObservedObject
    var location: Location
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Location.name, ascending: true)],animation: .default)
    private var locations: FetchedResults<Location>
   
    @ObservedObject var viewModel: SingleLocationTaskViewModel
    
    init(loc: Location, model: SingleLocationTaskViewModel){
        location = loc
        viewModel = model
    }
    
    var body: some View {
        VStack{
            VStack{
                // -- map center controls
                HStack(spacing:5){
                    Button(){
                        viewModel.map.setCenter(LocationServices.service.getLocation(), animated: true)
                    } label :{
                        ZStack{
                            Circle().foregroundColor(.red)
                            Image(systemName: "person.fill.questionmark").foregroundColor(.white)
                        }
                    }
                    
                    Button(){
                        viewModel.refreshMarkers()
                    } label :{
                        ZStack{
                            Circle().foregroundColor(.red)
                            Image(systemName: "arrow.counterclockwise").foregroundColor(.white)
                        }
                    }
                    Button(){
                        viewModel.map.setCenter(location.center(), animated: true)
                    } label :{
                        ZStack{
                            Circle().foregroundColor(.red)
                            Image(systemName: "mappin.and.ellipse").foregroundColor(.white)
                        }
                    }
                }.frame(width: 40*3 + 5*2, height: 40)
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
                                    viewModel.refreshMarkers()
                                }
                            }.padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                        }.frame(height: 70)
                    }
                }
            }
        }
        .onChange(of: editing) { nowEditing in
            viewModel.editing = nowEditing
            if nowEditing == false{
                if save() == false {
                    editMode?.wrappedValue = EditMode.active
                }
            }
        }
      //  .onChange(of: locations, { old, new in
        //    viewModel.refreshMarkers()
        //})
        .onAppear(perform: loadData)
        .toolbar {
            EditButton()
        }
    }
    
    func loadData(){
        viewModel.areas = [location]
        viewModel.markArea(area: location)
    }
    
    private func save() -> Bool{
        context.perform {
            do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
        }
        return true
    }
    
}


#Preview {
    LocationView(loc: Location(context: PersistenceController.preview.container.viewContext, name: "Location", area: CLCircularRegion(center: CLLocationCoordinate2D(latitude: 65, longitude: 70), radius: 50, identifier: "h")))
}
