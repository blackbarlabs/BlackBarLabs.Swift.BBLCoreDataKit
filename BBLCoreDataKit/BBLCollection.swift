//
//  BBLCollection.swift
//  BBLCoreDataKit
//
//  Created by Joel Perry on 2/26/16.
//  Copyright © 2016 Joel Perry. All rights reserved.
//

import Foundation
import CoreData

// MARK: - Protocols
public protocol BBLCollection {
    associatedtype T: NSManagedObject, BBLObject
    var context: NSManagedObjectContext! { get set }
    
    init()
    
    func object(identifier identifier: NSUUID) -> T
    func object(idString idString: String) -> T
    func frc(sortKey sortKey: String, ascending: Bool) -> NSFetchedResultsController
    func frc(sortKey sortKey: String, ascending: Bool, predicate: NSPredicate?) -> NSFetchedResultsController
    func frc(sortKey sortKey: String, ascending: Bool, predicate: NSPredicate?, sectionKeyPath: String?) -> NSFetchedResultsController
    func frc(sortDescriptors sortDescriptors: [NSSortDescriptor], predicate: NSPredicate?, sectionKeyPath: String?) -> NSFetchedResultsController
}

// MARK: - Extensions
extension NSManagedObjectContext {
    func insert<T: NSManagedObject where T: BBLObject>(object: T.Type) -> T {
        return NSEntityDescription.insertNewObjectForEntityForName(object.entityName, inManagedObjectContext:self) as! T
    }
}

public extension NSFetchedResultsController {
    func fetch(site: String) {
        do { try self.performFetch() }
        catch let error as NSError { print("===> \(site) fetch error: \(error.localizedDescription)") }
    }
}

public extension BBLCollection {
    // Initializers
    init(context: NSManagedObjectContext) {
        self.init()
        self.context = context
    }
    
    func object(identifier identifier: NSUUID) -> T {
        let request = NSFetchRequest(entityName: T.entityName)
        request.predicate = NSPredicate(format: "idString = %@", identifier.UUIDString)
        
        if let object = try! context.executeFetchRequest(request).first as? T {
            return object
        } else {
            let newObject = context.insert(T)
            newObject.idString = identifier.UUIDString
            return newObject
        }
    }
    
    func object(idString idString: String) -> T {
        let request = NSFetchRequest(entityName: T.entityName)
        request.predicate = NSPredicate(format: "idString = %@", idString)
        
        if let object = try! context.executeFetchRequest(request).first as? T {
            return object
        } else {
            let newObject = context.insert(T)
            newObject.idString = idString
            return newObject
        }
    }
    
    // FetchedResultsController constructors
    func frc(sortKey sortKey: String, ascending: Bool) -> NSFetchedResultsController {
        return frc(sortKey: sortKey, ascending: ascending, predicate: nil)
    }
    
    func frc(sortKey sortKey: String, ascending: Bool, predicate: NSPredicate?) -> NSFetchedResultsController {
        return frc(sortKey: sortKey, ascending: ascending, predicate: predicate, sectionKeyPath: nil)
    }
    
    func frc(sortKey sortKey: String, ascending: Bool, predicate: NSPredicate?, sectionKeyPath: String?) -> NSFetchedResultsController {
        let descriptor = NSSortDescriptor(key: sortKey, ascending: ascending)
        return frc(sortDescriptors: [ descriptor ], predicate: predicate, sectionKeyPath: sectionKeyPath)
    }
    
    func frc(sortDescriptors sortDescriptors: [NSSortDescriptor], predicate: NSPredicate?, sectionKeyPath: String?) -> NSFetchedResultsController {
        let fetchRequest = NSFetchRequest(entityName: T.entityName)
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.predicate = predicate
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: sectionKeyPath, cacheName: nil)
        return frc
    }
}


