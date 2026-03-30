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
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Location.name, ascending: true)],animation: .default)
    private var locations: FetchedResults<Location>
   
    @State var location: Location?
    
    @StateObject var viewModel = LocationManagerModel()
    
    let h = 45
    
    @State var showList = true
    @State var areasDrawn: [Bool] = []
    
    var body: some View {
        ZStack{
            // -- MAP
            ZStack{
                UIViewToViewWrapper(view: viewModel.map)
                    .frame(width: UIScreen.main.bounds.width)
            
                //notepad content
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
                                                        && areasDrawn[locations.firstIndex(of: loc)!] ? .black : .white)
                                                }
                                                .frame(width:30,height:30)
                                                Button(){
                                                    showLocation(location: loc)
                                                } label: {
                                                    Text(loc.name!)
                                                }
                                                Spacer()
                                                if editing && loc.tasks?.count == 0{
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
                    //Main UI buttons
                    VStack{
                        //header
                        HStack{
                            EditButton()
                                .foregroundColor(.white)
                                .opacity(showList ? 1 : 0)
                                    .disabled(showList ? false : true)
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
                                viewModel.map.setCenter(LocationServices.service.getLocation(), animated: true)
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
                areasDrawn.append(true)
                viewModel.registerLocation(loc: loc)
            }
        }
        .toolbar(){
            EditButton()
        }
        
    }
    
    func deleteLocation(_ loc: Location){
        context.perform {
                let i = locations.firstIndex(of: loc)!
                context.delete(loc)
                viewModel.unregisterLocation(areaIndex: i)
                areasDrawn.remove(at: i)
                do{try context.save()}catch{let nsError = error as NSError;fatalError("Unresolved error \(nsError),\(nsError.userInfo)")}
        }
    }
    func toggleLocation(_ loc: Location){
        let i = locations.firstIndex(of: loc)!
        areasDrawn[i].toggle()
        if areasDrawn[i]{
            viewModel.showArea(areaIndex: i)
            viewModel.centerOn(loc)
        } else {
            viewModel.hideArea(areaIndex: i)
        }
    }
    func showLocation(location: Location){
        viewModel.centerOn(location)
    }
    
    func showLocationDetails(){
        
    }
}

#Preview {
    LocationManagerView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
