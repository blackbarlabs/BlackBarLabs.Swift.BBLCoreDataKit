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
    public enum StoreType {
        case sqlite
        case inMemory
    }
    
    // MARK: - Properties
    private let modelName: String
    private let storeName: String
    private let shouldKillStore: Bool
    private let storeType: StoreType
    private var contexts = Set<NSManagedObjectContext>()
    private lazy var coordinator: NSPersistentStoreCoordinator = {
        guard let modelUrl = Bundle.main.url(forResource: self.modelName, withExtension: "momd"),
            let model = NSManagedObjectModel(contentsOf: modelUrl) else {
                fatalError("Couldn't create model")
        }
        
        self.model = model
        let c = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        switch storeType {
        case .sqlite:
            self.configureSQLiteStore(c)
            
        case .inMemory:
            self.configureInMemoryStore(c)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(contextSaved(_:)),
                                               name: Notification.Name.NSManagedObjectContextDidSave,
                                               object: nil)
        return c
    }()
    
    // MARK: - Public
    public convenience init(modelName: String) {
        self.init(modelName: modelName, storeName: modelName)
    }
    
    public convenience init(modelName: String, storeName: String) {
        self.init(modelName: modelName, storeName: storeName, shouldKillStore: false)
    }
    
    public convenience init(modelName: String, storeName: String, shouldKillStore: Bool) {
        self.init(modelName: modelName, storeName: storeName, shouldKillStore: shouldKillStore, storeType: .sqlite)
    }
    
    public init(modelName: String, storeName: String, shouldKillStore: Bool, storeType: StoreType) {
        self.modelName = modelName
        self.storeName = storeName
        self.shouldKillStore = shouldKillStore
        self.storeType = storeType
    }
    
    public func addContext(concurrencyType: NSManagedObjectContextConcurrencyType, mergePolicy: AnyObject) -> NSManagedObjectContext {
        let newContext = NSManagedObjectContext(concurrencyType: concurrencyType)
        newContext.persistentStoreCoordinator = coordinator
        newContext.mergePolicy = mergePolicy
        if concurrencyType == .privateQueueConcurrencyType { newContext.undoManager = nil }
        contexts.insert(newContext)
        print("===> \(contexts.count) contexts on add")
        return newContext
    }
    
    public func removeContext(_ context: NSManagedObjectContext) {
        contexts.remove(context)
        print("===> \(contexts.count) contexts on remove")
    }
    
    public var model: NSManagedObjectModel!
    
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
    
    private func configureInMemoryStore(_ coordinator: NSPersistentStoreCoordinator) {
        guard coordinator.persistentStores.isEmpty else { return }
        do {
            try coordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        } catch let error {
            fatalError("Error creating store: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Notification handlers
    @objc func contextSaved(_ notification: Notification) {
        if let savedContext = notification.object as? NSManagedObjectContext {
            let otherContexts = contexts.filter { $0 != savedContext }
                                        .filter { $0.persistentStoreCoordinator == savedContext.persistentStoreCoordinator }
            
            otherContexts.forEach { (context) in
                context.perform {
                    if let updated = (notification as NSNotification).userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
                        updated.forEach { (object) in
                            context.object(with: object.objectID).willAccessValue(forKey: nil)
                        }
                        context.mergeChanges(fromContextDidSave: notification)
                    }
                }
            }
        }
    }
}

