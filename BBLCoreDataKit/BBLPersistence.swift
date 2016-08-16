//
//  BBLPersistence.swift
//  BBLCoreDataKit
//
//  Created by Joel Perry on 2/26/16.
//  Copyright © 2016 Joel Perry. All rights reserved.
//

import Foundation
import CoreData

public class BBLPersistence: NSObject {
    
    // MARK: - Properties
    private let modelName: String
    private let storeName: String
    private let shouldKillStore: Bool
    private var contexts = [NSManagedObjectContext]()
    private lazy var coordinator: NSPersistentStoreCoordinator = {
        guard let modelUrl = Bundle.main.url(forResource: self.modelName, withExtension: "momd"),
            let model = NSManagedObjectModel(contentsOf: modelUrl) else {
                fatalError("Couldn't create model")
        }
        
        let c = NSPersistentStoreCoordinator(managedObjectModel: model)
        self.configureSQLiteStore(c)
        NotificationCenter.default.addObserver(self, selector: #selector(contextSaved(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: nil)
        return c
    }()
    
    // MARK: - Public
    public convenience init(modelName: String) {
        self.init(modelName: modelName, storeName: modelName)
    }
    
    public convenience init(modelName: String, storeName: String) {
        self.init(modelName: modelName, storeName: storeName, shouldKillStore: false)
    }
    
    public init(modelName: String, storeName: String, shouldKillStore: Bool) {
        self.modelName = modelName
        self.storeName = storeName
        self.shouldKillStore = shouldKillStore
    }
    
    public func addContext(concurrencyType: NSManagedObjectContextConcurrencyType, mergePolicy: AnyObject) -> NSManagedObjectContext {
        let newContext = NSManagedObjectContext(concurrencyType: concurrencyType)
        newContext.persistentStoreCoordinator = coordinator
        newContext.mergePolicy = mergePolicy
        if concurrencyType == .privateQueueConcurrencyType { newContext.undoManager = nil }
        contexts.append(newContext)
        return newContext
    }
    
    // MARK: - Private
    private func configureSQLiteStore(_ coordinator: NSPersistentStoreCoordinator) {
        let options: [AnyHashable: Any] = [ NSMigratePersistentStoresAutomaticallyOption : true,
                        NSInferMappingModelAutomaticallyOption : true,
                        NSSQLitePragmasOption : [ "journalMode" : "DELETE"] ]
        
        let fileManager = FileManager.default
        guard let documentsUrl = try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else {
            fatalError("Couldn't create store URL")
        }
        
        let storeUrl = documentsUrl.appendingPathComponent(storeName + ".sqlite")
        print(storeUrl)
        
        if shouldKillStore { _ = try? fileManager.removeItem(at: storeUrl) }
        
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeUrl, options: options)
        }
        catch let error as NSError {
            let errorCodes = [ NSMigrationError,
                               NSMigrationCancelledError,
                               NSMigrationMissingSourceModelError,
                               NSMigrationMissingMappingModelError,
                               NSMigrationManagerSourceStoreError,
                               NSMigrationManagerDestinationStoreError,
                               NSEntityMigrationPolicyError,
                               NSInferredMappingModelError,
                               NSExternalRecordImportError ]
            
            if fileManager.fileExists(atPath: storeUrl.path) && errorCodes.contains(error.code) {
                _ = try? fileManager.removeItem(at: storeUrl)
                configureSQLiteStore(coordinator)
            } else {
                fatalError("Error creating store: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Notification handlers
    func contextSaved(_ notification: Notification) {
        if let savedContext = notification.object as? NSManagedObjectContext {
            let otherContexts = contexts.filter { $0 != savedContext }
            for context in otherContexts {
                context.perform {
                    if let updated = (notification as NSNotification).userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
                        context.perform {
                            updated.forEach { object in
                                context.object(with: object.objectID).willAccessValue(forKey: nil)
                            }
                            context.mergeChanges(fromContextDidSave: notification)
                        }
                    }
                }
            }
        }
    }
}

