//
//  BBLCollection.swift
//  BBLCoreDataKit
//
//  Created by Joel Perry on 2/26/16.
//  Copyright © 2016 Joel Perry. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
    func insert<T>(_ object: T.Type) -> T where T: BBLObject {
        return NSEntityDescription.insertNewObject(forEntityName: object.entityName, into:self) as! T
    }
}

// MARK: -
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
        let request = NSFetchRequest<Object>(entityName: entityName)
        request.predicate = NSPredicate(format: "idString == %@", idString)
        request.fetchLimit = 1
        request.returnsObjectsAsFaults = false
        return (try? context.fetch(request))?.first
    }
    
    func object(withId idString: String) -> Object {
        let request = NSFetchRequest<Object>(entityName: entityName)
        request.predicate = NSPredicate(format: "idString == %@", idString)
        request.fetchLimit = 1
        request.returnsObjectsAsFaults = false
        
        switch (try? context.fetch(request))?.first {
        case .some(let object):
            return object
            
        case .none:
            let newObject = context.insert(Object.self)
            newObject.idString = idString
            return newObject
        }
    }
    
    var entityName: String { return Object.entityName }
    
    // FetchedResultsController constructors
    func frc(sortKey: String = #keyPath(BBLObject.idString), ascending: Bool = true,
             predicate: NSPredicate? = nil, sectionKeyPath: String? = nil) -> NSFetchedResultsController<Object> {
        let descriptor = NSSortDescriptor(key: sortKey, ascending: ascending)
        return frc(sortDescriptors: [ descriptor ], predicate: predicate, sectionKeyPath: sectionKeyPath)
    }
    
    func frc(sortDescriptors: [NSSortDescriptor], predicate: NSPredicate? = nil, sectionKeyPath: String? = nil) -> NSFetchedResultsController<Object> {
        let fetchRequest = NSFetchRequest<Object>(entityName: entityName)
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.predicate = predicate
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: sectionKeyPath, cacheName: nil)
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
        let request = NSFetchRequest<Object>(entityName: entityName)
        request.includesPropertyValues = false
        guard let fetched = try? context.fetch(request) else { return }
        fetched.forEach { (object) in context.delete(object) }
    }
}
