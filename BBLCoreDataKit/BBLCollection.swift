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
    associatedtype Object: BBLObject
    var context: NSManagedObjectContext! { get set }
    init()
}

// MARK: - Extensions
extension NSManagedObjectContext {
    func insert<T>(_ object: T.Type) -> T where T: BBLObject {
        return NSEntityDescription.insertNewObject(forEntityName: object.entityName, into:self) as! T
    }
}

public extension NSFetchedResultsController {
    @objc func fetch(_ site: String) {
        do { try self.performFetch() }
        catch let error { NSLog("===> %@ fetch error: %@", site, error.localizedDescription) }
    }
}

public extension BBLCollection {
    
    // Initializers
    init(context: NSManagedObjectContext) {
        self.init()
        self.context = context
    }
    
    // Objects
    func existingObject(identifier: UUID) -> Object? {
        let request = NSFetchRequest<Object>(entityName: entityName)
        request.predicate = NSPredicate(format: "idString == %@", identifier.uuidString)
        request.fetchLimit = 1
        request.returnsObjectsAsFaults = false
        guard let fetched = try? context.fetch(request) else { return nil }
        return fetched.first
    }
    
    func existingObject(idString: String) -> Object? {
        let request = NSFetchRequest<Object>(entityName: entityName)
        request.predicate = NSPredicate(format: "idString == %@", idString)
        request.fetchLimit = 1
        request.returnsObjectsAsFaults = false
        guard let fetched = try? context.fetch(request) else { return nil }
        return fetched.first
    }
    
    func object(identifier: UUID) -> Object {
        let request = NSFetchRequest<Object>(entityName: entityName)
        request.predicate = NSPredicate(format: "idString == %@", identifier.uuidString)
        request.fetchLimit = 1
        request.returnsObjectsAsFaults = false
        
        if let fetched = try? context.fetch(request), !fetched.isEmpty {
            return fetched.first!
        } else {
            let newObject = context.insert(Object.self)
            newObject.idString = identifier.uuidString
            return newObject
        }
    }
    
    func object(idString: String) -> Object {
        let request = NSFetchRequest<Object>(entityName: entityName)
        request.predicate = NSPredicate(format: "idString == %@", idString)
        request.fetchLimit = 1
        request.returnsObjectsAsFaults = false
        
        if let fetched = try? context.fetch(request), !fetched.isEmpty {
            return fetched.first!
        } else {
            let newObject = context.insert(Object.self)
            newObject.idString = idString
            return newObject
        }
    }
    
    var entityName: String { return Object.entityName }
    
    // FetchedResultsController constructors
    func frc(sortKey: String = #keyPath(BBLObject.idString), ascending: Bool = true, predicate: NSPredicate? = nil, sectionKeyPath: String? = nil) -> NSFetchedResultsController<Object> {
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
    
    func objects(withCompoundPredicate predicate: NSCompoundPredicate, sortDescriptors: [NSSortDescriptor], sectionKeyPath: String? = nil) -> NSFetchedResultsController<Object> {
        return frc(sortDescriptors: sortDescriptors, predicate: predicate, sectionKeyPath: sectionKeyPath)
    }
    
    func objects(withAndPredicates subpredicates: [NSPredicate], sortDescriptors: [NSSortDescriptor], sectionKeyPath: String? = nil) -> NSFetchedResultsController<Object> {
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)
        return objects(withCompoundPredicate: compoundPredicate, sortDescriptors: sortDescriptors, sectionKeyPath: sectionKeyPath)
    }
    
    func objects(withOrPredicates subpredicates: [NSPredicate], sortDescriptors: [NSSortDescriptor], sectionKeyPath: String? = nil) -> NSFetchedResultsController<Object> {
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
