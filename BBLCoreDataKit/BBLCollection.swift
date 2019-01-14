//
//  BBLCollection.swift
//  BBLCoreDataKit
//
//  Created by Joel Perry on 2/26/16.
//  Copyright © 2016 Joel Perry. All rights reserved.
//

import Foundation
import CoreData

public protocol BBLCollection {
    associatedtype Object: BBLObject
    var context: NSManagedObjectContext! { get set }
    init()
}

public extension BBLCollection {
    init(context: NSManagedObjectContext) {
        self.init()
        self.context = context
    }
    
    func existingObject(withId idString: String) -> Object? {
        let request = Object.fetchRequest() as! NSFetchRequest<Object>
        request.predicate = NSPredicate(format: "idString == %@", idString)
        request.fetchLimit = 1
        request.returnsObjectsAsFaults = false
        return (try? context.fetch(request))?.first
    }
    
    func object(withId idString: String) -> Object {
        let request = Object.fetchRequest() as! NSFetchRequest<Object>
        request.predicate = NSPredicate(format: "idString == %@", idString)
        request.fetchLimit = 1
        request.returnsObjectsAsFaults = false
        
        switch (try? context.fetch(request))?.first {
        case .some(let object):
            return object
            
        case .none:
            let newObject = Object(context: context)
            newObject.idString = idString
            return newObject
        }
    }
    
    // FetchedResultsController constructors
    func frc(sortKey: String = #keyPath(BBLObject.idString), ascending: Bool = true,
             predicate: NSPredicate? = nil, sectionKeyPath: String? = nil) -> NSFetchedResultsController<Object> {
        let descriptor = NSSortDescriptor(key: sortKey, ascending: ascending)
        return frc(sortDescriptors: [ descriptor ], predicate: predicate, sectionKeyPath: sectionKeyPath)
    }
    
    func frc(sortDescriptors: [NSSortDescriptor], predicate: NSPredicate? = nil, sectionKeyPath: String? = nil) -> NSFetchedResultsController<Object> {
        let request = Object.fetchRequest() as! NSFetchRequest<Object>
        request.sortDescriptors = sortDescriptors
        request.predicate = predicate
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: sectionKeyPath, cacheName: nil)
        return frc
    }
    
    func objects(withCompoundPredicate predicate: NSCompoundPredicate, sortDescriptors: [NSSortDescriptor],
                 sectionKeyPath: String? = nil) -> NSFetchedResultsController<Object> {
        return frc(sortDescriptors: sortDescriptors, predicate: predicate, sectionKeyPath: sectionKeyPath)
    }
    
    func objects(withAndPredicates subpredicates: [NSPredicate], sortDescriptors: [NSSortDescriptor],
                 sectionKeyPath: String? = nil) -> NSFetchedResultsController<Object> {
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)
        return objects(withCompoundPredicate: compoundPredicate, sortDescriptors: sortDescriptors, sectionKeyPath: sectionKeyPath)
    }
    
    func objects(withOrPredicates subpredicates: [NSPredicate], sortDescriptors: [NSSortDescriptor],
                 sectionKeyPath: String? = nil) -> NSFetchedResultsController<Object> {
        let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: subpredicates)
        return objects(withCompoundPredicate: compoundPredicate, sortDescriptors: sortDescriptors, sectionKeyPath: sectionKeyPath)
    }
    
    func changes(forObject object: BBLObject) -> NSFetchedResultsController<Object> {
        let predicate = NSPredicate(format: "idString == %@", object.idString)
        return frc(sortKey: #keyPath(BBLObject.idString), ascending: true, predicate: predicate)
    }
    
    func changes(forObject object: BBLObject?) -> NSFetchedResultsController<Object>? {
        guard let object = object else { return nil }
        let predicate = NSPredicate(format: "idString == %@", object.idString)
        return frc(sortKey: #keyPath(BBLObject.idString), ascending: true, predicate: predicate)
    }
    
    // Default FetchedResultsController
    func allObjects() -> NSFetchedResultsController<Object> {
        return frc()
    }
    
    // Operations
    func deleteAll() {
        let request = Object.fetchRequest() as! NSFetchRequest<Object>
        request.includesPropertyValues = false
        guard let fetched = try? context.fetch(request) else { return }
        fetched.forEach { (object) in context.delete(object) }
    }
}
