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
        guard let modelUrl = NSBundle.mainBundle().URLForResource(self.modelName, withExtension: "momd"),
            let model = NSManagedObjectModel(contentsOfURL: modelUrl) else {
                fatalError("Couldn't create model")
        }
        
        let c = NSPersistentStoreCoordinator(managedObjectModel: model)
        self.configureSQLiteStore(c)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(contextSaved(_:)), name: NSManagedObjectContextDidSaveNotification, object: nil)
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
    
    public func addContext(concurrencyType concurrencyType: NSManagedObjectContextConcurrencyType, mergePolicy: AnyObject) -> NSManagedObjectContext {
        let newContext = NSManagedObjectContext(concurrencyType: concurrencyType)
        newContext.persistentStoreCoordinator = coordinator
        newContext.mergePolicy = mergePolicy
        if concurrencyType == .PrivateQueueConcurrencyType { newContext.undoManager = nil }
        contexts.append(newContext)
        return newContext
    }
    
    // MARK: - Private
    private func configureSQLiteStore(coordinator: NSPersistentStoreCoordinator) {
        let options = [ NSMigratePersistentStoresAutomaticallyOption : true,
                        NSInferMappingModelAutomaticallyOption : true,
                        NSSQLitePragmasOption : [ "journalMode" : "DELETE"] ]
        
        let fileManager = NSFileManager.defaultManager()
        guard let documentsUrl = try? fileManager.URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false) else {
            fatalError("Couldn't find document directory")
        }
        let storeUrl = documentsUrl.URLByAppendingPathComponent(storeName + ".sqlite")
        print(storeUrl)
        
        if shouldKillStore { _ = try? fileManager.removeItemAtURL(storeUrl) }
        
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeUrl, options: options)
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
            
            if fileManager.fileExistsAtPath(storeUrl.path!) && errorCodes.contains(error.code) {
                _ = try? fileManager.removeItemAtURL(storeUrl)
                configureSQLiteStore(coordinator)
            } else {
                fatalError("Error creating store: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Notification handlers
    func contextSaved(notification: NSNotification) {
        if let savedContext = notification.object as? NSManagedObjectContext {
            let otherContexts = contexts.filter { $0 != savedContext }
            for context in otherContexts {
                context.performBlock {
                    if let updated = notification.userInfo?[NSUpdatedObjectsKey] as? [NSManagedObject] {
                        for object in updated {
                            context.objectWithID(object.objectID).willAccessValueForKey(nil)
                        }
                    }
                    context.mergeChangesFromContextDidSaveNotification(notification)
                }
            }
        }
    }
}

