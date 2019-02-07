//
//  BBLStack.swift
//  BBLCoreDataKit
//
//  Created by Joel Perry on 2/26/16.
//  Copyright © 2016 Joel Perry. All rights reserved.
//

import Foundation
import CoreData

public protocol BBLStack {
  static var persistence: BBLPersistence { get }
  var context: NSManagedObjectContext! { get set }
  init()
}

public extension BBLStack {
  init(concurrencyType: NSManagedObjectContextConcurrencyType, mergePolicy: AnyObject = NSErrorMergePolicy) {
    self.init()
    self.context = Self.persistence.addContext(concurrencyType: concurrencyType, mergePolicy: mergePolicy)
  }
  
  init(parentStack: BBLStack, concurrencyType: NSManagedObjectContextConcurrencyType, mergePolicy: AnyObject = NSErrorMergePolicy) {
    self.init()
    self.context = Self.persistence.addChildContext(forContext: parentStack.context, concurrencyType: concurrencyType, mergePolicy: mergePolicy)
  }
  
  func deinitialize() {
    Self.persistence.removeContext(context)
  }
  
  var model: NSManagedObjectModel {
    return Self.persistence.model
  }
  
  func performBlock(_ block: @escaping () -> Void) { context.perform(block) }
  
  func performBlockAndWait(_ block: @escaping () -> Void) { context.performAndWait(block) }
  
  func save() throws {
    guard context.hasChanges else { return }
    try context.save()
  }
}

