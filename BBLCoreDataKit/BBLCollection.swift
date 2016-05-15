//
//  BBLCollection.swift
//  BBLCoreDataKit
//
//  Created by Joel Perry on 2/26/16.
//  Copyright © 2016 Joel Perry. All rights reserved.
//

import Foundation
import CoreData

// MARK: - BBLCollection Protocol
public protocol BBLCollection {
    associatedtype Object: NSManagedObject, BBLObject
    var context: NSManagedObjectContext! { get set }
    init()
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
        catch let error as NSError { NSLog("===> %@ save error: %@", site, error.localizedDescription) }
    }
}

public extension BBLCollection {
    
    // Initializers
    init(context: NSManagedObjectContext) {
        self.init()
        self.context = context
    }
    
    // Objects
    func object(identifier identifier: NSUUID) -> Object {
        let request = NSFetchRequest(entityName: Object.entityName)
        request.predicate = NSPredicate(format: "idString == %@", identifier.UUIDString)
        
        if let object = try! context.executeFetchRequest(request).first as? Object {
            return object
        } else {
            let newObject = context.insert(Object)
            newObject.idString = identifier.UUIDString
            return newObject
        }
    }
    
    func object(idString idString: String) -> Object {
        let request = NSFetchRequest(entityName: Object.entityName)
        request.predicate = NSPredicate(format: "idString == %@", idString)
        
        if let object = try! context.executeFetchRequest(request).first as? Object {
            return object
        } else {
            let newObject = context.insert(Object)
            newObject.idString = idString
            return newObject
        }
    }
    
    // FetchedResultsController constructors
    func frc(sortKey sortKey: String = "idString", ascending: Bool = true, predicate: NSPredicate? = nil, sectionKeyPath: String? = nil) -> NSFetchedResultsController {
        let descriptor = NSSortDescriptor(key: sortKey, ascending: ascending)
        return frc(sortDescriptors: [ descriptor ], predicate: predicate, sectionKeyPath: sectionKeyPath)
    }
    
    func frc(sortDescriptors sortDescriptors: [NSSortDescriptor], predicate: NSPredicate? = nil, sectionKeyPath: String? = nil) -> NSFetchedResultsController {
        let fetchRequest = NSFetchRequest(entityName: Object.entityName)
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.predicate = predicate
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: sectionKeyPath, cacheName: nil)
        return frc
    }
    
    // Default FetchedResultsController
    var allObjects: NSFetchedResultsController {
        return frc()
    }
}
