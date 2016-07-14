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
    func insert<T: NSManagedObject where T: BBLObject>(_ object: T.Type) -> T {
        return NSEntityDescription.insertNewObject(forEntityName: object.entityName, into:self) as! T
    }
}

/*public extension NSFetchedResultsController {
    func fetch(site: String) {
        do { try self.performFetch() }
        catch let error as NSError { NSLog("===> %@ save error: %@", site, error.localizedDescription) }
    }
}*/

public extension BBLCollection {
    
    // Initializers
    init(context: NSManagedObjectContext) {
        self.init()
        self.context = context
    }
    
    // Objects
    func object(identifier: UUID) -> Object {
        let request = NSFetchRequest<Object>(entityName: entityName)
        request.predicate = Predicate(format: "idString == %@", identifier.uuidString)
        
        if let object = try! context.fetch(request).first {
            return object
        } else {
            let newObject = context.insert(Object.self)
            newObject.idString = identifier.uuidString
            return newObject
        }
    }
    
    func object(idString: String) -> Object {
        let request = NSFetchRequest<Object>(entityName: entityName)
        request.predicate = Predicate(format: "idString == %@", idString)
        
        if let object = try! context.fetch(request).first {
            return object
        } else {
            let newObject = context.insert(Object.self)
            newObject.idString = idString
            return newObject
        }
    }
    
    var entityName: String { return Object.entityName }
    
    // FetchedResultsController constructors
    func frc(sortKey: String = "idString", ascending: Bool = true, predicate: Predicate? = nil, sectionKeyPath: String? = nil) -> NSFetchedResultsController<Object> {
        let descriptor = SortDescriptor(key: sortKey, ascending: ascending)
        return frc(sortDescriptors: [ descriptor ], predicate: predicate, sectionKeyPath: sectionKeyPath)
    }
    
    func frc(sortDescriptors: [SortDescriptor], predicate: Predicate? = nil, sectionKeyPath: String? = nil) -> NSFetchedResultsController<Object> {
        let fetchRequest = NSFetchRequest<Object>(entityName: entityName)
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.predicate = predicate
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: sectionKeyPath, cacheName: nil)
        return frc
    }
    
    // Default FetchedResultsController
    func allObjects() -> NSFetchedResultsController<Object> {
        return frc()
    }
}
