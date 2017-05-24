//
//  BBLStack.swift
//  BBLCoreDataKit
//
//  Created by Joel Perry on 2/26/16.
//  Copyright © 2016 Joel Perry. All rights reserved.
//

import Foundation
import CoreData

// MARK: - BBLStack Protocol
public protocol BBLStack {
    static var persistence: BBLPersistence { get }
    var context: NSManagedObjectContext! { get set }
    init()
}

// MARK: - Extensions
public extension BBLStack {
    init(concurrencyType: NSManagedObjectContextConcurrencyType, mergePolicy: AnyObject = NSErrorMergePolicy) {
        self.init()
        self.context = Self.persistence.addContext(concurrencyType: concurrencyType, mergePolicy: mergePolicy)
    }
    
    func deinitialize() {
        Self.persistence.removeContext(context)
    }
    
    var model: NSManagedObjectModel {
        return Self.persistence.model
    }
    
    func performBlock(_ block: @escaping () -> Void) { context.perform(block) }
    
    func performBlockAndWait(_ block: @escaping () -> Void) { context.performAndWait(block) }
    
    func save(_ site: String) {
        guard context.hasChanges else { return }
        do { try context.save() }
        catch let error as NSError { NSLog("===> %@ save error: %@", site, error.localizedDescription) }
    }
}

