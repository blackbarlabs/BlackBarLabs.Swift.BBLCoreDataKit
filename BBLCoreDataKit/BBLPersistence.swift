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
  
  public init(modelName: String, storeName: String? = nil, shouldKillStore: Bool = false, storeType: StoreType = .sqlite) {
    self.modelName = modelName
    self.storeName = storeName ?? modelName
    self.shouldKillStore = shouldKillStore
    self.storeType = storeType
  }
  
  public func addContext(concurrencyType: NSManagedObjectContextConcurrencyType, mergePolicy: AnyObject) -> NSManagedObjectContext {
    let newContext = NSManagedObjectContext(concurrencyType: concurrencyType)
    newContext.persistentStoreCoordinator = coordinator
    newContext.mergePolicy = mergePolicy
    if concurrencyType == .privateQueueConcurrencyType { newContext.undoManager = nil }
    contexts.insert(newContext)
    if EnvironmentVariables.logContexts { print("[BBLCoreDataKit] \(contexts.count) contexts on add for \(modelName)") }
    return newContext
  }
  
  public func addChildContext(forContext parentContext: NSManagedObjectContext, concurrencyType: NSManagedObjectContextConcurrencyType, mergePolicy: AnyObject) -> NSManagedObjectContext {
    let newContext = NSManagedObjectContext(concurrencyType: concurrencyType)
    newContext.mergePolicy = mergePolicy
    if concurrencyType == .privateQueueConcurrencyType { newContext.undoManager = nil }
    newContext.parent = parentContext
    return newContext
  }
  
  public func removeContext(_ context: NSManagedObjectContext) {
    contexts.remove(context)
    if EnvironmentVariables.logContexts { print("[BBLCoreDataKit] \(contexts.count) contexts on remove for \(modelName)") }
  }
  
  public var model: NSManagedObjectModel!
  
  // MARK: Private
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
                                           name: .NSManagedObjectContextDidSave,
                                           object: nil)
    return c
  }()
  
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
  
  // MARK: Notification handlers
  @objc func contextSaved(_ notification: Notification) {
    guard let savedContext = notification.object as? NSManagedObjectContext, savedContext.parent == nil else { return }
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

// MARK: - Global
enum EnvironmentVariables: String {
  case BBLCOREDATAKIT_LOG_CONTEXTS
  
  var value: String {
    return ProcessInfo.processInfo.environment[self.rawValue] ?? ""
  }
}

extension EnvironmentVariables {
  static var logContexts: Bool { return EnvironmentVariables.BBLCOREDATAKIT_LOG_CONTEXTS.value == "enable" }
}
