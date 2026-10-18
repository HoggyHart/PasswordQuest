//
//  MultiPageList.swift
//  PQPrototype
//
//  Created by William Hart on 13/10/2026.
//

import Foundation

protocol MultiPageList: ObservableObject{
    
    associatedtype Item
    associatedtype ItemID
    
    var fullList: [Item] { get set }
    var subList: [Item] { get set }
    var selectedListItems: [ItemID] { get set}
    
    var subListSize: Int { get set }
    var subListOffset: Int { get set }
    
    func addItem()
    func deleteItems()
}

extension MultiPageList {
    
    func updateMainList(newItems: [Item]){
        self.fullList = newItems
        self.updateSubList()
    }
    
    func updateSubList(newSize: Int? = nil, newOffset: Int? = nil){
        self.subListSize = newSize ?? self.subListSize
        self.subListOffset = newOffset ?? self.subListOffset
        self.subList = [Item]()
        for i in self.subListOffset..<self.subListOffset+self.subListSize{
            if i >= self.fullList.count { break }
            self.subList.append(self.fullList[i])
        }
    }
}

import CoreData
class MultiPageListNSFRControllerDelegate<Item: NSManagedObject, ItemID>: NSObject, MultiPageList, NSFetchedResultsControllerDelegate{
    @Published var fullList: [Item] = []
    
    @Published var subList: [Item] = []
    
    @Published var selectedListItems: [ItemID] = []
    
    typealias Item = Item
    
    typealias ItemID = ItemID
    
    var subListSize: Int = 10
    
    var subListOffset: Int = 0
    
    func addItem() {
        fatalError(String(NotImplementedError()))
    }
    
    func deleteItems() {
        fatalError(String(NotImplementedError()))
    }
    
    var context: NSManagedObjectContext
    var controller: NSFetchedResultsController<Item>
    init(context: NSManagedObjectContext, controller: NSFetchedResultsController<Item>){
        self.context = context
        self.controller = controller
        super.init()
        self.controller.delegate = self
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        context.perform { [self] in
            do{
                self.updateMainList(newItems: try context.fetch(controller.fetchRequest) as? [Item] ?? [])
            }catch{
                self.updateMainList(newItems: [])
            }
        }
    }
    func startController(){
        do{
            try controller.performFetch()
            fullList = controller.fetchedObjects ?? []
        }catch{}
        self.updateSubList()
    }
}

